// The remote text editor: tabs of open files over the server's SFTP session
// (EditorPage.swift). The editor itself is re_editor, not Runestone.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../../app/router.dart';
import '../../core/store.dart';
import '../../sessions/editor_language.dart';
import '../../sessions/editor_workspace.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../servers/server_actions.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.workspace});
  final EditorWorkspace workspace;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  bool _wrap = false;

  EditorWorkspace get w => widget.workspace;

  Future<void> _openByPath() async {
    final path = await promptText(
      context,
      title: 'Open File',
      initial: '${w.transfer.currentDir == '/' ? '' : w.transfer.currentDir}/',
      hint: '/etc/hosts',
      confirmTitle: 'Open',
      monospace: true,
      validate: (v) => v.startsWith('/') ? null : 'Use an absolute path starting with /.',
    );
    if (path != null) w.open(path);
  }

  Future<void> _save(EditorDocument? doc) async {
    if (doc == null) return;
    final error = await doc.save();
    if (error != null && mounted) await presentError(context, error);
  }

  Future<void> _closeDocument(EditorDocument doc) async {
    if (doc.isEdited) {
      final ok = await requiresConfirmation(
        context,
        message: 'Close ${doc.name} without saving?',
        informative: "Your changes are lost if you don't save them.",
        confirmTitle: 'Discard Changes',
        destructive: true,
        always: true,
      );
      if (!ok) return;
    }
    w.remove(doc);
  }

  Future<void> _reload(EditorDocument doc) async {
    if (doc.isEdited) {
      final ok = await requiresConfirmation(
        context,
        message: 'Reload ${doc.name} from the server?',
        informative: 'Your changes are replaced by the file on the server.',
        confirmTitle: 'Reload from Server',
        destructive: true,
        always: true,
      );
      if (!ok) return;
    }
    doc.load();
  }

  Future<void> _closeEditor() async {
    if (w.hasUnsavedChanges) {
      final ok = await requiresConfirmation(
        context,
        message: 'Close the editor on ${w.transfer.machine.name}?',
        informative: 'Unsaved changes are lost.',
        confirmTitle: 'Discard Changes and Close',
        destructive: true,
        always: true,
      );
      if (!ok) return;
    }
    AppRouter.shared.closeEditor(w);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final saved = store.machine(w.transfer.machine.id);
    return ListenableBuilder(
      listenable: w,
      builder: (context, _) {
        final current = w.current;
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _save(current),
            const SingleActivator(LogicalKeyboardKey.keyO, control: true): _openByPath,
            const SingleActivator(LogicalKeyboardKey.keyW, control: true): () => current == null ? null : _closeDocument(current),
          },
          child: PageScaffold(
            scrollable: false,
            padding: const EdgeInsets.fromLTRB(RX.s6, 0, RX.s6, RX.s4),
            center: saved == null ? null : ServerToolSwitcher(machine: saved, current: ServerTool.editor),
            leading: IconButton(tooltip: 'Open File… (Ctrl+O)', icon: const Icon(Icons.file_open_outlined), onPressed: _openByPath),
            actions: [
              if (current != null) ...[
                Tooltip(
                  message: 'Syntax highlighting',
                  child: DropdownButton<EditorLanguage>(
                    value: current.language,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: [for (final l in EditorLanguage.values) DropdownMenuItem(value: l, child: Text(l.title))],
                    onChanged: (l) {
                      if (l != null) setState(() => current.language = l);
                    },
                  ),
                ),
                IconButton(
                  tooltip: _wrap ? "Don't Wrap Lines" : 'Wrap Lines',
                  isSelected: _wrap,
                  icon: const Icon(Icons.wrap_text),
                  onPressed: () => setState(() => _wrap = !_wrap),
                ),
                IconButton(tooltip: 'Reload', icon: const Icon(Icons.refresh), onPressed: () => _reload(current)),
                FilledButton.icon(
                  onPressed: current.isEdited && !current.saving ? () => _save(current) : null,
                  icon: current.saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(current.saving ? 'Saving…' : 'Save'),
                ),
              ],
              IconButton(tooltip: 'Close Editor', icon: const Icon(Icons.close), onPressed: _closeEditor),
            ],
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (w.documents.isNotEmpty) _Tabs(workspace: w, onClose: _closeDocument),
                const SizedBox(height: RX.s2),
                Expanded(
                  child: current == null
                      ? RXCard(
                          child: Center(
                            child: EmptyStateView(
                              'No file open',
                              icon: Icons.edit_note,
                              message: 'Double-click a text file in Files, or open one by its path.',
                              actionTitle: 'Open File…',
                              action: _openByPath,
                            ),
                          ),
                        )
                      : _DocumentView(key: ValueKey(current.id), document: current, wrap: _wrap),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.workspace, required this.onClose});
  final EditorWorkspace workspace;
  final void Function(EditorDocument) onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final d in workspace.documents)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: d.path,
                waitDuration: const Duration(seconds: 1),
                child: InputChip(
                  selected: d.id == workspace.selection,
                  showCheckmark: false,
                  onPressed: () => workspace.select(d),
                  avatar: d.isEdited ? Icon(Icons.circle, size: 10, color: scheme.primary) : null,
                  label: Text(d.name),
                  deleteButtonTooltipMessage: 'Close ${d.name}',
                  onDeleted: () => onClose(d),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentView extends StatelessWidget {
  const _DocumentView({super.key, required this.document, required this.wrap});
  final EditorDocument document;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: document,
      builder: (context, _) {
        switch (document.phase) {
          case DocumentLoading():
            return RXCard(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: RX.s3),
                  Text('Opening ${document.name}…'),
                ]),
              ),
            );
          case DocumentFailed(:final message):
            return RXCard(
              child: Center(
                child: EmptyStateView("Can't open ${document.name}",
                    icon: Icons.warning_amber_rounded, message: message, actionTitle: 'Try Again', action: document.load),
              ),
            );
          case DocumentEditing():
            final mode = document.language.mode;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CodeEditor(
                      controller: document.controller,
                      wordWrap: wrap,
                      style: CodeEditorStyle(
                        fontSize: CatusshStore.shared.terminalFontSize.toDouble(),
                        fontFamily: CatusshStore.shared.terminalFontFamily,
                        fontFamilyFallback: RX.monoFallback,
                        backgroundColor: scheme.surfaceContainerLowest,
                        textColor: scheme.onSurface,
                        selectionColor: scheme.primary.withValues(alpha: 0.25),
                        cursorColor: scheme.primary,
                        cursorLineColor: scheme.primary.withValues(alpha: 0.06),
                        codeTheme: mode == null
                            ? null
                            : CodeHighlightTheme(
                                languages: {document.language.name: CodeHighlightThemeMode(mode: mode)},
                                theme: dark ? atomOneDarkTheme : atomOneLightTheme,
                              ),
                      ),
                      indicatorBuilder: (context, editingController, chunkController, notifier) => Row(children: [
                        DefaultCodeLineNumber(controller: editingController, notifier: notifier),
                        DefaultCodeChunkIndicator(width: 20, controller: chunkController, notifier: notifier),
                      ]),
                    ),
                  ),
                ),
                _EditorStatus(document: document),
              ],
            );
        }
      },
    );
  }
}

class _EditorStatus extends StatelessWidget {
  const _EditorStatus({required this.document});
  final EditorDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ListenableBuilder(
      listenable: document.controller,
      builder: (context, _) {
        final sel = document.controller.selection;
        return SizedBox(
          height: 30,
          child: Row(children: [
            Expanded(child: Text(document.path, overflow: TextOverflow.ellipsis, style: RX.code(context, size: 11, color: style?.color))),
            if (document.isEdited) Text('Edited    ', style: style),
            Text(document.language.title, style: style),
            const SizedBox(width: RX.s4),
            Text('Ln ${sel.extentIndex + 1}, Col ${sel.extentOffset + 1}', style: style),
          ]),
        );
      },
    );
  }
}
