import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstalledApp {
  const InstalledApp(this.packageName, this.label, this.icon);
  final String packageName;
  final String label;
  final Uint8List? icon;
}

class BlockedAttempt {
  const BlockedAttempt(this.packageName, this.label, this.timestamp);
  final String packageName, label;
  final int timestamp;
}

/// Android-only features implemented in Kotlin (MainActivity.kt). Every call is a safe no-op elsewhere.
class NativeBridge {
  static const _ch = MethodChannel('deepwork/native');
  static bool get available => !kIsWeb && Platform.isAndroid;

  static Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    if (!available) return null;
    try {
      return await _ch.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<bool> blockerEnabled() async {
    final r = await _call<Map>('blockerStatus');
    return r?['serviceEnabled'] == true;
  }

  static Future<void> openBlockerSettings() => _call('openBlockerSettings');
  static Future<void> openAppSettings() => _call('openAppSettings');

  static Future<List<InstalledApp>> installedApps() async {
    final r = await _call<List>('getInstalledApps') ?? const [];
    return [
      for (final e in r)
        InstalledApp(
          (e as Map)['packageName'] as String,
          e['label'] as String,
          (e['icon'] as String?)?.isNotEmpty == true ? base64Decode(e['icon'] as String) : null,
        ),
    ];
  }

  static Future<void> startBlocking({required int until, required String mode, required List<String> packages, required String taskTitle}) =>
      _call('startBlocking', {'until': until, 'mode': mode, 'packages': packages, 'taskTitle': taskTitle});

  static Future<void> stopBlocking() => _call('stopBlocking');

  static Future<List<BlockedAttempt>> takeBlockedAttempts() async {
    final r = await _call<List>('takeBlockedAttempts') ?? const [];
    return [for (final e in r) BlockedAttempt((e as Map)['packageName'] as String, e['label'] as String, (e['timestamp'] as num).toInt())];
  }

  static Future<void> setKeepAwake(bool on) => _call('setKeepAwake', {'on': on});

  static Future<(String, String)> signingInfo() async {
    final r = await _call<Map>('getSigningInfo');
    return ((r?['packageName'] as String?) ?? 'com.niranjan.deepwork', (r?['sha1'] as String?) ?? '');
  }
}
