import 'dart:io';

import 'package:catussh/core/format.dart';
import 'package:catussh/core/models.dart';
import 'package:catussh/core/store.dart';
import 'package:catussh/core/vault.dart';
import 'package:catussh/sessions/batch_exec.dart';
import 'package:catussh/sessions/editor_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('machine command and search', () {
    final m = Machine(remoteAddress: '10.0.0.8', remotePort: '2222', name: 'web-01', group: 'Production');
    expect(m.getCommand('root'), 'ssh root@10.0.0.8 -p 2222');
    expect(m.getCommand(null, insertLeadingSSH: false), '10.0.0.8 -p 2222');
    expect(m.isQualifiedForSearch('prod'), isTrue);
    expect(m.isQualifiedForSearch('db'), isFalse);
    expect(Machine().isNotPlaceholder(), isFalse);
    expect(m.fileTransferLoginPath, '/');
  });

  test('identity key types', () {
    expect(Identity(username: 'a', password: 'p').getKeyType(), 'Password');
    expect(Identity(username: 'a', privateKey: 'k').getKeyType(), 'Plain Private Key');
    expect(Identity(username: 'a', privateKey: 'k', password: 'p').getKeyType(), 'Private Key');
    expect(Identity(username: 'a', privateKey: 'k', publicKey: 'p').getKeyType(), 'Plain Key Pair');
    expect(Identity(username: 'a').getKeyType(), 'Username Only');
    expect(Identity(publicKey: 'ssh-ed25519 AAAA', privateKey: 'x').authDescription, 'Key pair · ed25519');
  });

  test('port forward descriptions', () {
    final m = Machine(remoteAddress: 'gw', remotePort: '22', name: 'gateway');
    final f = PortForward(bindPort: 8080, targetHost: 'localhost', targetPort: 80, usingMachine: m.id);
    expect(f.shortDescription(m), 'localhost:8080 -gateway-> localhost:80');
    expect(f.getCommand(m, 'root'), 'ssh -L 8080:localhost:80 root@gw');
    f.forwardOrientation = ForwardOrientation.listenRemote;
    expect(f.getCommand(m, null), 'ssh -R 8080:localhost:80 gw');
    expect(f.shortDescription(null), 'Invalid Forward');
  });

  test('json round trips', () {
    final m = Machine(remoteAddress: 'h', remotePort: '22', associatedIdentity: 'X')..fileTransferLoginPath = '/srv';
    final back = Machine.fromJson(m.toJson());
    expect(back.fileTransferLoginPath, '/srv');
    expect(back.associatedIdentity, 'X');
    final r = RecentConnection.fromJson(const RecentMachine('abc').toJson());
    expect(r, const RecentMachine('abc'));
  });

  test('store seals items and reads them back', () async {
    final dir = Directory.systemTemp.createTempSync('catussh-store');
    addTearDown(() => dir.deleteSync(recursive: true));
    final vault = await Vault.open(directory: dir, useKeyring: false);
    final store = await CatusshStore.load(vault: vault);
    store.putIdentity(Identity(username: 'root', password: 'hunter2'));
    store.putMachine(Machine(remoteAddress: 'h', remotePort: '22'));
    store.putMachine(Machine()); // a placeholder is refused
    await store.flush();
    expect(File('${dir.path}/data.sealed').readAsStringSync().contains('hunter2'), isFalse);
    final again = await vault.readSealed();
    expect((again!['machines'] as List).length, 1);
    expect(((again['identities'] as List).first as Map)['password'], 'hunter2');
  });

  test('recent keeps the newest and its limit', () async {
    final dir = Directory.systemTemp.createTempSync('catussh-recent');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = await CatusshStore.load(vault: await Vault.open(directory: dir, useKeyring: false));
    store.maxRecentRecordCount = 2;
    for (final id in ['a', 'b', 'c', 'b']) {
      store.storeRecentMachine(id);
    }
    expect(store.recentRecord.map((r) => r.id), ['c', 'b']);
  });

  test('format', () {
    expect(RXFormat.bytesString(1234567), '1.2 MB');
    expect(RXFormat.rateString(999), '999 B/s');
    expect(RXFormat.duration(90061), '1d 1h');
    expect(RXFormat.duration(0), '—');
    final now = DateTime(2026, 1, 1, 12);
    expect(RXFormat.relative(now.subtract(const Duration(minutes: 5)), now: now), '5 minutes ago');
    expect(RXFormat.relative(DateTime.fromMillisecondsSinceEpoch(0), now: now), 'Never');
  });

  test('editor language detection', () {
    expect(EditorLanguage.detect('nginx.conf'), EditorLanguage.plain);
    expect(EditorLanguage.detect('app.py'), EditorLanguage.python);
    expect(EditorLanguage.detect('.bashrc'), EditorLanguage.bash);
    expect(EditorLanguage.detect('run', '#!/usr/bin/env python3'), EditorLanguage.python);
    expect(EditorLanguage.detect('run', '#!/bin/sh'), EditorLanguage.bash);
  });

  test('batch output cleaning', () {
    expect(BatchExec.cleanForTerminal('a\nb\r\nc'), 'a\r\nb\r\nc');
  });
}
