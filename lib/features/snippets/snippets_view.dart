// Snippets: tiles with their code, group filter, run on many servers
// (SnippetsView.swift, SnippetEditorSheet.swift).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/strings.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../servers/server_picker.dart';
import 'batch_run.dart';

/// The icons a snippet can wear: the Swift app's SF Symbols, as Material
/// icons under names of their own.
const snippetIcons = <String, IconData>{
  'terminal': Icons.terminal,
  'code': Icons.code,
  'restart': Icons.restart_alt,
  'bolt': Icons.bolt,
  'chart': Icons.bar_chart,
  'clock': Icons.schedule,
  'cpu': Icons.memory,
  'document': Icons.description_outlined,
  'disk': Icons.storage,
  'flame': Icons.local_fire_department_outlined,
  'folder': Icons.folder_outlined,
  'globe': Icons.public,
  'hammer': Icons.handyman_outlined,
  'key': Icons.key,
  'bug': Icons.bug_report_outlined,
  'lock': Icons.lock_outline,
  'search': Icons.search,
  'network': Icons.lan_outlined,
  'power': Icons.power_settings_new,
  'server': Icons.dns_outlined,
  'package': Icons.inventory_2_outlined,
  'trash': Icons.delete_outline,
  'build': Icons.build_outlined,
  'cloud': Icons.cloud_outlined,
  'docker': Icons.directions_boat_outlined,
  'database': Icons.dataset_outlined,
  'update': Icons.system_update_alt,
  'shield': Icons.shield_outlined,
};

IconData snippetIcon(Snippet s) => snippetIcons[s.avatar] ?? Icons.terminal;

class SnippetsView extends StatefulWidget {
  const SnippetsView({super.key});

  @override
  State<SnippetsView> createState() => _SnippetsViewState();
}

class _SnippetsViewState extends State<SnippetsView> {
  final _search = TextEditingController();
  String? _groupFilter;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final groupNames = store.snippets.map((s) => s.group).where((g) => g.isNotEmpty).toSet().toList()..sort();
    if (_groupFilter != null && !groupNames.contains(_groupFilter)) _groupFilter = null;
    var filtered = store.snippets.toList();
    if (_groupFilter != null) filtered = filtered.where((s) => s.group == _groupFilter).toList();
    if (_search.text.isNotEmpty) filtered = filtered.where((s) => s.isQualifiedForSearch(_search.text)).toList();
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    Widget body;
    if (store.snippets.isEmpty) {
      body = RXCard(
        child: EmptyStateView(S.l.noSnippetsYet,
            icon: Icons.code, actionTitle: S.l.newSnippet, action: () => showSnippetEditor(context)),
      );
    } else if (filtered.isEmpty) {
      body = RXCard(child: EmptyStateView(S.l.noMatches, icon: Icons.search));
    } else {
      body = LayoutBuilder(builder: (context, c) {
        final columns = (c.maxWidth / 280).floor().clamp(1, 6);
        final width = (c.maxWidth - RX.s4 * (columns - 1)) / columns;
        return Wrap(
          spacing: RX.s4,
          runSpacing: RX.s4,
          children: [for (final s in filtered) SizedBox(width: width, child: _SnippetTile(snippet: s))],
        );
      });
    }

    return PageScaffold(
      title: S.l.snippetsTitle,
      search: _search,
      searchHint: S.l.searchSnippets,
      leading: groupNames.isEmpty
          ? null
          : Tooltip(
              message: S.l.filterByGroup,
              child: DropdownButton<String?>(
                value: _groupFilter,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(value: null, child: Text(S.l.allGroups)),
                  for (final g in groupNames) DropdownMenuItem(value: g, child: Text(g)),
                ],
                onChanged: (v) => setState(() => _groupFilter = v),
              ),
            ),
      actions: [
        FilledButton.icon(
          onPressed: () => showSnippetEditor(context),
          icon: const Icon(Icons.add),
          label: Text(S.l.newSnippet),
        ),
      ],
      body: SizedBox(width: double.infinity, child: body),
    );
  }
}

class SnippetActions {
  static Future<void> run(BuildContext context, Snippet snippet) async {
    if (snippet.code.trim().isEmpty) {
      await presentError(context, S.l.snippetNoCommand);
      return;
    }
    final machines = await pickServers(context, title: S.l.runName(snippet.name), confirmTitle: S.l.runAction);
    if (machines == null || machines.isEmpty || !context.mounted) return;
    await showBatchRun(context, snippet, machines);
  }

  static void duplicate(Snippet snippet) {
    final copy = snippet.copy()
      ..id = newId()
      ..name = '${snippet.name} copy';
    CatusshStore.shared.putSnippet(copy);
  }

  static Future<void> delete(BuildContext context, Snippet snippet) async {
    final ok = await requiresConfirmation(
      context,
      message: S.l.deleteTitle(snippet.name.isEmpty ? S.l.thisSnippet : snippet.name),
      confirmTitle: S.l.delete,
      destructive: true,
    );
    if (ok) CatusshStore.shared.deleteSnippet(snippet.id);
  }
}

class _SnippetTile extends StatelessWidget {
  const _SnippetTile({required this.snippet});
  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = [snippet.group, snippet.comment].where((s) => s.isNotEmpty).join(' · ');
    void edit() => showSnippetEditor(context, snippet: snippet);

    return Hoverable(
      builder: (context, hovered) => AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: hovered ? 1.01 : 1,
        child: GestureDetector(
          onDoubleTap: edit,
          onSecondaryTapUp: (d) => runMenu(context, d.globalPosition, [
            menuItem(S.l.run, Icons.play_arrow, () => SnippetActions.run(context, snippet)),
            menuItem(S.l.edit, Icons.edit_outlined, edit),
            menuItem(S.l.duplicate, Icons.copy_all_outlined, () => SnippetActions.duplicate(snippet)),
            menuItem(S.l.copyCommand, Icons.content_copy, () => copyToClipboard(context, snippet.code, what: S.l.command)),
            const PopupMenuDivider(),
            menuItem(S.l.deleteEllipsis, Icons.delete_outline, () => SnippetActions.delete(context, snippet),
                destructive: true, context: context),
          ]),
          child: Card(
            elevation: hovered ? 2 : 0,
            child: Padding(
              padding: const EdgeInsets.all(RX.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                        child: Icon(snippetIcon(snippet), size: 20, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: RX.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(snippet.name.isEmpty ? S.l.untitled : snippet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            if (detail.isNotEmpty)
                              Text(detail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () => SnippetActions.run(context, snippet),
                        child: Text(S.l.run),
                      ),
                    ],
                  ),
                  const SizedBox(height: RX.s3),
                  Container(
                    padding: const EdgeInsets.all(RX.s3),
                    decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      snippet.code.trim(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: RX.code(context, size: 12),
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

Future<void> showSnippetEditor(BuildContext context, {Snippet? snippet}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SnippetEditor(snippet: snippet),
  );
}

class _SnippetEditor extends StatefulWidget {
  const _SnippetEditor({this.snippet});
  final Snippet? snippet;

  @override
  State<_SnippetEditor> createState() => _SnippetEditorState();
}

class _SnippetEditorState extends State<_SnippetEditor> {
  late final _draft = widget.snippet?.copy() ?? Snippet();
  late final _name = TextEditingController(text: _draft.name);
  late final _group = TextEditingController(text: _draft.group);
  late final _code = TextEditingController(text: _draft.code);
  late final _comment = TextEditingController(text: _draft.comment);

  bool get _isNew => widget.snippet == null;
  bool get _canSave => _name.text.trim().isNotEmpty || _code.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _code]) {
      c.addListener(() => setState(() {}));
    }
  }

  void _save() {
    _draft
      ..name = _name.text
      ..group = _group.text
      ..code = _code.text
      ..comment = _comment.text;
    CatusshStore.shared.putSnippet(_draft);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final groups = store.snippets.map((s) => s.group).where((g) => g.isNotEmpty).toSet().toList()..sort();
    final scheme = Theme.of(context).colorScheme;
    return SheetDialog(
      title: _isNew ? S.l.newSnippet : S.l.editSnippet,
      width: 600,
      leadingActions: [
        if (!_isNew)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: () async {
              final ok = await requiresConfirmation(context,
                  message: S.l.deleteTitle(_draft.name.isEmpty ? S.l.thisSnippet : _draft.name),
                  confirmTitle: S.l.delete,
                  destructive: true);
              if (ok && context.mounted) {
                store.deleteSnippet(_draft.id);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: Text(S.l.deleteEllipsis),
          ),
      ],
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(S.l.cancel)),
        FilledButton(onPressed: _canSave ? _save : null, child: Text(_isNew ? S.l.create : S.l.save)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(
                S.l.iconLabel,
                child: PopupMenuButton<String>(
                  tooltip: S.l.iconLabel,
                  onSelected: (v) => setState(() => _draft.avatar = v),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      enabled: false,
                      child: SizedBox(
                        width: 280,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final e in snippetIcons.entries)
                              IconButton(
                                isSelected: _draft.avatar == e.key,
                                icon: Icon(e.value),
                                onPressed: () {
                                  setState(() => _draft.avatar = e.key);
                                  Navigator.pop(context);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Icon(snippetIcon(_draft), color: scheme.onPrimaryContainer),
                  ),
                ),
              ),
              const SizedBox(width: RX.s4),
              Expanded(
                child: FieldLabel(S.l.fieldName,
                    child: TextField(
                        controller: _name, autofocus: true, decoration: InputDecoration(hintText: S.l.snippetNameHint))),
              ),
              const SizedBox(width: RX.s4),
              SizedBox(
                width: 180,
                child: FieldLabel(
                  S.l.fieldGroup,
                  child: TextField(
                    controller: _group,
                    decoration: InputDecoration(
                      hintText: S.l.defaultGroup,
                      suffixIcon: groups.isEmpty
                          ? null
                          : PopupMenuButton<String>(
                              icon: const Icon(Icons.expand_more),
                              onSelected: (g) => setState(() => _group.text = g),
                              itemBuilder: (_) => [for (final g in groups) PopupMenuItem(value: g, child: Text(g))],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FieldLabel(
            S.l.command,
            child: TextField(
              controller: _code,
              minLines: 6,
              maxLines: 14,
              style: RX.code(context, size: 13),
              decoration: InputDecoration(hintText: S.l.codeHint),
            ),
          ),
          const SizedBox(height: 14),
          FieldLabel(S.l.fieldComment,
              child: TextField(controller: _comment, decoration: InputDecoration(hintText: S.l.optional))),
        ],
      ),
    );
  }
}
