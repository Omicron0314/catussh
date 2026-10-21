// The saved things: servers, identities, snippets and port forwards.
//
// Field names follow the Swift models (RDMachine, RDIdentity, RDSnippet,
// RDPortForward) so the two stay easy to compare.

import 'package:uuid/uuid.dart';

import 'ssh_command_reader.dart';
import 'strings.dart';

const _uuid = Uuid();

/// Upper-case, like Foundation's `UUID().uuidString`.
String newId() => _uuid.v4().toUpperCase();

Map<String, String> _stringMap(Object? raw) =>
    raw is Map ? raw.map((k, v) => MapEntry('$k', '$v')) : <String, String>{};

DateTime _date(Object? raw) => raw is int
    ? DateTime.fromMillisecondsSinceEpoch(raw)
    : DateTime.fromMillisecondsSinceEpoch(0);

bool _contains(String haystack, String needle) =>
    haystack.toLowerCase().contains(needle);

// MARK: - Machine

class Machine {
  Machine({
    String? id,
    this.remoteAddress = '',
    this.remotePort = '',
    this.name = '',
    this.group = '',
    DateTime? lastConnection,
    this.lastBanner = '',
    this.comment = '',
    this.associatedIdentity,
    Map<String, String>? attachment,
  })  : id = id ?? newId(),
        lastConnection = lastConnection ?? DateTime.now(),
        attachment = attachment ?? {};

  String id;
  String remoteAddress;
  String remotePort;
  String name;
  String group;
  DateTime lastConnection;
  String lastBanner;
  String comment;
  String? associatedIdentity;
  Map<String, String> attachment;

  int get port => int.tryParse(remotePort) ?? 22;

  String get fileTransferLoginPath => attachment['sftp.login.path'] ?? '/';
  set fileTransferLoginPath(String value) =>
      attachment['sftp.login.path'] = value;

  bool isNotPlaceholder() => remoteAddress.isNotEmpty && remotePort.isNotEmpty;

  bool isQualifiedForSearch(String text) {
    final key = text.toLowerCase();
    return _contains(remoteAddress, key) ||
        _contains(remotePort, key) ||
        _contains(name, key) ||
        _contains(group, key) ||
        _contains(lastBanner, key) ||
        _contains(comment, key);
  }

  /// `ssh user@host -p port`; the user comes from the associated identity.
  String getCommand(String? username, {bool insertLeadingSSH = true}) {
    final leading = insertLeadingSSH ? 'ssh ' : '';
    var build = (username != null && username.isNotEmpty)
        ? '$leading$username@$remoteAddress'
        : '$leading$remoteAddress';
    if (remotePort != '22') build += ' -p $remotePort';
    return build;
  }

  Machine copy() => Machine.fromJson(toJson());

  Map<String, Object?> toJson() => {
        'id': id,
        'remoteAddress': remoteAddress,
        'remotePort': remotePort,
        'name': name,
        'group': group,
        'lastConnection': lastConnection.millisecondsSinceEpoch,
        'lastBanner': lastBanner,
        'comment': comment,
        'associatedIdentity': associatedIdentity,
        'attachment': attachment,
      };

  factory Machine.fromJson(Map<String, Object?> json) => Machine(
        id: json['id'] as String?,
        remoteAddress: json['remoteAddress'] as String? ?? '',
        remotePort: json['remotePort'] as String? ?? '',
        name: json['name'] as String? ?? '',
        group: json['group'] as String? ?? '',
        lastConnection: _date(json['lastConnection']),
        lastBanner: json['lastBanner'] as String? ?? '',
        comment: json['comment'] as String? ?? '',
        associatedIdentity: json['associatedIdentity'] as String?,
        attachment: _stringMap(json['attachment']),
      );

  /// The server a Quick Connect command reaches; it is never saved.
  factory Machine.fromCommand(SSHCommandReader command) => Machine(
        remoteAddress: command.remoteAddress,
        remotePort: command.remotePort,
        name: command.remoteAddress,
        group: 'SSHCommandReader',
      );
}

/// How much of the server list is hidden, for screen sharing.
enum RedactedLevel {
  none,
  sensitive,
  all;

  String get tooltip => switch (this) {
        RedactedLevel.none => 'Show Everything',
        RedactedLevel.sensitive => 'Hide Addresses',
        RedactedLevel.all => 'Hide Names and Addresses',
      };

  RedactedLevel get next =>
      RedactedLevel.values[(index + 1) % RedactedLevel.values.length];
}

// MARK: - Identity

class Identity {
  Identity({
    String? id,
    this.username = '',
    this.password = '',
    this.privateKey = '',
    this.publicKey = '',
    DateTime? lastRecentUsed,
    this.comment = '',
    this.group = '',
    this.authenticAutomatically = true,
    Map<String, String>? attachment,
  })  : id = id ?? newId(),
        lastRecentUsed = lastRecentUsed ?? DateTime.now(),
        attachment = attachment ?? {};

  String id;
  String username;
  String password;
  String privateKey;
  String publicKey;
  DateTime lastRecentUsed;
  String comment;
  String group;
  bool authenticAutomatically;
  Map<String, String> attachment;

  String getKeyType() {
    if (privateKey.isNotEmpty && publicKey.isNotEmpty) {
      return password.isNotEmpty ? S.l.keyTypeKeyPair : S.l.keyTypePlainKeyPair;
    } else if (privateKey.isNotEmpty) {
      return password.isNotEmpty ? S.l.keyTypePrivateKey : S.l.keyTypePlainPrivateKey;
    } else if (publicKey.isNotEmpty) {
      return S.l.unknownKey;
    } else if (password.isNotEmpty) {
      return S.l.password;
    }
    return S.l.usernameOnly;
  }

  String shortDescription() {
    if (username.isEmpty) return S.l.unknownError;
    var build = S.l.identityShort(username, getKeyType());
    if (group.isNotEmpty) build += ' ${S.l.identityGroup(group)}';
    if (comment.isNotEmpty) build += ' ($comment)';
    return build;
  }

  /// "Key pair · ed25519", "Password" style description.
  String get authDescription {
    if (privateKey.isNotEmpty) {
      final type = keyAlgorithm;
      return type == null ? S.l.keyPair : '${S.l.keyPair} · $type';
    }
    if (password.isNotEmpty) return S.l.password;
    return S.l.noCredentials;
  }

  String? get keyAlgorithm {
    final source = publicKey.isEmpty ? privateKey : publicKey;
    const markers = [
      ('ssh-ed25519', 'ed25519'),
      ('ecdsa-sha2', 'ecdsa'),
      ('ssh-rsa', 'rsa'),
      ('BEGIN RSA', 'rsa'),
      ('BEGIN EC', 'ecdsa'),
    ];
    for (final (marker, name) in markers) {
      if (source.contains(marker)) return name;
    }
    return null;
  }

  Identity copy() => Identity.fromJson(toJson());

  Map<String, Object?> toJson() => {
        'id': id,
        'username': username,
        'password': password,
        'privateKey': privateKey,
        'publicKey': publicKey,
        'lastRecentUsed': lastRecentUsed.millisecondsSinceEpoch,
        'comment': comment,
        'group': group,
        'authenticAutomatically': authenticAutomatically,
        'attachment': attachment,
      };

  factory Identity.fromJson(Map<String, Object?> json) => Identity(
        id: json['id'] as String?,
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        privateKey: json['privateKey'] as String? ?? '',
        publicKey: json['publicKey'] as String? ?? '',
        lastRecentUsed: _date(json['lastRecentUsed']),
        comment: json['comment'] as String? ?? '',
        group: json['group'] as String? ?? '',
        authenticAutomatically: json['authenticAutomatically'] as bool? ?? true,
        attachment: _stringMap(json['attachment']),
      );
}

// MARK: - Snippet

class Snippet {
  Snippet({
    String? id,
    this.name = '',
    this.group = '',
    this.code = '',
    this.comment = '',
    Map<String, String>? attachment,
  })  : id = id ?? newId(),
        attachment = attachment ?? {};

  String id;
  String name;
  String group;
  String code;
  String comment;
  Map<String, String> attachment;

  bool isQualifiedForSearch(String text) {
    final key = text.toLowerCase();
    return _contains(name, key) ||
        _contains(group, key) ||
        _contains(code, key) ||
        _contains(comment, key);
  }

  /// The Swift app keeps an SF Symbol name under `sfAvatar`; this one keeps a
  /// Material icon name under its own key so the two never clash.
  static const avatarKey = 'materialAvatar';
  String get avatar => attachment[avatarKey]?.isNotEmpty == true
      ? attachment[avatarKey]!
      : 'terminal';
  set avatar(String value) => attachment[avatarKey] = value;

  Snippet copy() => Snippet.fromJson(toJson());

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'code': code,
        'comment': comment,
        'attachment': attachment,
      };

  factory Snippet.fromJson(Map<String, Object?> json) => Snippet(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        group: json['group'] as String? ?? '',
        code: json['code'] as String? ?? '',
        comment: json['comment'] as String? ?? '',
        attachment: _stringMap(json['attachment']),
      );
}

// MARK: - Port forward

enum ForwardOrientation {
  listenLocal('Local'),
  listenRemote('Remote');

  const ForwardOrientation(this.rawValue);
  final String rawValue;

  static ForwardOrientation from(String? raw) =>
      raw == 'Remote' ? listenRemote : listenLocal;
}

class PortForward {
  PortForward({
    String? id,
    this.forwardOrientation = ForwardOrientation.listenLocal,
    this.bindPort = 0,
    this.targetHost = '',
    this.targetPort = 0,
    this.usingMachine,
    Map<String, String>? attachment,
  })  : id = id ?? newId(),
        attachment = attachment ?? {};

  String id;
  ForwardOrientation forwardOrientation;
  int bindPort;
  String targetHost;
  int targetPort;
  String? usingMachine;
  Map<String, String> attachment;

  bool get forwardReversed => forwardOrientation == ForwardOrientation.listenRemote;

  /// Valid when the ports fit and the server it goes through still exists.
  bool isValid(Machine? machine) =>
      bindPort >= 0 &&
      bindPort <= 65535 &&
      targetHost.isNotEmpty &&
      targetPort >= 0 &&
      targetPort <= 65535 &&
      machine != null &&
      machine.isNotPlaceholder();

  String shortDescription(Machine? machine) {
    if (!isValid(machine)) return S.l.invalidForward;
    final name = machine!.name;
    return switch (forwardOrientation) {
      ForwardOrientation.listenLocal =>
        S.l.localForwardShort(bindPort, name, targetHost, targetPort),
      ForwardOrientation.listenRemote =>
        S.l.remoteForwardShort(bindPort, name, targetHost, targetPort),
    };
  }

  String? getCommand(Machine? machine, String? username) {
    if (!isValid(machine)) return null;
    final flag = forwardReversed ? '-R' : '-L';
    return 'ssh $flag $bindPort:$targetHost:$targetPort '
        '${machine!.getCommand(username, insertLeadingSSH: false)}';
  }

  PortForward copy() => PortForward.fromJson(toJson());

  Map<String, Object?> toJson() => {
        'id': id,
        'forwardOrientation': forwardOrientation.rawValue,
        'bindPort': bindPort,
        'targetHost': targetHost,
        'targetPort': targetPort,
        'usingMachine': usingMachine,
        'attachment': attachment,
      };

  factory PortForward.fromJson(Map<String, Object?> json) => PortForward(
        id: json['id'] as String?,
        forwardOrientation:
            ForwardOrientation.from(json['forwardOrientation'] as String?),
        bindPort: json['bindPort'] as int? ?? 0,
        targetHost: json['targetHost'] as String? ?? '',
        targetPort: json['targetPort'] as int? ?? 0,
        usingMachine: json['usingMachine'] as String?,
        attachment: _stringMap(json['attachment']),
      );
}

// MARK: - Recent connections

/// A server or a Quick Connect command used lately, listed on Home.
sealed class RecentConnection {
  const RecentConnection();
  String get id;

  Map<String, Object?> toJson();

  static RecentConnection? fromJson(Map<String, Object?> json) {
    final command = json['command'];
    if (command is Map) {
      final reader = SSHCommandReader.fromJson(command.cast<String, Object?>());
      return reader == null ? null : RecentCommand(reader);
    }
    final machine = json['machine'];
    if (machine is String) return RecentMachine(machine);
    return null;
  }

  @override
  bool operator ==(Object other) => other is RecentConnection && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class RecentCommand extends RecentConnection {
  const RecentCommand(this.command);
  final SSHCommandReader command;

  @override
  String get id => command.command;

  @override
  Map<String, Object?> toJson() => {'command': command.toJson()};
}

class RecentMachine extends RecentConnection {
  const RecentMachine(this.machine);
  final String machine;

  @override
  String get id => machine;

  @override
  Map<String, Object?> toJson() => {'machine': machine};
}
