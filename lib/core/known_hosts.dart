// The host keys of the servers connected to so far. A server's key is saved
// the first time it is seen; after that a connection to the same address is
// only made when the server presents the same key, so someone answering in
// the server's place is refused instead of being handed the password.
//
// dartssh2 hands the verifier the key's SHA256 fingerprint (what
// `ssh-keygen -l` prints) rather than the raw key, so the fingerprint is what
// is saved, next to the algorithm.

import 'dart:convert';
import 'dart:io';

import 'strings.dart';

class HostKey {
  const HostKey(this.type, this.fingerprint);

  /// The algorithm as SSH names it, "ssh-ed25519" for one.
  final String type;

  /// `SHA256:…`, as `ssh-keygen -l` prints it.
  final String fingerprint;

  String get line => '$type $fingerprint';

  static HostKey? fromLine(String line) {
    final space = line.indexOf(' ');
    if (space <= 0) return null;
    return HostKey(line.substring(0, space), line.substring(space + 1));
  }

  @override
  bool operator ==(Object other) => other is HostKey && other.line == line;

  @override
  int get hashCode => line.hashCode;
}

class KnownHosts {
  KnownHosts(this.file) {
    _load();
  }

  /// Kept in memory only: for tests.
  KnownHosts.memory() : file = null;

  final File? file;
  final Map<String, String> _saved = {};

  /// The keys refused since launch, to tell the user what was offered.
  final Map<String, HostKey> _refused = {};

  void _load() {
    final file = this.file;
    if (file == null || !file.existsSync()) return;
    try {
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      raw.forEach((k, v) {
        if (v is String) _saved[k] = v;
      });
    } catch (_) {}
  }

  void _save() {
    final file = this.file;
    if (file == null) return;
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_saved));
  }

  /// `[host]:port`, as known_hosts writes an address with a port.
  static String name(String host, int port) =>
      '[${host.trim().toLowerCase()}]:$port';

  /// True for the key saved for the address, and for the first key seen
  /// there, which is saved. False for any other key.
  bool accepts(HostKey offered, String host, int port) {
    final key = name(host, port);
    final line = _saved[key];
    if (line == null) {
      _saved[key] = offered.line;
      _save();
      _refused.remove(key);
      return true;
    }
    if (line == offered.line) {
      _refused.remove(key);
      return true;
    }
    _refused[key] = offered;
    return false;
  }

  HostKey? savedKey(String host, int port) {
    final line = _saved[name(host, port)];
    return line == null ? null : HostKey.fromLine(line);
  }

  /// The key the address offered that was refused, if one was since launch.
  HostKey? refusedKey(String host, int port) => _refused[name(host, port)];

  /// The next key the address presents is saved as its key.
  void forget(String host, int port) {
    final key = name(host, port);
    _saved.remove(key);
    _refused.remove(key);
    _save();
  }

  void forgetAll() {
    _saved.clear();
    _refused.clear();
    _save();
  }

  int get count => _saved.length;

  /// Why a connection to the address was refused, when its host key was the
  /// reason; null when it was not.
  String? refusalMessage(String host, int port) {
    final offered = refusedKey(host, port);
    if (offered == null) return null;
    final saved = savedKey(host, port);
    return [
      S.l.hostKeyChanged(host, port),
      if (saved != null) S.l.hostKeySaved(saved.type, saved.fingerprint),
      S.l.hostKeyOffered(offered.type, offered.fingerprint),
      S.l.hostKeyChangedHelp,
    ].join('\n');
  }
}
