import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/reviews.dart';
import '../../core/settings.dart';
import '../../core/stats.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../ui/widgets.dart';
import '../backup/backup_service.dart';
import '../focus/focus_controller.dart';
import 'priorities_card.dart';
import 'timeline_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final today = watchToday(ref);
    final tasksA = ref.watch(tasksProvider);
    final sessionsA = ref.watch(sessionsProvider);
    final distractionsA = ref.watch(distractionsProvider);
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final blocks = ref.watch(blocksForDateProvider(today)).value ?? const <TimeBlock>[];
    final reviews = ref.watch(reviewsProvider).value ?? const <Review>[];
    final focus = ref.watch(focusProvider);
    final now = DateTime.now();

    final loading = !tasksA.hasValue || !sessionsA.hasValue || !distractionsA.hasValue;
    final error = tasksA.error ?? sessionsA.error ?? distractionsA.error;
    final tasks = tasksA.value ?? const <TaskItem>[];
    final sessions = sessionsA.value ?? const <FocusSession>[];
    final index = buildDayIndex(sessions, tasks, distractionsA.value ?? const <Distraction>[]);
    final day = index[today] ?? DayStats();
    final priorities = tasks.where((t) => t.isPriority && t.priorityDate == today).toList()..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
    final nextTask = priorities.where((t) => t.status != 'done').firstOrNull;
    final prioIds = priorities.map((t) => t.id).toSet();
    final tray = [
      ...priorities,
      ...tasks.where((t) => t.status != 'done' && !prioIds.contains(t.id) && (t.dueDate == today || t.flagged)),
    ].take(12).toList();
    final showTimeline = s.on('timeBlocks') && (s.b('timeBlocks.showWeekends') || !isWeekend(now));

    Widget? section(String id) => switch (id) {
          'startFocus' => _StartFocus(
              active: focus.phase != FocusPhase.idle,
              next: focus.phase == FocusPhase.idle ? nextTask?.title : null,
              onTap: () => context.go(focus.phase == FocusPhase.idle && nextTask != null ? '/focus?task=${nextTask.id}' : '/focus'),
            ),
          'summary' when s.on('summary') => _SummaryStrip(day: day),
          'streak' when s.on('streaks') => _StreakCard(info: computeStreak(s, index), rule: streakRuleLabel(s)),
          'eveningReview' when isEveningReviewDue(s, reviews) =>
            const _ReviewCard(route: '/review/evening', title: 'Evening review', body: "Two minutes: planned vs. done, one reflection, and tomorrow's priorities."),
          'weeklyReview' when isWeeklyReviewDue(s, reviews) =>
            const _ReviewCard(route: '/review/weekly', title: 'Weekly review', body: "Ten minutes to look at your week and choose what's next."),
          'priorities' when s.on('priorities') => PrioritiesCard(priorities: priorities, projects: projects, sessions: sessions, today: today),
          'timeline' when showTimeline => TimelineCard(blocks: blocks, tasks: tasks, projects: projects, tray: tray, today: today),
          'backup' when s.on('backup') => const _BackupStatus(),
          _ => null,
        };

    final visible = [for (final e in s.homeLayout) if (e['visible'] == true) section(e['id'] as String)].whereType<Widget>().toList();

    return Scaffold(
      body: PageBody(children: [
        PageHeader(
          overline: DateFormat('EEEE, MMMM d').format(now),
          title: greeting(now),
          action: (s.on('eveningReview') || s.on('weeklyReview')) ? IconBtn(Icons.edit_note_rounded, tooltip: 'Reviews', onPressed: () => context.push('/reviews')) : null,
        ),
        if (error != null)
          ErrorBlock(error)
        else if (loading)
          ...[56.0, 96.0, 200.0].map((h) => LoadingBlock(height: h))
        else
          for (var i = 0; i < visible.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: context.density.gap),
              child: _FadeIn(delay: Duration(milliseconds: 30 * i), child: visible[i]),
            ),
        if (!loading && visible.isEmpty)
          AppCard(child: EmptyState(icon: Icons.dashboard_customize_outlined, title: 'Nothing on Today', description: "All of Today's sections are hidden. Turn some back on in Settings → Appearance.", action: Btn('Open settings', onPressed: () => context.go('/settings/appearance')))),
      ]),
    );
  }
}

class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child, required this.delay});
  final Widget child;
  final Duration delay;
  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320) + delay,
      curve: Interval(delay.inMilliseconds / (320 + delay.inMilliseconds), 1, curve: Curves.easeOutCubic),
      builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child)),
      child: child,
    );
  }
}

class _StartFocus extends StatelessWidget {
  const _StartFocus({required this.active, required this.onTap, this.next});
  final bool active;
  final String? next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.45), blurRadius: 36, spreadRadius: -12, offset: const Offset(0, 14))],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(active ? 'Return to session' : 'Start focus', style: TextStyle(color: p.onAccent, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text(
                active ? 'Your session is still going' : next != null ? 'Next: $next' : 'Pick a task and a duration',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.onAccent.withValues(alpha: 0.8), fontSize: 14),
              ),
            ]),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(Icons.play_arrow_rounded, color: p.onAccent, size: 28),
          ),
        ]),
      ),
    );
  }
}

class _SummaryStrip extends ConsumerWidget {
  const _SummaryStrip({required this.day});
  final DayStats day;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final goal = goalProgress(s, day);
    Widget stat(String v, String label) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.4, fontFeatures: tabular))),
            Text(label, style: TextStyle(color: p.muted, fontSize: 12)),
          ]),
        );
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: context.density.pad, vertical: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        stat(formatDuration(day.focusSec), 'Focus'),
        if (s.on('tasks') || s.on('priorities')) stat('${day.tasksDone}', 'Tasks done'),
        stat('${day.sessions}', 'Sessions'),
        Expanded(
          flex: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '${goal.value}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.4)),
                TextSpan(text: '/${goal.target} ${goal.unit}', style: TextStyle(fontSize: 13, color: p.muted)),
              ]), style: const TextStyle(fontFeatures: tabular)),
            ),
            const SizedBox(height: 6),
            ProgressLine(value: goal.ratio, color: goal.ratio >= 1 ? p.success : p.accent),
            const SizedBox(height: 4),
            Text(goal.ratio >= 1 ? 'Daily goal reached' : 'Daily goal', style: TextStyle(color: p.muted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.info, required this.rule});
  final StreakInfo info;
  final String rule;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: context.density.pad, vertical: 14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: info.current > 0 ? p.warning.withValues(alpha: 0.12) : p.card2, borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.local_fire_department_rounded, color: info.current > 0 ? p.warning : p.muted, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${pluralize(info.current, 'day')} streak', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontFeatures: tabular)),
            Text(
              info.atRisk ? 'Missed yesterday — today keeps it alive.' : info.todayDone ? 'Today counts. Nice.' : rule,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.muted, fontSize: 12.5),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${info.best}', style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular)),
          Text('best', style: TextStyle(color: p.muted, fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.route, required this.title, required this.body});
  final String route, title, body;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      borderColor: p.accent.withValues(alpha: 0.35),
      onTap: () => context.push(route),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.edit_note_rounded, color: p.accent, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text(body, style: TextStyle(color: p.muted, fontSize: 13)),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: p.muted),
      ]),
    );
  }
}

class _BackupStatus extends ConsumerStatefulWidget {
  const _BackupStatus();
  @override
  ConsumerState<_BackupStatus> createState() => _BackupStatusState();
}

class _BackupStatusState extends ConsumerState<_BackupStatus> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    if (!s.b('backup.connected')) {
      return InkWell(
        onTap: () => context.go('/settings/backup'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(children: [Icon(Icons.cloud_off_rounded, size: 15, color: p.muted), const SizedBox(width: 8), Text('Google Drive not connected', style: TextStyle(color: p.muted, fontSize: 13))]),
        ),
      );
    }
    final last = s['backup.lastBackupAt'] as num?;
    final due = isBackupDue(s);
    final problem = s.b('backup.needsReconnect') || s['backup.lastError'] != null;
    final label = busy
        ? 'Backing up…'
        : s.b('backup.needsReconnect')
            ? 'Backup needs you to reconnect Google — tap to back up'
            : '${last == null ? 'No backup yet' : 'Last backup: ${relativeDays(last.toInt())}'}${due ? ' · due now, tap to back up' : ''}';
    return InkWell(
      onTap: busy
          ? null
          : () async {
              setState(() => busy = true);
              final (outcome, msg) = await runBackup(ref.read(settingsProvider.notifier), ref.read(databaseProvider), interactive: true);
              if (!mounted) return;
              setState(() => busy = false);
              if (outcome == BackupOutcome.ok) {
                toast(context, 'Backed up to Google Drive');
              } else if (msg != null) {
                toast(context, msg, error: true);
              }
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(children: [
          busy
              ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p.muted))
              : Icon(problem ? Icons.warning_amber_rounded : Icons.cloud_done_outlined, size: 15, color: problem ? p.warning : p.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: p.muted, fontSize: 13))),
        ]),
      ),
    );
  }
}

/// Exposed for tests.
List<String> visibleHomeSections(AppSettings s) => [for (final e in s.homeLayout) if (e['visible'] == true) e['id'] as String];
