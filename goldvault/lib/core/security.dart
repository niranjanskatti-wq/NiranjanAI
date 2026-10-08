import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'secure_store.dart';

/// Locks the app on start and after 1 minute in the background.
class AppLock extends ChangeNotifier with WidgetsBindingObserver {
  AppLock(this.secure, {this.timeout = const Duration(minutes: 1)});

  final SecureStore secure;
  final Duration timeout;
  final LocalAuthentication _auth = LocalAuthentication();

  bool _locked = true;
  bool _hasPin = false;
  DateTime? _pausedAt;
  int _failed = 0;
  DateTime? _blockedUntil;

  bool get locked => _locked;
  bool get hasPin => _hasPin;
  DateTime? get blockedUntil => _blockedUntil;

  Future<void> init() async {
    _hasPin = await secure.hasPin();
    _locked = true;
    WidgetsBinding.instance.addObserver(this);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pausedAt ??= DateTime.now();
        break;
      case AppLifecycleState.resumed:
        final p = _pausedAt;
        _pausedAt = null;
        if (p != null && DateTime.now().difference(p) >= timeout && _hasPin) lock();
        break;
      default:
        break;
    }
  }

  void lock() {
    if (_locked) return;
    _locked = true;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await secure.setPin(pin);
    _hasPin = true;
    _locked = false;
    notifyListeners();
  }

  /// Returns null on success, or remaining lock-out seconds / -1 on wrong PIN.
  Future<int?> unlockWithPin(String pin) async {
    final until = _blockedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      return until.difference(DateTime.now()).inSeconds + 1;
    }
    if (await secure.checkPin(pin)) {
      _failed = 0;
      _blockedUntil = null;
      _locked = false;
      notifyListeners();
      return null;
    }
    _failed++;
    if (_failed >= 5) {
      _blockedUntil = DateTime.now().add(Duration(seconds: 30 * (_failed - 4)));
      notifyListeners();
      return 30 * (_failed - 4);
    }
    return -1;
  }

  Future<bool> biometricAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithBiometrics(String reason) async {
    if (!await secure.biometricEnabled()) return false;
    try {
      final ok = await _auth.authenticate(localizedReason: reason, biometricOnly: true);
      if (ok) {
        _failed = 0;
        _locked = false;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Confirm identity (fingerprint, else nothing) before enabling biometrics.
  Future<bool> confirmBiometrics(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } catch (_) {
      return false;
    }
  }
}

/// Toggles Android FLAG_SECURE (blocks screenshots, screen recording and
/// hides the app preview in the recent-apps switcher).
class ScreenGuard {
  ScreenGuard._();
  static const _ch = MethodChannel('goldvault/secure');
  static int _depth = 0;
  static bool _always = false;

  static Future<void> setAlways(bool v) async {
    _always = v;
    await _apply();
  }

  static bool get always => _always;

  static Future<void> _apply() async {
    try {
      await _ch.invokeMethod(_always || _depth > 0 ? 'secure' : 'unsecure');
    } catch (_) {}
  }

  static void push() {
    _depth++;
    _apply();
  }

  static void pop() {
    if (_depth > 0) _depth--;
    _apply();
  }
}

/// Wrap any screen that shows sensitive information.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});
  final Widget child;
  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    ScreenGuard.push();
  }

  @override
  void dispose() {
    ScreenGuard.pop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
