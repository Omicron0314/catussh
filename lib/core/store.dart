// Everything the app keeps: saved items and settings. The CatusshStore of the
// Swift app, as a ChangeNotifier; writes are debounced like the original.

import 'dart:async';

import 'package:flutter/material.dart';

import 'known_hosts.dart';
import 'models.dart';
import 'ssh_command_reader.dart';
import 'vault.dart';

class CatusshStore extends ChangeNotifier {
  CatusshStore._(this.vault, this.knownHosts);

  static late CatusshStore shared;

  final Vault vault;
  final KnownHosts knownHosts;

  static Future<CatusshStore> load({Vault? vault}) async {
    vault ??= await Vault.open();
    final store = CatusshStore._(vault, KnownHosts(vault.knownHostsFile));
    await store._read();
    shared = store;
    return store;
  }

  // MARK: Saved items

  final List<Machine> machines = [];
  final List<Identity> identities = [];
  final List<Snippet> snippets = [];
  final List<PortForward> portForwards = [];
  final List<RecentConnection> recentRecord = [];

  // MARK: Settings (names and defaults as in the Swift app)

  bool licenseAgreed = false;
  bool storeRecent = true;
  bool saveTemporarySession = true;
  int maxRecentRecordCount = 8;
  int timeout = 5;
  int monitorInterval = 5;
  bool disableConformation = false;
  bool openInterfaceAutomatically = true;
  RedactedLevel machineRedacted = RedactedLevel.none;
  ThemeMode appearance = ThemeMode.system;
  /// Follow the desktop's accent color (Material You); off uses [seedColor].
  bool dynamicColor = true;
  Color seedColor = const Color(0xFF4B49C8);
  int terminalFontSize = 14;
  String terminalFontFamily = 'monospace';
  /// 'system', 'en' or 'zh'.
  String locale = 'system';
  String terminalTheme = 'catussh';

  Future<void> _read() async {
    final sealed = await vault.readSealed();
    if (sealed != null) {
      List<Map<String, Object?>> list(String key) =>
          (sealed[key] as List? ?? const []).whereType<Map>().map((e) => e.cast<String, Object?>()).toList();
      machines.addAll(list('machines').map(Machine.fromJson));
      identities.addAll(list('identities').map(Identity.fromJson));
      snippets.addAll(list('snippets').map(Snippet.fromJson));
      portForwards.addAll(list('portForwards').map(PortForward.fromJson));
      recentRecord.addAll(list('recent').map(RecentConnection.fromJson).whereType<RecentConnection>());
    }
    final s = await vault.readSettings();
    T read<T>(String key, T fallback) => s[key] is T ? s[key] as T : fallback;
    licenseAgreed = read('licenseAgreed', false);
    storeRecent = read('storeRecent', true);
    saveTemporarySession = read('saveTemporarySession', true);
    maxRecentRecordCount = read('maxRecentRecordCount', 8);
    timeout = read('timeout', 5);
    if (timeout <= 0) timeout = 5;
    monitorInterval = read('monitorInterval', 5);
    disableConformation = read('disableConformation', false);
    openInterfaceAutomatically = read('openInterfaceAutomatically', true);
    machineRedacted = RedactedLevel.values[read('machineRedacted', 0).clamp(0, 2)];
    appearance = ThemeMode.values.firstWhere(
      (m) => m.name == read('appearance', 'system'),
      orElse: () => ThemeMode.system,
    );
    dynamicColor = read('dynamicColor', true);
    seedColor = Color(read('seedColor', 0xFF4B49C8));
    terminalFontSize = read('terminalFontSize', 14);
    terminalFontFamily = read('terminalFontFamily', 'monospace');
    locale = read('locale', 'system');
    terminalTheme = read('terminalTheme', 'catussh');
  }

  Map<String, Object?> get _settings => {
        'licenseAgreed': licenseAgreed,
        'storeRecent': storeRecent,
        'saveTemporarySession': saveTemporarySession,
        'maxRecentRecordCount': maxRecentRecordCount,
        'timeout': timeout,
        'monitorInterval': monitorInterval,
        'disableConformation': disableConformation,
        'openInterfaceAutomatically': openInterfaceAutomatically,
        'machineRedacted': machineRedacted.index,
        'appearance': appearance.name,
        'dynamicColor': dynamicColor,
        'seedColor': seedColor.toARGB32(),
        'terminalFontSize': terminalFontSize,
        'terminalFontFamily': terminalFontFamily,
        'locale': locale,
        'terminalTheme': terminalTheme,
      };

  Map<String, Object?> get _sealed => {
        'machines': machines.map((e) => e.toJson()).toList(),
        'identities': identities.map((e) => e.toJson()).toList(),
        'snippets': snippets.map((e) => e.toJson()).toList(),
        'portForwards': portForwards.map((e) => e.toJson()).toList(),
        'recent': recentRecord.map((e) => e.toJson()).toList(),
      };

  Timer? _sealedTimer;
  Timer? _settingsTimer;

  /// Storing is debounced (1.5 s, as in the Swift app); [flush] writes what is
  /// still waiting.
  void saveItems() {
    notifyListeners();
    _sealedTimer?.cancel();
    _sealedTimer = Timer(const Duration(milliseconds: 1500), () {
      _sealedTimer = null;
      vault.writeSealed(_sealed);
    });
  }

  void saveSettings() {
    notifyListeners();
    _settingsTimer?.cancel();
    _settingsTimer = Timer(const Duration(milliseconds: 500), () {
      _settingsTimer = null;
      vault.writeSettings(_settings);
    });
  }

  /// Changes a setting and stores it.
  void update(void Function(CatusshStore s) change) {
    change(this);
    saveSettings();
  }

  Future<void> flush() async {
    if (_sealedTimer != null) {
      _sealedTimer!.cancel();
      _sealedTimer = null;
      await vault.writeSealed(_sealed);
    }
    if (_settingsTimer != null) {
      _settingsTimer!.cancel();
      _settingsTimer = null;
      await vault.writeSettings(_settings);
    }
  }

  // MARK: Lookups

  Machine? machine(String? id) {
    if (id == null) return null;
    for (final m in machines) {
      if (m.id == id) return m;
    }
    return null;
  }

  Identity? identity(String? id) {
    if (id == null) return null;
    for (final i in identities) {
      if (i.id.toUpperCase() == id.toUpperCase()) return i;
    }
    return null;
  }

  Snippet? snippet(String? id) {
    for (final s in snippets) {
      if (s.id == id) return s;
    }
    return null;
  }

  PortForward? portForward(String? id) {
    for (final f in portForwards) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// The identity a server signs in with, when it names one that exists.
  Identity? associatedIdentity(Machine machine) {
    final identity = this.identity(machine.associatedIdentity);
    return (identity == null || identity.username.isEmpty) ? null : identity;
  }

  String? usernameFor(Machine machine) => associatedIdentity(machine)?.username;

  /// Identities set to "Authenticate automatically", sorted by username so
  /// each username reconnects at most once.
  List<Identity> get identitiesForAutoAuth =>
      identities.where((i) => i.authenticAutomatically).toList()
        ..sort((a, b) => a.username.compareTo(b.username));

  List<String> get machineGroups =>
      machines.map((m) => m.group).where((g) => g.isNotEmpty).toSet().toList()..sort();

  // MARK: Mutations

  static void _upsert<T>(List<T> list, T value, String Function(T) id) {
    final index = list.indexWhere((e) => id(e) == id(value));
    if (index >= 0) {
      list[index] = value;
    } else {
      list.add(value);
    }
  }

  void putMachine(Machine machine) {
    if (!machine.isNotPlaceholder()) return;
    _upsert(machines, machine, (m) => m.id);
    saveItems();
  }

  void deleteMachine(String id) {
    machines.removeWhere((m) => m.id == id);
    cleanRecentIfNeeded();
    saveItems();
  }

  void putIdentity(Identity identity) {
    if (identity.username.isEmpty) return;
    _upsert(identities, identity, (i) => i.id);
    saveItems();
  }

  void deleteIdentity(String id) {
    identities.removeWhere((i) => i.id == id);
    saveItems();
  }

  void putSnippet(Snippet snippet) {
    if (snippet.name.isEmpty && snippet.code.isEmpty) return;
    _upsert(snippets, snippet, (s) => s.id);
    saveItems();
  }

  void deleteSnippet(String id) {
    snippets.removeWhere((s) => s.id == id);
    saveItems();
  }

  void putPortForward(PortForward forward) {
    _upsert(portForwards, forward, (f) => f.id);
    saveItems();
  }

  void deletePortForward(String id) {
    portForwards.removeWhere((f) => f.id == id);
    saveItems();
  }

  /// After a server's connection: its banner and the time.
  void recordConnection(String machineId, {String? banner}) {
    final machine = this.machine(machineId);
    if (machine == null) return;
    machine.lastConnection = DateTime.now();
    if (banner != null) machine.lastBanner = banner;
    saveItems();
  }

  void markIdentityUsed(String identityId) {
    final identity = this.identity(identityId);
    if (identity == null) return;
    identity.lastRecentUsed = DateTime.now();
    saveItems();
  }

  // MARK: Recent

  String equivalentSSHCommand(RecentConnection record) => switch (record) {
        RecentCommand(:final command) => command.command,
        RecentMachine(machine: final id) => () {
            final m = machine(id);
            final user = m == null ? null : usernameFor(m);
            if (m == null || user == null) return '';
            return 'ssh $user@${m.remoteAddress} -p ${m.remotePort}';
          }(),
      };

  void cleanRecentIfNeeded() {
    recentRecord.removeWhere((r) => r is RecentMachine && machine(r.machine) == null);
  }

  void _storeRecent(RecentConnection recent) {
    if (!storeRecent) return;
    if (recentRecord.contains(recent)) return;
    recentRecord.insert(0, recent);
    while (recentRecord.length > maxRecentRecordCount) {
      recentRecord.removeLast();
    }
    saveItems();
  }

  void storeRecentMachine(String machineId) => _storeRecent(RecentMachine(machineId));

  void storeRecentCommand(SSHCommandReader command) {
    if (!saveTemporarySession) return;
    _storeRecent(RecentCommand(command));
  }

  void removeRecent(RecentConnection record) {
    recentRecord.remove(record);
    saveItems();
  }

  void trimRecent() {
    if (recentRecord.length > maxRecentRecordCount) {
      recentRecord.removeRange(maxRecentRecordCount, recentRecord.length);
      saveItems();
    }
  }
}
