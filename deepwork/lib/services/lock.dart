import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// App lock: salted PBKDF2-SHA256 PIN hashing and the system fingerprint / face prompt.
class LockService {
  static const _iterations = 60000;

  static String newSalt() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<String> hashPin(String pin, String salt) => compute(_pbkdf2, (pin, salt));

  static Future<bool> verifyPin(String pin, String? salt, String? hash) async {
    if (salt == null || hash == null) return false;
    return await hashPin(pin, salt) == hash;
  }

  static final _auth = LocalAuthentication();

  static Future<bool> biometricsAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true, persistAcrossBackgrounding: true);
    } catch (_) {
      return false;
    }
  }
}

String _pbkdf2((String, String) args) {
  final (pin, salt) = args;
  final hmac = Hmac(sha256, utf8.encode(pin));
  final saltBytes = utf8.encode(salt);
  // Single 32-byte block (dkLen == hash length).
  var u = hmac.convert(Uint8List.fromList([...saltBytes, 0, 0, 0, 1])).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < LockService._iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
