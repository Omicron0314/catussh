// The main window's navigation and the sessions it shows: the AppRouter of
// the Swift app, together with TerminalManager, FileTransferManager,
// EditorCenter, MonitorCenter and PortForwardBackend.

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/ssh_command_reader.dart';
import '../core/store.dart';
import '../sessions/editor_workspace.dart';
import '../sessions/file_transfer_session.dart';
import '../sessions/monitor_session.dart';
import '../sessions/port_forward_session.dart';
import '../sessions/terminal_session.dart';

enum Place { home, servers, identities, snippets, portForward, settings }

/// The four ways into a server. Every surface that opens one uses these
/// names, icons and descriptions, so a button means the same thing wherever
/// it appears.
enum ServerTool {
  terminal('Terminal', Icons.terminal, 'Open an SSH terminal on this server'),
  files('Files', Icons.folder_outlined, 'Browse, upload and download files over SFTP'),
  editor('Editor', Icons.edit_note, 'Edit text files on this server'),
  monitor('Monitor', Icons.speed, 'Watch CPU, memory, disk and network usage');

  const ServerTool(this.title, this.icon, this.help);
  final String title;
  final IconData icon;
  final String help;
}

sealed class Route {
  const Route();
  bool get isSession => this is SessionRoute;
}

class PlaceRoute extends Route {
  const PlaceRoute(this.place);
  final Place place;

  @override
  bool operator ==(Object other) => other is PlaceRoute && other.place == place;
  @override
  int get hashCode => place.hashCode;
}

class SessionRoute extends Route {
  const SessionRoute(this.tool, this.id);
  final ServerTool tool;
  final String id;

  @override
  bool operator ==(Object other) => other is SessionRoute && other.tool == tool && other.id == id;
  @override
  int get hashCode => Object.hash(tool, id);
}

/// What owns a group of session pages: a saved server, or one Quick Connect
/// terminal (which has no saved server to group under).
sealed class SessionOwner {
  const SessionOwner();
}

class ServerOwner extends SessionOwner {
  const ServerOwner(this.machineId);
  final String machineId;
  @override
  bool operator ==(Object other) => other is ServerOwner && other.machineId == machineId;
  @override
  int get hashCode => machineId.hashCode;
}

class CommandOwner extends SessionOwner {
  const CommandOwner(this.terminalId);
  final String terminalId;
  @override
  bool operator ==(Object other) => other is CommandOwner && other.terminalId == terminalId;
  @override
  int get hashCode => terminalId.hashCode;
}

class AppRouter extends ChangeNotifier {
  AppRouter(this.store);

  static late AppRouter shared;

  final CatusshStore store;

  Route _route = const PlaceRoute(Place.home);
  Route get route => _route;

  /// The last page that is not a session; closing a session returns here.
  Route lastPlace = const PlaceRoute(Place.home);

  /// The page each server showed last, so its sidebar row returns to it.
  final Map<SessionOwner, Route> _lastRoute = {};

  String settingsCategory = 'general';

  /// Ask the active page to show the New Server editor (menu, Home, Servers).
  final ValueNotifier<int> newServerRequests = ValueNotifier(0);

  set route(Route value) {
    _route = value;
    if (!value.isSession) {
      lastPlace = value;
    } else {
      final owner = ownerOf(value);
      if (owner != null) _lastRoute[owner] = value;
    }
    notifyListeners();
  }

  void go(Place place) => route = PlaceRoute(place);

  void openSettings([String category = 'general']) {
    settingsCategory = category;
    go(Place.settings);
  }

  // MARK: Sessions

  final List<TerminalSession> terminals = [];
  final List<FileTransferSession> transfers = [];
  final List<EditorWorkspace> editors = [];
  final List<MonitorSession> monitors = [];
  final Map<String, PortForwardSession> forwards = {};

  void _changed() => notifyListeners();

  T _watch<T extends ChangeNotifier>(T session) {
    session.addListener(_changed);
    return session;
  }

  /// Leaves a session page whose session has just closed.
  void _leaveIfShowing(ServerTool tool, String id) {
    if (_route == SessionRoute(tool, id)) {
      _route = lastPlace;
    }
    notifyListeners();
  }

  // Terminals

  TerminalSession? terminalForMachine(String machineId) {
    for (final t in terminals) {
      if (t.remoteType == RemoteType.machine && t.machine.id == machineId) return t;
    }
    return null;
  }

  TerminalSession openTerminal(Machine machine) {
    final session = _watch(TerminalSession.machine(machine));
    terminals.add(session);
    store.storeRecentMachine(machine.id);
    if (store.openInterfaceAutomatically) {
      route = SessionRoute(ServerTool.terminal, session.id);
    } else {
      notifyListeners();
    }
    return session;
  }

  TerminalSession openTerminalCommand(SSHCommandReader command) {
    final session = _watch(TerminalSession.command(command));
    terminals.add(session);
    store.storeRecentCommand(command);
    if (store.openInterfaceAutomatically) {
      route = SessionRoute(ServerTool.terminal, session.id);
    } else {
      notifyListeners();
    }
    return session;
  }

  void closeTerminal(TerminalSession session) {
    session.removeListener(_changed);
    session.close();
    terminals.remove(session);
    _leaveIfShowing(ServerTool.terminal, session.id);
  }

  // Files

  FileTransferSession? transferForMachine(String machineId) {
    for (final t in transfers) {
      if (t.machine.id == machineId) return t;
    }
    return null;
  }

  FileTransferSession beginTransfer(Machine machine) {
    final existing = transferForMachine(machine.id);
    if (existing != null) return existing;
    final session = _watch(FileTransferSession(machine));
    transfers.add(session);
    store.storeRecentMachine(machine.id);
    return session;
  }

  void openFileTransfer(Machine machine) {
    route = SessionRoute(ServerTool.files, beginTransfer(machine).id);
  }

  void closeTransfer(FileTransferSession session) {
    final workspace = editorFor(session.id);
    if (workspace != null) closeEditor(workspace);
    session.removeListener(_changed);
    session.close();
    transfers.remove(session);
    _leaveIfShowing(ServerTool.files, session.id);
  }

  // Editor (works over the server's SFTP session, keyed by its id)

  EditorWorkspace? editorFor(String transferId) {
    for (final e in editors) {
      if (e.id == transferId) return e;
    }
    return null;
  }

  void openEditor(Machine machine, {String? path}) {
    final transfer = beginTransfer(machine);
    openEditorFor(transfer, path: path);
  }

  void openEditorFor(FileTransferSession transfer, {String? path}) {
    var workspace = editorFor(transfer.id);
    if (workspace == null) {
      workspace = _watch(EditorWorkspace(transfer));
      editors.add(workspace);
    }
    if (path != null) workspace.open(path);
    route = SessionRoute(ServerTool.editor, transfer.id);
  }

  void closeEditor(EditorWorkspace workspace) {
    workspace.removeListener(_changed);
    workspace.dispose();
    editors.remove(workspace);
    _leaveIfShowing(ServerTool.editor, workspace.id);
  }

  // Monitor

  MonitorSession? monitorForMachine(String machineId) {
    for (final m in monitors) {
      if (m.machine.id == machineId) return m;
    }
    return null;
  }

  MonitorSession beginMonitor(Machine machine) {
    final existing = monitorForMachine(machine.id);
    if (existing != null) return existing;
    final session = _watch(MonitorSession(machine));
    monitors.add(session);
    store.storeRecentMachine(machine.id);
    notifyListeners();
    return session;
  }

  void openMonitor(Machine machine) {
    route = SessionRoute(ServerTool.monitor, beginMonitor(machine).id);
  }

  void closeMonitor(MonitorSession session) {
    session.removeListener(_changed);
    session.shutdown();
    monitors.remove(session);
    _leaveIfShowing(ServerTool.monitor, session.id);
  }

  /// Shows [tool] for the server, reusing a session that is already open.
  void show(ServerTool tool, Machine machine) {
    switch (tool) {
      case ServerTool.terminal:
        final existing = terminalForMachine(machine.id);
        if (existing != null) {
          route = SessionRoute(ServerTool.terminal, existing.id);
        } else {
          openTerminal(machine);
          if (!store.openInterfaceAutomatically) {
            route = SessionRoute(ServerTool.terminal, terminals.last.id);
          }
        }
      case ServerTool.files:
        openFileTransfer(machine);
      case ServerTool.editor:
        openEditor(machine);
      case ServerTool.monitor:
        openMonitor(machine);
    }
  }

  // Port forwards

  bool isForwardRunning(String id) => forwards.containsKey(id);

  void startForward(PortForward forward) {
    if (forwards.containsKey(forward.id)) return;
    final machine = store.machine(forward.usingMachine);
    if (machine == null || !forward.isValid(machine)) return;
    final session = _watch(PortForwardSession(forward.copy(), machine));
    session.onTerminated = (s) {
      s.removeListener(_changed);
      if (forwards[forward.id] == s) forwards.remove(forward.id);
      notifyListeners();
    };
    forwards[forward.id] = session;
    notifyListeners();
  }

  void stopForward(String id) {
    forwards[id]?.terminate();
  }

  void stopAllForwards() {
    for (final f in forwards.values.toList()) {
      f.terminate();
    }
  }

  // MARK: Sessions by server

  SessionOwner? ownerOf(Route route) {
    if (route is! SessionRoute) return null;
    switch (route.tool) {
      case ServerTool.terminal:
        for (final t in terminals) {
          if (t.id == route.id) {
            return t.remoteType == RemoteType.machine ? ServerOwner(t.machine.id) : CommandOwner(t.id);
          }
        }
      case ServerTool.files || ServerTool.editor:
        for (final t in transfers) {
          if (t.id == route.id) return ServerOwner(t.machine.id);
        }
      case ServerTool.monitor:
        for (final m in monitors) {
          if (m.id == route.id) return ServerOwner(m.machine.id);
        }
    }
    return null;
  }

  /// Every open session page: terminals first, then files, editors, monitors.
  List<SessionRoute> get sessionRoutes => [
        for (final t in terminals) SessionRoute(ServerTool.terminal, t.id),
        for (final t in transfers) SessionRoute(ServerTool.files, t.id),
        for (final e in editors) SessionRoute(ServerTool.editor, e.id),
        for (final m in monitors) SessionRoute(ServerTool.monitor, m.id),
      ];

  /// Servers and Quick Connect terminals with something open.
  List<SessionOwner> get openOwners {
    final seen = <SessionOwner>{};
    return [
      for (final r in sessionRoutes)
        if (ownerOf(r) case final owner? when seen.add(owner)) owner,
    ];
  }

  List<SessionRoute> routesOf(SessionOwner owner) =>
      sessionRoutes.where((r) => ownerOf(r) == owner).toList();

  void showOwner(SessionOwner owner) {
    final open = routesOf(owner);
    final last = _lastRoute[owner];
    if (last != null && open.contains(last)) {
      route = last;
    } else if (open.isNotEmpty) {
      route = open.first;
    }
  }

  void closeRoute(SessionRoute route) {
    switch (route.tool) {
      case ServerTool.terminal:
        final t = terminals.where((t) => t.id == route.id).firstOrNull;
        if (t != null) closeTerminal(t);
      case ServerTool.files:
        final t = transfers.where((t) => t.id == route.id).firstOrNull;
        if (t != null) closeTransfer(t);
      case ServerTool.editor:
        final e = editorFor(route.id);
        if (e != null) closeEditor(e);
      case ServerTool.monitor:
        final m = monitors.where((m) => m.id == route.id).firstOrNull;
        if (m != null) closeMonitor(m);
    }
  }

  void closeAll(SessionOwner owner) {
    for (final r in routesOf(owner)) {
      closeRoute(r);
    }
  }

  /// Ends a deleted server's monitor, as ServerActions.delete did.
  void forgetMachine(String machineId) {
    final monitor = monitorForMachine(machineId);
    if (monitor != null) closeMonitor(monitor);
  }

  void shutdownAll() {
    for (final t in List.of(terminals)) {
      t.close();
    }
    for (final t in List.of(transfers)) {
      t.close();
    }
    for (final m in List.of(monitors)) {
      m.shutdown();
    }
    stopAllForwards();
  }
}
