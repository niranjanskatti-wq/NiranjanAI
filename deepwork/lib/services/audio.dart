import 'dart:async';
import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';

/// Ambient loops and chimes. The sounds are generated WAV files bundled in assets/sounds,
/// so they play fully offline.
/// Sound can be switched off entirely (used by tests, where no audio plugin exists).
bool soundEnabled = true;

class AmbientPlayer {
  AmbientPlayer._();
  static final instance = AmbientPlayer._();

  AudioPlayer? _player;
  String? current;
  double _volume = 0.5;
  Timer? _fade;

  static double _curve(double v) => math.pow(v.clamp(0, 1), 1.6).toDouble() * 0.9;

  bool get playing => _player?.playing == true;

  Future<void> play(String sound, double volume) async {
    _volume = volume;
    if (!soundEnabled) return;
    if (current == sound && playing) {
      await setVolume(volume);
      return;
    }
    await stop(fadeMs: 200);
    final p = AudioPlayer();
    _player = p;
    current = sound;
    try {
      await p.setAsset('assets/sounds/$sound.wav');
      await p.setLoopMode(LoopMode.one);
      await p.setVolume(0);
      unawaited(p.play());
      _ramp(p, 0, _curve(volume), 800);
    } catch (_) {
      current = null;
    }
  }

  Future<void> setVolume(double v) async {
    _volume = v;
    _fade?.cancel();
    await _player?.setVolume(_curve(v));
  }

  double get volume => _volume;

  void _ramp(AudioPlayer p, double from, double to, int ms, [void Function()? done]) {
    _fade?.cancel();
    const step = 40;
    var t = 0;
    _fade = Timer.periodic(const Duration(milliseconds: step), (timer) {
      t += step;
      final v = from + (to - from) * (t / ms).clamp(0, 1);
      p.setVolume(v);
      if (t >= ms) {
        timer.cancel();
        done?.call();
      }
    });
  }

  Future<void> stop({int fadeMs = 600}) async {
    final p = _player;
    _player = null;
    current = null;
    if (p == null) return;
    final from = p.volume;
    _ramp(p, from, 0, fadeMs, () async {
      await p.stop();
      await p.dispose();
    });
  }
}

/// A soft two-note bell.
Future<void> playChime({bool breakOver = false}) async {
  if (!soundEnabled) return;
  final p = AudioPlayer();
  try {
    await p.setAsset(breakOver ? 'assets/sounds/chime_break.wav' : 'assets/sounds/chime_complete.wav');
    await p.setVolume(0.8);
    await p.play();
  } catch (_) {
    // Audio unavailable — ignore.
  } finally {
    Future.delayed(const Duration(seconds: 4), p.dispose);
  }
}
