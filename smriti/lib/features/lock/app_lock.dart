import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../reminders/notification_service.dart';

final appLockProvider =
    StreamProvider<bool>((ref) => ref.watch(databaseProvider).watchSetting('appLock').map((v) => v == 'true'));

/// Fingerprint (or the phone's PIN / pattern) to open Smriti.
class AppLock {
  static final _auth = LocalAuthentication();

  /// True while the system unlock prompt is showing; it briefly pauses the app.
  static bool authenticating = false;

  static Future<bool> available() async {
    if (!NotificationService.supported) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unlock({String reason = 'Unlock Smriti'}) async {
    authenticating = true;
    try {
      return await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    } finally {
      authenticating = false;
    }
  }
}

/// Covers the app until unlocked, when the lock is on. Locks again after
/// Smriti has been in the background for a little while. The midnight alarm
/// screen is never covered.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child, required this.routeChanges, required this.isAlarm});

  final Widget child;
  final Listenable routeChanges;
  final bool Function() isAlarm;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  static const _grace = Duration(seconds: 30);
  bool? _locked;
  DateTime? _leftAt;
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AppLock.authenticating) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final left = _leftAt;
      _leftAt = null;
      if (left != null && DateTime.now().difference(left) > _grace && ref.read(appLockProvider).value == true) {
        setState(() {
          _locked = true;
          _prompted = false;
        });
      }
    }
  }

  Future<void> _unlock() async {
    final ok = await AppLock.unlock();
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(appLockProvider).value;
    if (enabled == null) return ColoredBox(color: context.c.bg);
    // The first value decides whether Smriti opens locked; switching the
    // lock on later (after a successful unlock) doesn't lock straight away.
    _locked ??= enabled;
    if (!enabled) return widget.child;
    return ListenableBuilder(
      listenable: widget.routeChanges,
      builder: (context, _) {
        final covered = _locked! && !widget.isAlarm();
        if (covered && !_prompted) {
          _prompted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
        }
        return Stack(children: [
          widget.child,
          if (covered) Positioned.fill(child: _LockScreen(onUnlock: _unlock)),
        ]);
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.bg,
      child: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.auto_awesome, size: 44, color: c.gold),
            const SizedBox(height: 16),
            Text('Smriti', style: context.text.displaySmall?.copyWith(fontFamily: serif, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Locked', style: context.text.bodyMedium?.copyWith(color: c.muted)),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Unlock'),
            ),
          ]),
        ),
      ),
    );
  }
}
