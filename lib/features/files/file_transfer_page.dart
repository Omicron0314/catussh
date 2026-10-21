// SFTP browser: breadcrumb, filter, file table, transfers, drag and drop
// upload (FileTransferPage.swift, FileTable.swift).

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/strings.dart';
import '../../sessions/file_transfer_session.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../servers/server_actions.dart';

class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key, required this.session});
  final FileTransferSession session;

  @override
  State<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  final _filter = TextEditingController();
  String? _selection;
  String _lastDir = '';
  bool _dropTargeted = false;

  FileTransferSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    _filter.addListener(() => setState(() {}));
  }

  bool get _busy => s.connectionPhase == ConnectionPhase.connecting || s.isProgressRunning;

  RemoteFile? get _selected => s.currentFileList.where((f) => f.name == _selection).firstOrNull;

  Future<void> _report(Future<String?> work) async {
    final error = await work;
    if (error != null && mounted) await presentError(context, error);
  }

  Future<void> _open(RemoteFile file) async {
    if (await s.openIfDirectory(file)) return;
    _edit(file);
  }

  void _edit(RemoteFile file) => AppRouter.shared.openEditorFor(s, path: file.path);

  Future<void> _download(RemoteFile file) async {
    final directory = await getDirectoryPath(confirmButtonText: S.l.downloadHere);
    if (directory == null) return;
    await _report(s.download(file, directory));
  }

  Future<void> _upload() async {
    final files = await openFiles(confirmButtonText: S.l.upload);
    if (files.isEmpty) return;
    await _report(s.upload(files.map((f) => f.path).toList()));
  }

  Future<void> _delete(RemoteFile file) async {
    final ok = await requiresConfirmation(
      context,
      message: S.l.deleteFile(file.name),
      informative: file.isDirectory ? S.l.deleteFolderWarning : S.l.deleteFileWarning,
      confirmTitle: S.l.delete,
      destructive: true,
      always: true,
    );
    if (ok) await _report(s.delete(file));
  }

  static String? _validName(String name) {
    if (name.isEmpty) return S.l.nameRequired;
    if (name.contains('/') || name == '.' || name == '..') return S.l.invalidName;
    return null;
  }

  Future<void> _rename(RemoteFile file) async {
    final name = await promptText(context, title: S.l.rename, initial: file.name, confirmTitle: S.l.rename, validate: _validName);
    if (name != null && name != file.name) await _report(s.rename(file, name));
  }

  Future<void> _newFolder() async {
    final name = await promptText(context,
        title: S.l.newFolder, hint: S.l.untitledFolder, confirmTitle: S.l.create, validate: _validName);
    if (name != null) await _report(s.createFolder(name));
  }

  Future<void> _goTo() async {
    final path = await promptText(
      context,
      title: S.l.goToFolder,
      initial: s.currentDir,
      confirmTitle: S.l.goAction,
      monospace: true,
      validate: (v) => v.startsWith('/') || v.startsWith('~') ? null : S.l.absolutePathRequired,
    );
    if (path != null) await s.navigate(path.startsWith('~') ? path.replaceFirst('~', '.') : path);
  }

  Future<void> _close() async {
    final router = AppRouter.shared;
    final workspace = router.editorFor(s.id);
    final unsaved = workspace?.hasUnsavedChanges ?? false;
    if (unsaved || s.currentProgress != null) {
      final ok = await requiresConfirmation(
        context,
        message: S.l.closeTransfer(s.machine.name),
        informative: unsaved ? S.l.unsavedFilesWarning : S.l.transferRunningWarning,
        confirmTitle: unsaved ? S.l.discardChanges : S.l.close,
        destructive: true,
        always: unsaved,
      );
      if (!ok) return;
    }
    router.closeTransfer(s);
  }

  void _menu(RemoteFile file, Offset position) {
    setState(() => _selection = file.name);
    runMenu(context, position, [
      file.isDirectory
          ? menuItem(S.l.openAction, Icons.folder_open_outlined, () => _open(file))
          : menuItem(S.l.editAction, Icons.edit_note, () => _edit(file)),
      menuItem(S.l.downloadEllipsis, Icons.download, () => _download(file)),
      const PopupMenuDivider(),
      menuItem(S.l.renameEllipsis, Icons.drive_file_rename_outline, () => _rename(file)),
      menuItem(S.l.copyName, Icons.content_copy, () => copyToClipboard(context, file.name, what: S.l.fieldName)),
      menuItem(S.l.copyPath, Icons.link, () => copyToClipboard(context, file.path, what: S.l.pathLabel)),
      const PopupMenuDivider(),
      menuItem(S.l.deleteEllipsis, Icons.delete_outline, () => _delete(file), destructive: true, context: context),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final saved = store.machine(s.machine.id);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        if (_lastDir != s.currentDir) {
          _lastDir = s.currentDir;
          _selection = null;
        }
        final connected = s.connected;
        final enabled = connected && !_busy;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        Widget content;
        if (s.connectionPhase == ConnectionPhase.closed) {
          content = RXCard(
            child: EmptyStateView(S.l.connectionClosed,
                icon: Icons.power_off_outlined,
                message: s.currentHint == S.l.connectionClosed ? null : s.currentHint,
                actionTitle: S.l.reconnect,
                action: s.reconnect),
          );
        } else if (s.connectionPhase != ConnectionPhase.connected && s.currentFileList.isEmpty) {
          content = RXCard(
            child: Padding(
              padding: const EdgeInsets.all(RX.s6),
              child: Column(children: [
                const CircularProgressIndicator(),
                const SizedBox(height: RX.s3),
                Text(s.currentHint.isEmpty ? S.l.connecting : s.currentHint, textAlign: TextAlign.center),
              ]),
            ),
          );
        } else {
          content = Expanded(child: _table(context, enabled));
        }

        final page = PageScaffold(
          scrollable: false,
          center: saved == null ? null : ServerToolSwitcher(machine: saved, current: ServerTool.files),
          leading: Row(children: [
            IconButton(
              tooltip: S.l.enclosingFolder,
              onPressed: enabled && s.currentDir != '/' ? s.goUp : null,
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: S.l.goToFolderShortcut,
              onPressed: enabled ? _goTo : null,
              icon: const Icon(Icons.subdirectory_arrow_right),
            ),
          ]),
          actions: [
            IconButton(tooltip: S.l.reloadShortcut, onPressed: enabled ? s.loadCurrentFileList : null, icon: const Icon(Icons.refresh)),
            IconButton(tooltip: S.l.newFolder, onPressed: enabled ? _newFolder : null, icon: const Icon(Icons.create_new_folder_outlined)),
            IconButton(tooltip: S.l.upload, onPressed: enabled ? _upload : null, icon: const Icon(Icons.upload_file)),
            FilledButton.icon(
              onPressed: enabled && _selected != null ? () => _download(_selected!) : null,
              icon: const Icon(Icons.download),
              label: Text(S.l.download),
            ),
            IconButton(tooltip: S.l.close, onPressed: _close, icon: const Icon(Icons.close)),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(store.machineRedacted == RedactedLevel.all ? S.l.fileTransfer : s.machine.name,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (store.machineRedacted == RedactedLevel.none)
                Text(s.machine.getCommand(store.usernameFor(s.machine), insertLeadingSSH: false),
                    style: RX.code(context, size: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: RX.s3),
              Row(children: [
                Expanded(child: _Breadcrumb(path: s.currentDir, onTap: enabled ? s.navigate : null)),
                const SizedBox(width: RX.s3),
                SizedBox(width: 220, child: SearchField(controller: _filter, hint: S.l.filterThisFolder)),
              ]),
              const SizedBox(height: RX.s3),
              content,
              if (s.currentProgress != null) ...[
                const SizedBox(height: RX.s3),
                _TransferCard(session: s),
              ],
              const SizedBox(height: RX.s4),
            ],
          ),
        );

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () => enabled && s.currentDir != '/' ? s.goUp() : null,
            const SingleActivator(LogicalKeyboardKey.keyG, control: true, shift: true): () => enabled ? _goTo() : null,
            const SingleActivator(LogicalKeyboardKey.keyR, control: true): () => enabled ? s.loadCurrentFileList() : null,
            const SingleActivator(LogicalKeyboardKey.delete): () => _selected != null ? _delete(_selected!) : null,
          },
          child: DropTarget(
            enable: enabled,
            onDragEntered: (_) => setState(() => _dropTargeted = true),
            onDragExited: (_) => setState(() => _dropTargeted = false),
            onDragDone: (details) {
              setState(() => _dropTargeted = false);
              _report(s.upload(details.files.map((f) => f.path).toList()));
            },
            child: Stack(children: [
              Positioned.fill(child: Focus(autofocus: false, child: page)),
              if (_dropTargeted)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.all(RX.s4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        border: Border.all(color: scheme.primary, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.upload_file, color: scheme.primary),
                        const SizedBox(width: RX.s2),
                        Text(S.l.dropToUpload(s.currentDir),
                            style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }

  Widget _table(BuildContext context, bool enabled) {
    final needle = _filter.text.toLowerCase();
    final files = needle.isEmpty ? s.currentFileList : s.currentFileList.where((f) => f.name.toLowerCase().contains(needle)).toList();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]);
    return Card(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _busy ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.all(RX.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 36,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: RX.s3),
                  child: Row(children: [
                    Expanded(child: CapsLabel(S.l.fieldName)),
                    SizedBox(width: 90, child: Align(alignment: Alignment.centerRight, child: CapsLabel(S.l.fileSize))),
                    SizedBox(width: 24),
                    SizedBox(width: 140, child: CapsLabel(S.l.modified)),
                    SizedBox(width: 110, child: CapsLabel(S.l.permissions)),
                    SizedBox(width: 90, child: CapsLabel(S.l.owner)),
                  ]),
                ),
              ),
              const Divider(),
              Expanded(
                child: files.isEmpty
                    ? EmptyStateView(needle.isEmpty ? S.l.emptyFolder : S.l.noMatches, icon: Icons.folder_outlined)
                    : ListView.builder(
                        itemCount: files.length,
                        itemExtent: 36,
                        itemBuilder: (context, i) {
                          final f = files[i];
                          final selected = f.name == _selection;
                          return GestureDetector(
                            onSecondaryTapUp: enabled ? (d) => _menu(f, d.globalPosition) : null,
                            child: Material(
                              color: selected ? scheme.secondaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: enabled ? () => setState(() => _selection = f.name) : null,
                                onDoubleTap: enabled ? () => _open(f) : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: RX.s3),
                                  child: Row(children: [
                                    Icon(
                                      f.isDirectory ? Icons.folder : (f.isLink ? Icons.link : Icons.insert_drive_file_outlined),
                                      size: 18,
                                      color: f.isDirectory ? scheme.primary : scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: RX.s2),
                                    Expanded(child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    SizedBox(
                                      width: 90,
                                      child: Text(f.isDirectory ? '—' : RXFormat.fileSize(f.size), textAlign: TextAlign.right, style: muted),
                                    ),
                                    const SizedBox(width: 24),
                                    SizedBox(width: 140, child: Text(RXFormat.dateTime(f.modified), style: muted)),
                                    SizedBox(width: 110, child: Text(f.permissions ?? '—', style: RX.code(context, size: 12, color: muted?.color))),
                                    SizedBox(width: 90, child: Text(f.owner ?? '—', overflow: TextOverflow.ellipsis, style: muted)),
                                  ]),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.path, required this.onTap});
  final String path;
  final void Function(String path)? onTap;

  @override
  Widget build(BuildContext context) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final scheme = Theme.of(context).colorScheme;
    Widget crumb(String label, String target, {bool last = false}) => TextButton(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: last ? scheme.onSurface : scheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: onTap == null || last ? null : () => onTap!(target),
          child: Text(label, style: RX.code(context, size: 13, weight: last ? FontWeight.w600 : null)),
        );
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(children: [
        crumb('/', '/', last: parts.isEmpty),
        for (final (i, p) in parts.indexed) ...[
          Icon(Icons.chevron_right, size: 16, color: scheme.onSurfaceVariant),
          crumb(p, '/${parts.take(i + 1).join('/')}', last: i == parts.length - 1),
        ],
      ]),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.session});
  final FileTransferSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = session.currentProcessingFile.isEmpty
        ? (session.currentHint.isEmpty ? 'Working…' : session.currentHint)
        : session.currentProcessingFile;
    return RXCard(
      child: Row(children: [
        const Icon(Icons.swap_vert),
        const SizedBox(width: RX.s3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.l.transfer, style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: session.currentProgress, borderRadius: BorderRadius.circular(4)),
          ]),
        ),
        const SizedBox(width: RX.s3),
        if (session.currentProgressCancelable)
          TextButton(onPressed: session.cancelTransfer, child: const Text('Cancel')),
      ]),
    );
  }
}
