// Ported from KnownHostsTests.swift.

import 'dart:io';

import 'package:catussh/core/known_hosts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const first = HostKey('ssh-ed25519', 'SHA256:firstfirstfirst');
  const other = HostKey('ssh-ed25519', 'SHA256:otherotherother');
  late KnownHosts hosts;

  setUp(() => hosts = KnownHosts.memory());

  test('the first key is saved and accepted again', () {
    expect(hosts.accepts(first, 'example.com', 22), isTrue);
    expect(hosts.savedKey('example.com', 22), first);
    expect(hosts.accepts(first, 'example.com', 22), isTrue);
    expect(hosts.refusalMessage('example.com', 22), isNull);
  });

  test('a changed key is refused and the saved one kept', () {
    expect(hosts.accepts(first, 'example.com', 22), isTrue);
    expect(hosts.accepts(other, 'example.com', 22), isFalse);
    expect(hosts.savedKey('example.com', 22), first);
    expect(hosts.refusedKey('example.com', 22), other);
    final message = hosts.refusalMessage('example.com', 22)!;
    expect(message.contains(first.fingerprint), isTrue);
    expect(message.contains(other.fingerprint), isTrue);
  });

  test('the same key of another type is refused', () {
    expect(hosts.accepts(first, 'example.com', 22), isTrue);
    expect(hosts.accepts(HostKey('ssh-rsa', first.fingerprint), 'example.com', 22), isFalse);
  });

  test('a key is saved per address and port', () {
    expect(hosts.accepts(first, 'example.com', 22), isTrue);
    expect(hosts.accepts(other, 'example.com', 2222), isTrue);
    expect(hosts.accepts(other, 'other.example.com', 22), isTrue);
    expect(hosts.accepts(first, ' Example.COM ', 22), isTrue, reason: 'an address is the same in any case');
    expect(hosts.count, 3);
  });

  test('forgetting lets the next key in', () {
    expect(hosts.accepts(first, 'example.com', 22), isTrue);
    expect(hosts.accepts(other, 'example.com', 22), isFalse);
    hosts.forget('example.com', 22);
    expect(hosts.refusalMessage('example.com', 22), isNull);
    expect(hosts.accepts(other, 'example.com', 22), isTrue);
    expect(hosts.savedKey('example.com', 22), other);
  });

  test('saved keys outlive the object', () {
    final dir = Directory.systemTemp.createTempSync('catussh-known-hosts');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/known_hosts.json');
    expect(KnownHosts(file).accepts(first, 'example.com', 22), isTrue);
    final reopened = KnownHosts(file);
    expect(reopened.accepts(other, 'example.com', 22), isFalse);
    reopened.forgetAll();
    expect(KnownHosts(file).count, 0);
  });
}
