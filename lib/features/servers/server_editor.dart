// New Server / Edit Server (ServerEditorSheet.swift). "Add and Connect"
// checks the connection first and remembers the identity that signed in.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../ssh/connection.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../identities/identity_picker.dart';

Future<void> showServerEditor(BuildContext context, {Machine? machine}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ServerEditor(machine: machine),
  );
}

class ServerEditor extends StatefulWidget {
  const ServerEditor({super.key, this.machine});
  final Machine? machine;

  @override
  State<ServerEditor> createState() => _ServerEditorState();
}

class _ServerEditorState extends State<ServerEditor> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _port = TextEditingController(text: '22');
  final _group = TextEditingController();
  final _startFolder = TextEditingController(text: '/');
  final _comment = TextEditingController();
  String? _identity;
  bool _connecting = false;
  String? _error;

  bool get _isNew => widget.machine == null;
  bool get _portIsValid {
    final v = int.tryParse(_port.text);
    return v != null && v >= 0 && v <= 65535 && RegExp(r'^\d+$').hasMatch(_port.text);
  }

  bool get _canSave => _address.text.trim().isNotEmpty && _portIsValid;

  @override
  void initState() {
    super.initState();
    final m = widget.machine;
    if (m != null) {
      _name.text = m.name;
      _address.text = m.remoteAddress;
      _port.text = m.remotePort;
      _group.text = m.group;
      _comment.text = m.comment;
      _startFolder.text = m.fileTransferLoginPath;
      _identity = m.associatedIdentity;
    }
    for (final c in [_name, _address, _port]) {
      c.addListener(() => setState(() {}));
    }
  }

  Machine _save({String? banner, String? identity}) {
    final store = context.read<CatusshStore>();
    final target = widget.machine?.copy() ?? Machine(lastConnection: DateTime.fromMillisecondsSinceEpoch(0));
    final address = _address.text.trim();
    target
      ..remoteAddress = address
      ..remotePort = _port.text
      ..name = _name.text.isEmpty ? address : _name.text
      ..group = _group.text
      ..comment = _comment.text
      ..fileTransferLoginPath = _startFolder.text.isEmpty ? '/' : _startFolder.text
      ..associatedIdentity = identity ?? _identity;
    if (banner != null) {
      target
        ..lastBanner = banner
        ..lastConnection = DateTime.now();
    }
    store.putMachine(target);
    return target;
  }

  Future<void> _createAndConnect() async {
    final store = context.read<CatusshStore>();
    setState(() {
      _error = null;
      _connecting = true;
    });
    final host = _address.text.trim();
    final port = int.parse(_port.text);
    final chosen = store.identity(_identity);
    try {
      final connection = await SshConnection.open(host: host, port: port, identity: chosen);
      final banner = connection.banner ?? '';
      final identity = connection.identity.id;
      connection.close();
      if (!mounted) return;
      final created = _save(banner: banner, identity: identity);
      Navigator.pop(context);
      Future<void>.delayed(const Duration(milliseconds: 200), () => AppRouter.shared.openTerminal(created));
    } on ConnectFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = failure.message;
      });
      if (failure.authentication && chosen == null) {
        setState(() => _error = 'No identity that authenticates automatically could sign in. Choose an identity.');
        final picked = await pickIdentity(context);
        if (picked != null && mounted) {
          setState(() => _identity = picked);
          _createAndConnect();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final groups = store.machineGroups;
    final mono = RX.code(context, size: 14);
    return SheetDialog(
      title: _isNew ? 'New Server' : 'Edit Server',
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (_connecting) ...[
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const Text('Connecting…'),
        ],
        if (_isNew) ...[
          Tooltip(
            message: 'Save the server without connecting',
            child: OutlinedButton(
              onPressed: !_canSave || _connecting
                  ? null
                  : () {
                      _save();
                      Navigator.pop(context);
                    },
              child: const Text('Add'),
            ),
          ),
          Tooltip(
            message: 'Check the connection, then save the server',
            child: FilledButton(
              onPressed: !_canSave || _connecting ? null : _createAndConnect,
              child: const Text('Add and Connect'),
            ),
          ),
        ] else
          FilledButton(
            onPressed: !_canSave
                ? null
                : () {
                    _save();
                    Navigator.pop(context);
                  },
            child: const Text('Save'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel('Name',
              child: TextField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(hintText: _address.text.isEmpty ? 'prod-web-01' : _address.text),
              )),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FieldLabel('Address',
                    child: TextField(
                      controller: _address,
                      autocorrect: false,
                      style: mono,
                      decoration: const InputDecoration(hintText: 'Host name or IP address'),
                    )),
              ),
              const SizedBox(width: RX.s4),
              SizedBox(
                width: 110,
                child: FieldLabel('Port',
                    child: TextField(
                      controller: _port,
                      style: mono,
                      decoration: InputDecoration(hintText: '22', errorText: _portIsValid ? null : '1–65535'),
                    )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FieldLabel(
                  'Identity',
                  child: DropdownButtonFormField<String?>(
                    initialValue: store.identity(_identity) == null ? null : _identity,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Automatic')),
                      for (final i in store.identities)
                        DropdownMenuItem(
                          value: i.id,
                          child: Text(i.group.isEmpty ? i.username : '${i.username} · ${i.group}',
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _identity = v),
                  ),
                ),
              ),
              const SizedBox(width: RX.s4),
              Expanded(
                child: FieldLabel(
                  'Group',
                  child: TextField(
                    controller: _group,
                    decoration: InputDecoration(
                      hintText: 'Default',
                      suffixIcon: groups.isEmpty
                          ? null
                          : PopupMenuButton<String>(
                              tooltip: 'Choose an existing group',
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
          FieldLabel('SFTP start folder',
              child: TextField(controller: _startFolder, style: mono, decoration: const InputDecoration(hintText: '/'))),
          const SizedBox(height: 14),
          FieldLabel('Comment', child: TextField(controller: _comment, decoration: const InputDecoration(hintText: 'Optional'))),
          if (!_isNew) ...[
            const SizedBox(height: 14),
            FieldLabel(
              'Last banner',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  widget.machine!.lastBanner.isEmpty ? 'None' : widget.machine!.lastBanner,
                  style: RX.code(context, size: 12),
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
