import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/settings.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../ui/widgets.dart';
import '../today/priorities_card.dart' show CheckCircle;

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String filter = 'all';
  String project = 'all';
  String? newProject;
  final title = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final tasksA = ref.watch(tasksProvider);
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final subtasks = ref.watch(subtasksProvider).value ?? const <Subtask>[];
    final sessions = ref.watch(sessionsProvider).value ?? const <FocusSession>[];
    final today = watchToday(ref);
    final blocks = ref.watch(blocksForDateProvider(today)).value ?? const <TimeBlock>[];
    final fields = s.strings('tasks.visibleFields').toSet();
    final projectMap = {for (final x in projects) x.id: x};
    final spent = <String, int>{};
    for (final x in sessions) {
      if (x.taskId != null && x.result != 'interrupted') spent[x.taskId!] = (spent[x.taskId!] ?? 0) + 1;
    }
    final subMap = <String, List<Subtask>>{};
    for (final x in subtasks) {
      subMap.putIfAbsent(x.taskId, () => []).add(x);
    }

    final all = tasksA.value ?? const <TaskItem>[];
    final blocked = blocks.map((b) => b.taskId).toSet();
    var list = all.where((t) => project == 'all' || t.projectId == project).toList();
    switch (filter) {
      case 'today':
        list = list.where((t) => t.status != 'done' && ((t.isPriority && t.priorityDate == today) || (t.dueDate != null && t.dueDate!.compareTo(today) <= 0) || blocked.contains(t.id))).toList();
      case 'upcoming':
        list = list.where((t) => t.status != 'done' && t.dueDate != null && t.dueDate!.compareTo(today) > 0).toList()..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      case 'completed':
        list = list.where((t) => t.status == 'done').toList()..sort((a, b) => (b.completedAt ?? 0).compareTo(a.completedAt ?? 0));
      default:
        list = list.where((t) => t.status != 'done').toList()..sort((a, b) => a.flagged != b.flagged ? (b.flagged ? 1 : -1) : a.sort.compareTo(b.sort));
    }
    final openCount = all.where((t) => t.status != 'done').length;

    Future<void> add() async {
      final t = title.text.trim();
      if (t.isEmpty) return;
      await ref.read(repositoryProvider).createTask(
            title: t,
            projectId: newProject ?? (project != 'all' ? project : null),
            dueDate: filter == 'today' ? today : null,
          );
      title.clear();
    }

    return Scaffold(
      body: PageBody(children: [
        PageHeader(
          title: 'Tasks',
          subtitle: tasksA.hasValue ? '$openCount open' : null,
          action: Btn('Projects', icon: Icons.folder_open_rounded, kind: BtnKind.ghost, small: true, onPressed: () => showAppSheet(context, title: 'Projects', description: 'Colored tags for grouping tasks.', builder: (_) => const ProjectManager())),
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          child: Row(children: [
            Icon(Icons.add_rounded, color: p.muted, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: title,
                decoration: const InputDecoration(hintText: 'Add a task…', filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => add(),
              ),
            ),
            if (fields.contains('project') && projects.isNotEmpty)
              PopupMenuButton<String?>(
                tooltip: 'Project for new task',
                initialValue: newProject,
                onSelected: (v) => setState(() => newProject = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('No project')),
                  for (final x in projects) PopupMenuItem(value: x.id, child: Row(children: [Dot(colorFromHex(x.color)), const SizedBox(width: 8), Text(x.name)])),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (newProject != null) ...[Dot(colorFromHex(projectMap[newProject]?.color ?? '#7C7CFF')), const SizedBox(width: 6)],
                    Text(newProject == null ? 'Project' : projectMap[newProject]?.name ?? 'Project', style: TextStyle(color: p.muted, fontSize: 13)),
                    Icon(Icons.expand_more_rounded, size: 18, color: p.muted),
                  ]),
                ),
              ),
            Btn('Add', kind: BtnKind.primary, small: true, onPressed: add),
          ]),
        ),
        const Gap(),
        Segmented<String>(
          value: filter,
          onChanged: (v) => setState(() => filter = v),
          options: const [('today', 'Today'), ('upcoming', 'Upcoming'), ('all', 'All open'), ('completed', 'Completed')],
        ),
        if (projects.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              PillChip(label: 'All projects', active: project == 'all', onTap: () => setState(() => project = 'all')),
              for (final x in projects) ...[
                const SizedBox(width: 6),
                PillChip(label: x.name, active: project == x.id, leading: Dot(colorFromHex(x.color)), onTap: () => setState(() => project = project == x.id ? 'all' : x.id)),
              ],
            ]),
          ),
        ],
        const Gap(),
        if (tasksA.hasError)
          ErrorBlock(tasksA.error!)
        else if (!tasksA.hasValue)
          ...List.generate(4, (_) => const LoadingBlock(height: 58))
        else if (list.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.checklist_rounded,
              title: switch (filter) { 'completed' => 'Nothing completed yet', 'upcoming' => 'Nothing upcoming', 'today' => 'Nothing planned for today', _ => 'No open tasks' },
              description: switch (filter) {
                'completed' => 'Finished tasks will show up here.',
                'upcoming' => 'Tasks with a future due date appear here.',
                _ => 'Add one above. Keep titles short and concrete.',
              },
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(children: [
              for (var i = 0; i < list.length; i++) ...[
                _TaskRow(
                  task: list[i],
                  project: list[i].projectId == null ? null : projectMap[list[i].projectId],
                  spent: spent[list[i].id] ?? 0,
                  subs: subMap[list[i].id] ?? const [],
                  fields: fields,
                  today: today,
                ),
                if (i < list.length - 1) Divider(color: p.border.withValues(alpha: 0.7)),
              ],
            ]),
          ),
      ]),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.project, required this.spent, required this.subs, required this.fields, required this.today});
  final TaskItem task;
  final Project? project;
  final int spent;
  final List<Subtask> subs;
  final Set<String> fields;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final repo = ref.read(repositoryProvider);
    final done = task.status == 'done';
    final overdue = task.dueDate != null && task.dueDate!.compareTo(today) < 0 && !done;
    final isPrio = task.isPriority && task.priorityDate == today;
    final subsDone = subs.where((x) => x.done).length;
    final meta = <Widget>[
      if (fields.contains('project') && project != null) TagPill(project!.name, colorFromHex(project!.color)),
      if (isPrio && s.on('priorities')) Text('Today', style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.w600)),
      if (fields.contains('status') && task.status == 'in_progress') Text('In progress', style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.w500)),
      if (fields.contains('sessions') && (task.estimateSessions != null || spent > 0))
        Text('$spent${task.estimateSessions != null ? '/${task.estimateSessions}' : ''} sessions',
            style: TextStyle(color: task.estimateSessions != null && spent > task.estimateSessions! ? p.warning : p.muted, fontSize: 12, fontFeatures: tabular))
      else if (fields.contains('estimate') && task.estimateSessions != null)
        Text('est. ${task.estimateSessions} sessions', style: TextStyle(color: p.muted, fontSize: 12)),
      if (fields.contains('dueDate') && task.dueDate != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_rounded, size: 13, color: overdue ? p.warning : p.muted),
          const SizedBox(width: 3),
          Text(task.dueDate == today ? 'Today' : DateFormat('MMM d').format(parseDateKey(task.dueDate!)), style: TextStyle(color: overdue ? p.warning : p.muted, fontSize: 12)),
        ]),
      if (fields.contains('subtasks') && s.on('subtasks') && subs.isNotEmpty) Text('$subsDone/${subs.length} steps', style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: tabular)),
      if (done && task.completedAt != null) Text('Done ${DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(task.completedAt!))}', style: TextStyle(color: p.muted, fontSize: 12)),
    ];

    Future<void> moveToToday() async {
      if (s.on('priorities')) {
        final ok = await repo.addToPriorities(task.id, s.priorityCount, today);
        if (context.mounted) toast(context, ok ? 'Added to ${s.priorityLabel.toLowerCase()}' : '${s.priorityLabel} are full (${s.priorityCount}).', error: !ok);
      } else {
        await repo.updateTask(task.id, TasksCompanion(dueDate: Value(today)));
        if (context.mounted) toast(context, 'Due today');
      }
    }

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: p.danger.withValues(alpha: 0.15), child: Icon(Icons.delete_outline_rounded, color: p.danger)),
      confirmDismiss: (_) => confirm(context, title: 'Delete “${task.title}”?', description: 'Sessions logged on it are kept.', confirmLabel: 'Delete', danger: true),
      onDismissed: (_) => repo.deleteTask(task.id),
      child: InkWell(
        onTap: () => showTaskSheet(context, ref, task.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(children: [
            CheckCircle(done: done, onTap: () => repo.setTaskDone(task.id, !done)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (fields.contains('flag') && task.flagged) ...[Icon(Icons.flag_rounded, size: 15, color: p.warning), const SizedBox(width: 4)],
                  Expanded(
                    child: Text(task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: done ? p.muted : p.fg, decoration: done ? TextDecoration.lineThrough : null, decorationColor: p.muted)),
                  ),
                ]),
                if (meta.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: meta)),
              ]),
            ),
            if (!done && !isPrio) IconBtn(Icons.wb_sunny_outlined, size: 36, tooltip: 'Move to today', onPressed: moveToToday),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ task details

Future<void> showTaskSheet(BuildContext context, WidgetRef ref, String taskId) {
  return showAppSheet(context, title: 'Task', builder: (ctx) => _TaskSheet(taskId: taskId));
}

class _TaskSheet extends ConsumerStatefulWidget {
  const _TaskSheet({required this.taskId});
  final String taskId;
  @override
  ConsumerState<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends ConsumerState<_TaskSheet> {
  late final TextEditingController title;
  final newSub = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = (ref.read(tasksProvider).value ?? const <TaskItem>[]).where((x) => x.id == widget.taskId).firstOrNull;
    title = TextEditingController(text: t?.title ?? '');
  }

  @override
  void dispose() {
    _saveTitle();
    title.dispose();
    newSub.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final t = (ref.read(tasksProvider).value ?? const <TaskItem>[]).where((x) => x.id == widget.taskId).firstOrNull;
    final v = title.text.trim();
    if (t != null && v.isNotEmpty && v != t.title) ref.read(repositoryProvider).updateTask(t.id, TasksCompanion(title: Value(v)));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final repo = ref.read(repositoryProvider);
    final task = (ref.watch(tasksProvider).value ?? const <TaskItem>[]).where((x) => x.id == widget.taskId).firstOrNull;
    if (task == null) return const SizedBox(height: 80);
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final subs = (ref.watch(subtasksProvider).value ?? const <Subtask>[]).where((x) => x.taskId == task.id).toList();
    final spent = (ref.watch(sessionsProvider).value ?? const <FocusSession>[]).where((x) => x.taskId == task.id && x.result != 'interrupted').length;
    final fields = s.strings('tasks.visibleFields').toSet();
    final today = todayKey();
    final isPrio = task.isPriority && task.priorityDate == today;
    TextStyle label() => TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500), onSubmitted: (_) => _saveTitle()),
      if (fields.contains('status')) ...[
        const SizedBox(height: 14),
        Segmented<String>(value: task.status, onChanged: (v) => repo.setTaskStatus(task.id, v), options: const [('todo', 'To do'), ('in_progress', 'In progress'), ('done', 'Done')]),
      ],
      const SizedBox(height: 14),
      Row(children: [
        if (fields.contains('project'))
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Project', style: label()),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: task.projectId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final x in projects) DropdownMenuItem(value: x.id, child: Row(children: [Dot(colorFromHex(x.color)), const SizedBox(width: 8), Flexible(child: Text(x.name, overflow: TextOverflow.ellipsis))])),
                ],
                onChanged: (v) => repo.updateTask(task.id, TasksCompanion(projectId: Value(v))),
              ),
            ]),
          ),
        if (fields.contains('project') && fields.contains('dueDate')) const SizedBox(width: 12),
        if (fields.contains('dueDate'))
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Due date', style: label()),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: task.dueDate == null ? DateTime.now() : parseDateKey(task.dueDate!),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) repo.updateTask(task.id, TasksCompanion(dueDate: Value(dateKey(d))));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                      decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
                      child: Text(task.dueDate == null ? 'None' : DateFormat('EEE, MMM d').format(parseDateKey(task.dueDate!)), style: TextStyle(color: task.dueDate == null ? p.muted : p.fg)),
                    ),
                  ),
                ),
                if (task.dueDate != null) IconBtn(Icons.close_rounded, size: 34, tooltip: 'Clear due date', onPressed: () => repo.updateTask(task.id, const TasksCompanion(dueDate: Value(null)))),
              ]),
            ]),
          ),
      ]),
      if (fields.contains('estimate') || fields.contains('sessions')) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Sessions', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('$spent spent${task.estimateSessions != null ? ' of ${task.estimateSessions} estimated' : ''}', style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: tabular)),
                if (task.estimateSessions != null && task.estimateSessions! > 0)
                  Padding(padding: const EdgeInsets.only(top: 6, right: 8), child: ProgressLine(value: spent / task.estimateSessions!, color: spent > task.estimateSessions! ? p.warning : null)),
              ]),
            ),
            if (fields.contains('estimate'))
              NumStepper(
                value: task.estimateSessions ?? 0,
                min: 0,
                max: 50,
                onChanged: (v) => repo.updateTask(task.id, TasksCompanion(estimateSessions: Value(v == 0 ? null : v))),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 6),
      if (fields.contains('flag')) SwitchRow(label: 'High priority', value: task.flagged, onChanged: (v) => repo.updateTask(task.id, TasksCompanion(flagged: Value(v)))),
      if (s.on('priorities') && task.status != 'done')
        SwitchRow(
          label: "In today's ${s.priorityLabel.toLowerCase()}",
          value: isPrio,
          onChanged: (v) async {
            if (v) {
              final ok = await repo.addToPriorities(task.id, s.priorityCount, today);
              if (!ok && context.mounted) toast(context, '${s.priorityLabel} are full (${s.priorityCount}).', error: true);
            } else {
              await repo.removeFromPriorities(task.id);
            }
          },
        ),
      if (s.on('subtasks')) ...[
        const SizedBox(height: 8),
        Text('Checklist', style: label()),
        const SizedBox(height: 4),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) {
            final ids = subs.map((x) => x.id).toList();
            final m = ids.removeAt(from);
            ids.insert(to, m);
            repo.reorderSubtasks(ids);
          },
          children: [
            for (var i = 0; i < subs.length; i++)
              Row(key: ValueKey(subs[i].id), children: [
                ReorderableDragStartListener(index: i, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.drag_indicator_rounded, size: 18, color: p.muted.withValues(alpha: 0.6)))),
                Checkbox(value: subs[i].done, onChanged: (v) => repo.updateSubtask(subs[i].id, SubtasksCompanion(done: Value(v ?? false)))),
                Expanded(
                  child: _InlineEdit(
                    value: subs[i].title,
                    strike: subs[i].done,
                    onCommit: (v) => repo.updateSubtask(subs[i].id, SubtasksCompanion(title: Value(v))),
                  ),
                ),
                IconBtn(Icons.close_rounded, size: 32, tooltip: 'Delete step', onPressed: () => repo.deleteSubtask(subs[i].id)),
              ]),
          ],
        ),
        Row(children: [
          Expanded(child: TextField(controller: newSub, decoration: const InputDecoration(hintText: 'Add a step'), onSubmitted: (_) => _addSub(task.id))),
          const SizedBox(width: 8),
          IconBtn(Icons.add_rounded, filled: true, tooltip: 'Add step', onPressed: () => _addSub(task.id)),
        ]),
      ],
      const SizedBox(height: 18),
      Row(children: [
        Btn('Delete', icon: Icons.delete_outline_rounded, kind: BtnKind.dangerGhost, onPressed: () async {
          if (await confirm(context, title: 'Delete “${task.title}”?', description: 'Subtasks are deleted too. Logged sessions are kept.', confirmLabel: 'Delete', danger: true)) {
            await repo.deleteTask(task.id);
            if (context.mounted) Navigator.pop(context);
          }
        }),
        const Spacer(),
        if (task.status != 'done')
          Btn('Focus', icon: Icons.play_arrow_rounded, kind: BtnKind.primary, onPressed: () {
            _saveTitle();
            Navigator.pop(context);
            GoRouter.of(context).go('/focus?task=${task.id}');
          }),
      ]),
    ]);
  }

  Future<void> _addSub(String taskId) async {
    final v = newSub.text.trim();
    if (v.isEmpty) return;
    await ref.read(repositoryProvider).addSubtask(taskId, v);
    newSub.clear();
  }
}

class _InlineEdit extends StatefulWidget {
  const _InlineEdit({required this.value, required this.onCommit, this.strike = false});
  final String value;
  final ValueChanged<String> onCommit;
  final bool strike;
  @override
  State<_InlineEdit> createState() => _InlineEditState();
}

class _InlineEditState extends State<_InlineEdit> {
  late final c = TextEditingController(text: widget.value);
  final f = FocusNode();
  @override
  void initState() {
    super.initState();
    f.addListener(() {
      if (!f.hasFocus && c.text.trim().isNotEmpty && c.text.trim() != widget.value) widget.onCommit(c.text.trim());
    });
  }

  @override
  void dispose() {
    c.dispose();
    f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return TextField(
      controller: c,
      focusNode: f,
      style: TextStyle(fontSize: 14, color: widget.strike ? p.muted : p.fg, decoration: widget.strike ? TextDecoration.lineThrough : null),
      decoration: const InputDecoration(filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, isDense: true),
    );
  }
}

// ------------------------------------------------------------------ projects

class ProjectManager extends ConsumerStatefulWidget {
  const ProjectManager({super.key});
  @override
  ConsumerState<ProjectManager> createState() => _ProjectManagerState();
}

class _ProjectManagerState extends ConsumerState<ProjectManager> {
  final name = TextEditingController();
  String color = accentPresets[1];

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final repo = ref.read(repositoryProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final x in projects)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Pressable(
              onTap: () async {
                final c = await pickColor(context, x.color);
                if (c != null) await repo.updateProject(x.id, ProjectsCompanion(color: Value(c)));
              },
              child: Container(width: 34, height: 34, decoration: BoxDecoration(color: colorFromHex(x.color), shape: BoxShape.circle, border: Border.all(color: p.border))),
            ),
            const SizedBox(width: 10),
            Expanded(child: _InlineEdit(value: x.name, onCommit: (v) => repo.updateProject(x.id, ProjectsCompanion(name: Value(v))))),
            IconBtn(Icons.delete_outline_rounded, tooltip: 'Delete ${x.name}', onPressed: () async {
              final count = (ref.read(tasksProvider).value ?? const <TaskItem>[]).where((t) => t.projectId == x.id).length;
              if (await confirm(context,
                  title: 'Delete “${x.name}”?',
                  description: count > 0 ? '$count task(s) will keep existing without a project.' : 'This project has no tasks.',
                  confirmLabel: 'Delete',
                  danger: true)) {
                await repo.deleteProject(x.id);
              }
            }),
          ]),
        ),
      if (projects.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No projects yet.', style: TextStyle(color: p.muted))),
      const SizedBox(height: 6),
      Row(children: [
        Pressable(
          onTap: () async {
            final c = await pickColor(context, color);
            if (c != null) setState(() => color = c);
          },
          child: Container(width: 34, height: 34, decoration: BoxDecoration(color: colorFromHex(color), shape: BoxShape.circle, border: Border.all(color: p.border))),
        ),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: name, decoration: const InputDecoration(hintText: 'New project'), onSubmitted: (_) => _add())),
        const SizedBox(width: 8),
        IconBtn(Icons.add_rounded, filled: true, tooltip: 'Add project', onPressed: _add),
      ]),
    ]);
  }

  Future<void> _add() async {
    final n = name.text.trim();
    if (n.isEmpty) return;
    await ref.read(repositoryProvider).addProject(n, color);
    name.clear();
    final count = (ref.read(projectsProvider).value?.length ?? 0) + 2;
    setState(() => color = accentPresets[count % accentPresets.length]);
  }
}

/// Preset swatches plus a hue/brightness custom picker.
Future<String?> pickColor(BuildContext context, String current) {
  return showAppSheet<String>(context, title: 'Choose a color', builder: (ctx) => _ColorPicker(current: current));
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.current});
  final String current;
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late HSVColor hsv = HSVColor.fromColor(colorFromHex(widget.current));

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = hsv.toColor();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final hex in accentPresets)
          Pressable(
            onTap: () => Navigator.pop(context, hex),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: colorFromHex(hex), shape: BoxShape.circle, border: Border.all(color: hex.toUpperCase() == widget.current.toUpperCase() ? p.fg : Colors.transparent, width: 2)),
            ),
          ),
      ]),
      const SizedBox(height: 18),
      Text('Custom', style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(
        height: 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          gradient: LinearGradient(colors: [for (var h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h.toDouble(), hsv.saturation, hsv.value).toColor()]),
        ),
      ),
      Slider(value: hsv.hue, min: 0, max: 360, onChanged: (v) => setState(() => hsv = hsv.withHue(v))),
      Row(children: [Text('Saturation', style: TextStyle(color: p.muted, fontSize: 12)), Expanded(child: Slider(value: hsv.saturation, onChanged: (v) => setState(() => hsv = hsv.withSaturation(v))))]),
      Row(children: [Text('Brightness', style: TextStyle(color: p.muted, fontSize: 12)), Expanded(child: Slider(value: hsv.value, min: 0.2, onChanged: (v) => setState(() => hsv = hsv.withValue(v))))]),
      const SizedBox(height: 8),
      Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(toHex(c), style: const TextStyle(fontFeatures: tabular)),
        const Spacer(),
        Btn('Use color', kind: BtnKind.primary, onPressed: () => Navigator.pop(context, toHex(c))),
      ]),
    ]);
  }
}
