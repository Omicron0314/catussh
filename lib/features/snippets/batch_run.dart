// Run <snippet>: one output per server, with progress (BatchRunSheet.swift).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../sessions/batch_exec.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

Future<void> showBatchRun(BuildContext context, Snippet snippet, List<String> machines) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BatchRun(snippet: snippet, machines: machines),
  );
}

class _BatchRun extends StatefulWidget {
  const _BatchRun({required this.snippet, required this.machines});
  final Snippet snippet;
  final List<String> machines;

  @override
  State<_BatchRun> createState() => _BatchRunState();
}

class _BatchRunState extends State<_BatchRun> {
  late final BatchExec _exec = BatchExec(widget.snippet, widget.machines)..addListener(_changed);
  late String? _selection = widget.machines.firstOrNull;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _exec.start();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_exec.finished) setState(() {});
    });
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _tick?.cancel();
    _exec.removeListener(_changed);
    _exec.dispose();
    super.dispose();
  }

  String _duration(MachineRunState state) {
    final Duration d;
    switch (state) {
      case RunWaiting():
        return '';
      case RunRunning(:final since):
        d = DateTime.now().difference(since);
      case RunDone(:final duration) || RunFailed(:final duration):
        d = duration;
    }
    return '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';
  }

  Widget _stateIcon(BuildContext context, MachineRunState state) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      RunWaiting() => const SizedBox(width: 16),
      RunRunning() => const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
      RunDone() => Icon(Icons.check, size: 16, color: scheme.success, semanticLabel: 'Done'),
      RunFailed() => Icon(Icons.close, size: 16, color: scheme.error, semanticLabel: 'Failed'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = widget.machines.length;
    final done = _exec.completedCount;
    final terminalTheme = resolveTerminalTheme(CatusshStore.shared.terminalTheme, scheme);
    return SheetDialog(
      title: 'Run ${widget.snippet.name}',
      width: 880,
      leadingActions: [
        Text('$done of $total finished', style: TextStyle(color: scheme.onSurfaceVariant)),
      ],
      actions: [
        if (!_exec.finished) OutlinedButton(onPressed: _exec.stopAll, child: const Text('Stop')),
        FilledButton(
          onPressed: () async {
            if (_exec.finished) {
              Navigator.pop(context);
              return;
            }
            final ok = await requiresConfirmation(context,
                message: 'Stop running ${widget.snippet.name}?', confirmTitle: 'Stop and Close', destructive: true);
            if (ok && context.mounted) {
              _exec.stopAll();
              Navigator.pop(context);
            }
          },
          child: const Text('Done'),
        ),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 360,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 230,
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(RX.s1),
                    children: [
                      for (final id in widget.machines)
                        ListTile(
                          dense: true,
                          selected: _selection == id,
                          selectedTileColor: scheme.secondaryContainer,
                          onTap: () => setState(() => _selection = id),
                          title: Text(_exec.names[id] ?? 'Unknown server', maxLines: 1, overflow: TextOverflow.ellipsis),
                          leading: _stateIcon(context, _exec.states[id] ?? const RunWaiting()),
                          trailing: Text(_duration(_exec.states[id] ?? const RunWaiting()),
                              style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: RX.s3),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: terminalTheme.background,
                      padding: const EdgeInsets.all(RX.s2),
                      child: IndexedStack(
                        index: _selection == null ? 0 : widget.machines.indexOf(_selection!),
                        children: [
                          for (final id in widget.machines)
                            TerminalView(
                              _exec.outputs[id] ?? Terminal(),
                              theme: terminalTheme,
                              readOnly: true,
                              textStyle: TerminalStyle(
                                fontSize: 13,
                                fontFamily: CatusshStore.shared.terminalFontFamily,
                                fontFamilyFallback: RX.monoFallback,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RX.s3),
          LinearProgressIndicator(value: total == 0 ? 1 : done / total, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}
