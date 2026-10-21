// The server context menu (Servers table, Home tiles) and the actions behind
// it (ServerActions.swift).

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/strings.dart';
import '../../ui/widgets.dart';
import '../menubar/tray.dart';
import 'server_editor.dart';

class ServerActions {
  static Future<void> duplicate(BuildContext context, Machine machine) async {
    final ok = await requiresConfirmation(context, message: S.l.duplicateServer(machine.name), confirmTitle: S.l.duplicate);
    if (!ok) return;
    final copy = machine.copy()
      ..id = newId()
      ..name = '${machine.name} copy';
    CatusshStore.shared.putMachine(copy);
  }

  static Future<void> delete(BuildContext context, List<Machine> machines) async {
    if (machines.isEmpty) return;
    final ok = await requiresConfirmation(
      context,
      message: machines.length == 1 ? S.l.deleteServer(machines.first.name) : S.l.deleteServers(machines.length),
      informative: S.l.portForwardsStop,
      confirmTitle: S.l.delete,
      destructive: true,
    );
    if (!ok) return;
    for (final m in machines) {
      AppRouter.shared.forgetMachine(m.id);
      TrayController.instance.removeIfShowing(m.id);
      CatusshStore.shared.deleteMachine(m.id);
    }
  }

  /// For a server whose keys were replaced: its next host key is saved.
  static Future<void> forgetHostKey(BuildContext context, Machine machine) async {
    final ok = await requiresConfirmation(
      context,
      message: S.l.forgetHostKeyOf(machine.name),
      informative: S.l.forgetHostKeyExplain,
      confirmTitle: S.l.forget,
    );
    if (!ok) return;
    CatusshStore.shared.knownHosts.forget(machine.remoteAddress, machine.port);
  }
}

/// Open Terminal, Files, Editor, Monitor, New Terminal, Show in Tray, Edit,
/// Duplicate, Copy Address, Copy SSH Command, Forget Host Key, Delete.
Future<void> showServerMenu(BuildContext context, Machine machine, Offset position, {bool includesTools = true}) {
  final router = AppRouter.shared;
  final store = CatusshStore.shared;
  return runMenu(context, position, [
    if (includesTools) ...[
      menuItem(S.l.openTerminal, ServerTool.terminal.icon, () => router.show(ServerTool.terminal, machine)),
      menuItem(S.l.openFiles, ServerTool.files.icon, () => router.show(ServerTool.files, machine)),
      menuItem(S.l.openEditor, ServerTool.editor.icon, () => router.show(ServerTool.editor, machine)),
      menuItem(S.l.openMonitor, ServerTool.monitor.icon, () => router.show(ServerTool.monitor, machine)),
    ],
    menuItem(S.l.newTerminal, Icons.add_box_outlined, () => router.openTerminal(machine)),
    menuItem(S.l.showInTray, Icons.pets, () => TrayController.instance.show(machine),
        enabled: TrayController.instance.available),
    const PopupMenuDivider(),
    menuItem(S.l.edit, Icons.edit_outlined, () => showServerEditor(context, machine: machine)),
    menuItem(S.l.duplicate, Icons.copy_all_outlined, () => ServerActions.duplicate(context, machine)),
    menuItem(S.l.copyAddress, Icons.content_copy,
        () => copyToClipboard(context, '${machine.remoteAddress}:${machine.remotePort}', what: S.l.fieldAddress)),
    menuItem(S.l.copyCommand, Icons.code,
        () => copyToClipboard(context, machine.getCommand(store.usernameFor(machine)), what: S.l.command)),
    menuItem(S.l.forgetHostKey, Icons.key_off_outlined, () => ServerActions.forgetHostKey(context, machine)),
    const PopupMenuDivider(),
    menuItem(S.l.deleteEllipsis, Icons.delete_outline, () => ServerActions.delete(context, [machine]),
        destructive: true, context: context),
  ]);
}

/// Terminal · Files · Editor · Monitor for one server, centred in a session
/// page's toolbar (ServerToolSwitcher).
class ServerToolSwitcher extends StatelessWidget {
  const ServerToolSwitcher({super.key, required this.machine, required this.current});
  final Machine machine;
  final ServerTool current;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ServerTool>(
      showSelectedIcon: false,
      segments: [
        for (final t in ServerTool.values)
          ButtonSegment(value: t, label: Text(t.title), icon: Icon(t.icon, size: 18), tooltip: t.help),
      ],
      selected: {current},
      onSelectionChanged: (s) => AppRouter.shared.show(s.first, machine),
    );
  }
}
