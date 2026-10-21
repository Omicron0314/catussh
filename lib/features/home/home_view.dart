// Home: Quick Connect, recent connections and a grid of server tiles
// (HomeView.swift).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/ssh_command_reader.dart';
import '../../core/store.dart';
import '../../core/strings.dart';
import '../../sessions/monitor_session.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../servers/server_actions.dart';
import '../servers/server_editor.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    return PageScaffold(
      actions: [
        FilledButton.icon(
          onPressed: () => showServerEditor(context),
          icon: const Icon(Icons.add),
          label: Text(S.l.newServer),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const QuickConnectHero(),
          const SizedBox(height: RX.s6 * 2),
          if (store.machines.isEmpty)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: RXCard(
                  child: EmptyStateView(
                    S.l.emptyServersTitle,
                    icon: Icons.dns_outlined,
                    message: S.l.emptyServersMessage,
                    actionTitle: S.l.newServer,
                    action: () => showServerEditor(context),
                  ),
                ),
              ),
            )
          else ...[
            SectionTitle(
              S.l.serversSection,
              count: store.machines.length,
              trailing: TextButton(
                onPressed: () => context.read<AppRouter>().go(Place.servers),
                child: Text(S.l.showAll),
              ),
            ),
            const SizedBox(height: RX.s3),
            LayoutBuilder(
              builder: (context, c) {
                final columns = (c.maxWidth / 310).floor().clamp(1, 6);
                final width = (c.maxWidth - RX.s4 * (columns - 1)) / columns;
                return Wrap(
                  spacing: RX.s4,
                  runSpacing: RX.s4,
                  children: [
                    for (final m in store.machines) SizedBox(width: width, child: ServerTile(machine: m)),
                    SizedBox(width: width, child: const NewServerTile()),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class QuickConnectHero extends StatefulWidget {
  const QuickConnectHero({super.key});

  @override
  State<QuickConnectHero> createState() => _QuickConnectHeroState();
}

class _QuickConnectHeroState extends State<QuickConnectHero> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _suggestion;

  SSHCommandReader? get _parsed => SSHCommandReader.quickConnect(_controller.text);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _focus.addListener(() => setState(() {}));
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    final text = _controller.text;
    if (text.startsWith('ssh ssh ')) {
      _controller.text = text.substring(4);
      return;
    }
    final store = context.read<CatusshStore>();
    setState(() {
      _suggestion = SSHCommandReader.suggestion(text, store.recentRecord.map(store.equivalentSSHCommand));
    });
  }

  void _connect([SSHCommandReader? command]) {
    final parsed = command ?? _parsed;
    if (parsed == null) return;
    context.read<AppRouter>().openTerminalCommand(parsed);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parsed = _parsed;
    final focused = _focus.hasFocus;
    final recents = store.storeRecent ? store.recentRecord : const <RecentConnection>[];

    final field = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 64,
      padding: const EdgeInsets.only(left: 20, right: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: focused ? scheme.primary : Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: focused ? 0.12 : 0.05),
            blurRadius: focused ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.terminal, size: 24, color: scheme.onSurfaceVariant),
          const SizedBox(width: RX.s3),
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
                  final s = _suggestion;
                  if (s != null) _connect(SSHCommandReader.parse(s));
                },
              },
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autocorrect: false,
                style: RX.code(context, size: 22, color: scheme.onSurface),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: S.l.quickConnectHint,
                  hintStyle: RX.code(context, size: 22, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
                onSubmitted: (_) => _connect(),
              ),
            ),
          ),
          Tooltip(
            message: S.l.connectEnter,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              scale: parsed == null ? 0.9 : 1,
              child: IconButton.filled(
                onPressed: parsed == null ? null : _connect,
                icon: const Icon(Icons.arrow_forward),
                style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: field),
        const SizedBox(height: RX.s4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: parsed != null
              ? _ParsedCommand(key: ValueKey(parsed.command), command: parsed)
              : (!'ssh '.startsWith(_controller.text.toLowerCase())
                  ? Text(
                      S.l.quickConnectHelp,
                      key: const ValueKey('help'),
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    )
                  : const SizedBox(key: ValueKey('none'), height: 0)),
        ),
        if (_suggestion != null) ...[
          const SizedBox(height: RX.s2),
          TextButton.icon(
            onPressed: () => _connect(SSHCommandReader.parse(_suggestion!)),
            icon: const Icon(Icons.subdirectory_arrow_right, size: 18),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_suggestion!, style: RX.code(context, size: 13)),
                const SizedBox(width: RX.s2),
                const _KeyHint('Ctrl+Enter'),
              ],
            ),
          ),
        ],
        if (store.identitiesForAutoAuth.isEmpty) ...[
          const SizedBox(height: RX.s3),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: RX.s2,
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: scheme.warning),
              Text(
                S.l.quickConnectNoAutoIdentity,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.warning),
              ),
              TextButton(
                onPressed: () => context.read<AppRouter>().go(Place.identities),
                child: Text(S.l.openIdentities),
              ),
            ],
          ),
        ],
        if (recents.isNotEmpty) ...[
          const SizedBox(height: RX.s5),
          CapsLabel(S.l.recent),
          const SizedBox(height: RX.s2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: RX.s2,
              runSpacing: RX.s2,
              children: [for (final r in recents) RecentChip(record: r)],
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _ParsedCommand extends StatelessWidget {
  const _ParsedCommand({super.key, required this.command});
  final SSHCommandReader command;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget token(String title, String value, IconData icon, Color tint) => Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tint.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: tint),
              const SizedBox(width: 5),
              CapsLabel(title),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: RX.code(context, size: 12, color: scheme.onSurface, weight: FontWeight.w500)),
              ),
            ],
          ),
        );
    return Wrap(
      spacing: RX.s2,
      runSpacing: RX.s2,
      alignment: WrapAlignment.center,
      children: [
        token(S.l.user, command.username, Icons.person_outline, scheme.primary),
        token(S.l.host, command.remoteAddress, Icons.lan_outlined, scheme.series2),
        token(S.l.port, command.remotePort, Icons.tag, scheme.onSurfaceVariant),
      ],
    );
  }
}

class RecentChip extends StatelessWidget {
  const RecentChip({super.key, required this.record});
  final RecentConnection record;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final isCommand = record is RecentCommand;
    final String title;
    switch (record) {
      case RecentCommand(:final command):
        title = command.command.startsWith('ssh ') ? command.command.substring(4) : command.command;
      case RecentMachine(:final machine):
        title = store.machine(machine)?.name ?? S.l.deletedServer;
    }
    return GestureDetector(
      onSecondaryTapUp: (d) => runMenu(context, d.globalPosition, [
        menuItem(S.l.copyCommand, Icons.copy, () => copyToClipboard(context, store.equivalentSSHCommand(record), what: S.l.command)),
        const PopupMenuDivider(),
        menuItem(S.l.removeFromRecent, Icons.delete_outline, () => store.removeRecent(record),
            destructive: true, context: context),
      ]),
      child: ActionChip(
        avatar: Icon(isCommand ? Icons.terminal : Icons.dns_outlined, size: 16),
        label: RedactableText(
          title,
          redacted: !isCommand && store.machineRedacted == RedactedLevel.all,
          style: isCommand ? RX.code(context, size: 12) : null,
        ),
        shape: const StadiumBorder(),
        onPressed: () {
          final router = context.read<AppRouter>();
          switch (record) {
            case RecentCommand(:final command):
              router.openTerminalCommand(command);
            case RecentMachine(:final machine):
              final m = store.machine(machine);
              if (m != null) router.openTerminal(m);
          }
        },
      ),
    );
  }
}

const _tileHeight = 172.0;

class ServerTile extends StatelessWidget {
  const ServerTile({super.key, required this.machine});
  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final router = context.watch<AppRouter>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final connected = router.terminals.any((t) => t.machine.id == machine.id && !t.closed);
    final monitor = router.monitorForMachine(machine.id);

    return Hoverable(
      builder: (context, hovered) => AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: hovered ? 1.01 : 1,
        child: GestureDetector(
          onSecondaryTapUp: (d) => showServerMenu(context, machine, d.globalPosition),
          child: Card(
            elevation: hovered ? 3 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: hovered ? scheme.primary.withValues(alpha: 0.35) : Colors.transparent),
            ),
            child: InkWell(
              onTap: () => router.show(ServerTool.terminal, machine),
              child: Tooltip(
                message: S.l.clickToOpenTerminal,
                waitDuration: const Duration(seconds: 1),
                child: Padding(
                  padding: const EdgeInsets.all(RX.s4),
                  child: SizedBox(
                    height: _tileHeight - RX.s4 * 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RedactableText(machine.name,
                                      redacted: store.machineRedacted == RedactedLevel.all,
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  RedactableText(machine.remoteAddress,
                                      redacted: store.machineRedacted != RedactedLevel.none,
                                      style: RX.code(context, size: 12, color: scheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            if (connected)
                              Tooltip(
                                message: S.l.terminalOpen,
                                child: const Padding(padding: EdgeInsets.only(top: 6), child: StatusDot(size: 7)),
                              ),
                          ],
                        ),
                        const Spacer(),
                        if (monitor != null)
                          ListenableBuilder(
                            listenable: monitor,
                            builder: (context, _) => _TileLive(session: monitor, machine: machine),
                          )
                        else
                          _TileInfo(machine: machine),
                        const Spacer(),
                        _TileActions(machine: machine),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TileInfo extends StatelessWidget {
  const _TileInfo({required this.machine});
  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    String identityName() {
      if (machine.associatedIdentity == null) return S.l.automatic;
      return store.identity(machine.associatedIdentity)?.username ?? S.l.missing;
    }

    Widget row(String title, String value) => SizedBox(
          height: 18,
          child: Row(children: [CapsLabel(title), const Spacer(), Text(value, style: style)]),
        );
    return Column(
      children: [
        row(S.l.lastUsed, RXFormat.relative(machine.lastConnection)),
        const SizedBox(height: 4),
        row(S.l.identityLabel, identityName()),
      ],
    );
  }
}

class _TileLive extends StatelessWidget {
  const _TileLive({required this.session, required this.machine});
  final MonitorSession session;
  final Machine machine;

  @override
  Widget build(BuildContext context) {
    if (session.phase is! MonitorConnected || !session.status.hasData) return _TileInfo(machine: machine);
    final scheme = Theme.of(context).colorScheme;
    Widget bar(String title, double percent, Color color) => SizedBox(
          height: 18,
          child: Row(
            children: [
              SizedBox(width: 60, child: CapsLabel(title)),
              Expanded(child: UsageBar(segments: [(percent / 100, color)])),
              SizedBox(
                width: 40,
                child: Text('${RXFormat.percent(percent)}%',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ],
          ),
        );
    return Column(children: [
      bar(S.l.cpu, session.status.processor.summary.sumUsed, scheme.primary),
      const SizedBox(height: 4),
      bar(S.l.memory, session.status.memoryUsedPercent, scheme.series2),
    ]);
  }
}

class _TileActions extends StatelessWidget {
  const _TileActions({required this.machine});
  final Machine machine;

  @override
  Widget build(BuildContext context) {
    final router = context.read<AppRouter>();
    final label = Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 9)),
      iconSize: const WidgetStatePropertyAll(15),
      textStyle: WidgetStatePropertyAll(label),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    return LayoutBuilder(builder: (context, c) {
      // A narrow tile keeps the tools' icons and drops their names.
      final labels = c.maxWidth >= 280;
      Widget tool(ServerTool t) => Tooltip(
            message: t.help,
            child: labels
                ? FilledButton.tonalIcon(
                    style: style,
                    onPressed: () => router.show(t, machine),
                    icon: Icon(t.icon, size: 15),
                    label: Text(t.title),
                  )
                : IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () => router.show(t, machine),
                    icon: Icon(t.icon, size: 16),
                  ),
          );
      return Row(
        children: [
          Tooltip(
            message: ServerTool.terminal.help,
            child: FilledButton.icon(
              style: style,
              onPressed: () => router.show(ServerTool.terminal, machine),
              icon: const Icon(Icons.terminal, size: 15),
              label: Text(S.l.connect),
            ),
          ),
          const SizedBox(width: 6),
          tool(ServerTool.files),
          const SizedBox(width: 6),
          tool(ServerTool.monitor),
          const Spacer(),
          Builder(
            builder: (context) => IconButton(
              tooltip: S.l.moreActions,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                final box = context.findRenderObject() as RenderBox;
                showServerMenu(context, machine, box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                    includesTools: false);
              },
            ),
          ),
        ],
      );
    });
  }
}

class NewServerTile extends StatelessWidget {
  const NewServerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Hoverable(
      builder: (context, hovered) => Tooltip(
        message: S.l.addServer,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showServerEditor(context),
          child: CustomPaint(
            painter: _DashedBorder(color: hovered ? scheme.primary : scheme.outline, radius: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _tileHeight,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: hovered ? 0.06 : 0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: hovered ? 1.15 : 1,
                    child: Icon(Icons.add, color: hovered ? scheme.primary : scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: RX.s2),
                  Text(S.l.newServer, style: TextStyle(color: hovered ? scheme.primary : scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => oldDelegate.color != color;
}
