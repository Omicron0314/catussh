// Where saved servers and credentials live on disk.
//
// Like the Swift app (AES-encrypted defaults, master key in the Keychain), the
// data file is sealed with AES-256-GCM under a random key that only the
// system keyring holds (libsecret / Secret Service on Linux, the Android
// Keystore on Android). Settings that are not secret stay in plain JSON.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class Vault {
  Vault._(this.directory, this._key, this.problem);

  static const _keyName = 'catussh.masterKey.v1';
  static final _cipher = AesGcm.with256bits();

  final Directory directory;
  final SecretKey? _key;

  /// Why secrets cannot be stored, in a sentence; null when they can. When
  /// set, nothing secret is written: it would replace data the real key can
  /// still read.
  final String? problem;

  File get _dataFile => File('${directory.path}/data.sealed');
  File get _settingsFile => File('${directory.path}/settings.json');
  File get knownHostsFile => File('${directory.path}/known_hosts.json');

  /// [useKeyring] false keeps the key in a file next to the data instead of
  /// the system keyring: for tests and for `CATUSSH_DATA_DIR` development
  /// profiles, never for real data.
  static Future<Vault> open({Directory? directory, bool useKeyring = true}) async {
    final override = Platform.environment['CATUSSH_DATA_DIR'];
    if (directory == null && override != null && override.isNotEmpty) {
      directory = Directory(override);
      useKeyring = false;
    }
    final dir = directory ?? await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    if (!useKeyring) {
      final keyFile = File('${dir.path}/vault.key');
      if (!await keyFile.exists()) await _atomicWrite(keyFile, base64Encode(_randomBytes(32)));
      return Vault._(dir, SecretKey(base64Decode((await keyFile.readAsString()).trim())), null);
    }
    const storage = FlutterSecureStorage();
    try {
      var encoded = await storage.read(key: _keyName);
      if (encoded == null) {
        if (await File('${dir.path}/data.sealed').exists()) {
          return Vault._(dir, null,
              'The key that opens your saved servers is missing from the system keyring.');
        }
        encoded = base64Encode(_randomBytes(32));
        await storage.write(key: _keyName, value: encoded);
      }
      return Vault._(dir, SecretKey(base64Decode(encoded)), null);
    } catch (error) {
      debugPrint('keyring unavailable: $error');
      return Vault._(dir, null,
          'The system keyring (Secret Service) could not be reached, so servers and identities are kept for this run only.');
    }
  }

  static List<int> _randomBytes(int count) {
    final random = Random.secure();
    return List<int>.generate(count, (_) => random.nextInt(256));
  }

  Future<Map<String, Object?>?> readSealed() async {
    final key = _key;
    if (key == null || !await _dataFile.exists()) return null;
    try {
      final envelope = jsonDecode(await _dataFile.readAsString()) as Map<String, Object?>;
      final box = SecretBox(
        base64Decode(envelope['cipher'] as String),
        nonce: base64Decode(envelope['nonce'] as String),
        mac: Mac(base64Decode(envelope['mac'] as String)),
      );
      final plain = await _cipher.decrypt(box, secretKey: key);
      return jsonDecode(utf8.decode(plain)) as Map<String, Object?>;
    } catch (error) {
      debugPrint('sealed data could not be opened: $error');
      return null;
    }
  }

  Future<void> writeSealed(Map<String, Object?> data) async {
    final key = _key;
    if (key == null) return;
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(data)),
      secretKey: key,
    );
    await _atomicWrite(
      _dataFile,
      jsonEncode({
        'version': 1,
        'nonce': base64Encode(box.nonce),
        'cipher': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      }),
    );
  }

  Future<Map<String, Object?>> readSettings() async {
    try {
      if (await _settingsFile.exists()) {
        return jsonDecode(await _settingsFile.readAsString()) as Map<String, Object?>;
      }
    } catch (error) {
      debugPrint('settings could not be read: $error');
    }
    return {};
  }

  Future<void> writeSettings(Map<String, Object?> settings) =>
      _atomicWrite(_settingsFile, const JsonEncoder.withIndent('  ').convert(settings));

  static Future<void> _atomicWrite(File file, String contents) async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(contents, flush: true);
    if (Platform.isLinux) {
      // Owner only: the sealed file is encrypted, but nobody else needs it.
      try {
        await Process.run('chmod', ['600', temp.path]);
      } catch (_) {}
    }
    await temp.rename(file.path);
  }
}
