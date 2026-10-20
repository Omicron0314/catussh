// Identities: grouped list on the left, editable detail on the right
// (IdentitiesView.swift).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'identity_form.dart';

class IdentitiesView extends StatefulWidget {
  const IdentitiesView({super.key});

  @override
  State<IdentitiesView> createState() => _IdentitiesViewState();
}

class _IdentitiesViewState extends State<IdentitiesView> {
  final _search = TextEditingController();
  String? _selection;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  List<(String, List<Identity>)> _groups(List<Identity> identities) {
    final names = identities.map((i) => i.group).toSet().toList()
      ..sort((a, b) {
        if (a.isEmpty) return 1;
        if (b.isEmpty) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return [
      for (final n in names) (n, identities.where((i) => i.group == n).toList()..sort((a, b) => a.username.compareTo(b.username))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final key = _search.text.toLowerCase();
    final filtered = key.isEmpty
        ? store.identities
        : store.identities
            .where((i) =>
                i.username.toLowerCase().contains(key) ||
                i.group.toLowerCase().contains(key) ||
                i.comment.toLowerCase().contains(key))
            .toList();
    final groups = _groups(filtered);
    if (_selection == null || store.identity(_selection) == null) {
      _selection = groups.firstOrNull?.$2.firstOrNull?.id;
    }
    final selected = store.identity(_selection);

    return PageScaffold(
      title: 'Identities',
      search: _search,
      searchHint: 'Search identities',
      actions: [
        FilledButton.icon(
          onPressed: () async {
            final created = await showIdentityEditor(context);
            if (created != null) setState(() => _selection = created);
          },
          icon: const Icon(Icons.add),
          label: const Text('New Identity'),
        ),
      ],
      body: store.identities.isEmpty
          ? RXCard(
              child: EmptyStateView(
                'No identities yet',
                icon: Icons.person_outline,
                message: 'A username with a password or key.',
                actionTitle: 'New Identity',
                action: () async {
                  final created = await showIdentityEditor(context);
                  if (created != null) setState(() => _selection = created);
                },
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 320,
                  child: RXCard(
                    padding: const EdgeInsets.all(RX.s2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (filtered.isEmpty) const EmptyStateView('No matches', icon: Icons.search),
                        for (final (name, items) in groups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(RX.s3, RX.s3, RX.s3, RX.s1),
                            child: Text(name.isEmpty ? 'Default' : name,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          ),
                          for (final i in items)
                            _IdentityRow(
                              identity: i,
                              selected: i.id == _selection,
                              onTap: () => setState(() => _selection = i.id),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: RX.s4),
                Expanded(
                  child: selected == null
                      ? const RXCard(child: EmptyStateView('Select an identity', icon: Icons.person_outline))
                      : _IdentityDetail(key: ValueKey(selected.id), identity: selected),
                ),
              ],
            ),
    );
  }
}

class IdentityActions {
  static void duplicate(Identity identity) {
    if (identity.username.isEmpty) return;
    final copy = identity.copy()
      ..id = newId()
      ..comment = identity.comment.isEmpty ? 'Copy' : '${identity.comment} (copy)';
    CatusshStore.shared.putIdentity(copy);
  }

  static Future<void> delete(BuildContext context, Identity identity) async {
    final store = CatusshStore.shared;
    final users = store.machines.where((m) => m.associatedIdentity == identity.id).length;
    final ok = await requiresConfirmation(
      context,
      message: 'Delete identity ${identity.username}?',
      informative: users > 0
          ? '$users server${users == 1 ? '' : 's'} use it and will try automatic identities instead.'
          : 'Its password and keys are removed from catussh.',
      confirmTitle: 'Delete',
      destructive: true,
    );
    if (ok) store.deleteIdentity(identity.id);
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.identity, required this.selected, required this.onTap});
  final Identity identity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final usage = store.machines.where((m) => m.associatedIdentity == identity.id).length;
    return GestureDetector(
      onSecondaryTapUp: (d) => runMenu(context, d.globalPosition, [
        menuItem('Duplicate', Icons.copy_all_outlined, () => IdentityActions.duplicate(identity)),
        menuItem('Copy Public Key', Icons.content_copy, () => copyToClipboard(context, identity.publicKey, what: 'Public key'),
            enabled: identity.publicKey.isNotEmpty),
        const PopupMenuDivider(),
        menuItem('Delete…', Icons.delete_outline, () => IdentityActions.delete(context, identity),
            destructive: true, context: context),
      ]),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.secondaryContainer,
        selectedColor: scheme.onSecondaryContainer,
        onTap: onTap,
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: scheme.primaryContainer,
          child: Icon(identity.privateKey.isNotEmpty ? Icons.key : Icons.password, size: 16, color: scheme.onPrimaryContainer),
        ),
        title: Text(identity.username.isEmpty ? 'No username' : identity.username),
        subtitle: Text(identity.authDescription),
        trailing: Text('$usage server${usage == 1 ? '' : 's'}', style: theme.textTheme.labelMedium),
      ),
    );
  }
}

class _IdentityDetail extends StatefulWidget {
  const _IdentityDetail({super.key, required this.identity});
  final Identity identity;

  @override
  State<_IdentityDetail> createState() => _IdentityDetailState();
}

class _IdentityDetailState extends State<_IdentityDetail> {
  late IdentityDraft _draft = IdentityDraft.from(widget.identity);
  final CatusshStore _store = CatusshStore.shared;

  @override
  void dispose() {
    // Leaving with valid changes saves them, as the Swift app does.
    final original = _store.identity(widget.identity.id);
    if (original != null && _draft.differsFrom(original) && _draft.isValid) {
      _store.putIdentity(_draft.applyTo(original));
    }
    super.dispose();
  }

  void _save() {
    final original = _store.identity(widget.identity.id);
    if (original == null || !_draft.isValid) return;
    _store.putIdentity(_draft.applyTo(original));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final original = store.identity(widget.identity.id) ?? widget.identity;
    final usedBy = store.machines.where((m) => m.associatedIdentity == original.id).map((m) => m.name).toList();
    final usage = usedBy.isEmpty
        ? 'Not used by any server'
        : 'Used by ${usedBy.take(4).join(', ')}${usedBy.length > 4 ? ' and ${usedBy.length - 4} more' : ''}';
    final dirty = _draft.differsFrom(original);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => dirty ? _save() : null},
      child: RXCard(
        padding: const EdgeInsets.all(RX.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(usage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      final box = context.findRenderObject() as RenderBox;
                      runMenu(context, box.localToGlobal(box.size.bottomLeft(Offset.zero)), [
                        menuItem('Duplicate', Icons.copy_all_outlined, () => IdentityActions.duplicate(original)),
                        const PopupMenuDivider(),
                        menuItem('Delete…', Icons.delete_outline, () => IdentityActions.delete(context, original),
                            destructive: true, context: context),
                      ]);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: RX.s4),
            IdentityForm(draft: _draft, onChanged: () => setState(() {})),
            const SizedBox(height: RX.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: dirty ? () => setState(() => _draft = IdentityDraft.from(original)) : null,
                  child: const Text('Revert'),
                ),
                const SizedBox(width: RX.s2),
                Tooltip(
                  message: 'Save (Ctrl+S)',
                  child: FilledButton(onPressed: dirty && _draft.isValid ? _save : null, child: const Text('Save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// New Identity; returns the id of the one created.
Future<String?> showIdentityEditor(BuildContext context) {
  return showDialog<String>(context: context, barrierDismissible: false, builder: (_) => const _IdentityEditor());
}

class _IdentityEditor extends StatefulWidget {
  const _IdentityEditor();

  @override
  State<_IdentityEditor> createState() => _IdentityEditorState();
}

class _IdentityEditorState extends State<_IdentityEditor> {
  final _draft = IdentityDraft();

  @override
  Widget build(BuildContext context) {
    return SheetDialog(
      title: 'New Identity',
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: !_draft.isValid
              ? null
              : () {
                  final identity = _draft.applyTo(Identity());
                  CatusshStore.shared.putIdentity(identity);
                  Navigator.pop(context, identity.id);
                },
          child: const Text('Create'),
        ),
      ],
      child: IdentityForm(draft: _draft, onChanged: () => setState(() {})),
    );
  }
}
