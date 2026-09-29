import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/add_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/countdown.dart';
import '../../widgets/event_row.dart';

enum TimeFilter { today, week, month, all }

enum KindFilter { all, people, important }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  TimeFilter _time = TimeFilter.all;
  KindFilter _kind = KindFilter.all;
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  Day? _celebrated;

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  bool _matches(Upcoming u, Day today) {
    final timeOk = switch (_time) {
      TimeFilter.today => u.daysLeft == 0,
      TimeFilter.week => u.daysLeft <= 6,
      TimeFilter.month => u.date.year == today.year && u.date.month == today.month,
      TimeFilter.all => true,
    };
    final kindOk = switch (_kind) {
      KindFilter.all => true,
      KindFilter.people => u.entry.kind != EventKind.other,
      KindFilter.important => u.entry.kind == EventKind.other,
    };
    return timeOk && kindOk;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final upcoming = ref.watch(upcomingProvider);
    final today = ref.watch(todayProvider).value ?? Day.today();
    final me = ref.watch(meProvider).value;
    final notices = ref.watch(noticesProvider).value ?? const [];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add',
        onPressed: () => showAddSheet(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: upcoming.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text('Something went wrong: $e')),
              data: (items) {
                final todays = items.where((u) => u.isToday).toList();
                if (todays.isNotEmpty && _celebrated != today) {
                  _celebrated = today;
                  if (!MediaQuery.of(context).disableAnimations) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
                  }
                }
                final hero = items.firstOrNull;
                final list = items.where((u) => _matches(u, today)).toList();
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _Header(name: me?.shortName)),
                    for (final n in notices)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _NoticeCard(
                            message: n.message,
                            onOpen: () {
                              ref.read(repoProvider).markNoticeSeen(n.id);
                              context.push('/person/${n.personId}');
                            },
                            onDismiss: () => ref.read(repoProvider).markNoticeSeen(n.id),
                          ),
                        ),
                      ),
                    if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: EmptyState(
                            title: 'No one here yet',
                            message: 'Add the first person you never want to forget.',
                            actionLabel: 'Pick from contacts',
                            onAction: () => context.push('/person/new?contacts=1'),
                            secondaryLabel: 'Add manually',
                            onSecondary: () => context.push('/person/new'),
                          ),
                        ),
                      )
                    else ...[
                      if (todays.length > 1)
                        SliverToBoxAdapter(child: _TodayBanner(items: todays)),
                      if (hero != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: HeroCard(item: hero),
                          ),
                        ),
                      SliverToBoxAdapter(child: _filters(context)),
                      if (list.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text('Nothing here for this filter.',
                                textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                          sliver: SliverList.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => UpcomingRow(item: list[i]),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              gravity: 0.25,
              colors: [c.gold, const Color(0xFFD4789A), const Color(0xFFE0892E), c.text],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(BuildContext context) {
    Widget chip<T>(String label, T value, T group, ValueChanged<T> set) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(label),
            selected: value == group,
            showCheckmark: false,
            labelStyle: context.text.titleSmall?.copyWith(color: value == group ? context.c.bg : context.c.muted),
            onSelected: (_) => setState(() => set(value)),
          ),
        );
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip('Today', TimeFilter.today, _time, (v) => _time = v),
          chip('This week', TimeFilter.week, _time, (v) => _time = v),
          chip('This month', TimeFilter.month, _time, (v) => _time = v),
          chip('All', TimeFilter.all, _time, (v) => _time = v),
          const SizedBox(width: 10),
          chip('People', KindFilter.people, _kind, (v) => _kind = _kind == v ? KindFilter.all : v),
          chip('Important dates', KindFilter.important, _kind, (v) => _kind = _kind == v ? KindFilter.all : v),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name == null ? part : '$part, $name', style: context.text.bodySmall),
                Text('Smriti', style: context.text.headlineLarge?.copyWith(fontSize: 32)),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search_rounded),
            style: IconButton.styleFrom(side: BorderSide(color: context.c.line)),
          ),
        ],
      ),
    );
  }
}

/// Large card for the next event, with a live countdown.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.item});

  final Upcoming item;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final e = item.entry;
    final phrase = item.yearsPhrase;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card + 4),
        gradient: LinearGradient(
          colors: [c.raised, c.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.7],
        ),
        border: Border.all(color: item.milestone ? c.gold : c.line),
        boxShadow: c.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.card + 4),
          onTap: () => context.push('/event/${e.event.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    EventAvatar(entry: e, size: 68, ring: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              style: context.text.headlineLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (e.kind != EventKind.other) e.relationLine,
                              e.typeLabel,
                              fmtWeekday(item.date),
                            ].join(' · '),
                            style: context.text.bodySmall,
                          ),
                          if (phrase != null) ...[
                            const SizedBox(height: 6),
                            Badge2(item.milestone ? '✦ $phrase!' : phrase),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (item.isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: c.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.gold),
                    ),
                    child: Text(
                      e.type == EventType.birthday ? 'Today! 🎉' : 'Today!',
                      textAlign: TextAlign.center,
                      style: context.text.headlineMedium?.copyWith(color: c.goldText),
                    ),
                  )
                else
                  Countdown(target: item.date),
                const SizedBox(height: 10),
                Text(
                  e.kind == EventKind.other ? relativeDays(item.daysLeft) : 'Call and Share arrive in the next update',
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayBanner extends StatelessWidget {
  const _TodayBanner({required this.items});

  final List<Upcoming> items;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final names = items.map((u) => u.entry.title).join(', ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.gold),
        ),
        child: Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 26, color: c.text)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${items.length} celebrations today', style: context.text.titleMedium),
                  Text(names, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message, required this.onOpen, required this.onDismiss});

  final String message;
  final VoidCallback onOpen, onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: c.gold)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          child: Row(
            children: [
              Icon(Icons.contacts_outlined, size: 18, color: c.goldText),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: context.text.bodyMedium)),
              IconButton(tooltip: 'Dismiss', onPressed: onDismiss, icon: const Icon(Icons.close_rounded, size: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
