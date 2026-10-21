// License, agreement and the first-launch "Welcome to catussh" sheet.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/store.dart';
import '../../core/strings.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

enum AboutDocument {
  license('assets/LICENSE'),
  agreement('assets/EULA');

  const AboutDocument(this.asset);
  final String asset;

  String get title => this == AboutDocument.license ? S.l.license : S.l.eula;
}

Widget _documentBox(BuildContext context, AboutDocument document, double height) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    height: height,
    decoration: BoxDecoration(
      border: Border.all(color: scheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: FutureBuilder<String>(
      future: rootBundle.loadString(document.asset).catchError((_) => S.l.textNotLoaded),
      builder: (context, snapshot) => SingleChildScrollView(
        padding: const EdgeInsets.all(RX.s4),
        child: SelectableText(
          snapshot.data ?? '',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    ),
  );
}

Future<void> showDocument(BuildContext context, AboutDocument document) {
  return showDialog<void>(
    context: context,
    builder: (context) => SheetDialog(
      title: document.title,
      width: 640,
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(S.l.done))],
      child: _documentBox(context, document, 360),
    ),
  );
}

Future<void> showAgreement(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _AgreementSheet(),
  );
}

class _AgreementSheet extends StatefulWidget {
  const _AgreementSheet();

  @override
  State<_AgreementSheet> createState() => _AgreementSheetState();
}

class _AgreementSheetState extends State<_AgreementSheet> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SheetDialog(
        title: S.l.welcome,
        width: 600,
        leadingActions: [
          TextButton(onPressed: () => exit(0), child: Text(S.l.quit)),
        ],
        actions: [
          FilledButton(
            onPressed: _agreed
                ? () {
                    CatusshStore.shared.update((s) => s.licenseAgreed = true);
                    Navigator.pop(context);
                  }
                : null,
            child: Text(S.l.continue_),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _documentBox(context, AboutDocument.agreement, 260),
            const SizedBox(height: RX.s3),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _agreed,
              title: Text(S.l.iAgree),
              onChanged: (v) => setState(() => _agreed = v ?? false),
            ),
          ],
        ),
      ),
    );
  }
}
