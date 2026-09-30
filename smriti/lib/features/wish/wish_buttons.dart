import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'share_sheet.dart';
import 'wish_service.dart';

Future<void> _act(BuildContext context, WidgetRef ref, Future<WishTarget> Function() make,
    {required bool share}) async {
  final t = await make();
  if (!context.mounted) return;
  share ? await showShareSheet(context, ref, t) : await callTarget(context, ref, t);
}

/// Whether Call and Share make sense for this event.
bool canWish(EventEntry e) =>
    (e.kind == EventKind.person || e.kind == EventKind.couple) && !e.isMine && e.people.isNotEmpty;

/// Big Call + Share buttons (hero card, event detail).
class CallShareButtons extends ConsumerWidget {
  const CallShareButtons({super.key, required this.entry, required this.date, this.belated = false, this.height = 46});

  final EventEntry entry;
  final Day date;
  final bool belated;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: c.call,
            side: BorderSide(color: c.call, width: 1.4),
            minimumSize: Size(0, height),
          ),
          onPressed: () => _act(context, ref, () => targetFor(ref, entry, date, belated: belated), share: false),
          icon: const Icon(Icons.call_rounded, size: 20),
          label: const Text('Call'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: Size(0, height)),
          onPressed: () => _act(context, ref, () => targetFor(ref, entry, date, belated: belated), share: true),
          icon: const Icon(Icons.send_rounded, size: 20),
          label: Text(belated ? 'Belated wish' : 'Share'),
        ),
      ),
    ]);
  }
}

/// Small round Call and Share icons for list rows.
class MiniCallShare extends ConsumerWidget {
  const MiniCallShare({super.key, required this.entry, required this.date, this.belated = false, this.vertical = false});

  final EventEntry entry;
  final Day date;
  final bool belated;

  /// Stacked, so list rows keep room for the name and age.
  final bool vertical;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    Widget btn(IconData icon, Color color, String tip, VoidCallback onTap) => SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            tooltip: tip,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(side: BorderSide(color: c.line)),
            onPressed: onTap,
            icon: Icon(icon, size: 17, color: color),
          ),
        );
    final children = [
      btn(Icons.call_rounded, c.call, 'Call',
          () => _act(context, ref, () => targetFor(ref, entry, date, belated: belated), share: false)),
      const SizedBox(width: 6, height: 6),
      btn(Icons.send_rounded, c.goldText, 'Share',
          () => _act(context, ref, () => targetFor(ref, entry, date, belated: belated), share: true)),
    ];
    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// Call and Share for a person without a specific event (profile page).
class PersonCallShare extends ConsumerWidget {
  const PersonCallShare({super.key, required this.person, this.next});

  final Person person;
  final Upcoming? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    Future<WishTarget> target() async {
      final n = next;
      if (n != null && canWish(n.entry)) return targetFor(ref, n.entry, n.date);
      return WishTarget(date: Day.today(), recipients: [person], about: person);
    }

    Widget tile(IconData icon, String label, Color fg, Color bg, Color border, VoidCallback onTap) => Expanded(
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(children: [
                  Icon(icon, color: fg),
                  const SizedBox(height: 4),
                  Text(label, style: context.text.labelLarge?.copyWith(color: fg)),
                ]),
              ),
            ),
          ),
        );
    return Row(children: [
      tile(Icons.call_rounded, 'Call', c.call, c.surface, c.line, () => _act(context, ref, target, share: false)),
      const SizedBox(width: 10),
      tile(Icons.send_rounded, 'Share', c.onGold, c.gold, c.gold,
          () => _act(context, ref, target, share: true)),
    ]);
  }
}

/// Floating "Mark X as wished?" chip after a call or share. Never blocks.
class WishedChip extends ConsumerWidget {
  const WishedChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(pendingWishProvider);
    final c = context.c;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: p == null
          ? const SizedBox.shrink()
          : SafeArea(
              key: ValueKey(p.date + p.label),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 84),
                child: Material(
                  color: c.surface,
                  elevation: 6,
                  shadowColor: Colors.black38,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: c.gold)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline, color: c.goldText, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Mark ${p.label} as wished?',
                            style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref.read(repoProvider).markWished(
                              eventId: p.eventId, festivalId: p.festivalId, occasionDate: p.date, personId: p.personId);
                          ref.read(pendingWishProvider.notifier).set(null);
                          if (context.mounted) showToast(context, 'Marked as wished');
                        },
                        child: const Text('Yes'),
                      ),
                      IconButton(
                        tooltip: 'Dismiss',
                        onPressed: () => ref.read(pendingWishProvider.notifier).set(null),
                        icon: Icon(Icons.close_rounded, size: 18, color: c.muted),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Events from the last 7 days not marked as wished.
final missedProvider = Provider<List<Upcoming>>((ref) {
  final entries = ref.watch(entriesProvider).value ?? const <EventEntry>[];
  final wished = ref.watch(wishedKeysProvider);
  // A call or message started from Smriti counts too, even if not confirmed.
  final tried = {
    for (final l in ref.watch(wishLogsProvider).value ?? const <WishLog>[])
      if (l.occasionDate != null && l.eventId != null) '${l.eventId}|${l.occasionDate}',
  };
  final today = ref.watch(todayProvider).value ?? Day.today();
  final out = <Upcoming>[];
  for (final e in entries) {
    if (!canWish(e) || e.isArchived) continue;
    final prev = previousOccurrence(
      repeat: e.repeat,
      month: e.event.month,
      day: e.event.day,
      year: e.repeat == Repeat.once ? e.event.year : e.startYear,
      feb29: e.feb29,
      before: today,
    );
    if (prev == null) continue;
    final ago = prev.daysUntil(today);
    if (ago < 1 || ago > 7) continue;
    if (wished.contains('${e.event.id}|$prev') || tried.contains('${e.event.id}|$prev')) continue;
    out.add(Upcoming(e, prev, -ago));
  }
  out.sort((a, b) => b.date.compareTo(a.date));
  return out;
});
