// One SSH terminal: the TerminalContext of the Swift app. The xterm.dart
// Terminal plays the part of the Ghostty surface.

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import '../core/strings.dart';
import '../core/models.dart';
import '../core/ssh_command_reader.dart';
import '../core/store.dart';
import '../ssh/connection.dart';

enum RemoteType { machine, command }

class TerminalSession extends ChangeNotifier {
  TerminalSession.machine(Machine machine)
      : machine = machine.copy(),
        command = null,
        remoteType = RemoteType.machine {
    _start();
  }

  TerminalSession.command(SSHCommandReader command)
      : machine = Machine.fromCommand(command),
        command = command,
        remoteType = RemoteType.command {
    _start();
  }

  final String id = newId();
  final Machine machine;
  final SSHCommandReader? command;
  final RemoteType remoteType;

  final Terminal terminal = Terminal(maxLines: 10000);
  final TerminalController controller = TerminalController();

  SshConnection? _connection;
  SSHSession? _shell;
  bool _closed = false;
  bool _disposed = false;

  /// The title the remote shell set (OSC 0/2), shown under the server name.
  String navigationSubtitle = '';

  bool get closed => _closed;

  String get displayName => switch (remoteType) {
        RemoteType.machine => machine.name,
        RemoteType.command => '${command!.username}@${command!.remoteAddress}',
      };

  String get navigationTitle => switch (remoteType) {
        RemoteType.machine => machine.name,
        RemoteType.command => command!.command,
      };

  void _putInformation(String line) => terminal.write('$line\r\n');

  void _start() {
    terminal.onTitleChange = (title) {
      navigationSubtitle = title;
      _notify();
    };
    terminal.onOutput = (data) {
      _shell?.write(Uint8List.fromList(utf8.encode(data)));
    };
    terminal.onResize = (w, h, pw, ph) {
      _shell?.resizeTerminal(w, h, pw, ph);
    };
    _bootstrap();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _bootstrap() async {
    _closed = false;
    _notify();
    _putInformation(S.l.creatingConnection);
    final store = CatusshStore.shared;
    try {
      final Machine target = machine;
      final connection = await SshConnection.forMachine(
        target,
        username: command?.username,
        hint: _putInformation,
      );
      if (_disposed) {
        connection.close();
        return;
      }
      _connection = connection;
      if (remoteType == RemoteType.machine) {
        store.recordConnection(machine.id, banner: connection.banner ?? 'No Banner');
      }
      final width = terminal.viewWidth < 8 ? 80 : terminal.viewWidth;
      final height = terminal.viewHeight < 8 ? 40 : terminal.viewHeight;
      final shell = await connection.client.shell(
        pty: SSHPtyConfig(type: 'xterm-256color', width: width, height: height),
      );
      _shell = shell;
      final decoder = const Utf8Decoder(allowMalformed: true);
      final output = StreamGroup.merge([shell.stdout, shell.stderr]);
      await for (final chunk in output.cast<List<int>>().transform(decoder)) {
        terminal.write(chunk);
      }
      await shell.done;
      _processShutdown(exitFromShell: true);
    } on ConnectFailure catch (failure) {
      _putInformation(failure.message.replaceAll('\n', '\r\n'));
      _processShutdown(exitFromShell: true);
    } catch (error) {
      _processShutdown(exitFromShell: true, lastError: '$error');
    }
  }

  void _processShutdown({bool exitFromShell = false, String? lastError}) {
    if (_closed) return;
    if (exitFromShell && !_disposed) {
      _putInformation('');
      _putInformation(S.l.connectionClosedBanner);
    }
    if (lastError != null) {
      _putInformation(S.l.lastErrorFromBackend);
      _putInformation('    $lastError');
    }
    _closed = true;
    _shell?.close();
    _shell = null;
    _connection?.close();
    _connection = null;
    _notify();
  }

  void reconnect() {
    if (!_closed) return;
    _putInformation(S.l.reconnectingNote);
    _putInformation(S.l.reconnectingNoteHelp);
    _bootstrap();
  }

  void close() {
    _processShutdown();
    _disposed = true;
  }
}

/// Merges streams without pulling in package:async.
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late StreamController<T> controller;
    final subscriptions = <StreamSubscription<T>>[];
    var open = streams.length;
    controller = StreamController<T>(
      onListen: () {
        for (final stream in streams) {
          subscriptions.add(stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              open -= 1;
              if (open == 0) controller.close();
            },
          ));
        }
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }
}
