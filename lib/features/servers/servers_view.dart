// All servers grouped, with search, privacy, Open Terminals and New Server
// (ServersView.swift).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../sessions/monitor_session.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'server_actions.dart';
import 'server_editor.dart';
import 'server_picker.dart';

List<(String, List<Machine>)> groupMachines(List<Machine> machines) {
  final names = machines.map((m) => m.group).toSet().toList()
    ..sort((a, b) {
      if (a.isEmpty) return 1;
      if (b.isEmpty) return -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
  return [
    for (final name in names)
      (
        name,
        machines.where((m) => m.group == name).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      ),
  ];
}

class ServersView extends StatefulWidget {
  const ServersView({super.key});

  @override
  State<ServersView> createState() => _ServersViewState();
}

class _ServersViewState extends State<ServersView> {
  final _search = TextEditingController();
  String? _selection;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final filtered = _search.text.isEmpty
        ? store.machines
        : store.machines.where((m) => m.isQualifiedForSearch(_search.text)).toList();
    final groups = groupMachines(filtered);

    Widget body;
    if (store.machines.isEmpty) {
      body = RXCard(
        child: EmptyStateView('No servers yet',
            icon: Icons.dns_outlined, actionTitle: 'New Server', action: () => showServerEditor(context)),
      );
    } else if (filtered.isEmpty) {
      body = const RXCard(child: EmptyStateView('No matches', icon: Icons.search));
    } else {
      body = _ServersTable(groups: groups, selection: _selection, onSelect: (id) => setState(() => _selection = id));
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.delete): () {
          final m = store.machine(_selection);
          if (m != null) ServerActions.delete(context, [m]);
        },
      },
      child: Focus(
        autofocus: true,
        child: PageScaffold(
          title: 'Servers',
          search: _search,
          searchHint: 'Search servers',
          actions: [
            const RedactionMenu(),
            Tooltip(
              message: 'Pick several servers and open a terminal on each',
              child: OutlinedButton.icon(
                onPressed: store.machines.isEmpty ? null : () => openTerminals(context),
                icon: const Icon(Icons.library_add_outlined, size: 18),
                label: const Text('Open Terminals…'),
              ),
            ),
            FilledButton.icon(
              onPressed: () => showServerEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('New Server'),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (store.machineRedacted != RedactedLevel.none) ...[
                const RedactionBanner(),
                const SizedBox(height: RX.s3),
              ],
              SizedBox(width: double.infinity, child: body),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openTerminals(BuildContext context) async {
    final router = context.read<AppRouter>();
    final store = context.read<CatusshStore>();
    final picked = await pickServers(context, title: 'Open Terminals', confirmTitle: 'Open');
    if (picked == null || picked.isEmpty) return;
    final auto = store.openInterfaceAutomatically;
    String? first;
    for (final id in picked) {
      final m = store.machine(id);
      if (m == null) continue;
      store.openInterfaceAutomatically = false;
      final session = router.openTerminal(m);
      first ??= session.id;
    }
    store.openInterfaceAutomatically = auto;
    if (first != null && auto) router.route = SessionRoute(ServerTool.terminal, first);
  }
}

class RedactionMenu extends StatelessWidget {
  const RedactionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final level = store.machineRedacted;
    MenuItemButton item(String title, IconData icon, RedactedLevel l) => MenuItemButton(
          leadingIcon: Icon(icon, size: 18),
          trailingIcon: level == l ? const Icon(Icons.check, size: 18) : null,
          onPressed: () => store.update((s) => s.machineRedacted = l),
          child: Text(title),
        );
    return MenuAnchor(
      menuChildren: [
        item('Show Everything', Icons.visibility_outlined, RedactedLevel.none),
        item('Hide Addresses', Icons.visibility_off_outlined, RedactedLevel.sensitive),
        item('Hide Names and Addresses', Icons.visibility_off, RedactedLevel.all),
      ],
      builder: (context, controller, _) => Tooltip(
        message: level.tooltip,
        child: TextButton.icon(
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: Icon(level == RedactedLevel.none ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
          label: const Text('Privacy'),
        ),
      ),
    );
  }
}

class RedactionBanner extends StatelessWidget {
  const RedactionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 4),
      height: 40,
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_outlined, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: RX.s2),
          Text(store.machineRedacted == RedactedLevel.all ? 'Names and addresses hidden' : 'Addresses hidden',
              style: TextStyle(color: scheme.onSecondaryContainer)),
          const SizedBox(width: RX.s2),
          TextButton(onPressed: () => store.update((s) => s.machineRedacted = RedactedLevel.none), child: const Text('Show')),
        ],
      ),
    );
  }
}

class _ServersTable extends StatelessWidget {
  const _ServersTable({required this.groups, required this.selection, required this.onSelect});
  final List<(String, List<Machine>)> groups;
  final String? selection;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return RXCard(
      padding: const EdgeInsets.all(RX.s2),
      child: LayoutBuilder(builder: (context, c) {
        final columns = _Columns(c.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, columns),
            const Divider(),
            for (final (name, machines) in groups) ...[
              _GroupRow(name.isEmpty ? 'Default' : name, machines.length),
              for (final m in machines)
                _ServerRow(machine: m, columns: columns, selected: m.id == selection, onSelect: () => onSelect(m.id)),
            ],
          ],
        );
      }),
    );
  }

  Widget _header(BuildContext context, _Columns columns) {
    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RX.s3),
        child: Row(
          children: [
            const Expanded(child: CapsLabel('Name')),
            const SizedBox(width: _Columns.address, child: CapsLabel('Address')),
            if (columns.showIdentity) const SizedBox(width: _Columns.identity, child: CapsLabel('Identity')),
            if (columns.showCPU) const SizedBox(width: _Columns.cpu, child: CapsLabel('CPU')),
            if (columns.showLastUsed) const SizedBox(width: _Columns.lastUsed, child: CapsLabel('Last used')),
            const SizedBox(width: _Columns.actions),
          ],
        ),
      ),
    );
  }
}

class _Columns {
  _Columns(double width)
      : showCPU = width > _base + cpu,
        showIdentity = width > _base + cpu + identity,
        showLastUsed = width > _base + cpu + identity + lastUsed;

  static const address = 160.0;
  static const identity = 120.0;
  static const cpu = 110.0;
  static const lastUsed = 130.0;
  static const actions = 250.0;
  static const _base = 180 + address + actions + 24;

  final bool showIdentity, showCPU, showLastUsed;
}

class _GroupRow extends StatelessWidget {
  const _GroupRow(this.title, this.count);
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(RX.s3, RX.s3, RX.s3, RX.s1),
      child: Row(children: [Text(title, style: style), const Spacer(), Text('$count', style: style)]),
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({required this.machine, required this.columns, required this.selected, required this.onSelect});
  final Machine machine;
  final _Columns columns;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final router = context.watch<AppRouter>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monitor = router.monitorForMachine(machine.id);
    final identityName = machine.associatedIdentity == null
        ? 'Automatic'
        : (store.identity(machine.associatedIdentity)?.username ?? 'Missing');
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    const dense = VisualDensity(horizontal: -3, vertical: -3);

    return GestureDetector(
      onSecondaryTapUp: (d) {
        onSelect();
        showServerMenu(context, machine, d.globalPosition);
      },
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSelect,
          onDoubleTap: () => router.show(ServerTool.terminal, machine),
          child: Container(
            constraints: const BoxConstraints(minHeight: RX.tableRowHeight),
            padding: const EdgeInsets.symmetric(horizontal: RX.s3, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RedactableText(machine.name,
                          redacted: store.machineRedacted == RedactedLevel.all, style: theme.textTheme.bodyMedium),
                      if (machine.comment.isNotEmpty && store.machineRedacted == RedactedLevel.none)
                        Text(machine.comment,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                SizedBox(
                  width: _Columns.address,
                  child: RedactableText(machine.remoteAddress,
                      redacted: store.machineRedacted != RedactedLevel.none, style: RX.code(context, size: 13)),
                ),
                if (columns.showIdentity)
                  SizedBox(
                    width: _Columns.identity,
                    child: Text(identityName,
                        overflow: TextOverflow.ellipsis,
                        style: machine.associatedIdentity == null ? muted : theme.textTheme.bodyMedium),
                  ),
                if (columns.showCPU)
                  SizedBox(
                    width: _Columns.cpu,
                    child: monitor == null
                        ? Text('—', style: muted)
                        : ListenableBuilder(
                            listenable: monitor,
                            builder: (context, _) => monitor.phase is MonitorConnected && monitor.status.hasData
                                ? Row(children: [
                                    SizedBox(
                                        width: 50,
                                        child: UsageBar(segments: [(monitor.status.processor.summary.sumUsed / 100, scheme.primary)])),
                                    const SizedBox(width: 8),
                                    Text('${RXFormat.percent(monitor.status.processor.summary.sumUsed)}%'),
                                  ])
                                : Text('—', style: muted),
                          ),
                  ),
                if (columns.showLastUsed)
                  SizedBox(width: _Columns.lastUsed, child: Text(RXFormat.relative(machine.lastConnection), style: muted)),
                SizedBox(
                  width: _Columns.actions,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: ServerTool.files.help,
                        child: TextButton(
                            style: TextButton.styleFrom(visualDensity: dense),
                            onPressed: () => router.show(ServerTool.files, machine),
                            child: const Text('Files')),
                      ),
                      Tooltip(
                        message: ServerTool.monitor.help,
                        child: TextButton(
                            style: TextButton.styleFrom(visualDensity: dense),
                            onPressed: () => router.show(ServerTool.monitor, machine),
                            child: const Text('Monitor')),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: ServerTool.terminal.help,
                        child: FilledButton.tonal(
                            style: FilledButton.styleFrom(visualDensity: dense),
                            onPressed: () => router.show(ServerTool.terminal, machine),
                            child: const Text('Connect')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
