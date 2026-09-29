import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/enums.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'message_editor.dart';
import 'message_engine.dart';
import 'message_store.dart';

/// Relationship families shown as library filters.
const relationFilters = <String, String>{
  'parent': 'Parents',
  'spouse': 'Wife / Husband',
  'child': 'Children',
  'sibling': 'Siblings',
  'grandparent': 'Grandparents',
  'elder': 'Uncle, Aunt, In-laws',
  'young': 'Niece / Nephew',
  'cousin': 'Cousins',
  'friend': 'Friends',
  'work': 'Work',
};

/// Sample values so placeholders read naturally while browsing.
const sampleContext = MessageContext(
  name: 'Ravi',
  nickname: 'Ravi',
  relation: Relationship.friend,
  age: 60,
  yearsMarried: 25,
  coupleNames: 'Ravi & Priya',
  festival: 'Diwali',
  myName: 'Niranjan',
);

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  Occasion? _occasion = Occasion.birthday;
  String? _relation;
  Tone? _tone;
  Lang _lang = Lang.en;
  bool _favOnly = false;
  bool _mineOnly = false;
  String _q = '';

  @override
  void initState() {
    super.initState();
    ref.read(databaseProvider).getSetting('messageLang').then((v) {
      if (mounted) setState(() => _lang = Lang.parse(v));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lib = ref.watch(libraryProvider).value;
    final users = ref.watch(userMessagesProvider).value ?? const [];
    final favs = {
      ...?ref.watch(favouriteIdsProvider).value,
      for (final u in users)
        if (u.favourite) 'u${u.id}',
    };
    final hidden = {for (final u in users) ?u.baseId};
    final all = [...users.map(userTemplate), ...?lib?.all.where((t) => !hidden.contains(t.id))];
    final list = all.where((t) {
      if (t.lang != _lang) return false;
      if (_occasion != null && t.occasion != _occasion) return false;
      if (_relation != null && !t.relations.contains(_relation) && !t.relations.contains('any')) return false;
      if (_tone != null && t.tone != _tone) return false;
      if (_favOnly && !favs.contains(t.id)) return false;
      if (_mineOnly && !t.custom) return false;
      if (_q.isNotEmpty && !t.text.toLowerCase().contains(_q.toLowerCase())) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final fa = favs.contains(a.id) ? 0 : 1, fb = favs.contains(b.id) ? 0 : 1;
        if (fa != fb) return fa - fb;
        if (a.custom != b.custom) return a.custom ? -1 : 1;
        final ra = _relation != null && a.relations.contains(_relation) ? 0 : 1;
        final rb = _relation != null && b.relations.contains(_relation) ? 0 : 1;
        return ra - rb;
      });

    Widget menuChip<T>(String label, bool active, Map<T, String> items, ValueChanged<T> onSelected) =>
        PopupMenuButton<T>(
          tooltip: label,
          onSelected: onSelected,
          itemBuilder: (_) => [for (final e in items.entries) PopupMenuItem(value: e.key, child: Text(e.value))],
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? c.text : c.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? c.text : c.line),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: context.text.titleSmall?.copyWith(color: active ? c.bg : c.text)),
              Icon(Icons.arrow_drop_down_rounded, size: 18, color: active ? c.bg : c.muted),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          PopupMenuButton<Lang>(
            tooltip: 'Language',
            onSelected: (l) {
              setState(() => _lang = l);
              ref.read(databaseProvider).setSetting('messageLang', l.name);
            },
            itemBuilder: (_) => [for (final l in Lang.values) PopupMenuItem(value: l, child: Text(l.label))],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [Text(_lang.label, style: context.text.titleSmall), const Icon(Icons.translate, size: 18)]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openMessageEditor(context, lang: _lang, occasion: _occasion ?? Occasion.birthday),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Write my own'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search messages'),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              menuChip<Occasion?>(_occasion?.label ?? 'All occasions', _occasion != null,
                  {null: 'All occasions', for (final o in Occasion.values) o: o.label}, (v) => setState(() => _occasion = v)),
              menuChip<String?>(relationFilters[_relation] ?? 'Everyone', _relation != null,
                  {null: 'Everyone', ...relationFilters}, (v) => setState(() => _relation = v)),
              menuChip<Tone?>(_tone?.label ?? 'Any tone', _tone != null,
                  {null: 'Any tone', for (final t in Tone.values) t: t.label}, (v) => setState(() => _tone = v)),
              FilterChip(
                label: const Text('Favourites'),
                selected: _favOnly,
                showCheckmark: false,
                labelStyle: context.text.titleSmall?.copyWith(color: _favOnly ? c.bg : c.text),
                onSelected: (v) => setState(() => _favOnly = v),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('My messages'),
                selected: _mineOnly,
                showCheckmark: false,
                labelStyle: context.text.titleSmall?.copyWith(color: _mineOnly ? c.bg : c.text),
                onSelected: (v) => setState(() => _mineOnly = v),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: Row(children: [
            Text('${list.length} messages', style: context.text.bodySmall),
            const Spacer(),
            Text('Names shown as examples', style: context.text.bodySmall),
          ]),
        ),
        Expanded(
          child: lib == null
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? const Center(
                      child: EmptyState(
                        title: 'No messages here',
                        message: 'Try another filter, or write your own with the button below.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => MessageCard(template: list[i], favourite: favs.contains(list[i].id)),
                    ),
        ),
      ]),
    );
  }
}

class MessageCard extends ConsumerWidget {
  const MessageCard({super.key, required this.template, required this.favourite, this.onUse});

  final MessageTemplate template;
  final bool favourite;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final t = template;
    final store = MessageStore(ref.read(databaseProvider));
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: onUse,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(sampleContext.fill(t.text), style: context.text.bodyLarge),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: Text(
                  [
                    t.tone.label,
                    if (t.festival != null) t.festival!.replaceAll('_', ' '),
                    if (!t.relations.contains('any')) t.relations.map((r) => relationFilters[r] ?? r).join(', '),
                    if (t.custom) 'Mine',
                  ].join(' · '),
                  style: context.text.bodySmall,
                ),
              ),
              IconButton(
                tooltip: favourite ? 'Remove from favourites' : 'Add to favourites',
                onPressed: () => store.toggleFavourite(t, !favourite),
                icon: Icon(favourite ? Icons.star_rounded : Icons.star_outline_rounded, color: favourite ? c.gold : c.muted),
              ),
              IconButton(
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sampleContext.fill(t.text)));
                  showToast(context, 'Copied');
                },
                icon: Icon(Icons.copy_rounded, color: c.muted, size: 20),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => openMessageEditor(context, original: t),
                icon: Icon(Icons.edit_outlined, color: c.muted, size: 20),
              ),
              if (onUse != null)
                TextButton(onPressed: onUse, child: const Text('Use')),
            ]),
          ]),
        ),
      ),
    );
  }
}
