// An SFTP session on one server: the FileTransferContext of the Swift app.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../ssh/connection.dart';

enum ConnectionPhase { idle, connecting, connected, closed }

class RemoteFile {
  RemoteFile({
    required this.directory,
    required this.name,
    required this.isDirectory,
    required this.isLink,
    this.size,
    this.modified,
    this.permissions,
    this.owner,
  });

  final String directory;
  final String name;
  final bool isDirectory;
  final bool isLink;
  final int? size;
  final DateTime? modified;
  final String? permissions;
  final String? owner;

  String get path => joinRemote(directory, name);
}

String joinRemote(String directory, String name) =>
    directory.endsWith('/') ? '$directory$name' : '$directory/$name';

String parentRemote(String path) {
  if (path == '/' || path.isEmpty) return '/';
  final trimmed = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  final index = trimmed.lastIndexOf('/');
  return index <= 0 ? '/' : trimmed.substring(0, index);
}

class FileTransferSession extends ChangeNotifier {
  FileTransferSession(Machine machine)
      : machine = machine.copy(),
        currentDir = machine.fileTransferLoginPath {
    _connect();
  }

  final String id = newId();
  final Machine machine;

  ConnectionPhase connectionPhase = ConnectionPhase.idle;
  String currentDir;
  List<RemoteFile> currentFileList = [];
  bool isProgressRunning = true;
  String currentHint = '';

  /// A transfer in progress: what, how far (0–1), and whether it can stop.
  String currentProcessingFile = '';
  double? currentProgress;
  bool currentProgressCancelable = false;
  bool _cancelTransfer = false;

  SshConnection? _connection;
  SftpClient? _sftp;
  bool _disposed = false;

  bool get connected => connectionPhase == ConnectionPhase.connected;
  SftpClient? get sftp => _sftp;

  /// Lets the editor follow uploads and listings.
  final StreamController<String> _changes = StreamController.broadcast();
  Stream<String> get changes => _changes.stream;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _hint(String text) {
    currentHint = text;
    _notify();
  }

  Future<void> _connect() async {
    connectionPhase = ConnectionPhase.connecting;
    _hint('Connecting...');
    try {
      final connection = await SshConnection.forMachine(machine, hint: _hint);
      if (_disposed) {
        connection.close();
        return;
      }
      _connection = connection;
      CatusshStore.shared.recordConnection(machine.id, banner: connection.banner);
      try {
        _sftp = await connection.client.sftp();
      } catch (_) {
        _hint('Failed to setup file transfer protocol');
        processShutdown();
        return;
      }
      connectionPhase = ConnectionPhase.connected;
      connection.done.whenComplete(() {
        if (connectionPhase == ConnectionPhase.connected) processShutdown();
      });
      await loadCurrentFileList();
    } on ConnectFailure catch (failure) {
      _hint(failure.message);
      processShutdown(keepHint: true);
    } catch (error) {
      _hint('Unable to connect for ${machine.remoteAddress}:${machine.remotePort}');
      processShutdown(keepHint: true);
    }
  }

  void reconnect() {
    if (connectionPhase == ConnectionPhase.connecting) return;
    _connect();
  }

  void processShutdown({bool keepHint = false}) {
    if (!keepHint) currentHint = 'Connection Closed';
    connectionPhase = ConnectionPhase.closed;
    currentFileList = [];
    isProgressRunning = false;
    _sftp?.close();
    _sftp = null;
    _connection?.close();
    _connection = null;
    _notify();
  }

  void close() {
    processShutdown();
    _disposed = true;
    _changes.close();
  }

  // MARK: Browsing

  Future<void> loadCurrentFileList() async {
    final sftp = _sftp;
    if (sftp == null) return;
    final dir = currentDir;
    isProgressRunning = true;
    _hint('Loading... $dir');
    try {
      final names = await sftp.listdir(dir);
      if (currentDir != dir) return;
      currentFileList = [
        for (final n in names)
          if (n.filename != '.' && n.filename != '..') _remoteFile(dir, n),
      ]..sort((a, b) {
          if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      _hint('Load Complete');
    } catch (error) {
      currentFileList = [];
      _hint('Failed to load $dir: ${_describe(error)}');
    }
    isProgressRunning = false;
    _notify();
  }

  RemoteFile _remoteFile(String dir, SftpName name) {
    final attr = name.attr;
    final mode = attr.mode;
    // The long name is `ls -l` output: "drwxr-xr-x 2 root root …".
    final fields = name.longname.split(RegExp(r'\s+'));
    final isLink = mode?.type == SftpFileType.symbolicLink;
    return RemoteFile(
      directory: dir,
      name: name.filename,
      isDirectory: attr.isDirectory,
      isLink: isLink,
      size: attr.size,
      modified: attr.modifyTime == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(attr.modifyTime! * 1000),
      permissions: fields.isNotEmpty && fields.first.length == 10 ? fields.first : null,
      owner: fields.length > 3 ? fields[2] : null,
    );
  }

  Future<void> navigate(String path) async {
    final sftp = _sftp;
    if (sftp == null) return;
    var target = path.trim();
    if (target.isEmpty) return;
    try {
      target = await sftp.absolute(target);
    } catch (_) {}
    currentDir = target;
    _notify();
    await loadCurrentFileList();
  }

  /// Opens a link that points at a folder; returns false for anything else.
  Future<bool> openIfDirectory(RemoteFile file) async {
    if (file.isDirectory) {
      await navigate(file.path);
      return true;
    }
    if (file.isLink) {
      try {
        final attrs = await _sftp!.stat(file.path);
        if (attrs.isDirectory) {
          await navigate(file.path);
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<void> goUp() => navigate(parentRemote(currentDir));

  // MARK: Operations

  Future<String?> _run(String hint, Future<void> Function(SftpClient sftp) work) async {
    final sftp = _sftp;
    if (sftp == null) return 'Not connected';
    _hint(hint);
    try {
      await work(sftp);
      await loadCurrentFileList();
      return null;
    } catch (error) {
      final message = _describe(error);
      _hint(message);
      return message;
    }
  }

  Future<String?> createFolder(String name) =>
      _run('Creating Folder ${joinRemote(currentDir, name)}...', (s) => s.mkdir(joinRemote(currentDir, name)));

  Future<String?> rename(RemoteFile file, String name) =>
      _run('Renaming ${file.name}...', (s) => s.rename(file.path, joinRemote(file.directory, name)));

  Future<String?> delete(RemoteFile file) =>
      _run('Deleting ${file.name}...', (s) => _deleteRecursive(s, file.path, file.isDirectory));

  Future<void> _deleteRecursive(SftpClient sftp, String path, bool isDirectory) async {
    if (!isDirectory) {
      await sftp.remove(path);
      return;
    }
    for (final entry in await sftp.listdir(path)) {
      if (entry.filename == '.' || entry.filename == '..') continue;
      await _deleteRecursive(sftp, joinRemote(path, entry.filename), entry.attr.isDirectory);
    }
    await sftp.rmdir(path);
  }

  void cancelTransfer() {
    _cancelTransfer = true;
  }

  void _beginTransfer(String name) {
    _cancelTransfer = false;
    currentProcessingFile = name;
    currentProgress = 0;
    currentProgressCancelable = true;
    _notify();
  }

  void _endTransfer() {
    currentProcessingFile = '';
    currentProgress = null;
    currentProgressCancelable = false;
    _notify();
  }

  /// Uploads local files and folders into the current folder.
  Future<String?> upload(List<String> localPaths) async {
    final sftp = _sftp;
    if (sftp == null) return 'Not connected';
    final into = currentDir;
    try {
      for (final local in localPaths) {
        if (_cancelTransfer) break;
        await _uploadEntity(sftp, local, into);
      }
      _hint(_cancelTransfer ? 'Upload cancelled' : 'Upload complete');
    } catch (error) {
      _hint('Upload failed: ${_describe(error)}');
      _endTransfer();
      await loadCurrentFileList();
      return _describe(error);
    }
    _endTransfer();
    await loadCurrentFileList();
    return null;
  }

  Future<void> _uploadEntity(SftpClient sftp, String local, String remoteDir) async {
    final name = local.split(Platform.pathSeparator).last;
    final target = joinRemote(remoteDir, name);
    if (await FileSystemEntity.isDirectory(local)) {
      try {
        await sftp.mkdir(target);
      } catch (_) {}
      await for (final child in Directory(local).list()) {
        if (_cancelTransfer) return;
        await _uploadEntity(sftp, child.path, target);
      }
      return;
    }
    final file = File(local);
    final length = await file.length();
    _beginTransfer(name);
    final remote = await sftp.open(
      target,
      mode: SftpFileOpenMode.create | SftpFileOpenMode.truncate | SftpFileOpenMode.write,
    );
    try {
      final stream = file.openRead().takeWhile((_) => !_cancelTransfer).map(Uint8List.fromList);
      await remote.write(stream, onProgress: (sent) {
        currentProgress = length == 0 ? 1 : sent / length;
        _notify();
      }).done;
    } finally {
      await remote.close();
    }
  }

  /// Downloads a file or folder into a local folder.
  Future<String?> download(RemoteFile file, String localDirectory) async {
    final sftp = _sftp;
    if (sftp == null) return 'Not connected';
    try {
      await _downloadEntity(sftp, file.path, file.isDirectory, file.name, localDirectory);
      _hint(_cancelTransfer ? 'Download cancelled' : 'Download complete');
    } catch (error) {
      _hint('Download failed: ${_describe(error)}');
      _endTransfer();
      return _describe(error);
    }
    _endTransfer();
    return null;
  }

  Future<void> _downloadEntity(
    SftpClient sftp,
    String remote,
    bool isDirectory,
    String name,
    String localDirectory,
  ) async {
    final localPath = '$localDirectory${Platform.pathSeparator}$name';
    if (isDirectory) {
      await Directory(localPath).create(recursive: true);
      for (final entry in await sftp.listdir(remote)) {
        if (_cancelTransfer) return;
        if (entry.filename == '.' || entry.filename == '..') continue;
        await _downloadEntity(sftp, joinRemote(remote, entry.filename), entry.attr.isDirectory,
            entry.filename, localPath);
      }
      return;
    }
    _beginTransfer(name);
    final handle = await sftp.open(remote);
    final size = (await handle.stat()).size ?? 0;
    final sink = File(localPath).openWrite();
    try {
      await for (final chunk in handle.read(onProgress: (read) {
        currentProgress = size == 0 ? 1 : read / size;
        _notify();
      })) {
        if (_cancelTransfer) break;
        sink.add(chunk);
      }
    } finally {
      await sink.close();
      await handle.close();
    }
  }

  // MARK: Editing (used by the editor)

  Future<String> readText(String path) async {
    final handle = await _sftp!.open(path);
    try {
      final bytes = await handle.readBytes();
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    } finally {
      await handle.close();
    }
  }

  Future<void> writeText(String path, String text) async {
    final handle = await _sftp!.open(
      path,
      mode: SftpFileOpenMode.create | SftpFileOpenMode.truncate | SftpFileOpenMode.write,
    );
    try {
      await handle.writeBytes(Uint8List.fromList(utf8.encode(text)));
    } finally {
      await handle.close();
    }
    _changes.add(path);
    if (parentRemote(path) == currentDir) await loadCurrentFileList();
  }

  static String _describe(Object error) {
    if (error is SftpStatusError) return error.message;
    return '$error';
  }
}
