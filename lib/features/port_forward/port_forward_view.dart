// Port Forward: table with a switch per forward, editor sheet
// (PortForwardView.swift).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/strings.dart';
import '../../sessions/port_forward_session.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

class PortForwardView extends StatefulWidget {
  const PortForwardView({super.key});

  @override
  State<PortForwardView> createState() => _PortForwardViewState();
}

class _PortForwardViewState extends State<PortForwardView> {
  final _search = TextEditingController();
  String? _selection;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final router = context.watch<AppRouter>();
    final key = _search.text.toLowerCase();
    final filtered = key.isEmpty
        ? store.portForwards
        : store.portForwards
            .where((f) =>
                f.targetHost.toLowerCase().contains(key) ||
                '${f.targetPort}'.contains(key) ||
                '${f.bindPort}'.contains(key) ||
                (store.machine(f.usingMachine)?.name.toLowerCase().contains(key) ?? false))
            .toList();

    Widget body;
    if (store.portForwards.isEmpty) {
      body = RXCard(
        child: EmptyStateView(S.l.noPortForwards,
            icon: Icons.arrow_forward, actionTitle: S.l.newPortForward, action: () => showPortForwardEditor(context)),
      );
    } else if (filtered.isEmpty) {
      body = RXCard(child: EmptyStateView(S.l.noMatches, icon: Icons.search));
    } else {
      body = RXCard(
        padding: const EdgeInsets.all(RX.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: RX.s3),
                child: Row(children: [
                  SizedBox(width: _orientation, child: CapsLabel(S.l.orientation)),
                  SizedBox(width: _bind, child: CapsLabel(S.l.bind)),
                  Expanded(child: CapsLabel(S.l.through)),
                  Expanded(child: CapsLabel(S.l.target)),
                  SizedBox(width: _status + _toggle),
                ]),
              ),
            ),
            const Divider(),
            for (final f in filtered)
              _ForwardRow(forward: f, selected: f.id == _selection, onSelect: () => setState(() => _selection = f.id)),
          ],
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.delete): () {
          final f = store.portForward(_selection);
          if (f != null) PortForwardActions.delete(context, f);
        },
      },
      child: Focus(
        autofocus: true,
        child: PageScaffold(
          title: S.l.portForwardTitle,
          search: _search,
          searchHint: S.l.searchForwards,
          actions: [
            OutlinedButton.icon(
              onPressed: router.forwards.isEmpty ? null : router.stopAllForwards,
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
              label: Text(S.l.stopAll),
            ),
            FilledButton.icon(
              onPressed: () => showPortForwardEditor(context),
              icon: const Icon(Icons.add),
              label: Text(S.l.newPortForward),
            ),
          ],
          body: SizedBox(width: double.infinity, child: body),
        ),
      ),
    );
  }
}

const _orientation = 140.0;
const _bind = 90.0;
const _status = 220.0;
const _toggle = 60.0;

class PortForwardActions {
  static void duplicate(PortForward forward) {
    CatusshStore.shared.putPortForward(forward.copy()..id = newId());
  }

  static Future<void> delete(BuildContext context, PortForward forward) async {
    final ok = await requiresConfirmation(context,
        message: S.l.deleteForward(forward.bindPort), confirmTitle: S.l.delete, destructive: true);
    if (!ok) return;
    AppRouter.shared.stopForward(forward.id);
    CatusshStore.shared.deletePortForward(forward.id);
  }
}

/// The status text and its tone (PortForwardPresentation.swift).
(String, bool) presentForward(PortForwardSession? session) {
  if (session == null) return ('', false);
  return switch (session.lifecycle) {
    ForwardLifecycle.forwardRunning => (S.l.forwardRunning, false),
    ForwardLifecycle.failedConnect => (S.l.forwardFailedConnect, true),
    ForwardLifecycle.failedAuthenticate => (S.l.forwardFailedAuth, true),
    ForwardLifecycle.forwardStopped => (session.lastError ?? S.l.forwardStopped, true),
    _ => ('${session.lifecycle.label[0].toUpperCase()}${session.lifecycle.label.substring(1)}…', false),
  };
}

class _ForwardRow extends StatelessWidget {
  const _ForwardRow({required this.forward, required this.selected, required this.onSelect});
  final PortForward forward;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final router = context.watch<AppRouter>();
    final scheme = Theme.of(context).colorScheme;
    final machine = store.machine(forward.usingMachine);
    final session = router.forwards[forward.id];
    final running = session != null;
    final valid = forward.isValid(machine);
    final (statusText, danger) = presentForward(session);
    void edit() {
      if (!running) showPortForwardEditor(context, forward: forward);
    }

    return GestureDetector(
      onSecondaryTapUp: (d) {
        onSelect();
        runMenu(context, d.globalPosition, [
          menuItem(S.l.edit, Icons.edit_outlined, edit, enabled: !running),
          menuItem(S.l.duplicate, Icons.copy_all_outlined, () => PortForwardActions.duplicate(forward)),
          menuItem(S.l.copyCommand, Icons.code,
              () => copyToClipboard(context, forward.getCommand(machine, machine == null ? null : store.usernameFor(machine)) ?? '', what: S.l.command),
              enabled: valid),
          const PopupMenuDivider(),
          menuItem(S.l.deleteEllipsis, Icons.delete_outline, () => PortForwardActions.delete(context, forward),
              destructive: true, context: context),
        ]);
      },
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSelect,
          onDoubleTap: edit,
          child: SizedBox(
            height: RX.tableRowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: RX.s3),
              child: Row(
                children: [
                  SizedBox(
                    width: _orientation,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text(forward.forwardReversed ? S.l.listenRemote : S.l.listenLocal,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onTertiaryContainer)),
                      ),
                    ),
                  ),
                  SizedBox(width: _bind, child: Text(':${forward.bindPort}', style: RX.code(context, size: 13))),
                  Expanded(
                    child: RedactableText(machine?.name ?? S.l.noServer,
                        redacted: store.machineRedacted == RedactedLevel.all,
                        style: TextStyle(color: machine == null ? scheme.onSurfaceVariant : null)),
                  ),
                  Expanded(
                    child: Text(forward.targetHost.isEmpty ? '—' : '${forward.targetHost}:${forward.targetPort}',
                        overflow: TextOverflow.ellipsis, style: RX.code(context, size: 13)),
                  ),
                  SizedBox(
                    width: _status,
                    child: Row(children: [
                      if (running && !danger && session.lifecycle == ForwardLifecycle.forwardRunning) ...[
                        const StatusDot(size: 7),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: danger ? scheme.error : scheme.onSurfaceVariant)),
                      ),
                    ]),
                  ),
                  SizedBox(
                    width: _toggle,
                    child: Tooltip(
                      message: valid ? (running ? S.l.stop : S.l.start) : S.l.incomplete,
                      child: Switch(
                        value: running,
                        onChanged: !valid
                            ? null
                            : (on) => on ? router.startForward(forward) : router.stopForward(forward.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showPortForwardEditor(BuildContext context, {PortForward? forward}) {
  return showDialog<void>(context: context, barrierDismissible: false, builder: (_) => _ForwardEditor(forward: forward));
}

class _ForwardEditor extends StatefulWidget {
  const _ForwardEditor({this.forward});
  final PortForward? forward;

  @override
  State<_ForwardEditor> createState() => _ForwardEditorState();
}

class _ForwardEditorState extends State<_ForwardEditor> {
  late ForwardOrientation _orientation = widget.forward?.forwardOrientation ?? ForwardOrientation.listenLocal;
  late final _bind = TextEditingController(text: widget.forward == null ? '' : '${widget.forward!.bindPort}');
  late final _host = TextEditingController(text: widget.forward?.targetHost ?? '127.0.0.1');
  late final _port = TextEditingController(text: widget.forward == null ? '' : '${widget.forward!.targetPort}');
  late String? _machine = widget.forward?.usingMachine;

  @override
  void initState() {
    super.initState();
    for (final c in [_bind, _host, _port]) {
      c.addListener(() => setState(() {}));
    }
  }

  static bool _portOk(String s) {
    final v = int.tryParse(s);
    return v != null && v >= 0 && v <= 65535;
  }

  PortForward get _draft => (widget.forward?.copy() ?? PortForward())
    ..forwardOrientation = _orientation
    ..bindPort = int.tryParse(_bind.text) ?? 0
    ..usingMachine = _machine
    ..targetHost = _host.text.trim()
    ..targetPort = int.tryParse(_port.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final draft = _draft;
    final machine = store.machine(_machine);
    final valid = draft.isValid(machine) && _portOk(_bind.text) && _portOk(_port.text);
    final mono = RX.code(context, size: 14);
    final scheme = Theme.of(context).colorScheme;
    final command = draft.getCommand(machine, machine == null ? null : store.usernameFor(machine));

    void save({bool start = false}) {
      store.putPortForward(draft);
      Navigator.pop(context);
      if (start) AppRouter.shared.startForward(draft);
    }

    return SheetDialog(
      title: widget.forward == null ? S.l.newPortForward : S.l.editPortForward,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(S.l.cancel)),
        OutlinedButton(onPressed: valid ? save : null, child: Text(S.l.save)),
        FilledButton(onPressed: valid ? () => save(start: true) : null, child: Text(S.l.saveAndStart)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _orientation == ForwardOrientation.listenLocal ? S.l.localForwardExplain : S.l.remoteForwardExplain,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: RX.s4),
          FieldLabel(
            S.l.orientation,
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ForwardOrientation>(
                segments: [
                  ButtonSegment(value: ForwardOrientation.listenLocal, label: Text(S.l.listenLocal)),
                  ButtonSegment(value: ForwardOrientation.listenRemote, label: Text(S.l.listenRemote)),
                ],
                selected: {_orientation},
                onSelectionChanged: (s) => setState(() => _orientation = s.first),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: FieldLabel(S.l.bindPort,
                    child: TextField(
                      controller: _bind,
                      style: mono,
                      decoration: InputDecoration(
                          hintText: '5433', errorText: _bind.text.isEmpty || _portOk(_bind.text) ? null : S.l.portRange),
                    )),
              ),
              const SizedBox(width: RX.s4),
              Expanded(
                child: FieldLabel(
                  S.l.forwardThrough,
                  child: DropdownButtonFormField<String?>(
                    initialValue: machine == null ? null : _machine,
                    isExpanded: true,
                    hint: Text(S.l.chooseServer),
                    items: [
                      for (final m in store.machines) DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _machine = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FieldLabel(S.l.targetHost,
                    child: TextField(controller: _host, style: mono, decoration: const InputDecoration(hintText: '127.0.0.1'))),
              ),
              const SizedBox(width: RX.s4),
              SizedBox(
                width: 130,
                child: FieldLabel(S.l.targetPort,
                    child: TextField(
                      controller: _port,
                      style: mono,
                      decoration: InputDecoration(
                          hintText: '5432', errorText: _port.text.isEmpty || _portOk(_port.text) ? null : S.l.portRange),
                    )),
              ),
            ],
          ),
          if (command != null) ...[
            const SizedBox(height: 14),
            FieldLabel(
              S.l.equivalentCommand,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: SelectableText(command, style: RX.code(context, size: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
