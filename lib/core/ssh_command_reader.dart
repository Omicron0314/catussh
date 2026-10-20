// Reads `ssh user@host -p port` (and Quick Connect's `user@host:port`).
// A line-for-line port of the Swift SSHCommandReader, with its tests.

class SSHCommandReader {
  const SSHCommandReader._(this.username, this.remoteAddress, this.remotePort);

  final String username;
  final String remoteAddress;
  final String remotePort;

  String get command => 'ssh $username@$remoteAddress -p $remotePort';

  /// Null unless [input] is a full `ssh` command with a user, a host and at
  /// most a `-p` port. Anything else (`-i`, `-v`, …) is refused rather than
  /// silently ignored.
  static SSHCommandReader? parse(String input) {
    var parser = input.trim();
    if (!parser.toLowerCase().startsWith('ssh ')) return null;
    while (parser.contains('  ')) {
      parser = parser.replaceAll('  ', ' ');
    }
    parser = parser.substring(4);
    var tokens = parser.split(' ').where((t) => t.isNotEmpty).toList();

    // A lone `user@host:port` target carries its port after the colon. Only
    // with exactly one colon: an IPv6 address keeps its colons.
    if (tokens.length == 1) {
      final token = tokens.first;
      if (token.contains('@') && ':'.allMatches(token).length == 1) {
        final colon = token.lastIndexOf(':');
        tokens = [token.substring(0, colon), '-p', token.substring(colon + 1)];
      }
    }

    String? target;
    String? port;
    var index = 0;
    while (index < tokens.length) {
      final token = tokens[index];
      if (token == '-p' && port == null) {
        if (index + 1 >= tokens.length) return null;
        final value = _uint16(tokens[index + 1]);
        if (value == null) return null;
        port = '$value';
        index += 2;
      } else if (target == null && token.contains('@')) {
        target = token;
        index += 1;
      } else {
        return null;
      }
    }
    // Requires a username: anonymous logins are blocked.
    if (target == null) return null;
    final component = target.split('@');
    if (component.length != 2) return null;
    final name = component[0].trim();
    final addr = component[1].trim();
    if (name.isEmpty || addr.isEmpty) return null;
    return SSHCommandReader._(name, addr, port ?? '22');
  }

  /// What Home's Quick Connect field accepts: the command with or without
  /// its leading `ssh `.
  static SSHCommandReader? quickConnect(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.toLowerCase().startsWith('ssh ')) trimmed = 'ssh $trimmed';
    return parse(trimmed);
  }

  /// The first recent command that completes what has been typed.
  static String? suggestion(String input, Iterable<String> candidates) {
    if (input.length <= 2) return null;
    final typed = input.startsWith('ssh ') ? input : 'ssh $input';
    for (final candidate in candidates) {
      if (candidate.isNotEmpty && candidate.startsWith(typed) && candidate != typed) {
        return candidate;
      }
    }
    return null;
  }

  static int? _uint16(String raw) {
    if (!RegExp(r'^\d+$').hasMatch(raw)) return null;
    final value = int.tryParse(raw);
    if (value == null || value > 65535) return null;
    return value;
  }

  Map<String, Object?> toJson() => {
        'username': username,
        'remoteAddress': remoteAddress,
        'remotePort': remotePort,
      };

  static SSHCommandReader? fromJson(Map<String, Object?> json) {
    final user = json['username'] as String? ?? '';
    final host = json['remoteAddress'] as String? ?? '';
    final port = json['remotePort'] as String? ?? '22';
    if (user.isEmpty || host.isEmpty) return null;
    return SSHCommandReader._(user, host, port);
  }

  @override
  bool operator ==(Object other) =>
      other is SSHCommandReader && other.command == command;

  @override
  int get hashCode => command.hashCode;
}
