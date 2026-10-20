// The identity form shared by the detail pane and New Identity
// (IdentityDraft, IdentityForm and KeyField in IdentitiesView.swift).

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

enum AuthMethod { keyPair, password }

class IdentityDraft {
  IdentityDraft();

  IdentityDraft.from(Identity identity)
      : username = identity.username,
        group = identity.group,
        method = identity.privateKey.isEmpty ? AuthMethod.password : AuthMethod.keyPair,
        password = identity.password,
        privateKey = identity.privateKey,
        publicKey = identity.publicKey,
        comment = identity.comment,
        automatic = identity.authenticAutomatically;

  String username = '';
  String group = '';
  AuthMethod method = AuthMethod.password;
  String password = '';
  String privateKey = '';
  String publicKey = '';
  String comment = '';
  bool automatic = true;

  bool get isValid => username.trim().isNotEmpty;

  Identity applyTo(Identity identity) => identity.copy()
    ..username = username.trim()
    ..group = group
    ..password = password
    ..privateKey = method == AuthMethod.keyPair ? privateKey : ''
    ..publicKey = method == AuthMethod.keyPair ? publicKey : ''
    ..comment = comment
    ..authenticAutomatically = automatic;

  bool differsFrom(Identity identity) {
    final e = applyTo(identity);
    return e.username != identity.username ||
        e.group != identity.group ||
        e.password != identity.password ||
        e.privateKey != identity.privateKey ||
        e.publicKey != identity.publicKey ||
        e.comment != identity.comment ||
        e.authenticAutomatically != identity.authenticAutomatically;
  }
}

class IdentityForm extends StatefulWidget {
  const IdentityForm({super.key, required this.draft, required this.onChanged});
  final IdentityDraft draft;
  final VoidCallback onChanged;

  @override
  State<IdentityForm> createState() => _IdentityFormState();
}

class _IdentityFormState extends State<IdentityForm> {
  late final _username = TextEditingController(text: widget.draft.username);
  late final _group = TextEditingController(text: widget.draft.group);
  late final _password = TextEditingController(text: widget.draft.password);
  late final _comment = TextEditingController(text: widget.draft.comment);
  bool _showPassword = false;

  IdentityDraft get d => widget.draft;

  void _set(void Function() change) {
    setState(change);
    widget.onChanged();
  }

  @override
  void didUpdateWidget(IdentityForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft != widget.draft) {
      _username.text = d.username;
      _group.text = d.group;
      _password.text = d.password;
      _comment.text = d.comment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final passwordField = TextField(
      controller: _password,
      obscureText: !_showPassword,
      onChanged: (v) => _set(() => d.password = v),
      decoration: InputDecoration(
        hintText: d.method == AuthMethod.password ? 'Required' : 'None',
        suffixIcon: IconButton(
          tooltip: _showPassword ? 'Hide' : 'Show',
          icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FieldLabel('Username',
                  child: TextField(
                    controller: _username,
                    autocorrect: false,
                    decoration: const InputDecoration(hintText: 'root'),
                    onChanged: (v) => _set(() => d.username = v),
                  )),
            ),
            const SizedBox(width: RX.s4),
            Expanded(
              child: FieldLabel('Group',
                  child: TextField(
                    controller: _group,
                    decoration: const InputDecoration(hintText: 'Default'),
                    onChanged: (v) => _set(() => d.group = v),
                  )),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FieldLabel(
          'Authentication',
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<AuthMethod>(
              segments: const [
                ButtonSegment(value: AuthMethod.keyPair, label: Text('Key pair'), icon: Icon(Icons.key)),
                ButtonSegment(value: AuthMethod.password, label: Text('Password'), icon: Icon(Icons.password)),
              ],
              selected: {d.method},
              onSelectionChanged: (s) => _set(() => d.method = s.first),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (d.method == AuthMethod.keyPair) ...[
          FieldLabel(
            'Private key',
            child: KeyField(
              text: d.privateKey,
              masked: true,
              placeholder: 'No private key loaded',
              loadTitle: 'Load Private Key…',
              matches: (s) => s.contains('PRIVATE KEY'),
              onChanged: (v) => _set(() => d.privateKey = v),
            ),
          ),
          const SizedBox(height: 14),
          FieldLabel(
            'Public key (optional)',
            child: KeyField(
              text: d.publicKey,
              masked: false,
              placeholder: 'No public key loaded',
              loadTitle: 'Load Public Key…',
              matches: _looksLikePublicKey,
              onChanged: (v) => _set(() => d.publicKey = v),
            ),
          ),
          const SizedBox(height: 14),
          FieldLabel('Passphrase', child: passwordField),
        ] else
          FieldLabel('Password', child: passwordField),
        const SizedBox(height: 14),
        FieldLabel('Comment',
            child: TextField(
              controller: _comment,
              decoration: const InputDecoration(hintText: 'Optional'),
              onChanged: (v) => _set(() => d.comment = v),
            )),
        const SizedBox(height: 14),
        const Divider(),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text('Authenticate automatically'),
          subtitle: Text('Required for Quick Connect.', style: TextStyle(color: scheme.onSurfaceVariant)),
          value: d.automatic,
          onChanged: (v) => _set(() => d.automatic = v),
        ),
      ],
    );
  }
}

bool _looksLikePublicKey(String s) {
  const prefixes = ['ssh-rsa', 'ssh-ed25519', 'ecdsa-sha2-', 'sk-ssh-', 'sk-ecdsa-'];
  final t = s.trim();
  return prefixes.any(t.startsWith);
}

class KeyField extends StatelessWidget {
  const KeyField({
    super.key,
    required this.text,
    required this.masked,
    required this.placeholder,
    required this.loadTitle,
    required this.matches,
    required this.onChanged,
  });

  final String text;
  final bool masked;
  final String placeholder;
  final String loadTitle;
  final bool Function(String) matches;
  final ValueChanged<String> onChanged;

  String get _display {
    if (text.isEmpty) return '';
    if (masked) {
      final header = text.split('\n').first;
      return '$header  •••••••• ${text.length} bytes';
    }
    return text.trim();
  }

  Future<void> _load(BuildContext context) async {
    final home = Platform.environment['HOME'];
    final file = await openFile(initialDirectory: home == null ? null : '$home/.ssh');
    if (file == null || !context.mounted) return;
    String content;
    try {
      content = await file.readAsString();
    } catch (_) {
      if (context.mounted) await presentError(context, 'The file could not be read as text.');
      return;
    }
    if (!context.mounted) return;
    if (matches(content)) {
      onChanged(content);
      return;
    }
    final ok = await requiresConfirmation(
      context,
      message: 'This file does not look like a ${masked ? 'private' : 'public'} key',
      informative: 'Load it anyway?',
      confirmTitle: 'Load',
      always: true,
    );
    if (ok) onChanged(content);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text.isEmpty ? placeholder : _display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RX.code(context, size: 12, color: text.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface),
            ),
          ),
        ),
        if (text.isNotEmpty) ...[
          if (!masked)
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.content_copy, size: 18),
              onPressed: () => copyToClipboard(context, text, what: 'Public key'),
            ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () => onChanged(''),
          ),
        ],
        const SizedBox(width: RX.s2),
        OutlinedButton(onPressed: () => _load(context), child: Text(loadTitle)),
      ],
    );
  }
}
