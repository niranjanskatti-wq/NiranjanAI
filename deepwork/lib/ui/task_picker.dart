import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tokens.dart';
import '../data/database.dart';
import '../data/providers.dart';
import 'widgets.dart';

/// Result of picking: a task, "none", or cancelled (null from the sheet).
class PickedTask {
  const PickedTask(this.task);
  final TaskItem? task;
}

/// Choose an open task, or create one inline.
Future<PickedTask?> pickTask(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  String? description,
  List<String> exclude = const [],
  String? noneLabel,
}) {
  final search = TextEditingController();
  return showAppSheet<PickedTask>(
    context,
    title: title,
    description: description,
    builder: (ctx) => Consumer(builder: (ctx, ref, _) {
      return StatefulBuilder(builder: (ctx, setState) {
        final p = ctx.pal;
        final tasks = ref.watch(tasksProvider).value ?? const <TaskItem>[];
        final projects = {for (final x in ref.watch(projectsProvider).value ?? const <Project>[]) x.id: x};
        final q = search.text.trim().toLowerCase();
        final list = tasks.where((t) => t.status != 'done' && !exclude.contains(t.id) && (q.isEmpty || t.title.toLowerCase().contains(q))).toList();
        Future<void> create() async {
          final text = search.text.trim();
          if (text.isEmpty) return;
          final t = await ref.read(repositoryProvider).createTask(title: text);
          if (ctx.mounted) Navigator.pop(ctx, PickedTask(t));
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: search,
            autofocus: false,
            decoration: const InputDecoration(hintText: 'Search or create a task', prefixIcon: Icon(Icons.search_rounded, size: 20)),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => list.length == 1 ? Navigator.pop(ctx, PickedTask(list.first)) : create(),
          ),
          const SizedBox(height: 10),
          if (noneLabel != null) _Row(title: noneLabel, muted: true, onTap: () => Navigator.pop(ctx, const PickedTask(null))),
          for (final t in list)
            _Row(
              title: t.title,
              subtitle: t.projectId == null ? null : projects[t.projectId]?.name,
              color: t.projectId == null ? null : colorFromHex(projects[t.projectId]?.color ?? '#7C7CFF'),
              onTap: () => Navigator.pop(ctx, PickedTask(t)),
            ),
          if (q.isNotEmpty && !list.any((t) => t.title.toLowerCase() == q))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Btn('Create “${search.text.trim()}”', icon: Icons.add_rounded, kind: BtnKind.subtle, expand: true, onPressed: create),
            ),
          if (q.isEmpty && list.isEmpty)
            Padding(padding: const EdgeInsets.all(20), child: Text('No open tasks. Type above to create one.', textAlign: TextAlign.center, style: TextStyle(color: p.muted))),
        ]);
      });
    }),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.color, this.muted = false, required this.onTap});
  final String title;
  final String? subtitle;
  final Color? color;
  final bool muted;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(children: [
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w500, color: muted ? p.muted : p.fg))),
          if (subtitle != null) ...[
            if (color != null) ...[Dot(color!, size: 7), const SizedBox(width: 6)],
            Text(subtitle!, style: TextStyle(color: p.muted, fontSize: 12)),
          ],
        ]),
      ),
    );
  }
}
