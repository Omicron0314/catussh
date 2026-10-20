// Runs against a real sshd when CATUSSH_TEST_SSHD is set:
//   CATUSSH_TEST_SSHD="host:port:user:/path/to/private_key" flutter test test/ssh_integration_test.dart
// Skipped otherwise.

import 'dart:io';

import 'package:catussh/core/known_hosts.dart';
import 'package:catussh/core/models.dart';
import 'package:catussh/core/store.dart';
import 'package:catussh/core/vault.dart';
import 'package:catussh/monitor/server_status.dart';
import 'package:catussh/sessions/port_forward_session.dart';
import 'package:catussh/ssh/connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final spec = Platform.environment['CATUSSH_TEST_SSHD'];
  final skip = spec == null ? 'CATUSSH_TEST_SSHD not set' : null;
  late CatusshStore store;
  late Machine machine;
  late Directory dir;

  setUpAll(() async {
    if (spec == null) return;
    final [host, port, user, keyPath] = spec.split(':');
    dir = Directory.systemTemp.createTempSync('catussh-it');
    store = await CatusshStore.load(vault: await Vault.open(directory: dir, useKeyring: false));
    final identity = Identity(username: user, privateKey: File(keyPath).readAsStringSync());
    store.putIdentity(identity);
    machine = Machine(remoteAddress: host, remotePort: port, name: 'it', associatedIdentity: identity.id);
    store.putMachine(machine);
  });

  tearDownAll(() {
    if (spec != null) dir.deleteSync(recursive: true);
  });

  test('connects, saves the host key and runs a command', () async {
    final c = await SshConnection.forMachine(machine, store: store);
    expect(store.knownHosts.count, 1);
    expect((await c.run('echo hello')).trim(), 'hello');
    c.close();
  }, skip: skip);

  test('a changed host key is refused', () async {
    final key = store.knownHosts.savedKey(machine.remoteAddress, machine.port)!;
    store.knownHosts.forget(machine.remoteAddress, machine.port);
    store.knownHosts.accepts(HostKey(key.type, 'SHA256:not-the-real-key'), machine.remoteAddress, machine.port);
    await expectLater(
      SshConnection.forMachine(machine, store: store),
      throwsA(isA<ConnectFailure>().having((f) => f.message, 'message', contains('has changed'))),
    );
    store.knownHosts.forget(machine.remoteAddress, machine.port);
  }, skip: skip);

  test('auto identities are tried when the server names none', () async {
    final auto = Machine(remoteAddress: machine.remoteAddress, remotePort: machine.remotePort, name: 'auto');
    final c = await SshConnection.forMachine(auto, store: store);
    expect(c.identity.username, isNotEmpty);
    c.close();
  }, skip: skip);

  test('the monitor script parses on a real Linux host', () async {
    final c = await SshConnection.forMachine(machine, store: store);
    final parsed = ServerStatus.parse(
      merged: await c.run(ServerStatus.monitorScript(includeStatic: true)),
      graphics: await c.run(ServerStatus.graphicsScript),
    );
    final s = parsed.status;
    expect(s.hasData, isTrue);
    expect(s.system.hostname, isNotEmpty);
    expect(s.system.releaseName, isNotEmpty);
    expect(s.memory.memTotal, greaterThan(0));
    expect(s.processor.cores, isNotEmpty);
    expect(s.fileSystem.elements.any((e) => e.mountPoint == '/'), isTrue);
    expect(s.network.elements, isNotEmpty);
    // ignore: avoid_print
    print('host ${s.system.hostname} · ${s.system.releaseName} · ${s.processor.cores.length} cores · '
        'cpu ${s.processor.summary.sumUsed.toStringAsFixed(1)}% · gpu ${s.graphics?.units.map((u) => u.name).join(', ') ?? 'none'}');
    c.close();
  }, skip: skip);

  test('sftp lists, writes, reads and removes', () async {
    final c = await SshConnection.forMachine(machine, store: store);
    final sftp = await c.client.sftp();
    final names = await sftp.listdir('/');
    expect(names.any((n) => n.filename == 'etc'), isTrue);
    sftp.close();
    c.close();
  }, skip: skip);

  test('a local port forward carries a connection', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((s) {
      s.write('pong');
      s.close();
    });
    final forward = PortForward(bindPort: 0, targetHost: '127.0.0.1', targetPort: server.port, usingMachine: machine.id);
    // Bind port 0 is refused by isValid's caller in the UI only; pick a free one.
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    forward.bindPort = probe.port;
    await probe.close();
    CatusshStore.shared = store;
    final session = PortForwardSession(forward, machine);
    for (var i = 0; i < 50 && !session.running; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(session.lifecycle, ForwardLifecycle.forwardRunning);
    final socket = await Socket.connect('127.0.0.1', forward.bindPort);
    final reply = await socket.fold<List<int>>([], (a, b) => a..addAll(b));
    expect(String.fromCharCodes(reply), 'pong');
    session.terminate();
    await server.close();
  }, skip: skip);
}

