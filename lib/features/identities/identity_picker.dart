// Choose Identity (IdentityPickerPanel in PickerSheets.swift).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store.dart';
import '../../core/strings.dart';
import '../../ui/widgets.dart';
import 'identities_view.dart';

Future<String?> pickIdentity(BuildContext context) {
  return showDialog<String>(context: context, builder: (_) => const _IdentityPicker());
}

class _IdentityPicker extends StatefulWidget {
  const _IdentityPicker();

  @override
  State<_IdentityPicker> createState() => _IdentityPickerState();
}

class _IdentityPickerState extends State<_IdentityPicker> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    return SheetDialog(
      title: S.l.chooseIdentity,
      width: 480,
      leadingActions: [
        TextButton.icon(
          onPressed: () async {
            final created = await showIdentityEditor(context);
            if (created != null) setState(() => _selected = created);
          },
          icon: const Icon(Icons.add),
          label: Text(S.l.newIdentity),
        ),
      ],
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(S.l.cancel)),
        FilledButton(
          onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
          child: Text(S.l.choose),
        ),
      ],
      child: store.identities.isEmpty
          ? EmptyStateView(S.l.noIdentitiesYet, icon: Icons.person_outline)
          : RadioGroup<String>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              child: Column(
                children: [
                  for (final i in store.identities)
                    RadioListTile<String>(
                      value: i.id,
                      title: Text(i.username),
                      subtitle: Text(i.group.isEmpty ? i.authDescription : '${i.authDescription} · ${i.group}'),
                    ),
                ],
              ),
            ),
    );
  }
}
