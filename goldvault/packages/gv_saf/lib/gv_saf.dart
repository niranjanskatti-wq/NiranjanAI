import 'package:flutter/services.dart';

/// A file the user picked once; GoldVault keeps overwriting it.
class SafTarget {
  final String uri;
  final String? name;
  final bool drive;
  const SafTarget(this.uri, this.name, this.drive);
}

class SafException implements Exception {
  final String code; // no_access / io / no_activity / no_picker / busy
  final String? message;
  SafException(this.code, [this.message]);
  @override
  String toString() => 'SafException($code, $message)';
}

class GvSaf {
  GvSaf._();
  static const _ch = MethodChannel('goldvault/saf');

  /// Opens Android's "Save to" screen. Returns null if the user cancels.
  static Future<SafTarget?> create(String name) async {
    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('create', {'name': name});
      if (m == null) return null;
      return SafTarget(m['uri'] as String, m['name'] as String?, m['drive'] == true);
    } on PlatformException catch (e) {
      throw SafException(e.code, e.message);
    }
  }

  /// Overwrites the picked file with the contents of [path].
  static Future<void> write(String uri, String path) async {
    try {
      await _ch.invokeMethod('write', {'uri': uri, 'path': path});
    } on PlatformException catch (e) {
      throw SafException(e.code, e.message);
    } on MissingPluginException {
      throw SafException('io', 'not available');
    }
  }

  static Future<bool> canWrite(String uri) async {
    try {
      return await _ch.invokeMethod<bool>('canWrite', {'uri': uri}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> release(String uri) async {
    try {
      await _ch.invokeMethod('release', {'uri': uri});
    } catch (_) {}
  }
}
