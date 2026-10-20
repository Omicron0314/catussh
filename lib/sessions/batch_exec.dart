// Runs one snippet on many servers at once: BatchSnippetExecContext.

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../ssh/connection.dart';

sealed class MachineRunState {
  const MachineRunState();
}

class RunWaiting extends MachineRunState {
  const RunWaiting();
}

class RunRunning extends MachineRunState {
  const RunRunning(this.since);
  final DateTime since;
}

class RunDone extends MachineRunState {
  const RunDone(this.duration);
  final Duration duration;
}

class RunFailed extends MachineRunState {
  const RunFailed(this.duration);
  final Duration duration;
}

class BatchExec extends ChangeNotifier {
  BatchExec(this.snippet, List<String> machineIds) {
    for (final id in machineIds) {
      final machine = CatusshStore.shared.machine(id);
      final terminal = Terminal(maxLines: 10000);
      outputs[id] = terminal;
      if (machine == null) {
        terminal.write('\r\n[*] Malformed Machine Info\r\n');
        states[id] = const RunFailed(Duration.zero);
        continue;
      }
      machines.add(machine.copy());
      names[id] = machine.name;
      states[id] = const RunWaiting();
    }
  }

  final Snippet snippet;
  final List<Machine> machines = [];
  final Map<String, String> names = {};
  final Map<String, Terminal> outputs = {};
  final Map<String, MachineRunState> states = {};
  final Map<String, SshConnection> _connections = {};
  final Map<String, SSHSession> _sessions = {};
  bool _started = false;
  bool _stopped = false;
  bool _disposed = false;

  int get completedCount =>
      states.values.where((s) => s is RunDone || s is RunFailed).length;
  bool get finished => completedCount >= states.length;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void start() {
    if (_started) return;
    _started = true;
    for (final machine in machines) {
      _exec(machine);
    }
  }

  Future<void> _exec(Machine machine) async {
    final out = outputs[machine.id]!;
    final start = DateTime.now();
    states[machine.id] = RunRunning(start);
    _notify();
    var failed = false;
    try {
      final connection = await SshConnection.forMachine(machine);
      if (_stopped) {
        connection.close();
        throw const _Stopped();
      }
      _connections[machine.id] = connection;
      out.write('[*] Execute Begin\r\n');
      final session = await connection.client.execute(snippet.code);
      _sessions[machine.id] = session;
      const decoder = Utf8Decoder(allowMalformed: true);
      final done = Completer<void>();
      var open = 2;
      void finish() {
        open -= 1;
        if (open == 0 && !done.isCompleted) done.complete();
      }

      session.stdout.map(decoder.convert).listen((s) => out.write(cleanForTerminal(s)), onDone: finish);
      session.stderr.map(decoder.convert).listen((s) => out.write(cleanForTerminal(s)), onDone: finish);
      await done.future;
      await session.done;
      if (_stopped) throw const _Stopped();
      out.write('\r\n[*] Execution completed\r\n');
    } on _Stopped {
      out.write('\r\n[*] Stopped\r\n');
      failed = true;
    } on ConnectFailure catch (failure) {
      out.write(failure.authentication
          ? '\r\n[E] The identity could not sign in\r\n'
          : '\r\n[E] Could not connect to the server\r\n');
      out.write('${failure.message.replaceAll('\n', '\r\n')}\r\n');
      failed = true;
    } catch (error) {
      out.write('\r\n[E] $error\r\n');
      failed = true;
    } finally {
      _sessions.remove(machine.id)?.close();
      _connections.remove(machine.id)?.close();
    }
    final duration = DateTime.now().difference(start);
    states[machine.id] = failed ? RunFailed(duration) : RunDone(duration);
    _notify();
  }

  void stopAll() {
    _stopped = true;
    for (final s in _sessions.values) {
      s.close();
    }
    for (final c in _connections.values) {
      c.close();
    }
  }

  @override
  void dispose() {
    stopAll();
    _disposed = true;
    super.dispose();
  }

  /// \n becomes \r\n; an existing \r\n stays as it is.
  static String cleanForTerminal(String output) =>
      output.replaceAll('\n', '\r\n').replaceAll('\r\r\n', '\r\n');
}

class _Stopped implements Exception {
  const _Stopped();
}
