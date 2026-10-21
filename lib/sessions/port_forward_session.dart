// A running port forward: the PortForwardContext of the Swift app, with the
// same lifecycle names and the same reconnect-after-3-seconds behaviour.

import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../core/strings.dart';
import '../core/models.dart';
import '../ssh/connection.dart';

enum ForwardLifecycle {
  awaitingConnect('awaiting connect'),
  openingChannel('opening channel'),
  forwardRunning('forward running'),
  forwardStopped('forward stopped'),
  failedConnect('failed connect'),
  failedAuthenticate('failed authenticate'),
  terminating('terminating'),
  terminated('terminated');

  const ForwardLifecycle(this.label);
  final String label;
}

class PortForwardSession extends ChangeNotifier {
  PortForwardSession(this.info, Machine machine) : machine = machine.copy() {
    _run();
  }

  final PortForward info;
  final Machine machine;
  ForwardLifecycle lifecycle = ForwardLifecycle.awaitingConnect;
  String? lastError;
  void Function(PortForwardSession)? onTerminated;

  static const reconnectDelay = Duration(seconds: 3);

  bool _closed = false;
  SshConnection? _connection;
  ServerSocket? _server;
  SSHRemoteForward? _remote;
  final List<Socket> _sockets = [];
  Completer<void>? _wake;

  bool get running => lifecycle == ForwardLifecycle.forwardRunning;

  void _put(ForwardLifecycle state) {
    lifecycle = state;
    if (!_closedNotified) notifyListeners();
  }

  bool _closedNotified = false;

  Future<void> _run() async {
    while (!_closed) {
      _put(ForwardLifecycle.awaitingConnect);
      try {
        _connection = await SshConnection.forMachine(machine);
      } on ConnectFailure catch (failure) {
        lastError = failure.message;
        _put(failure.authentication ? ForwardLifecycle.failedAuthenticate : ForwardLifecycle.failedConnect);
        await _sleep();
        continue;
      } catch (error) {
        lastError = '$error';
        _put(ForwardLifecycle.failedConnect);
        await _sleep();
        continue;
      }
      if (_closed) break;
      _put(ForwardLifecycle.openingChannel);
      try {
        if (info.forwardReversed) {
          await _runRemote(_connection!);
        } else {
          await _runLocal(_connection!);
        }
      } catch (error) {
        lastError = '$error';
      }
      await _teardown();
      if (_closed) break;
      _put(ForwardLifecycle.forwardStopped);
      await _sleep();
    }
    _put(ForwardLifecycle.terminated);
    _closedNotified = true;
    onTerminated?.call(this);
  }

  Future<void> _sleep() async {
    if (_closed) return;
    final wake = _wake = Completer<void>();
    final timer = Timer(reconnectDelay, () {
      if (!wake.isCompleted) wake.complete();
    });
    await wake.future;
    timer.cancel();
    _wake = null;
  }

  /// `ssh -L`: this computer listens, the server dials the target.
  Future<void> _runLocal(SshConnection connection) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, info.bindPort);
    _server = server;
    _put(ForwardLifecycle.forwardRunning);
    final serving = server.listen((socket) async {
      _sockets.add(socket);
      try {
        final channel = await connection.client.forwardLocal(info.targetHost, info.targetPort);
        channel.stream.cast<List<int>>().pipe(socket).catchError((_) {});
        socket.cast<List<int>>().pipe(channel.sink).catchError((_) {});
        await socket.done.catchError((_) {});
      } catch (_) {
        socket.destroy();
      } finally {
        _sockets.remove(socket);
      }
    }).asFuture<void>();
    await Future.any([serving, connection.done]);
  }

  /// `ssh -R`: the server listens, this computer dials the target.
  Future<void> _runRemote(SshConnection connection) async {
    final remote = await connection.client.forwardRemote(port: info.bindPort);
    if (remote == null) throw Exception(S.l.serverRefusedListen(info.bindPort));
    _remote = remote;
    _put(ForwardLifecycle.forwardRunning);
    final serving = remote.connections.listen((channel) async {
      try {
        final socket = await Socket.connect(info.targetHost, info.targetPort);
        _sockets.add(socket);
        channel.stream.cast<List<int>>().pipe(socket).catchError((_) {});
        socket.cast<List<int>>().pipe(channel.sink).catchError((_) {});
        await socket.done.catchError((_) {});
        _sockets.remove(socket);
      } catch (_) {
        channel.close();
      }
    }).asFuture<void>();
    await Future.any([serving, connection.done]);
  }

  Future<void> _teardown() async {
    for (final socket in List.of(_sockets)) {
      socket.destroy();
    }
    _sockets.clear();
    await _server?.close();
    _server = null;
    try {
      _remote?.close();
    } catch (_) {}
    _remote = null;
    _connection?.close();
    _connection = null;
  }

  void terminate() {
    if (_closed) return;
    _closed = true;
    _put(ForwardLifecycle.terminating);
    if (_wake?.isCompleted == false) _wake!.complete();
    _teardown();
  }
}
