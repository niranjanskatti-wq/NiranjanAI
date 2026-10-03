import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/stats.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../ui/charts.dart';
import '../../ui/widgets.dart';

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.4, fontFeatures: tabular)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.pal.muted, fontSize: 12)),
        ]),
      );
}

Widget _questions(BuildContext context, List<String> questions, List<TextEditingController> answers, String hint) => AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CardHeader(title: 'Reflection'),
        for (var i = 0; i < questions.length; i++) ...[
          Text(questions[i], style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(controller: answers[i], minLines: 2, maxLines: 6, decoration: InputDecoration(hintText: hint)),
          if (i < questions.length - 1) const SizedBox(height: 16),
        ],
      ]),
    );

// =============================================================================== evening

class EveningReviewScreen extends ConsumerStatefulWidget {
  const EveningReviewScreen({super.key});
  @override
  ConsumerState<EveningReviewScreen> createState() => _EveningReviewScreenState();
}

class _EveningReviewScreenState extends ConsumerState<EveningReviewScreen> {
  late final List<String> questions = ref.read(settingsProvider).strings('eveningReview.questions');
  late final List<TextEditingController> answers = [for (final _ in questions) TextEditingController()];
  List<String>? picked;
  Review? existing;
  bool loaded = false, saving = false;
  final newTask = TextEditingController();

  @override
  void dispose() {
    for (final a in answers) {
      a.dispose();
    }
    newTask.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final today = todayKey(), tomorrow = tomorrowKey();
    final tasks = ref.watch(tasksProvider).value;
    final blocks = ref.watch(blocksForDateProvider(today)).value;
    final reviews = ref.watch(reviewsProvider).value;
    final since = startOfDay(DateTime.now()).millisecondsSinceEpoch;
    final sessions = (ref.watch(sessionsProvider).value ?? const <FocusSession>[]).where((x) => x.startedAt >= since).toList();
    final distractions = (ref.watch(distractionsProvider).value ?? const <Distraction>[]).where((x) => x.timestamp >= since).toList();

    if (tasks == null || blocks == null || reviews == null) {
      return Scaffold(appBar: backBar(context), body: const PageBody(children: [PageHeader(title: 'Evening review'), LoadingBlock(height: 240)]));
    }
    if (!loaded) {
      loaded = true;
      existing = reviews.where((r) => r.type == 'daily' && r.date == today).firstOrNull;
      if (existing != null) {
        final saved = (jsonDecode(existing!.answers) as List).cast<Map>();
        for (var i = 0; i < questions.length; i++) {
          answers[i].text = '${saved.where((a) => a['question'] == questions[i]).firstOrNull?['answer'] ?? ''}';
        }
      }
      picked = (tasks.where((t) => t.isPriority && t.priorityDate == tomorrow).toList()..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder))).map((t) => t.id).toList();
    }

    final pvd = plannedVsDone(today, tasks, blocks);
    final focusSec = sessions.fold<int>(0, (a, x) => a + x.actualDuration);
    final counts = <String, int>{};
    for (final d in distractions) {
      counts[d.reason] = (counts[d.reason] ?? 0) + 1;
    }
    final top = counts.isEmpty ? null : counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    final limit = s.priorityCount;
    final candidates = tasks.where((t) => t.status != 'done').toList();

    void toggle(String id) => setState(() {
          if (picked!.contains(id)) {
            picked!.remove(id);
          } else if (picked!.length >= limit) {
            toast(context, 'Up to $limit priorities.', error: true);
          } else {
            picked!.add(id);
          }
        });

    Widget taskLine(TaskItem t, {bool unplanned = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(t.status == 'done' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 17, color: t.status == 'done' ? p.success : p.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: t.title, style: TextStyle(color: t.status == 'done' ? p.fg : p.muted, fontSize: 13.5)),
                if (unplanned) TextSpan(text: '  unplanned', style: TextStyle(color: p.muted, fontSize: 11.5)),
              ])),
            ),
          ]),
        );

    return Scaffold(
      appBar: backBar(context),
      body: PageBody(children: [
        PageHeader(title: 'Evening review', subtitle: '${DateFormat('EEEE, MMMM d').format(DateTime.now())} · about 2 minutes'),
        if (s.on('priorities') || s.on('timeBlocks')) ...[
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              CardHeader(title: 'Planned vs. done', subtitle: pvd.planned.isEmpty ? 'Nothing was planned today' : '${pvd.done.length} of ${pvd.planned.length} planned tasks finished'),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PLANNED', style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    for (final t in pvd.planned) taskLine(t),
                    if (pvd.planned.isEmpty) Text('—', style: TextStyle(color: p.muted)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DONE', style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    for (final t in pvd.done) taskLine(t),
                    for (final t in pvd.unplannedDone) taskLine(t, unplanned: true),
                    if (pvd.done.isEmpty && pvd.unplannedDone.isEmpty) Text('Nothing marked done yet.', style: TextStyle(color: p.muted, fontSize: 13)),
                  ]),
                ),
              ]),
            ]),
          ),
          const Gap(),
        ],
        AppCard(
          child: Row(children: [
            _Stat(formatDuration(focusSec), 'Focus time'),
            _Stat('${sessions.where((x) => x.result != 'interrupted').length}', 'Sessions'),
            if (s.on('distractions')) _Stat('${distractions.length}', top == null ? 'Distractions' : 'Top: ${top.key}') else _Stat('${sessions.where((x) => x.result == 'interrupted').length}', 'Interrupted'),
          ]),
        ),
        const Gap(),
        if (questions.isNotEmpty) ...[_questions(context, questions, answers, 'Write a line…'), const Gap()],
        if (s.on('priorities')) ...[
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              CardHeader(title: "Tomorrow's ${s.priorityLabel.toLowerCase()}", subtitle: '${picked!.length} of $limit chosen'),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(shrinkWrap: true, children: [
                  for (final t in candidates)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => toggle(t.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(color: picked!.contains(t.id) ? p.accentSoft : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: picked!.contains(t.id) ? p.accent : Colors.transparent,
                              border: Border.all(color: picked!.contains(t.id) ? p.accent : p.border, width: 2),
                            ),
                            child: picked!.contains(t.id) ? Text('${picked!.indexOf(t.id) + 1}', style: TextStyle(color: p.onAccent, fontSize: 11.5, fontWeight: FontWeight.w700)) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                      ),
                    ),
                  if (candidates.isEmpty) Padding(padding: const EdgeInsets.all(10), child: Text('No open tasks. Add one below.', style: TextStyle(color: p.muted))),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: newTask, decoration: const InputDecoration(hintText: 'New task for tomorrow'), onSubmitted: (_) => _addTask())),
                const SizedBox(width: 8),
                IconBtn(Icons.add_rounded, filled: true, tooltip: 'Add task', onPressed: _addTask),
              ]),
            ]),
          ),
          const Gap(),
        ],
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Btn('Cancel', kind: BtnKind.ghost, onPressed: () => context.pop()),
          const SizedBox(width: 8),
          Btn(existing != null ? 'Update review' : 'Save review', kind: BtnKind.primary, large: true, onPressed: saving
              ? null
              : () async {
                  setState(() => saving = true);
                  final repo = ref.read(repositoryProvider);
                  if (s.on('priorities')) await repo.setPriorities(tomorrow, picked!);
                  await repo.saveReview(
                    id: existing?.id,
                    type: 'daily',
                    date: today,
                    createdAt: existing?.createdAt,
                    answers: [for (var i = 0; i < questions.length; i++) {'question': questions[i], 'answer': answers[i].text.trim()}],
                    nextPriorities: s.on('priorities') ? [for (final id in picked!) {'task_id': id, 'title': tasks.where((t) => t.id == id).firstOrNull?.title ?? ''}] : const [],
                    stats: {'focus_minutes': (focusSec / 60).round(), 'planned': pvd.planned.length, 'done': pvd.done.length, 'distractions': distractions.length, 'top_distraction': top?.key ?? ''},
                  );
                  if (!context.mounted) return;
                  toast(context, 'Evening review saved');
                  context.go('/');
                }),
        ]),
      ]),
    );
  }

  Future<void> _addTask() async {
    final v = newTask.text.trim();
    if (v.isEmpty) return;
    final t = await ref.read(repositoryProvider).createTask(title: v);
    newTask.clear();
    setState(() {
      if (picked!.length < ref.read(settingsProvider).priorityCount) picked!.add(t.id);
    });
  }
}

// =============================================================================== weekly

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});
  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  late final List<String> questions = ref.read(settingsProvider).strings('weeklyReview.questions');
  late final List<TextEditingController> answers = [for (final _ in questions) TextEditingController()];
  bool saving = false;

  @override
  void dispose() {
    for (final a in answers) {
      a.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final days = lastNDays(7);
    final since = days.first.millisecondsSinceEpoch;
    final allSessions = ref.watch(sessionsProvider).value;
    final allDistractions = ref.watch(distractionsProvider).value;
    final tasks = ref.watch(tasksProvider).value;
    if (allSessions == null || allDistractions == null || tasks == null) {
      return Scaffold(appBar: backBar(context), body: const PageBody(children: [PageHeader(title: 'Weekly review'), LoadingBlock(height: 240)]));
    }
    final sessions = allSessions.where((x) => x.startedAt >= since).toList();
    final distractions = allDistractions.where((x) => x.timestamp >= since).toList();
    final labels = [for (final d in days) DateFormat('EEE').format(d)];
    final hours = [for (final d in days) (sessions.where((x) => dateKeyMs(x.startedAt) == dateKey(d)).fold<int>(0, (a, x) => a + x.actualDuration) / 360).round() / 10];
    final done = [for (final d in days) tasks.where((t) => t.status == 'done' && t.completedAt != null && dateKeyMs(t.completedAt!) == dateKey(d)).length.toDouble()];
    final dist = [for (final d in days) distractions.where((x) => dateKeyMs(x.timestamp) == dateKey(d)).length.toDouble()];
    final best = bestFocusTime(allSessions);
    final focusSec = sessions.fold<int>(0, (a, x) => a + x.actualDuration);
    final tasksDone = done.fold<double>(0, (a, v) => a + v).round();

    return Scaffold(
      appBar: backBar(context),
      body: PageBody(children: [
        PageHeader(title: 'Weekly review', subtitle: '${DateFormat('MMM d').format(days.first)} – ${DateFormat('MMM d').format(days.last)} · about 10 minutes'),
        AppCard(
          child: Row(children: [
            _Stat(formatDuration(focusSec), 'Focus time'),
            _Stat('$tasksDone', 'Tasks done'),
            s.on('distractions') ? _Stat('${distractions.length}', 'Distractions') : _Stat('${sessions.length}', 'Sessions'),
          ]),
        ),
        const Gap(),
        ChartCard(title: 'Focus hours per day', child: SimpleBarChart(labels: labels, values: hours, unit: 'h', height: 170)),
        const Gap(),
        ChartCard(title: 'Tasks completed', child: SimpleBarChart(labels: labels, values: done, color: p.success, height: 150)),
        if (s.on('distractions')) ...[
          const Gap(),
          ChartCard(title: 'Distraction trend', child: SimpleLineChart(labels: labels, values: dist, color: p.warning, height: 150)),
        ],
        const Gap(),
        AppCard(
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.schedule_rounded, color: p.accent)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(best == null ? 'Best focus time' : 'Best focus time: ${best.label}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  best == null ? 'Needs at least $bestTimeMinSessions sessions in the last 14 days.' : '${(best.rate * 100).round()}% of ${best.count} sessions started then were marked done (last 14 days).',
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
              ]),
            ),
          ]),
        ),
        const Gap(),
        if (questions.isNotEmpty) ...[_questions(context, questions, answers, 'Write a few lines…'), const Gap()],
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Btn('Cancel', kind: BtnKind.ghost, onPressed: () => context.pop()),
          const SizedBox(width: 8),
          Btn('Save review', kind: BtnKind.primary, large: true, onPressed: saving
              ? null
              : () async {
                  setState(() => saving = true);
                  await ref.read(repositoryProvider).saveReview(
                    type: 'weekly',
                    date: todayKey(),
                    answers: [for (var i = 0; i < questions.length; i++) {'question': questions[i], 'answer': answers[i].text.trim()}],
                    stats: {'focus_minutes': (focusSec / 60).round(), 'tasks_done': tasksDone, 'distractions': distractions.length, 'sessions': sessions.length, 'best_time': best?.label ?? ''},
                  );
                  if (!context.mounted) return;
                  toast(context, 'Weekly review saved');
                  context.go('/reviews');
                }),
        ]),
      ]),
    );
  }
}

// =============================================================================== history

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});
  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  String type = 'all';
  final expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final reviewsA = ref.watch(reviewsProvider);
    final types = {if (s.on('eveningReview')) 'daily', if (s.on('weeklyReview')) 'weekly'};
    final list = (reviewsA.value ?? const <Review>[]).where((r) => types.contains(r.type) && (type == 'all' || r.type == type)).toList();

    return Scaffold(
      appBar: backBar(context),
      body: PageBody(children: [
        const PageHeader(title: 'Reviews', subtitle: 'Your review history.'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (s.on('eveningReview')) Btn('Evening review', icon: Icons.edit_note_rounded, kind: BtnKind.primary, onPressed: () => context.push('/review/evening')),
          if (s.on('weeklyReview')) Btn('Weekly review', icon: Icons.edit_note_rounded, onPressed: () => context.push('/review/weekly')),
        ]),
        const Gap(),
        if (types.length == 2) ...[
          Segmented<String>(value: type, onChanged: (v) => setState(() => type = v), options: const [('all', 'All'), ('daily', 'Evening'), ('weekly', 'Weekly')]),
          const Gap(),
        ],
        if (reviewsA.hasError)
          ErrorBlock(reviewsA.error!)
        else if (!reviewsA.hasValue)
          const LoadingBlock(height: 160)
        else if (list.isEmpty)
          const AppCard(child: EmptyState(icon: Icons.menu_book_rounded, title: 'No reviews yet', description: 'Reviews you save will be listed here so you can look back on them.'))
        else
          for (final r in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReviewItem(review: r, open: expanded.contains(r.id), onToggle: () => setState(() => expanded.contains(r.id) ? expanded.remove(r.id) : expanded.add(r.id))),
            ),
      ]),
    );
  }
}

class _ReviewItem extends ConsumerWidget {
  const _ReviewItem({required this.review, required this.open, required this.onToggle});
  final Review review;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final answers = (jsonDecode(review.answers) as List).cast<Map>();
    final next = (jsonDecode(review.nextPriorities) as List).cast<Map>();
    final stats = Map<String, dynamic>.from(jsonDecode(review.stats) as Map);
    final firstAnswer = answers.map((a) => '${a['answer'] ?? ''}').where((a) => a.isNotEmpty).firstOrNull;
    final statBits = [
      if (stats['focus_minutes'] != null) 'Focus ${stats['focus_minutes']} min',
      if (stats['planned'] != null) '${stats['done']}/${stats['planned']} planned done',
      if (stats['tasks_done'] != null) '${stats['tasks_done']} tasks done',
      if (stats['distractions'] != null) '${stats['distractions']} distractions',
      if ('${stats['best_time'] ?? ''}'.isNotEmpty) 'Best time ${stats['best_time']}',
    ];
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(radiusCard),
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.all(context.density.pad),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: review.type == 'weekly' ? p.accentSoft : p.card2, borderRadius: BorderRadius.circular(99)),
                child: Text(review.type == 'weekly' ? 'Weekly' : 'Evening', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: review.type == 'weekly' ? p.accent : p.muted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(DateFormat('EEEE, MMM d, yyyy').format(parseDateKey(review.date)), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  if (!open && firstAnswer != null) Text(firstAnswer, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 13)),
                ]),
              ),
              AnimatedRotation(turns: open ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: Icon(Icons.expand_more_rounded, color: p.muted)),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          child: !open
              ? const SizedBox(width: double.infinity)
              : Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border.withValues(alpha: 0.7)))),
                  padding: EdgeInsets.all(context.density.pad),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (statBits.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(statBits.join('  ·  '), style: TextStyle(color: p.muted, fontSize: 12))),
                    for (final a in answers) ...[
                      Text('${a['question']}', style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500)),
                      Padding(padding: const EdgeInsets.only(top: 2, bottom: 10), child: Text('${a['answer'] ?? ''}'.isEmpty ? '—' : '${a['answer']}', style: const TextStyle(fontSize: 14))),
                    ],
                    if (next.isNotEmpty) ...[
                      Text('Next priorities', style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500)),
                      for (var i = 0; i < next.length; i++) Text('${i + 1}. ${next[i]['title']}', style: const TextStyle(fontSize: 14)),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: Btn('Delete', icon: Icons.delete_outline_rounded, kind: BtnKind.dangerGhost, small: true, onPressed: () async {
                        if (await confirm(context, title: 'Delete this review?', confirmLabel: 'Delete', danger: true)) await ref.read(repositoryProvider).deleteReview(review.id);
                      }),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }
}
