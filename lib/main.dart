import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app/router.dart';
import 'core/store.dart';
import 'core/strings.dart';
import 'l10n/app_localizations.dart';
import 'features/shell/main_view.dart';
import 'features/menubar/tray.dart';
import 'ui/dynamic_accent.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final desktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  if (desktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'catussh',
        size: Size(1200, 780),
        minimumSize: Size(940, 600),
        center: true,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
  await DynamicAccent.load();
  final store = await CatusshStore.load();
  final router = AppRouter(store);
  AppRouter.shared = router;
  if (desktop) TrayController.instance.attach(router);
  runApp(CatusshApp(store: store, router: router));
  _openFromEnvironment(store, router);
}

/// `CATUSSH_OPEN=terminal:<server name>` (or files, editor, monitor) opens a
/// server's tool at launch, like `open catussh://` would; handy for desktop
/// launchers and for checking a build by hand.
void _openFromEnvironment(CatusshStore store, AppRouter router) {
  final spec = Platform.environment['CATUSSH_OPEN'];
  if (spec == null || !spec.contains(':')) return;
  final colon = spec.indexOf(':');
  final tool = ServerTool.values.where((t) => t.name == spec.substring(0, colon)).firstOrNull;
  final name = spec.substring(colon + 1);
  final machine = store.machines.where((m) => m.name == name).firstOrNull;
  if (tool == null || machine == null) return;
  Future<void>.delayed(const Duration(milliseconds: 800), () => router.show(tool, machine));
}

class CatusshApp extends StatefulWidget {
  const CatusshApp({super.key, required this.store, required this.router});
  final CatusshStore store;
  final AppRouter router;

  @override
  State<CatusshApp> createState() => _CatusshAppState();
}

class _CatusshAppState extends State<CatusshApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Storing is debounced; leaving the foreground writes what is waiting.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      widget.store.flush();
    } else {
      DynamicAccent.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.store),
        ChangeNotifierProvider.value(value: widget.router),
      ],
      child: Consumer<CatusshStore>(
        builder: (context, store, _) => ValueListenableBuilder<Color?>(
          valueListenable: DynamicAccent.seed,
          builder: (context, dynamicSeed, _) {
            final seed = store.dynamicColor && dynamicSeed != null ? dynamicSeed : store.seedColor;
            ColorScheme scheme(Brightness b) => ColorScheme.fromSeed(seedColor: seed, brightness: b);
            // Messages written outside widgets (sessions, stores) use the same
            // locale the interface resolved to.
            final locale = store.locale == 'system'
                ? basicLocaleListResolution(
                    WidgetsBinding.instance.platformDispatcher.locales, L10n.supportedLocales)
                : Locale(store.locale);
            S.setLocale(locale);
            return MaterialApp(
              title: 'catussh',
              debugShowCheckedModeBanner: false,
              locale: locale,
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              themeMode: store.appearance,
              theme: buildTheme(scheme(Brightness.light)),
              darkTheme: buildTheme(scheme(Brightness.dark)),
              home: const MainView(),
            );
          },
        ),
      ),
    );
  }
}
