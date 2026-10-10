import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/occurrence.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../wish/share_sheet.dart';
import '../wish/wish_buttons.dart';
import '../wish/wish_service.dart';
import 'notification_service.dart';

/// Full-screen midnight alarm: counts the last seconds to 12:00, then celebrates.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key, required this.eventId, this.date, this.payload});

  final int? eventId;
  final String? date;
  final Map<String, dynamic>? payload;

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  Timer? _timer;
  int _left = 0;
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  bool _celebrated = false;

  Day get _day {
    final d = widget.date?.split('-');
    if (d != null && d.length == 3) return Day(int.parse(d[0]), int.parse(d[1]), int.parse(d[2]));
    return Day.today();
  }

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    final left = _day.asDateTime.difference(DateTime.now()).inMilliseconds;
    final secs = left <= 0 ? 0 : (left / 1000).ceil();
    if (secs != _left || !_celebrated) {
      setState(() => _left = secs.clamp(0, 99));
      if (secs == 0 && !_celebrated) {
        _celebrated = true;
        _confetti.play();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    NotificationService.setLockScreen(false);
    super.dispose();
  }

  void _close() {
    NotificationService.setLockScreen(false);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.eventId;
    final entry = id == null ? null : ref.watch(entryProvider(id)).value;
    final u = entry == null ? null : Upcoming(entry, _day, 0);
    final title = entry == null
        ? (widget.payload?['t'] as String? ?? 'Smriti')
        : (u!.years != null && entry.type.name == 'birthday' ? '${entry.title} turns ${u.years}' : entry.title);
    const fg = Color(0xFFF4EFE4), muted = Color(0xFFA8A294), gold = Color(0xFFD6B26E);

    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.4), radius: 1.1, colors: [Color(0xFF2A2418), Color(0xFF121214)]),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(children: [
              Text(
                _celebrated ? "IT'S MIDNIGHT" : 'MIDNIGHT ALARM',
                style: const TextStyle(fontFamily: sans, fontSize: 12, letterSpacing: 2.4, fontWeight: FontWeight.w700, color: muted),
              ),
              const Spacer(),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _celebrated ? 1 : (10 - _left.clamp(0, 10)) / 10,
                      strokeWidth: 3,
                      color: gold,
                      backgroundColor: gold.withValues(alpha: 0.2),
                    ),
                  ),
                  _celebrated
                      ? const Icon(Icons.celebration_rounded, size: 88, color: gold)
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('${_left.clamp(0, 99)}'.padLeft(2, '0'),
                              style: const TextStyle(
                                  fontFamily: sans,
                                  fontSize: 76,
                                  fontWeight: FontWeight.w600,
                                  color: fg,
                                  fontFeatures: [FontFeature.tabularFigures()])),
                          const Text('SECONDS TO MIDNIGHT',
                              style: TextStyle(fontFamily: sans, fontSize: 10, letterSpacing: 2, color: muted)),
                        ]),
                ]),
              ),
              const SizedBox(height: 28),
              if (entry != null) EventAvatar(entry: entry, size: 64, ring: true),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: serif, fontSize: 36, fontWeight: FontWeight.w600, color: fg, height: 1.1)),
              const SizedBox(height: 6),
              Text(
                entry == null ? (widget.payload?['b'] as String? ?? '') : 'Be the first to wish',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: sans, fontSize: 15, color: muted),
              ),
              const Spacer(),
              if (entry != null && canWish(entry))
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5CC08F),
                        side: const BorderSide(color: Color(0xFF5CC08F), width: 1.5),
                        minimumSize: const Size(0, 58),
                      ),
                      onPressed: () async {
                        final t = await targetFor(ref, entry, _day);
                        if (context.mounted) await callTarget(context, ref, t);
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF1A1408),
                        minimumSize: const Size(0, 58),
                      ),
                      onPressed: () async {
                        final t = await targetFor(ref, entry, _day);
                        if (context.mounted) await showShareSheet(context, ref, t);
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send wish'),
                    ),
                  ),
                ]),
              const SizedBox(height: 14),
              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                for (final (label, action) in [('Snooze 10 min', 'snooze10'), ('1 hour', 'snooze60'), ('Morning', 'snoozeMorning')])
                  ActionChip(
                    label: Text(label, style: const TextStyle(color: muted)),
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Color(0xFF34323A)),
                    onPressed: () async {
                      final m = int.tryParse(await ref.read(databaseProvider).getSetting('morningMinute') ?? '') ?? 480;
                      await NotificationService.snooze(
                          widget.payload ?? {'k': 'rem', 'e': id, 't': title, 'b': 'Snoozed reminder', 'a': true},
                          action,
                          morningMinute: m);
                      if (context.mounted) {
                        showToast(context, 'Snoozed');
                        _close();
                      }
                    },
                  ),
                TextButton(onPressed: _close, child: const Text('Dismiss', style: TextStyle(color: gold))),
              ]),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            gravity: 0.2,
            colors: const [gold, Color(0xFFD4789A), Color(0xFFE0892E), fg],
          ),
        ),
      ]),
    );
  }
}
