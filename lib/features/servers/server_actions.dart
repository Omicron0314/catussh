// The server context menu (Servers table, Home tiles) and the actions behind
// it (ServerActions.swift).

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../ui/widgets.dart';
import '../menubar/tray.dart';
import 'server_editor.dart';

class ServerActions {
  static Future<void> duplicate(BuildContext context, Machine machine) async {
    final ok = await requiresConfirmation(context, message: 'Duplicate ${machine.name}?', confirmTitle: 'Duplicate');
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
      message: machines.length == 1 ? 'Delete ${machines.first.name}?' : 'Delete ${machines.length} servers?',
      informative: 'Port forwards through it stop working.',
      confirmTitle: 'Delete',
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
      message: 'Forget the host key of ${machine.name}?',
      informative:
          'The key the server presents on the next connection is saved as its key. Do this only when you know its keys were replaced.',
      confirmTitle: 'Forget',
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
      menuItem('Open Terminal', ServerTool.terminal.icon, () => router.show(ServerTool.terminal, machine)),
      menuItem('Open Files', ServerTool.files.icon, () => router.show(ServerTool.files, machine)),
      menuItem('Open Editor', ServerTool.editor.icon, () => router.show(ServerTool.editor, machine)),
      menuItem('Open Monitor', ServerTool.monitor.icon, () => router.show(ServerTool.monitor, machine)),
    ],
    menuItem('New Terminal', Icons.add_box_outlined, () => router.openTerminal(machine)),
    menuItem('Show in Tray', Icons.pets, () => TrayController.instance.show(machine),
        enabled: TrayController.instance.available),
    const PopupMenuDivider(),
    menuItem('Edit…', Icons.edit_outlined, () => showServerEditor(context, machine: machine)),
    menuItem('Duplicate', Icons.copy_all_outlined, () => ServerActions.duplicate(context, machine)),
    menuItem('Copy Address', Icons.content_copy,
        () => copyToClipboard(context, '${machine.remoteAddress}:${machine.remotePort}', what: 'Address')),
    menuItem('Copy SSH Command', Icons.code,
        () => copyToClipboard(context, machine.getCommand(store.usernameFor(machine)), what: 'Command')),
    menuItem('Forget Host Key…', Icons.key_off_outlined, () => ServerActions.forgetHostKey(context, machine)),
    const PopupMenuDivider(),
    menuItem('Delete…', Icons.delete_outline, () => ServerActions.delete(context, [machine]),
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
