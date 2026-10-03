import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../services/lock.dart';
import '../../ui/brand.dart';
import '../focus/focus_controller.dart';

/// Covers the app with a PIN / fingerprint screen when locked. Locks on launch, after the
/// configured inactivity, and when returning to the app after being away that long.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  late bool locked;
  DateTime lastActivity = DateTime.now();
  DateTime? hiddenAt;
  Timer? _timer;

  bool get _active {
    final s = ref.read(settingsProvider);
    return s.b('lock.enabled') && s['lock.pinHash'] != null;
  }

  @override
  void initState() {
    super.initState();
    locked = _active;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final minutes = ref.read(settingsProvider).i('lock.autoLockMinutes');
      final busy = ref.read(focusProvider).inSession || ref.read(focusProvider).phase == FocusPhase.breakTime;
      if (_active && !locked && minutes > 0 && !busy && DateTime.now().difference(lastActivity).inMinutes >= minutes) {
        setState(() => locked = true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      hiddenAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed && hiddenAt != null) {
      final minutes = ref.read(settingsProvider).i('lock.autoLockMinutes');
      if (minutes == 0 || DateTime.now().difference(hiddenAt!).inMinutes >= minutes) setState(() => locked = true);
      hiddenAt = null;
      lastActivity = DateTime.now();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (prev, next) {
      if (!(next.b('lock.enabled') && next['lock.pinHash'] != null) && locked) setState(() => locked = false);
    });
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => lastActivity = DateTime.now(),
      child: Stack(children: [
        ExcludeSemantics(excluding: locked, child: TickerMode(enabled: !locked, child: widget.child)),
        if (locked)
          Positioned.fill(
            child: _LockScreen(onUnlock: () => setState(() {
                  locked = false;
                  lastActivity = DateTime.now();
                })),
          ),
      ]),
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen({required this.onUnlock});
  final VoidCallback onUnlock;
  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> with SingleTickerProviderStateMixin {
  String pin = '';
  bool error = false, checking = false;
  late final AnimationController shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    if (ref.read(settingsProvider).b('lock.biometric')) WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
  }

  @override
  void dispose() {
    shake.dispose();
    super.dispose();
  }

  Future<void> _bio() async {
    if (await LockService.authenticate('Unlock Deepwork')) widget.onUnlock();
  }

  Future<void> _press(String d) async {
    final s = ref.read(settingsProvider);
    final len = s.i('lock.pinLength');
    if (checking || pin.length >= len) return;
    HapticFeedback.selectionClick();
    setState(() => pin += d);
    if (pin.length == len) {
      setState(() => checking = true);
      final ok = await LockService.verifyPin(pin, s['lock.pinSalt'] as String?, s['lock.pinHash'] as String?);
      if (!mounted) return;
      if (ok) {
        widget.onUnlock();
      } else {
        HapticFeedback.heavyImpact();
        setState(() => error = true);
        await shake.forward(from: 0);
        if (!mounted) return;
        setState(() {
          pin = '';
          error = false;
          checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = ref.watch(settingsProvider);
    final len = s.i('lock.pinLength');
    Widget key(Widget child, VoidCallback onTap, {bool subtle = false, String? label}) => Semantics(
          button: true,
          label: label,
          child: InkResponse(
            onTap: onTap,
            radius: 40,
            child: Container(
              width: 74,
              height: 74,
              alignment: Alignment.center,
              decoration: subtle ? null : BoxDecoration(shape: BoxShape.circle, color: p.card, border: Border.all(color: p.border)),
              child: child,
            ),
          ),
        );
    return Material(
      color: p.bg,
      child: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const DeepworkMark(size: 52),
            const SizedBox(height: 20),
            Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_outline_rounded, size: 15, color: p.muted), const SizedBox(width: 6), Text('Enter your PIN', style: TextStyle(color: p.muted))]),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: shake,
              builder: (c, child) => Transform.translate(offset: Offset(math.sin(shake.value * math.pi * 6) * 10 * (1 - shake.value), 0), child: child),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < len; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < pin.length ? (error ? p.danger : p.accent) : Colors.transparent,
                      border: Border.all(color: i < pin.length ? (error ? p.danger : p.accent) : p.border, width: 2),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 40),
            for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final d in row) Padding(padding: const EdgeInsets.symmetric(horizontal: 9), child: key(Text(d, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)), () => _press(d))),
                ]),
              ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: s.b('lock.biometric') ? key(Icon(Icons.fingerprint_rounded, size: 30, color: p.muted), _bio, subtle: true, label: 'Unlock with fingerprint') : const SizedBox(width: 74),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 9), child: key(const Text('0', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)), () => _press('0'))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: key(Icon(Icons.backspace_outlined, color: p.muted), () => setState(() => pin = pin.isEmpty ? pin : pin.substring(0, pin.length - 1)), subtle: true, label: 'Delete'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
