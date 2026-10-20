// The main window: sidebar and the page it selects (MainView.swift).
// Session pages stay alive while hidden, so terminals keep their scrollback
// and connections, like SessionPages in the Swift app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/store.dart';
import '../editor/editor_page.dart';
import '../files/file_transfer_page.dart';
import '../home/home_view.dart';
import '../identities/identities_view.dart';
import '../monitor/monitor_page.dart';
import '../port_forward/port_forward_view.dart';
import '../servers/server_editor.dart';
import '../servers/servers_view.dart';
import '../settings/agreement.dart';
import '../settings/settings_view.dart';
import '../snippets/snippets_view.dart';
import '../terminal/terminal_page.dart';
import 'sidebar.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  bool _sidebarVisible = true;
  late final AppRouter _router = context.read<AppRouter>();

  @override
  void initState() {
    super.initState();
    _router.newServerRequests.addListener(_newServer);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (!context.read<CatusshStore>().licenseAgreed) {
        await showAgreement(context);
      }
      if (!mounted) return;
      final problem = context.read<CatusshStore>().vault.problem;
      if (problem != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(problem), duration: const Duration(seconds: 10), showCloseIcon: true),
        );
      }
    });
  }

  @override
  void dispose() {
    _router.newServerRequests.removeListener(_newServer);
    super.dispose();
  }

  void _newServer() {
    if (mounted) showServerEditor(context);
  }

  @override
  Widget build(BuildContext context) {
    final router = context.watch<AppRouter>();
    final route = router.route;
    final scheme = Theme.of(context).colorScheme;

    Widget? place;
    if (route case PlaceRoute(place: final p)) {
      place = switch (p) {
        Place.home => const HomeView(),
        Place.servers => const ServersView(),
        Place.identities => const IdentitiesView(),
        Place.snippets => const SnippetsView(),
        Place.portForward => const PortForwardView(),
        Place.settings => const SettingsView(),
      };
    }

    final sessions = <(SessionRoute, Widget)>[
      for (final t in router.terminals)
        (SessionRoute(ServerTool.terminal, t.id), TerminalPage(key: ValueKey('t${t.id}'), session: t)),
      for (final t in router.transfers)
        (SessionRoute(ServerTool.files, t.id), FileTransferPage(key: ValueKey('f${t.id}'), session: t)),
      for (final e in router.editors)
        (SessionRoute(ServerTool.editor, e.id), EditorPage(key: ValueKey('e${e.id}'), workspace: e)),
      for (final m in router.monitors)
        (SessionRoute(ServerTool.monitor, m.id), MonitorPage(key: ValueKey('m${m.id}'), session: m)),
    ];

    final content = Stack(
      children: [
        if (place != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(key: ValueKey(route), child: place),
          ),
        for (final (r, page) in sessions)
          Offstage(
            offstage: r != route,
            child: TickerMode(enabled: r == route, child: ActivePage(active: r == route, child: page)),
          ),
      ],
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () => router.openSettings(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true): () => showServerEditor(context),
        const SingleActivator(LogicalKeyboardKey.backslash, control: true): () =>
            setState(() => _sidebarVisible = !_sidebarVisible),
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainer,
        body: Row(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _sidebarVisible
                  ? Sidebar(onHide: () => setState(() => _sidebarVisible = false))
                  : const SizedBox(width: 0),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(_sidebarVisible ? 0 : 8, 8, 8, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    color: scheme.surfaceContainerLow,
                    child: Stack(
                      children: [
                        Positioned.fill(child: content),
                        if (!_sidebarVisible)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: IconButton.filledTonal(
                              tooltip: 'Show Sidebar (Ctrl+\\)',
                              icon: const Icon(Icons.view_sidebar_outlined),
                              onPressed: () => setState(() => _sidebarVisible = true),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tells a session page whether it is the one showing (Environment
/// isActivePage in the Swift app).
class ActivePage extends InheritedWidget {
  const ActivePage({super.key, required this.active, required super.child});
  final bool active;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActivePage>()?.active ?? true;

  @override
  bool updateShouldNotify(ActivePage oldWidget) => oldWidget.active != active;
}
