import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'crypto.dart';

/// Secrets kept in the Android Keystore-backed secure storage.
///
/// * `db_key`     – random SQLCipher key for the local database (per device)
/// * `photo_key`  – random AES key for photo files (travels inside backups)
/// * `pin_*`      – salted PBKDF2 hash of the app PIN
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _s = storage ??
            const FlutterSecureStorage(
              // Never silently wipe keys: that would make the database unreadable.
              aOptions: AndroidOptions(resetOnError: false),
            );

  final FlutterSecureStorage _s;

  Future<String?> read(String k) => _s.read(key: k);
  Future<void> write(String k, String? v) =>
      v == null ? _s.delete(key: k) : _s.write(key: k, value: v);

  Future<String> dbKey() async {
    var k = await read('db_key');
    if (k == null) {
      k = _hex(Crypto.randomBytes(32));
      await write('db_key', k);
    }
    return k;
  }

  Future<Uint8List> photoKey() async {
    var k = await read('photo_key');
    if (k == null) {
      k = base64Encode(Crypto.randomBytes(32));
      await write('photo_key', k);
    }
    return base64Decode(k);
  }

  Future<void> setPhotoKey(Uint8List key) => write('photo_key', base64Encode(key));

  // ------------------------------------------------------------------- PIN

  Future<bool> hasPin() async => (await read('pin_hash')) != null;

  Future<void> setPin(String pin) async {
    final salt = Crypto.randomBytes(16);
    final hash = Crypto.pbkdf2(pin, salt, iterations: 30000);
    await write('pin_salt', base64Encode(salt));
    await write('pin_hash', base64Encode(hash));
  }

  Future<bool> checkPin(String pin) async {
    final salt = await read('pin_salt');
    final hash = await read('pin_hash');
    if (salt == null || hash == null) return false;
    final h = Crypto.pbkdf2(pin, base64Decode(salt), iterations: 30000);
    return Crypto.constantTimeEquals(h, base64Decode(hash));
  }

  Future<bool> biometricEnabled() async => (await read('biometric')) == '1';
  Future<void> setBiometricEnabled(bool v) => write('biometric', v ? '1' : '0');


  static String _hex(List<int> b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}
