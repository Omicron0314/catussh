// Pick one or more servers (ServerPickerPanel in PickerSheets.swift).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'servers_view.dart';

Future<List<String>?> pickServers(
  BuildContext context, {
  required String title,
  required String confirmTitle,
  bool allowsMany = true,
  bool Function(Machine)? filter,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => _ServerPicker(title: title, confirmTitle: confirmTitle, allowsMany: allowsMany, filter: filter),
  );
}

class _ServerPicker extends StatefulWidget {
  const _ServerPicker({required this.title, required this.confirmTitle, required this.allowsMany, this.filter});
  final String title;
  final String confirmTitle;
  final bool allowsMany;
  final bool Function(Machine)? filter;

  @override
  State<_ServerPicker> createState() => _ServerPickerState();
}

class _ServerPickerState extends State<_ServerPicker> {
  final _search = TextEditingController();
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final all = store.machines.where(widget.filter ?? (_) => true).toList();
    final shown = _search.text.isEmpty ? all : all.where((m) => m.isQualifiedForSearch(_search.text)).toList();
    final groups = groupMachines(shown);
    final theme = Theme.of(context);

    return SheetDialog(
      title: widget.title,
      width: 560,
      leadingActions: [
        if (widget.allowsMany)
          TextButton(
            onPressed: () => setState(() {
              if (_selected.length == shown.length) {
                _selected.clear();
              } else {
                _selected.addAll(shown.map((m) => m.id));
              }
            }),
            child: Text(_selected.length == shown.length && shown.isNotEmpty ? 'Deselect All' : 'Select All'),
          ),
      ],
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected.toList()),
          child: Text(widget.confirmTitle),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(controller: _search, hint: 'Search servers'),
          const SizedBox(height: RX.s3),
          if (all.isEmpty)
            const EmptyStateView('No servers yet', icon: Icons.dns_outlined)
          else if (shown.isEmpty)
            const EmptyStateView('No matches', icon: Icons.search)
          else
            for (final (name, machines) in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                child: Text(name.isEmpty ? 'Default' : name,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              for (final m in machines)
                widget.allowsMany
                    ? CheckboxListTile(
                        dense: true,
                        value: _selected.contains(m.id),
                        title: RedactableText(m.name, redacted: store.machineRedacted == RedactedLevel.all),
                        subtitle: RedactableText(m.remoteAddress,
                            redacted: store.machineRedacted != RedactedLevel.none, style: RX.code(context, size: 12)),
                        onChanged: (v) => setState(() => v == true ? _selected.add(m.id) : _selected.remove(m.id)),
                      )
                    : RadioGroup<String>(
                        groupValue: _selected.firstOrNull,
                        onChanged: (v) => setState(() {
                          _selected
                            ..clear()
                            ..add(v!);
                        }),
                        child: RadioListTile<String>(
                          dense: true,
                          value: m.id,
                          title: RedactableText(m.name, redacted: store.machineRedacted == RedactedLevel.all),
                          subtitle: RedactableText(m.remoteAddress,
                              redacted: store.machineRedacted != RedactedLevel.none, style: RX.code(context, size: 12)),
                        ),
                      ),
            ],
        ],
      ),
    );
  }
}
