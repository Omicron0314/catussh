// Fills a development profile with the servers of the README screenshots:
//   CATUSSH_SEED_DIR=/tmp/catussh-demo CATUSSH_SEED_KEY=~/.ssh/key \
//     flutter test test/tool/seed_demo_test.dart
//   CATUSSH_DATA_DIR=/tmp/catussh-demo build/linux/x64/debug/bundle/catussh
// Skipped unless CATUSSH_SEED_DIR is set.

import 'dart:io';

import 'package:catussh/core/models.dart';
import 'package:catussh/core/store.dart';
import 'package:catussh/core/vault.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dir = Platform.environment['CATUSSH_SEED_DIR'];
  test('seed demo profile', () async {
    final store = await CatusshStore.load(vault: await Vault.open(directory: Directory(dir!), useKeyring: false));
    final key = Platform.environment['CATUSSH_SEED_KEY'];
    final user = Platform.environment['USER'] ?? 'root';
    final local = Identity(
      username: user,
      privateKey: key == null ? '' : File(key).readAsStringSync(),
      comment: 'Test sshd',
      group: 'Lab',
    );
    store.putIdentity(local);
    store.putIdentity(Identity(username: 'deploy', password: 'demo', authenticAutomatically: false, group: 'CI'));
    final ago = DateTime.now().subtract(const Duration(minutes: 2));
    store.putMachine(Machine(
        remoteAddress: '127.0.0.1', remotePort: '2222', name: 'localhost', group: 'Home Lab',
        comment: 'Arch Linux, test sshd', associatedIdentity: local.id, lastConnection: ago));
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
    store.putSnippet(Snippet(name: 'Restart nginx', group: 'Web', code: 'sudo systemctl restart nginx\nsystemctl status nginx --no-pager')..avatar = 'restart');
    store.putSnippet(Snippet(name: 'Who is logged in', group: 'Ops', code: 'w\nlast -n 5')..avatar = 'search');
    final localhost = store.machines.first;
    store.putPortForward(PortForward(bindPort: 15432, targetHost: '127.0.0.1', targetPort: 5432, usingMachine: localhost.id));
    store.putPortForward(PortForward(
        bindPort: 8080, targetHost: '127.0.0.1', targetPort: 80, usingMachine: localhost.id,
        forwardOrientation: ForwardOrientation.listenRemote));
    store.licenseAgreed = true;
    store.saveSettings();
    await store.flush();
  }, skip: dir == null ? 'CATUSSH_SEED_DIR not set' : null);
}

