// Renders the main pages to PNGs with real fonts, for the README and for
// checking layouts without a display:
//   CATUSSH_SHOTS=/tmp/shots flutter test test/tool/screenshots_test.dart
// Skipped unless CATUSSH_SHOTS is set. Sessions are not connected; the
// monitor page is fed a reading parsed from the monitor fixtures.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:catussh/app/router.dart';
import 'package:catussh/core/models.dart';
import 'package:catussh/core/store.dart';
import 'package:catussh/core/vault.dart';
import 'package:catussh/features/shell/main_view.dart';
import 'package:catussh/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    if (File(f).existsSync()) loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  final out = Platform.environment['CATUSSH_SHOTS'];
  final skip = out == null ? 'CATUSSH_SHOTS not set' : null;

  setUpAll(() async {
    if (out == null) return;
    final material = '${Platform.environment['HOME']}/fvm/versions/stable/bin/cache/artifacts/material_fonts';
    await _loadFont('Roboto', ['$material/Roboto-Regular.ttf', '$material/Roboto-Medium.ttf', '$material/Roboto-Bold.ttf']);
    // The real app falls back through fontconfig; the test engine needs the arrows named.
    await _loadFont('DejaVu Sans', ['/usr/share/fonts/TTF/DejaVuSans.ttf']);
    await _loadFont('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
    await _loadFont('monospace', ['/usr/share/fonts/TTF/DejaVuSansMono.ttf', '/usr/share/fonts/TTF/DejaVuSansMono-Bold.ttf']);
    Directory(out).createSync(recursive: true);
  });

  Future<void> shoot(WidgetTester tester, String name, Brightness brightness, void Function(AppRouter) go, {int live = 0}) async {
    tester.view.devicePixelRatio = 1.5;
    tester.view.physicalSize = const Size(1280 * 1.5, 800 * 1.5);
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('catussh-shots');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = await tester.runAsync(() async => CatusshStore.load(vault: await Vault.open(directory: dir, useKeyring: false)));
    _seed(store!);
    final router = AppRouter(store);
    AppRouter.shared = router;
    final scheme = ColorScheme.fromSeed(seedColor: RX.accent, brightness: brightness);
    final key = GlobalKey();
    await tester.pumpWidget(MultiProvider(
      providers: [ChangeNotifierProvider.value(value: store), ChangeNotifierProvider.value(value: router)],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(scheme), home: const MainView()),
      ),
    ));
    go(router);
    await tester.pump(const Duration(milliseconds: 600));
    // Live sessions talk to a real server: give them real time.
    Future<void> wait(int quarters) async {
      for (var i = 0; i < quarters; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    await wait(live * 4);
    if (live > 0 && name == 'terminal') {
      router.terminals.first.terminal.textInput(_demoCommand);
      await wait(8);
    }
    await tester.pump(const Duration(milliseconds: 600));
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name-${brightness.name}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    router.shutdownAll();
    await tester.pumpWidget(const SizedBox());
    // Let the store's debounced writes and the agreement delay run out.
    await tester.pump(const Duration(seconds: 3));
    await tester.runAsync(store.flush);
  }

  for (final b in Brightness.values) {
    testWidgets('home ${b.name}', (t) => shoot(t, 'home', b, (r) => r.go(Place.home)), skip: skip != null);
    testWidgets('servers ${b.name}', (t) => shoot(t, 'servers', b, (r) => r.go(Place.servers)), skip: skip != null);
  }
  testWidgets('identities', (t) => shoot(t, 'identities', Brightness.light, (r) => r.go(Place.identities)), skip: skip != null);
  testWidgets('snippets', (t) => shoot(t, 'snippets', Brightness.light, (r) => r.go(Place.snippets)), skip: skip != null);
  testWidgets('forwards', (t) => shoot(t, 'forwards', Brightness.light, (r) => r.go(Place.portForward)), skip: skip != null);
  testWidgets('settings', (t) => shoot(t, 'settings', Brightness.dark, (r) => r.openSettings('terminal')), skip: skip != null);

  // With a test sshd, the live pages too.
  final sshd = Platform.environment['CATUSSH_TEST_SSHD'];
  for (final (tool, b) in [
    (ServerTool.monitor, Brightness.light),
    (ServerTool.monitor, Brightness.dark),
    (ServerTool.terminal, Brightness.dark),
    (ServerTool.files, Brightness.light),
  ]) {
    testWidgets('live ${tool.name} ${b.name}', (t) async {
      await shoot(t, tool.name, b, (r) {
        final m = r.store.machines.firstWhere((m) => m.name == 'localhost');
        if (tool == ServerTool.terminal) {
          final s = r.openTerminal(m);
          r.route = SessionRoute(ServerTool.terminal, s.id);
        } else {
          r.show(tool, m);
        }
      }, live: tool == ServerTool.monitor ? 8 : 4);
    }, skip: skip != null || sshd == null);
  }
}

const _demoCommand = 'clear; uname -srm; uptime; ls --color=always /; printf "\\e[1;35mcatussh\\e[0m on Flutter\\n"\r';

void _seed(CatusshStore store) {
  store.licenseAgreed = true;
  final sshd = Platform.environment['CATUSSH_TEST_SSHD'];
  if (sshd != null) {
    final [host, port, user, keyPath] = sshd.split(':');
    final local = Identity(username: user, privateKey: File(keyPath).readAsStringSync(), authenticAutomatically: false);
    store.putIdentity(local);
    store.putMachine(Machine(remoteAddress: host, remotePort: port, name: 'localhost', group: 'Home Lab', associatedIdentity: local.id));
  }
  final id = Identity(username: 'root', privateKey: '-----BEGIN OPENSSH PRIVATE KEY-----\nx', publicKey: 'ssh-ed25519 AAAA');
  store.putIdentity(id);
  store.putIdentity(Identity(username: 'deploy', password: 'x', group: 'CI'));
  final ago = DateTime.now().subtract(const Duration(minutes: 2));
  for (final (name, address, group, comment) in [
    ('web-01', '203.0.113.10', 'Production', 'nginx · edge'),
    ('web-02', '203.0.113.11', 'Production', 'nginx · edge'),
    ('db-primary', '198.51.100.20', 'Production', 'PostgreSQL 16'),
    ('build-runner', 'ci.example.com', 'CI', 'GitHub Actions runner'),
    ('homelab-pi', '192.0.2.50', 'Home Lab', 'Raspberry Pi 5'),
  ]) {
    store.putMachine(Machine(remoteAddress: address, remotePort: '22', name: name, group: group, comment: comment, lastConnection: ago));
  }
  store.putSnippet(Snippet(name: 'Disk usage', group: 'Ops', code: 'df -h /\ndu -sh /var/log')..avatar = 'disk');
  store.putSnippet(Snippet(name: 'Restart nginx', group: 'Web', code: 'sudo systemctl restart nginx')..avatar = 'restart');
  store.putPortForward(PortForward(bindPort: 15432, targetHost: '127.0.0.1', targetPort: 5432, usingMachine: store.machines[2].id));
}
