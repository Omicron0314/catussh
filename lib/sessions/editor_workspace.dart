// The remote file editor of one server: EditorWorkspace and EditorDocument.
// It works over the server's SFTP session, so it shares its id.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:re_editor/re_editor.dart';

import '../core/models.dart';
import 'editor_language.dart';
import 'file_transfer_session.dart';

sealed class DocumentPhase {
  const DocumentPhase();
}

class DocumentLoading extends DocumentPhase {
  const DocumentLoading();
}

class DocumentEditing extends DocumentPhase {
  const DocumentEditing();
}

class DocumentFailed extends DocumentPhase {
  const DocumentFailed(this.message);
  final String message;
}

class EditorDocument extends ChangeNotifier {
  EditorDocument(this.path, this._transfer) {
    controller.addListener(_edited);
    load();
  }

  final String id = newId();
  final String path;
  final FileTransferSession _transfer;
  final CodeLineEditingController controller = CodeLineEditingController();

  DocumentPhase phase = const DocumentLoading();
  bool isEdited = false;
  bool saving = false;
  EditorLanguage language = EditorLanguage.plain;
  String _savedText = '';
  bool _disposed = false;

  String get name => path.split('/').last;
  String get folder => parentRemote(path);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _edited() {
    final edited = controller.text != _savedText;
    if (edited != isEdited) {
      isEdited = edited;
      _notify();
    }
  }

  Future<void> load() async {
    phase = const DocumentLoading();
    _notify();
    try {
      await _waitForConnection();
      final loaded = await _transfer.readText(path);
      _savedText = loaded;
      controller.text = loaded;
      final firstLine = loaded.split('\n').first;
      language = EditorLanguage.detect(name, firstLine);
      isEdited = false;
      phase = const DocumentEditing();
    } catch (error) {
      phase = DocumentFailed('$error');
    }
    _notify();
  }

  /// Returns an error message, or null when it was saved.
  Future<String?> save() async {
    if (phase is! DocumentEditing || !isEdited || saving) return null;
    final snapshot = controller.text;
    saving = true;
    _notify();
    try {
      await _transfer.writeText(path, snapshot);
      _savedText = snapshot;
      isEdited = controller.text != snapshot;
      return null;
    } catch (error) {
      return "Couldn't save $name. $error";
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> _waitForConnection() async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (!_transfer.connected &&
        _transfer.connectionPhase != ConnectionPhase.closed &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!_transfer.connected) throw Exception('The file transfer session is not connected.');
  }

  @override
  void dispose() {
    _disposed = true;
    controller.dispose();
    super.dispose();
  }
}

class EditorWorkspace extends ChangeNotifier {
  EditorWorkspace(this.transfer) : id = transfer.id;

  final FileTransferSession transfer;
  final String id;
  final List<EditorDocument> documents = [];
  String? selection;

  EditorDocument? get current {
    for (final d in documents) {
      if (d.id == selection) return d;
    }
    return null;
  }

  bool get hasUnsavedChanges => documents.any((d) => d.isEdited);

  void open(String path) {
    for (final d in documents) {
      if (d.path == path) {
        selection = d.id;
        notifyListeners();
        return;
      }
    }
    final document = EditorDocument(path, transfer)..addListener(notifyListeners);
    documents.add(document);
    selection = document.id;
    notifyListeners();
  }

  void remove(EditorDocument document) {
    final index = documents.indexOf(document);
    if (index < 0) return;
    documents.removeAt(index);
    document.removeListener(notifyListeners);
    document.dispose();
    if (selection == document.id) {
      selection = documents.isEmpty ? null : documents[index.clamp(0, documents.length - 1)].id;
    }
    notifyListeners();
  }

  void select(EditorDocument document) {
    selection = document.id;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final d in documents) {
      d.removeListener(notifyListeners);
      d.dispose();
    }
    documents.clear();
    super.dispose();
  }
}
