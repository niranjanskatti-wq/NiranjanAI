import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'message_editor.dart';
import 'message_engine.dart';
import 'message_store.dart';

/// Prepare the message for an event days in advance; Share then uses it.
class EventMessageScreen extends ConsumerStatefulWidget {
  const EventMessageScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<EventMessageScreen> createState() => _EventMessageScreenState();
}

class _EventMessageScreenState extends ConsumerState<EventMessageScreen> {
  final _text = TextEditingController();
  Lang _lang = Lang.en;
  List<MessageTemplate> _suggestions = const [];
  MessageContext? _ctx;
  bool _loaded = false;
  AgeInWishes _ageWhere = AgeInWishes.start;
  AgeLines _own = const AgeLines();

  /// A suggestion filled in, with "Happy 60th birthday" when that's switched on.
  String _fill(MessageContext ctx, String text) => ctx.withAge(ctx.fill(text), _lang, _ageWhere, _own);

  Future<void> _load(EventEntry e) async {
    _loaded = true;
    final db = ref.read(databaseProvider);
    _lang = Lang.parse(await db.getSetting('messageLang'));
    _ageWhere = AgeInWishes.parse(await db.getSetting('ageInWishes'));
    _own = await AgeLines.load(db);
    _text.text = e.event.draftMessage ?? '';
    await _refresh(e);
  }

  Future<void> _refresh(EventEntry e) async {
    final repo = ref.read(repoProvider);
    final lib = await MessageLibrary.load();
    final prefs = await MessagePrefs.load(ref.read(databaseProvider));
    final me = await repo.getMe();
    final today = Day.today();
    final next = e.nextFrom(today) ?? today;
    final u = Upcoming(e, next, 0);
    final ctx = MessageContext.forEntry(e, years: u.years, me: me);
    final person = e.people.where((p) => !p.isMe).firstOrNull;
    final sent = person == null ? const <String>{} : sentKeys(await repo.wishLogsFor(person.id));
    final list = lib.suggest(
      occasions: occasionsFor(e, milestone: u.milestone),
      lang: _lang,
      ctx: ctx,
      alreadySent: sent,
      extra: prefs.extra,
      hidden: prefs.hidden,
      favourites: prefs.favourites,
    );
    if (mounted) {
      setState(() {
        _ctx = ctx;
        _suggestions = list;
      });
    }
  }

  void _surprise() {
    final ctx = _ctx;
    if (ctx == null || _suggestions.isEmpty) return;
    // Pick among the best unsent few so it feels fresh but still fitting.
    final pool = _suggestions.take(min(6, _suggestions.length)).toList();
    final pick = pool[Random().nextInt(pool.length)];
    setState(() => _text.text = _fill(ctx, pick.text));
    HapticFeedback.selectionClick();
  }

  Future<void> _save(int eventId) async {
    final text = _text.text.trim();
    await ref.read(repoProvider).updateEvent(eventId, EventsCompanion(draftMessage: Value(text.isEmpty ? null : text)));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context, text.isEmpty ? 'Prepared message cleared' : 'Saved. Share will use it.');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final e = ref.watch(entryProvider(widget.eventId)).value;
    if (e == null) return const Scaffold();
    if (!_loaded) _load(e);
    return Scaffold(
      appBar: AppBar(title: const Text('Prepare message')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          Text('${e.title} · ${e.typeLabel}', style: context.text.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Write your message, or pick one below'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            FilledButton.tonalIcon(
              onPressed: _suggestions.isEmpty ? null : _surprise,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Surprise me'),
            ),
            const Spacer(),
            PopupMenuButton<Lang>(
              tooltip: 'Language',
              onSelected: (l) {
                setState(() => _lang = l);
                _refresh(e);
              },
              itemBuilder: (_) => [for (final l in Lang.values) PopupMenuItem(value: l, child: Text(l.label))],
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [Text(_lang.label, style: context.text.titleSmall), const Icon(Icons.arrow_drop_down)]),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          SectionLabel('Suggestions for ${e.title}'),
          if (_ctx != null)
            for (final t in _suggestions.take(25))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.card),
                    onTap: () => setState(() => _text.text = _fill(_ctx!, t.text)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_fill(_ctx!, t.text), style: context.text.bodyMedium),
                        const SizedBox(height: 4),
                        Text('${t.tone.label}${t.custom ? ' · Mine' : ''} · tap to use', style: context.text.bodySmall),
                      ]),
                    ),
                  ),
                ),
              ),
          TextButton.icon(
            onPressed: () => openMessageEditor(context, lang: _lang),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Write a reusable message for the library'),
          ),
          Text('Messages already sent to them go to the bottom, so you don\'t repeat yourself.',
              style: context.text.bodySmall?.copyWith(color: c.muted)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: () => _save(e.event.id), child: const Text('Save for this event')),
        ),
      ),
    );
  }
}
