// Opening an authenticated SSH connection: the job NSRemoteShell's
// connectAndAuthenticate did for the Swift app, on dartssh2.
//
// The rules are the same: with a chosen identity only that one is tried;
// without, every identity set to authenticate automatically is tried in
// username order, reconnecting when the username changes (a server only
// takes one username per connection).

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';

import '../core/known_hosts.dart';
import '../core/models.dart';
import '../core/store.dart';

class ConnectFailure implements Exception {
  ConnectFailure(this.message, {this.authentication = false});
  final String message;
  final bool authentication;

  @override
  String toString() => message;
}

class SshConnection {
  SshConnection._(this.client, this.identity, this.banner);

  final SSHClient client;
  final Identity identity;
  final String? banner;

  Future<void> get done => client.done;
  bool get isClosed => client.isClosed;

  void close() => client.close();

  /// Connects to [host]:[port] and signs in.
  ///
  /// [hint] receives the progress lines the Swift app printed in the
  /// terminal ("[i] trying to authenticate with …").
  static Future<SshConnection> open({
    required String host,
    required int port,
    Identity? identity,
    List<Identity>? autoIdentities,
    String? username,
    void Function(String line)? hint,
    CatusshStore? store,
  }) async {
    store ??= CatusshStore.shared;
    final timeout = Duration(seconds: store.timeout.clamp(2, 60));
    var candidates = identity != null ? [identity] : (autoIdentities ?? store.identitiesForAutoAuth);
    // Quick Connect names its user: only identities for that user are tried.
    if (username != null) {
      candidates = candidates.where((i) => i.username == username).toList();
      if (candidates.isEmpty) {
        throw ConnectFailure(
          'No identity for $username authenticates automatically. Add one under Identities.',
          authentication: true,
        );
      }
    }
    if (candidates.isEmpty) {
      throw ConnectFailure(
        'No identity is set to authenticate automatically. Choose an identity for this server.',
        authentication: true,
      );
    }

    Object? lastError;
    for (final candidate in candidates) {
      if (identity == null) hint?.call('[i] trying to authenticate with ${candidate.shortDescription()}');
      final SSHSocket socket;
      try {
        socket = await SSHSocket.connect(host, port, timeout: timeout);
      } catch (error) {
        throw ConnectFailure('Unable to connect for $host:$port ($error)');
      }
      String? banner;
      final hostKeyRefused = Completer<bool>();
      final client = SSHClient(
        socket,
        username: candidate.username,
        handshakeTimeout: timeout,
        authTimeout: timeout * 3,
        identities: _keyPairs(candidate),
        onPasswordRequest: candidate.password.isEmpty ? null : () => candidate.password,
        onUserInfoRequest: candidate.password.isEmpty
            ? null
            : (request) => request.prompts.map((_) => candidate.password).toList(),
        onUserauthBanner: (text) => banner = (banner ?? '') + text,
        onVerifyHostKey: (type, fingerprint) {
          final ok = store!.knownHosts.accepts(
            HostKey(type, utf8.decode(fingerprint)),
            host,
            port,
          );
          if (!ok && !hostKeyRefused.isCompleted) hostKeyRefused.complete(true);
          return ok;
        },
      );
      try {
        await client.authenticated;
        store.markIdentityUsed(candidate.id);
        return SshConnection._(client, candidate, banner ?? client.remoteVersion);
      } catch (error) {
        client.close();
        final refusal = store.knownHosts.refusalMessage(host, port);
        if (hostKeyRefused.isCompleted && refusal != null) {
          throw ConnectFailure(refusal);
        }
        if (error is SSHAuthError) {
          lastError = error;
          continue;
        }
        throw ConnectFailure('Unable to connect for $host:$port ($error)');
      }
    }
    throw ConnectFailure(
      identity != null
          ? 'The selected identity could not sign in to $host. ($lastError)'
          : 'Failed to authenticate connection. Did you forget to add identity or enable auto authentication?',
      authentication: true,
    );
  }

  static Future<SshConnection> forMachine(
    Machine machine, {
    void Function(String line)? hint,
    String? username,
    CatusshStore? store,
  }) {
    store ??= CatusshStore.shared;
    final identity = store.associatedIdentity(machine);
    if (machine.associatedIdentity != null && identity == null) {
      throw ConnectFailure('Malformed machine or identity data');
    }
    return open(
      host: machine.remoteAddress,
      port: machine.port,
      identity: identity,
      username: username,
      hint: hint,
      store: store,
    );
  }

  static List<SSHKeyPair>? _keyPairs(Identity identity) {
    if (identity.privateKey.trim().isEmpty) return null;
    try {
      return SSHKeyPair.fromPem(
        identity.privateKey,
        identity.password.isEmpty ? null : identity.password,
      );
    } catch (_) {
      return null;
    }
  }

  /// Runs [command] and returns its standard output (stderr is dropped, as
  /// NSRemoteShell's beginExecute did for the monitor).
  Future<String> run(String command, {Duration? timeout}) async {
    final session = await client.execute(command);
    final out = StringBuffer();
    final decoder = const Utf8Decoder(allowMalformed: true);
    final done = session.stdout.map(decoder.convert).forEach(out.write);
    session.stderr.drain<void>();
    if (timeout != null) {
      await done.timeout(timeout, onTimeout: session.close);
    } else {
      await done;
    }
    return out.toString();
  }
}
