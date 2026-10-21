// Identities: grouped list on the left, editable detail on the right
// (IdentitiesView.swift).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/strings.dart';
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
      title: S.l.identitiesTitle,
      search: _search,
      searchHint: S.l.searchIdentities,
      actions: [
        FilledButton.icon(
          onPressed: () async {
            final created = await showIdentityEditor(context);
            if (created != null) setState(() => _selection = created);
          },
          icon: const Icon(Icons.add),
          label: Text(S.l.newIdentity),
        ),
      ],
      body: store.identities.isEmpty
          ? RXCard(
              child: EmptyStateView(
                S.l.noIdentitiesYet,
                icon: Icons.person_outline,
                message: S.l.identityEmptyMessage,
                actionTitle: S.l.newIdentity,
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
                        if (filtered.isEmpty) EmptyStateView(S.l.noMatches, icon: Icons.search),
                        for (final (name, items) in groups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(RX.s3, RX.s3, RX.s3, RX.s1),
                            child: Text(name.isEmpty ? S.l.defaultGroup : name,
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
                      ? RXCard(child: EmptyStateView(S.l.selectIdentity, icon: Icons.person_outline))
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
      message: S.l.deleteIdentity(identity.username),
      informative: users > 0 ? S.l.identityInUse(users) : S.l.identityRemoved,
      confirmTitle: S.l.delete,
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
        menuItem(S.l.duplicate, Icons.copy_all_outlined, () => IdentityActions.duplicate(identity)),
        menuItem(S.l.copyPublicKey, Icons.content_copy, () => copyToClipboard(context, identity.publicKey, what: S.l.publicKey),
            enabled: identity.publicKey.isNotEmpty),
        const PopupMenuDivider(),
        menuItem(S.l.deleteEllipsis, Icons.delete_outline, () => IdentityActions.delete(context, identity),
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
        title: Text(identity.username.isEmpty ? S.l.noUsername : identity.username),
        subtitle: Text(identity.authDescription),
        trailing: Text(S.l.serversUsingCount(usage), style: theme.textTheme.labelMedium),
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
        ? S.l.notUsedByAnyServer
        : (usedBy.length > 4
            ? S.l.usedByMore(usedBy.take(4).join(', '), usedBy.length - 4)
            : S.l.usedBy(usedBy.join(', ')));
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
                    tooltip: S.l.more,
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      final box = context.findRenderObject() as RenderBox;
                      runMenu(context, box.localToGlobal(box.size.bottomLeft(Offset.zero)), [
                        menuItem(S.l.duplicate, Icons.copy_all_outlined, () => IdentityActions.duplicate(original)),
                        const PopupMenuDivider(),
                        menuItem(S.l.deleteEllipsis, Icons.delete_outline, () => IdentityActions.delete(context, original),
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
                  child: Text(S.l.revert),
                ),
                const SizedBox(width: RX.s2),
                Tooltip(
                  message: S.l.saveShortcut,
                  child: FilledButton(onPressed: dirty && _draft.isValid ? _save : null, child: Text(S.l.save)),
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
      title: S.l.newIdentity,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(S.l.cancel)),
        FilledButton(
          onPressed: !_draft.isValid
              ? null
              : () {
                  final identity = _draft.applyTo(Identity());
                  CatusshStore.shared.putIdentity(identity);
                  Navigator.pop(context, identity.id);
                },
          child: Text(S.l.create),
        ),
      ],
      child: IdentityForm(draft: _draft, onChanged: () => setState(() {})),
    );
  }
}
