// Ported from SSHCommandReaderTests.swift.

import 'package:catussh/core/ssh_command_reader.dart';
import 'package:flutter_test/flutter_test.dart';

SSHCommandReader? p(String s) => SSHCommandReader.parse(s);

void main() {
  test('basic command', () {
    final r = p('ssh root@example.com')!;
    expect(r.username, 'root');
    expect(r.remoteAddress, 'example.com');
    expect(r.remotePort, '22');
  });

  test('custom port', () {
    final r = p('ssh ubuntu@10.0.0.8 -p 2222')!;
    expect(r.remotePort, '2222');
    expect(r.command, 'ssh ubuntu@10.0.0.8 -p 2222');
  });

  test('rejects anonymous login', () => expect(p('ssh example.com'), isNull));

  test('rejects missing parts', () {
    expect(p('ssh @example.com'), isNull);
    expect(p('ssh root@'), isNull);
    expect(p('ssh'), isNull);
    expect(p('mosh root@example.com'), isNull);
  });

  test('rejects invalid port', () {
    expect(p('ssh root@example.com -p abc'), isNull);
    expect(p('ssh root@example.com -p 70000'), isNull);
  });

  test('tolerates repeated spaces', () {
    final r = p('ssh  root@example.com  -p  2222')!;
    expect(r.username, 'root');
    expect(r.remotePort, '2222');
  });

  test('preserves case', () {
    final r = p('ssh Root@Example.COM -p 2222')!;
    expect(r.username, 'Root');
    expect(r.remoteAddress, 'Example.COM');
  });

  test('uppercase prefix', () {
    final r = p('SSH root@example.com')!;
    expect(r.username, 'root');
    expect(r.remoteAddress, 'example.com');
  });

  test('port before host', () {
    final r = p('ssh -p 2222 ubuntu@10.0.0.8')!;
    expect(r.username, 'ubuntu');
    expect(r.remoteAddress, '10.0.0.8');
    expect(r.command, 'ssh ubuntu@10.0.0.8 -p 2222');
  });

  test('rejects unknown tokens', () {
    expect(p('ssh root@example.com -v'), isNull);
    expect(p('ssh -i key.pem root@example.com'), isNull);
    expect(p('ssh -p 2222'), isNull);
    expect(p('ssh root@example.com -p'), isNull);
    expect(p('ssh -p abc root@example.com'), isNull);
  });

  test('round trip', () {
    const original = 'ssh admin@server.local -p 2200';
    expect(p(original)!.command, original);
  });

  test('colon port on bare target', () {
    final r = p('ssh root@example.com:2222')!;
    expect(r.remoteAddress, 'example.com');
    expect(r.remotePort, '2222');
    expect(r.command, 'ssh root@example.com -p 2222');
  });

  test('rejects broken colon port', () {
    expect(p('ssh root@example.com:'), isNull);
    expect(p('ssh root@example.com:abc'), isNull);
    expect(p('ssh root@example.com:70000'), isNull);
  });

  test('colon stays in host when not a lone target', () {
    final r = p('ssh -p 2222 root@example.com:3333')!;
    expect(r.remoteAddress, 'example.com:3333');
    expect(r.remotePort, '2222');
    final v6 = p('ssh root@2001:db8::1')!;
    expect(v6.remoteAddress, '2001:db8::1');
    expect(v6.remotePort, '22');
    expect(p('ssh user:name@example.com'), isNull);
  });

  test('quick connect adds missing prefix', () {
    final r = SSHCommandReader.quickConnect('root@example.com')!;
    expect(r.username, 'root');
    expect(r.remotePort, '22');
  });

  test('quick connect accepts colon port', () {
    expect(SSHCommandReader.quickConnect('root@example.com:2222')!.remotePort, '2222');
    expect(SSHCommandReader.quickConnect('ssh root@example.com:2222')!.remotePort, '2222');
  });

  test('quick connect keeps full commands', () {
    final r = SSHCommandReader.quickConnect('SSH -p 2222 Root@Example.COM')!;
    expect(r.username, 'Root');
    expect(r.remoteAddress, 'Example.COM');
    expect(r.remotePort, '2222');
  });

  test('suggestion completes from recent commands', () {
    final recent = ['ssh root@web-01 -p 22', 'ssh admin@db -p 2222'];
    expect(SSHCommandReader.suggestion('ro', recent), isNull);
    expect(SSHCommandReader.suggestion('root@w', recent), 'ssh root@web-01 -p 22');
    expect(SSHCommandReader.suggestion('ssh admin', recent), 'ssh admin@db -p 2222');
    expect(SSHCommandReader.suggestion('ssh root@web-01 -p 22', recent), isNull);
  });
}
