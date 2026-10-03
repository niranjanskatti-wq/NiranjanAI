import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../ui/task_picker.dart';
import '../../ui/widgets.dart';

/// Today's top priorities: drag the handle to reorder, long-press a row to drag it onto the
/// timeline, tap to start focus.
class PrioritiesCard extends ConsumerWidget {
  const PrioritiesCard({super.key, required this.priorities, required this.projects, required this.sessions, required this.today});
  final List<TaskItem> priorities;
  final List<Project> projects;
  final List<FocusSession> sessions;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final limit = s.priorityCount;
    final room = limit - priorities.length;
    final projectMap = {for (final x in projects) x.id: x};
    final spent = <String, int>{};
    for (final x in sessions) {
      if (x.taskId != null && x.result != 'interrupted') spent[x.taskId!] = (spent[x.taskId!] ?? 0) + 1;
    }
    final tasks = ref.watch(tasksProvider).value ?? const <TaskItem>[];
    // Unfinished priorities from the most recent earlier day, offered for carry-over.
    final earlier = tasks.where((t) => t.isPriority && t.status != 'done' && t.priorityDate != null && t.priorityDate!.compareTo(today) < 0).toList();
    final latest = earlier.fold<String?>(null, (m, t) => m == null || t.priorityDate!.compareTo(m) > 0 ? t.priorityDate : m);
    final carry = earlier.where((t) => t.priorityDate == latest).toList();
    final doneCount = priorities.where((t) => t.status == 'done').length;

    Future<void> add() async {
      final picked = await pickTask(context, ref,
          title: 'Add to ${s.priorityLabel.toLowerCase()}', description: '${priorities.length} of $limit chosen', exclude: priorities.map((t) => t.id).toList());
      if (picked?.task == null) return;
      final ok = await ref.read(repositoryProvider).addToPriorities(picked!.task!.id, limit, today);
      if (!ok && context.mounted) toast(context, 'You can have up to $limit. Change this in Settings.', error: true);
    }

    Future<void> carryOver() async {
      var added = 0;
      for (final t in carry.take(room < 0 ? 0 : room)) {
        if (await ref.read(repositoryProvider).addToPriorities(t.id, limit, today)) added++;
      }
      if (context.mounted) toast(context, added > 0 ? 'Carried over ${pluralize(added, 'priority', 'priorities')}.' : 'Your priorities are already full.', error: added == 0);
    }

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CardHeader(
          icon: Icons.track_changes_rounded,
          title: s.priorityLabel,
          subtitle: priorities.isEmpty ? null : '$doneCount of ${priorities.length} done',
          action: room > 0 ? Btn('Add', icon: Icons.add_rounded, kind: BtnKind.ghost, small: true, onPressed: add) : null,
        ),
        if (priorities.isEmpty)
          EmptyState(
            title: 'What matters most today?',
            description: 'Pick up to $limit. Fewer is usually better.',
            action: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              Btn('Choose priorities', icon: Icons.add_rounded, kind: BtnKind.subtle, small: true, onPressed: add),
              if (carry.isNotEmpty) Btn('Carry over ${carry.length}', icon: Icons.undo_rounded, kind: BtnKind.ghost, small: true, onPressed: carryOver),
            ]),
          )
        else ...[
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: priorities.length,
            proxyDecorator: (child, i, anim) => Material(color: Colors.transparent, elevation: 6, borderRadius: BorderRadius.circular(12), child: child),
            onReorderItem: (from, to) {
              final ids = priorities.map((t) => t.id).toList();
              final moved = ids.removeAt(from);
              ids.insert(to, moved);
              ref.read(repositoryProvider).reorderPriorities(ids);
            },
            itemBuilder: (context, i) {
              final t = priorities[i];
              return _PriorityRow(
                key: ValueKey(t.id),
                task: t,
                index: i,
                project: t.projectId == null ? null : projectMap[t.projectId],
                spent: spent[t.id] ?? 0,
                showProject: s.on('tasks'),
              );
            },
          ),
          if (carry.isNotEmpty && room > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: carryOver,
                icon: Icon(Icons.undo_rounded, size: 16, color: p.muted),
                label: Text('Carry over ${pluralize(carry.length, 'unfinished priority', 'unfinished priorities')}', style: TextStyle(color: p.muted, fontSize: 13)),
              ),
            ),
        ],
      ]),
    );
  }
}

class _PriorityRow extends ConsumerWidget {
  const _PriorityRow({super.key, required this.task, required this.index, required this.project, required this.spent, required this.showProject});
  final TaskItem task;
  final int index, spent;
  final Project? project;
  final bool showProject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final done = task.status == 'done';
    final repo = ref.read(repositoryProvider);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        ReorderableDragStartListener(
          index: index,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8), child: Icon(Icons.drag_indicator_rounded, size: 20, color: p.muted.withValues(alpha: 0.6))),
        ),
        const SizedBox(width: 4),
        _CheckCircle(done: done, onTap: () => repo.setTaskDone(task.id, !done)),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: done ? null : () => context.go('/focus?task=${task.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('${index + 1}  ', style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: tabular)),
                  Expanded(
                    child: Text(task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: done ? p.muted : p.fg,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: p.muted,
                        )),
                  ),
                ]),
                if ((project != null && showProject) || task.estimateSessions != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 18, top: 2),
                    child: Row(children: [
                      if (project != null && showProject) ...[Dot(colorFromHex(project!.color), size: 7), const SizedBox(width: 5), Text(project!.name, style: TextStyle(color: p.muted, fontSize: 12)), const SizedBox(width: 10)],
                      if (task.estimateSessions != null) Text('$spent/${task.estimateSessions} sessions', style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: tabular)),
                    ]),
                  ),
              ]),
            ),
          ),
        ),
        if (!done) IconBtn(Icons.play_arrow_rounded, filled: true, size: 34, tooltip: 'Focus on ${task.title}', onPressed: () => context.go('/focus?task=${task.id}')),
        IconBtn(Icons.close_rounded, size: 34, tooltip: 'Remove from priorities', onPressed: () => repo.removeFromPriorities(task.id)),
      ]),
    );
    // Long-press to drag the task onto the timeline.
    return LongPressDraggable<String>(
      data: 'task:${task.id}',
      feedback: DragChip(title: task.title),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({super.key, required this.done, required this.onTap});
  final bool done;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'Mark not done' : 'Mark done',
      child: Pressable(
        onTap: onTap,
        scale: 0.85,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? p.success : Colors.transparent, border: Border.all(color: done ? p.success : p.border, width: 2)),
          child: done ? Icon(Icons.check_rounded, size: 15, color: p.bg) : null,
        ),
      ),
    );
  }
}

/// Floating chip shown while dragging a task.
class DragChip extends StatelessWidget {
  const DragChip({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: p.accent.withValues(alpha: 0.6)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16)],
        ),
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.fg, fontWeight: FontWeight.w500, fontSize: 13.5)),
      ),
    );
  }
}

/// Exported for reuse by the task list.
class CheckCircle extends _CheckCircle {
  const CheckCircle({super.key, required super.done, required super.onTap});
}
