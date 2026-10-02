import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/occurrence.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../festivals/festival_model.dart';
import '../messages/message_engine.dart';
import '../wish/suggest.dart';
import '../wish/wish_service.dart';
import 'wish_mode_repo.dart';

/// One person at a time: photo, name, ready message, and one-tap send.
class WishModeRunner extends ConsumerStatefulWidget {
  const WishModeRunner({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<WishModeRunner> createState() => _WishModeRunnerState();
}

class _WishModeRunnerState extends ConsumerState<WishModeRunner> {
  int? _itemId;
  WishTarget? _target;
  Person? _person;
  Suggestions? _sugg;
  int _msgIndex = 0;
  String _text = '';
  Lang _lang = Lang.en;
  bool _loading = true;
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Day _parse(String s) {
    final p = s.split('-');
    return Day(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// Loads the target and message for [item].
  Future<void> _prepare(WishSession s, WishSessionItem item) async {
    if (_itemId == item.id) return;
    _itemId = item.id;
    setState(() => _loading = true);
    _lang = Lang.parse(await ref.read(databaseProvider).getSetting('messageLang'));
    final repo = ref.read(repoProvider);
    final person = await repo.getPerson(item.personId);
    final date = _parse(s.occasionDate);
    WishTarget t;
    if (s.festivalId != null) {
      final all = await FestivalRepo.loadAll(ref.read(databaseProvider));
      final f = all.where((x) => x.key == s.festivalId).firstOrNull;
      t = WishTarget(
        date: date,
        recipients: [?person],
        about: person,
        festivalId: f?.messageId ?? s.festivalId,
        festivalName: f?.nameIn(_lang.name),
      );
    } else {
      final entry = await repo.watchEntry(item.eventId ?? -1).first;
      t = entry == null
          ? WishTarget(date: date, recipients: [?person], about: person)
          : await targetFor(ref, entry, date);
    }
    final to = t.recipients.firstOrNull ?? person;
    final sugg = await suggestFor(ref, t, to, _lang);
    if (!mounted) return;
    setState(() {
      _target = t;
      _person = to;
      _sugg = sugg;
      _msgIndex = 0;
      _text = item.message ?? (t.entry?.event.draftMessage ?? sugg.textAt(0));
      _loading = false;
    });
  }

  Future<void> _mark(WishSessionItem item, String status) async {
    await WishModeRepo(ref.read(databaseProvider)).setStatus(item.id, status, message: _text);
    HapticFeedback.selectionClick();
  }

  Future<void> _send(WishSessionItem item, String how) async {
    final t = _target, to = _person;
    if (t == null) return;
    final svc = WishService(ref, wishMode: true);
    final tid = _sugg?.idAt(_msgIndex);
    switch (how) {
      case 'whatsapp':
        if (to?.effectiveWhatsapp == null) return showToast(context, 'No WhatsApp number saved');
        final apps = await WishService.installedWhatsapp();
        if (apps.isEmpty) {
          if (mounted) showToast(context, 'WhatsApp is not installed. Try Text.');
          return;
        }
        final app = to!.whatsappApp == 'business' && apps.contains(WhatsappApp.business)
            ? WhatsappApp.business
            : apps.first;
        await svc.whatsapp(t, to, _text, app, templateId: tid);
      case 'sms':
        if (to?.callNumber == null && to?.whatsappNumber == null) return showToast(context, 'No number saved');
        await svc.sms(t, to!, _text, templateId: tid);
      case 'copy':
        await svc.copy(t, to, _text, templateId: tid);
        if (mounted) showToast(context, 'Copied');
      case 'call':
        if (!mounted) return;
        await callTargetWishMode(context, ref, t);
    }
    await _mark(item, 'wished');
  }

  Future<void> _edit() async {
    final c = TextEditingController(text: _text);
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(controller: c, minLines: 4, maxLines: 10, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Done')),
        ],
      ),
    );
    if (r != null && r.trim().isNotEmpty) setState(() => _text = r.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = ref.watch(sessionProvider(widget.sessionId)).value;
    final items = ref.watch(sessionItemsProvider(widget.sessionId)).value;
    if (s == null || items == null) return const Scaffold();
    final done = items.where((i) => i.status != 'pending').length;
    final wished = items.where((i) => i.status == 'wished').length;
    final current = items.where((i) => i.id == _itemId).firstOrNull ??
        items.where((i) => i.status == 'pending').firstOrNull;

    if (current == null || (current.status != 'pending' && items.every((i) => i.status != 'pending') && _itemId == null)) {
      return _finished(s, items, wished);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare(s, current));
    final idx = items.indexOf(current);
    final person = _person;

    void next() {
      final after = items.skip(idx + 1).where((i) => i.status == 'pending').firstOrNull ??
          items.where((i) => i.status == 'pending' && i.id != current.id).firstOrNull;
      if (after == null) {
        WishModeRepo(ref.read(databaseProvider)).finish(s.id);
        _confetti.play();
        setState(() => _itemId = null);
      } else {
        setState(() => _itemId = after.id);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.title),
        actions: [
          TextButton(
            onPressed: () {
              showToast(context, 'Paused. Continue any time from Home.');
              context.pop();
            },
            child: const Text('Pause'),
          ),
        ],
      ),
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
          children: [
            Row(children: [
              Text('$wished of ${items.length} wished', style: context.text.titleMedium),
              const Spacer(),
              Text('${idx + 1} / ${items.length}', style: context.text.bodySmall),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: items.isEmpty ? 0 : done / items.length,
                minHeight: 8,
                color: c.gold,
                backgroundColor: c.raised,
              ),
            ),
            const SizedBox(height: 24),
            if (_loading || person == null)
              const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
            else ...[
              Center(child: PersonAvatar(person: person, size: 110, ring: true)),
              const SizedBox(height: 12),
              Text(person.shortName, textAlign: TextAlign.center, style: context.text.displayMedium),
              Text(
                [
                  person.relationLabel,
                  if (person.callNumber != null) formatPhone(person.callNumber),
                  if (_target?.about != null && _target!.about!.id != person.id) 'for ${_target!.about!.shortName}',
                ].join(' · '),
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
              if (current.status == 'wished')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(child: Badge2('Wished', sparkle: true)),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16)),
                child: Text(_text, style: context.text.bodyLarge),
              ),
              Row(children: [
                TextButton.icon(
                  onPressed: (_sugg?.list.length ?? 0) > 1
                      ? () => setState(() {
                            _msgIndex++;
                            _text = _sugg!.textAt(_msgIndex);
                          })
                      : null,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Change'),
                ),
                TextButton.icon(onPressed: _edit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit')),
              ]),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8,
                children: [
                  _Action(Icons.chat_rounded, 'WhatsApp', const Color(0xFF25A35A), () => _send(current, 'whatsapp')),
                  _Action(Icons.sms_outlined, 'Text', const Color(0xFF5E86B8), () => _send(current, 'sms')),
                  _Action(Icons.copy_rounded, 'Copy', const Color(0xFF6E685D), () => _send(current, 'copy')),
                  _Action(Icons.call_rounded, 'Call', c.call, () => _send(current, 'call')),
                ],
              ),
            ],
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  if (current.status == 'pending') await _mark(current, 'skipped');
                  next();
                },
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () async {
                  if (current.status == 'pending') await _mark(current, 'wished');
                  next();
                },
                child: Text(current.status == 'wished' ? 'Next' : 'Wished · Next'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _finished(WishSession s, List<WishSessionItem> items, int wished) {
    final skipped = items.where((i) => i.status == 'skipped').toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: Stack(children: [
        Center(
          child: EmptyState(
            title: 'All done! 🎉',
            message: 'You wished $wished of ${items.length} people.'
                '${skipped.isEmpty ? '' : ' ${skipped.length} skipped.'}',
            actionLabel: skipped.isEmpty ? 'Back to Home' : 'Go back to the skipped ones',
            onAction: () async {
              if (skipped.isEmpty) {
                await WishModeRepo(ref.read(databaseProvider)).finish(s.id);
                if (mounted) context.go('/home');
              } else {
                for (final i in skipped) {
                  await WishModeRepo(ref.read(databaseProvider)).setStatus(i.id, 'pending');
                }
                setState(() => _itemId = null);
              }
            },
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive),
        ),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.color, this.onTap);

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: context.c.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: context.text.titleMedium),
          ]),
        ),
      );
}

/// Call from Wish Mode: counts as wished, no chip.
Future<void> callTargetWishMode(BuildContext context, WidgetRef ref, WishTarget t) async {
  final to = t.recipients.where((p) => p.callNumber != null).firstOrNull;
  if (to == null) {
    showToast(context, 'No phone number saved');
    return;
  }
  await WishService(ref, wishMode: true).call(t, to);
}
