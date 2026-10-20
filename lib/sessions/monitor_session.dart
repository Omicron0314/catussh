// A live monitor of one server: the MonitorSession of the Swift app.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../monitor/server_status.dart';
import '../ssh/connection.dart';

class MonitorHistory {
  static const capacity = 60;
  final List<double> cpu = [];
  final List<double> memory = [];
  final List<double> receive = [];
  final List<double> transmit = [];

  void record(ServerStatus status) {
    _push(status.processor.summary.sumUsed, cpu);
    _push(status.memoryUsedPercent, memory);
    _push(status.totalReceivePerSecond.toDouble(), receive);
    _push(status.totalTransmitPerSecond.toDouble(), transmit);
  }

  static void _push(double value, List<double> list) {
    list.add(value.isFinite ? value : 0);
    if (list.length > capacity) list.removeRange(0, list.length - capacity);
  }
}

sealed class MonitorPhase {
  const MonitorPhase();
}

class MonitorConnecting extends MonitorPhase {
  const MonitorConnecting();
}

class MonitorConnected extends MonitorPhase {
  const MonitorConnected();
}

class MonitorFailed extends MonitorPhase {
  const MonitorFailed(this.message);
  final String message;
}

class MonitorClosed extends MonitorPhase {
  const MonitorClosed();
}

class MonitorSession extends ChangeNotifier {
  MonitorSession(Machine machine) : machine = machine.copy() {
    _loop();
  }

  final String id = newId();
  final Machine machine;

  ServerStatus status = const ServerStatus();
  MonitorPhase phase = const MonitorConnecting();
  final MonitorHistory history = MonitorHistory();
  DateTime? lastUpdate;
  bool isRefreshing = false;

  SshConnection? _connection;
  bool _cancelled = false;
  Completer<void>? _wake;

  /// Hostname and os-release cannot change while a connection stays up.
  String? _hostname;
  String? _release;

  int get refreshInterval => math.max(1, CatusshStore.shared.monitorInterval);

  void _notify() {
    if (!_cancelled) notifyListeners();
  }

  Future<void> _loop() async {
    var failures = 0;
    while (!_cancelled) {
      if (_connection == null || _connection!.isClosed) {
        _hostname = null;
        _release = null;
        if (phase is! MonitorConnected) {
          phase = const MonitorConnecting();
          _notify();
        }
        try {
          _connection = await SshConnection.forMachine(machine);
          CatusshStore.shared.recordConnection(machine.id, banner: _connection!.banner);
        } on ConnectFailure catch (failure) {
          _connection = null;
          failures += 1;
          phase = MonitorFailed(failure.message);
          _notify();
        } catch (error) {
          _connection = null;
          failures += 1;
          phase = MonitorFailed('Unable to connect or authenticate ($error)');
          _notify();
        }
      }
      if (_cancelled) break;
      final connection = _connection;
      if (connection != null) {
        failures = 0;
        phase = const MonitorConnected();
        isRefreshing = true;
        _notify();
        try {
          await _refresh(connection);
          history.record(status);
          lastUpdate = DateTime.now();
        } catch (error) {
          connection.close();
          _connection = null;
        }
        isRefreshing = false;
        _notify();
      }
      final wait = failures > 0 ? math.min(30, 5 * failures) : refreshInterval;
      // A timer that shutdown and retry can cut short, not a bare delay.
      final wake = _wake = Completer<void>();
      final timer = Timer(Duration(seconds: wait), () {
        if (!wake.isCompleted) wake.complete();
      });
      await wake.future;
      timer.cancel();
      _wake = null;
    }
    phase = const MonitorClosed();
  }

  Future<void> _refresh(SshConnection connection) async {
    final includeStatic = _hostname == null || _release == null;
    final timeout = Duration(seconds: math.max(10, refreshInterval * 2));
    // Two channels, as in the Swift app: a slow or missing nvidia-smi must
    // not cost the other sections.
    final results = await Future.wait([
      connection.run(ServerStatus.monitorScript(includeStatic: includeStatic), timeout: timeout),
      connection.run(ServerStatus.graphicsScript, timeout: timeout).catchError((_) => ''),
    ]);
    final parsed = ServerStatus.parse(
      merged: results[0],
      graphics: results[1],
      cachedHostname: _hostname,
      cachedRelease: _release,
    );
    _hostname = parsed.hostname;
    _release = parsed.releaseName;
    status = parsed.status;
  }

  /// Try Again after a failure: skips the back-off wait.
  void retry() {
    phase = const MonitorConnecting();
    _notify();
    if (_wake?.isCompleted == false) _wake!.complete();
  }

  void shutdown() {
    _cancelled = true;
    if (_wake?.isCompleted == false) _wake!.complete();
    _connection?.close();
    _connection = null;
  }
}
