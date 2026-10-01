import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../contacts/duplicates.dart';
import '../contacts/duplicates_screen.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/enums.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/add_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/countdown.dart';
import '../../widgets/event_row.dart';
import '../reminders/notification_service.dart';
import '../festivals/festival_model.dart';
import '../festivals/festival_route.dart';
import '../wish/wish_buttons.dart';
import '../wishmode/wish_mode_repo.dart';

enum TimeFilter { today, week, month, all }

enum KindFilter { all, people, festivals, important }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  bool _notifOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotif();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _checkNotif();
  }

  Future<void> _checkNotif() async {
    final on = await NotificationService.notificationsEnabled();
    if (mounted && on == _notifOff) setState(() => _notifOff = !on);
  }

  TimeFilter _time = TimeFilter.all;
  KindFilter _kind = KindFilter.all;
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  Day? _celebrated;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confetti.dispose();
    super.dispose();
  }

  bool _matches(Upcoming u, Day today) {
    // A chip for something that is now hidden falls back to showing everything.
    if ((_kind == KindFilter.festivals && ref.read(showFestivalsProvider).value == false) ||
        (_kind == KindFilter.important && ref.read(showImportantProvider).value == false)) {
      _kind = KindFilter.all;
    }
    final timeOk = switch (_time) {
      TimeFilter.today => u.daysLeft == 0,
      TimeFilter.week => u.daysLeft <= 6,
      TimeFilter.month => u.date.year == today.year && u.date.month == today.month,
      TimeFilter.all => true,
    };
    final kindOk = switch (_kind) {
      KindFilter.all => true,
      KindFilter.people => u.entry.kind == EventKind.person || u.entry.kind == EventKind.couple,
      KindFilter.festivals => u.entry.kind == EventKind.festival,
      KindFilter.important => u.entry.kind == EventKind.other,
    };
    return timeOk && kindOk;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final all = ref.watch(entriesProvider).whenData((_) => ref.watch(visibleEntriesProvider));
    final upcoming = all.whenData((list) => computeUpcoming(list, ref.watch(todayProvider).value ?? Day.today()));
    final sessions = ref.watch(openSessionsProvider).value ?? const [];
    final today = ref.watch(todayProvider).value ?? Day.today();
    final me = ref.watch(meProvider).value;
    final notices = ref.watch(noticesProvider).value ?? const [];
    final dupCount = ref.watch(duplicateCountProvider);
    final dupSeen = ref.watch(dupNoticeSeenProvider).value;
    final missed = (ref.watch(showMissedProvider).value ?? true) ? ref.watch(missedProvider) : const <Upcoming>[];

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
                final heroSize = ref.watch(heroSizeProvider).value ?? HeroSize.big;
                void setHero(HeroSize v) => ref.read(databaseProvider).setSetting('homeHero', v.name);
                final list = items.where((u) => _matches(u, today)).toList();
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _Header(name: me?.shortName)),
                    if (_notifOff && items.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _NoticeCard(
                            message: 'Reminders are off. Tap to turn on notifications so you never miss a day.',
                            onOpen: () async {
                              await NotificationService.requestNotifications();
                              _checkNotif();
                            },
                            onDismiss: () => setState(() => _notifOff = false),
                          ),
                        ),
                      ),
                    if (dupCount > 0 && dupSeen != '$dupCount')
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _NoticeCard(
                            message: dupCount == 1
                                ? '1 thing to check: the same person may be saved twice (same date or number). Tap to review and merge.'
                                : '$dupCount things to check: people who may be saved twice (same date or number). Tap to review and merge.',
                            onOpen: () => context.push('/duplicates'),
                            onDismiss: () => ref.read(databaseProvider).setSetting('dupNoticeSeen', '$dupCount'),
                          ),
                        ),
                      ),
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
                    if (items.every((u) => u.entry.kind == EventKind.festival))
                      SliverToBoxAdapter(
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
                      ),
                    if (items.isNotEmpty) ...[
                      if (todays.any((u) => u.entry.isMine && u.entry.type == EventType.birthday))
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: _NoticeCard(
                              message: "It's your birthday! 🎉 Tap for ready thank-you replies to everyone who wished you.",
                              onOpen: () => context.push('/thank-you'),
                              onDismiss: () {},
                            ),
                          ),
                        ),
                      for (final s in sessions)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _NoticeCard(
                              message: 'Continue ${s.session.title}: ${s.done} of ${s.total} done',
                              onOpen: () => context.push('/wish-mode/${s.session.id}'),
                              onDismiss: () => WishModeRepo(ref.read(databaseProvider)).finish(s.session.id),
                            ),
                          ),
                        ),
                      if (todays.length > 1)
                        SliverToBoxAdapter(child: _TodayBanner(items: todays)),
                      if (hero != null && heroSize != HeroSize.hidden)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: heroSize == HeroSize.big
                                ? HeroCard(item: hero, onResize: () => setHero(HeroSize.small))
                                : _SmallHero(item: hero, onResize: () => setHero(HeroSize.big)),
                          ),
                        ),
                      if (missed.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SectionLabel(
                              'Missed this week',
                              trailing: TextButton(
                                onPressed: () async {
                                  await ref.read(databaseProvider).setSetting('showMissed', 'false');
                                  if (context.mounted) {
                                    showToast(context, 'Missed list hidden. Turn it back on with the filter button above.');
                                  }
                                },
                                child: const Text('Hide'),
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList.separated(
                            itemCount: missed.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => UpcomingRow(item: missed[i], belated: true),
                          ),
                        ),
                      ],
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
          if (ref.watch(showFestivalsProvider).value ?? true)
            chip('Festivals', KindFilter.festivals, _kind, (v) => _kind = _kind == v ? KindFilter.all : v),
          if (ref.watch(showImportantProvider).value ?? true)
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
          const ShowButton(),
          const SizedBox(width: 8),
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

/// How many possible duplicates there are, for a one-time note on Home.
final duplicateCountProvider = Provider<int>((ref) {
  final entries = ref.watch(entriesProvider).value ?? const <EventEntry>[];
  final people = ref.watch(peopleProvider).value ?? const <Person>[];
  return Duplicates.sameDay(entries).length +
      Duplicates.people(people, entries).length +
      ref.watch(coupleSuggestionsProvider).length +
      ref.watch(sameDateGroupsProvider).length;
});

final dupNoticeSeenProvider =
    StreamProvider<String?>((ref) => ref.watch(databaseProvider).watchSetting('dupNoticeSeen'));

/// Whether Home shows "Missed this week".
final showMissedProvider =
    StreamProvider<bool>((ref) => ref.watch(databaseProvider).watchSetting('showMissed').map((v) => v != 'false'));

/// "What to show" button on Home: switch festivals and other dates on or off.
class ShowButton extends ConsumerWidget {
  const ShowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final festivals = ref.watch(showFestivalsProvider).value ?? true;
    final important = ref.watch(showImportantProvider).value ?? true;
    final missed = ref.watch(showMissedProvider).value ?? true;
    final filtered = !festivals || !important || !missed;
    return Badge(
      isLabelVisible: filtered,
      backgroundColor: c.gold,
      smallSize: 9,
      child: IconButton.outlined(
        tooltip: 'What to show',
        onPressed: () => showWhatToShow(context),
        icon: Icon(filtered ? Icons.filter_alt_rounded : Icons.tune_rounded),
        style: IconButton.styleFrom(side: BorderSide(color: filtered ? c.gold : c.line)),
      ),
    );
  }
}

/// Sheet with the "show festivals / other dates" switches.
Future<void> showWhatToShow(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _WhatToShowSheet(),
    );

class _WhatToShowSheet extends ConsumerWidget {
  const _WhatToShowSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final db = ref.read(databaseProvider);
    final festivals = ref.watch(showFestivalsProvider).value ?? true;
    final important = ref.watch(showImportantProvider).value ?? true;
    final missed = ref.watch(showMissedProvider).value ?? true;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('What to show', style: context.text.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('Birthdays and anniversaries always show. Turn off the rest to see only your people.',
                style: context.text.bodySmall),
          ),
          SwitchListTile(
            secondary: Icon(Icons.temple_hindu_rounded, color: groupColor(EventGroup.festival)),
            title: const Text('Festivals & holidays'),
            subtitle: const Text('Diwali, Ugadi, Christmas…'),
            value: festivals,
            onChanged: (v) => db.setSetting('showFestivals', '$v'),
          ),
          SwitchListTile(
            secondary: Icon(Icons.receipt_long_outlined, color: groupColor(EventGroup.important)),
            title: const Text('Bills, renewals & other dates'),
            subtitle: const Text('Insurance, passport, rent…'),
            value: important,
            onChanged: (v) => db.setSetting('showImportant', '$v'),
          ),
          SwitchListTile(
            secondary: Icon(Icons.history_rounded, color: c.muted),
            title: const Text('Missed this week'),
            subtitle: const Text('Dates from the last 7 days not yet wished'),
            value: missed,
            onChanged: (v) => db.setSetting('showMissed', '$v'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'This changes Home, Calendar and the widget. Reminders are not changed: '
              'festival reminders are in Settings › Festivals.',
              style: context.text.bodySmall?.copyWith(color: c.muted),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Large card for the next event, with a live countdown.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.item, this.onResize});

  final Upcoming item;

  /// Shows a small button to shrink the card.
  final VoidCallback? onResize;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final e = item.entry;
    final phrase = item.yearsPhrase;
    final festival = e.kind == EventKind.festival;
    final saffron = groupColor(EventGroup.festival);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card + 4),
        gradient: LinearGradient(
          colors: festival
              ? [Color.alphaBlend(saffron.withValues(alpha: 0.18), c.raised), c.surface]
              : [c.raised, c.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.7],
        ),
        border: Border.all(color: festival ? saffron.withValues(alpha: 0.6) : (item.milestone ? c.gold : c.line)),
        boxShadow: c.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.card + 4),
          onTap: () => openEntry(context, e),
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
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              child: Text(e.title,
                                  style: context.text.headlineLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                            if (onResize != null)
                              IconButton(
                                tooltip: 'Make smaller',
                                visualDensity: VisualDensity.compact,
                                onPressed: onResize,
                                icon: Icon(Icons.unfold_less_rounded, color: c.muted),
                              ),
                          ]),
                          const SizedBox(height: 6),
                          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            KindPill(entry: e, large: true),
                            if (phrase != null) Badge2(item.milestone ? '$phrase!' : phrase, sparkle: item.milestone),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            [
                              if (e.kind == EventKind.person || e.kind == EventKind.couple) e.relationLine,
                              fmtWeekday(item.date),
                            ].where((t) => t.isNotEmpty).join(' · '),
                            style: context.text.bodySmall,
                          ),
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
                const SizedBox(height: 12),
                if (canWish(e))
                  CallShareButtons(entry: e, date: item.date)
                else if (e is FestivalEntry)
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/wish-mode/new?festival=${Uri.encodeQueryComponent(e.festival.key)}'),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text('Start Wish Mode · ${relativeDays(item.daysLeft)}'),
                  )
                else
                  Text(relativeDays(item.daysLeft), textAlign: TextAlign.center, style: context.text.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The top card made small: one line with the next date and its countdown.
class _SmallHero extends StatelessWidget {
  const _SmallHero({required this.item, required this.onResize});

  final Upcoming item;
  final VoidCallback onResize;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final e = item.entry;
    final phrase = item.yearsPhrase;
    return Material(
      color: c.raised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: item.milestone || item.isToday ? c.gold : c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openEntry(context, e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(children: [
            EventAvatar(entry: e, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NEXT UP', style: context.text.labelSmall?.copyWith(color: c.goldText, letterSpacing: 1.5)),
                Text(e.title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text([?phrase, fmtWeekday(item.date)].join(' · '),
                    style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Text(item.isToday ? 'Today 🎉' : relativeDays(item.daysLeft),
                style: context.text.titleSmall?.copyWith(color: c.goldText, fontWeight: FontWeight.w800)),
            IconButton(
              tooltip: 'Make bigger',
              onPressed: onResize,
              icon: Icon(Icons.unfold_more_rounded, color: c.muted),
            ),
          ]),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.gold),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text('🎉', style: TextStyle(fontSize: 24, color: c.text)),
              const SizedBox(width: 10),
              Text('${items.length} celebrations today', style: context.text.titleLarge),
            ]),
            const SizedBox(height: 6),
            for (final u in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  EventAvatar(entry: u.entry, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${u.entry.title} · ${u.entry.typeLabel}',
                        style: context.text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (canWish(u.entry)) MiniCallShare(entry: u.entry, date: u.date),
                ]),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push('/wish-mode/new'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Start Wish Mode'),
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
