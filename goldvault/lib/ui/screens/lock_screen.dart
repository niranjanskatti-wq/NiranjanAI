import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/security.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 84});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: GV.goldGradient,
          boxShadow: [BoxShadow(color: GV.gold.withValues(alpha: 0.45), blurRadius: 30)],
        ),
        child: Icon(Icons.diamond_outlined, size: size * 0.52, color: const Color(0xFF1A1405)),
      );
}

/// PIN pad used for unlocking and first-time PIN setup.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.lock});
  final AppLock lock;
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  static const pinLength = 4;
  String _pin = '';
  String? _first; // during setup: first entry
  String? _error;
  bool _bioAvailable = false;
  bool _askBio = false;

  bool get _setup => !widget.lock.hasPin;

  @override
  void initState() {
    super.initState();
    ScreenGuard.push();
    _initBio();
  }

  @override
  void dispose() {
    ScreenGuard.pop();
    super.dispose();
  }

  Future<void> _initBio() async {
    _bioAvailable = await widget.lock.biometricAvailable();
    if (mounted) setState(() {});
    if (!_setup && _bioAvailable && mounted) _tryBio();
  }

  Future<void> _tryBio() async {
    await widget.lock.unlockWithBiometrics(context.t('lock.bioReason'));
  }

  Future<void> _tap(String d) async {
    if (_pin.length >= pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == pinLength) await _complete();
  }

  Future<void> _complete() async {
    final pin = _pin;
    if (_setup) {
      if (_first == null) {
        setState(() {
          _first = pin;
          _pin = '';
        });
        return;
      }
      if (_first != pin) {
        HapticFeedback.heavyImpact();
        setState(() {
          _first = null;
          _pin = '';
          _error = context.t('lock.mismatch');
        });
        return;
      }
      if (_bioAvailable) {
        setState(() => _askBio = true);
        return;
      }
      await widget.lock.setPin(pin);
      return;
    }
    final r = await widget.lock.unlockWithPin(pin);
    if (!mounted) return;
    if (r != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _error = r > 0 ? context.t('lock.wait', {'s': r}) : context.t('lock.wrong');
      });
    }
  }

  Future<void> _finishSetup(bool bio) async {
    if (bio) {
      final ok = await widget.lock.confirmBiometrics(context.t('lock.bioReason'));
      await widget.lock.secure.setBiometricEnabled(ok);
    }
    await widget.lock.setPin(_first!);
  }

  @override
  Widget build(BuildContext context) {
    final title = _setup
        ? (_first == null ? context.t('lock.create') : context.t('lock.confirm'))
        : context.t('lock.enter');
    return Scaffold(
      backgroundColor: GV.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.7), radius: 1.2, colors: [Color(0xFF1B2440), GV.bg]),
        ),
        child: SafeArea(
          child: _askBio ? _bioPrompt(context) : _pad(context, title),
        ),
      ),
    );
  }

  Widget _bioPrompt(BuildContext context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.fingerprint, size: 96, color: GV.gold),
          const SizedBox(height: 24),
          Text(context.t('lock.bioAsk'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => _finishSetup(true), child: Text(context.t('lock.bioYes')))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _finishSetup(false), child: Text(context.t('lock.bioNo')))),
        ]),
      );

  Widget _pad(BuildContext context, String title) {
    return LayoutBuilder(builder: (context, box) {
      final keySize = ((box.maxWidth - 120) / 3).clamp(64.0, 92.0);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 24),
            const Logo(),
            const SizedBox(height: 16),
            const Text('GoldVault', style: TextStyle(fontFamily: GV.display, fontSize: 34, color: GV.gold, fontWeight: FontWeight.w700)),
            const SizedBox(height: 28),
            Text(title, style: const TextStyle(fontSize: 19, color: GV.text)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < pinLength; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? GV.gold : Colors.transparent,
                    border: Border.all(color: GV.gold, width: 2),
                  ),
                ),
            ]),
            SizedBox(
              height: 40,
              child: Center(
                child: Text(_error ?? '', style: const TextStyle(color: GV.danger, fontSize: 15.5)),
              ),
            ),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['bio', '0', 'del'],
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final k in row) Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: _key(k, keySize)),
                ]),
              ),
            const SizedBox(height: 24),
          ]),
        ),
      );
    });
  }

  Widget _key(String k, double size) {
    if (k == 'bio') {
      final show = !_setup && _bioAvailable;
      return SizedBox(
        width: size,
        height: size,
        child: show ? IconButton(iconSize: 40, icon: const Icon(Icons.fingerprint, color: GV.gold), onPressed: _tryBio) : null,
      );
    }
    if (k == 'del') {
      return SizedBox(
        width: size,
        height: size,
        child: IconButton(
          iconSize: 32,
          icon: const Icon(Icons.backspace_outlined, color: GV.muted),
          onPressed: _pin.isEmpty ? null : () => setState(() => _pin = _pin.substring(0, _pin.length - 1)),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: GV.surface2,
        shape: const CircleBorder(side: BorderSide(color: GV.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _tap(k),
          child: Center(child: Text(k, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: GV.text))),
        ),
      ),
    );
  }
}
