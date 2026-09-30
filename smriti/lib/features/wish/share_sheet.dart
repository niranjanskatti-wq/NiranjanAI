import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/occurrence.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../cards/card_screen.dart';
import '../events/age_input.dart';
import '../messages/message_engine.dart';
import '../messages/message_store.dart';
import 'wish_service.dart';

/// Preferred message language, remembered in settings.
final messageLangProvider = StreamProvider<Lang>(
    (ref) => ref.watch(databaseProvider).watchSetting('messageLang').map((v) => Lang.parse(v)));

/// Where to put "Happy 60th birthday" in wishes (Settings › Messages).
final ageInWishesProvider = StreamProvider<AgeInWishes>(
    (ref) => ref.watch(databaseProvider).watchSetting('ageInWishes').map(AgeInWishes.parse));

/// Call: picks the recipient if there are several, then dials.
Future<void> callTarget(BuildContext context, WidgetRef ref, WishTarget t) async {
  final withNumber = t.recipients.where((p) => p.callNumber != null).toList();
  if (withNumber.isEmpty) {
    showToast(context, 'No phone number saved. Add one on their profile.');
    return;
  }
  var to = withNumber.first;
  if (withNumber.length > 1) {
    final chosen = await showModalBottomSheet<Person>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Call who?', style: ctx.text.headlineMedium)),
          ),
          for (final p in withNumber)
            ListTile(
              leading: PersonAvatar(person: p, size: 40),
              title: Text(p.shortName),
              subtitle: Text(formatPhone(p.callNumber)),
              onTap: () => Navigator.pop(ctx, p),
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (chosen == null) return;
    to = chosen;
  }
  await WishService(ref).call(t, to);
}

Future<void> showShareSheet(BuildContext context, WidgetRef ref, WishTarget t) => showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(target: t),
    );

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.target});

  final WishTarget target;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  List<MessageTemplate> _suggestions = const [];
  int _index = 0;
  String _text = '';
  String? _templateId;
  Lang _lang = Lang.en;
  Person? _to;
  bool _loading = true;
  bool _fromDraft = false;

  /// Age line in the message: from the setting, switched per wish with the chip.
  AgeInWishes _ageWhere = AgeInWishes.start;
  bool _age = true;
  AgeLines _own = const AgeLines();

  /// Age or years typed in here when the year wasn't saved.
  int? _years;

  WishTarget get t => widget.target;

  /// A suggestion filled in, with the age line when it's switched on.
  String _fill(MessageContext ctx, String text) {
    final filled = ctx.fill(text);
    return _age ? ctx.withAge(filled, _lang, _ageWhere, _own) : filled;
  }

  @override
  void initState() {
    super.initState();
    _to = t.recipients.firstOrNull;
    _init();
  }

  Future<void> _init() async {
    _lang = Lang.parse(await ref.read(databaseProvider).getSetting('messageLang'));
    _ageWhere = AgeInWishes.parse(await ref.read(databaseProvider).getSetting('ageInWishes'));
    _age = _ageWhere != AgeInWishes.off;
    _own = await AgeLines.load(ref.read(databaseProvider));
    final draft = t.entry?.event.draftMessage;
    if (draft != null && draft.trim().isNotEmpty && !t.belated) {
      _text = draft;
      _fromDraft = true;
    }
    await _loadSuggestions(keepText: _fromDraft);
  }

  MessageContext _ctx(Person? me) {
    if (t.entry != null) {
      return MessageContext.forEntry(t.entry!, years: _years ?? t.years, me: me, festival: t.festivalName);
    }
    final p = t.about ?? _to;
    return MessageContext(
      name: p?.name.trim().split(RegExp(r'\s+')).first,
      nickname: p?.shortName,
      relation: p?.relation,
      festival: t.festivalName,
      myName: me?.name.trim().split(RegExp(r'\s+')).first,
    );
  }

  List<Occasion> get _occasions {
    if (t.festivalId != null) return [Occasion.festival];
    if (t.entry == null) return [Occasion.general];
    return occasionsFor(t.entry!, milestone: t.milestone, belated: t.belated);
  }

  Future<void> _loadSuggestions({bool keepText = false}) async {
    final lib = await MessageLibrary.load();
    final prefs = await MessagePrefs.load(ref.read(databaseProvider));
    final repo = ref.read(repoProvider);
    final me = await repo.getMe();
    final logs = _to == null ? const <WishLog>[] : await repo.wishLogsFor(_to!.id);
    final ctx = _ctx(me);
    final list = lib.suggest(
      occasions: _occasions,
      lang: _lang,
      ctx: ctx,
      alreadySent: sentKeys(logs),
      festivalId: t.festivalId,
      extra: prefs.extra,
      hidden: prefs.hidden,
      favourites: prefs.favourites,
    );
    if (!mounted) return;
    setState(() {
      _suggestions = list;
      _index = 0;
      if (!keepText) {
        _templateId = list.firstOrNull?.id;
        _text = list.isEmpty ? _fill(ctx, fallbackMessage(ctx, _occasions.first)) : _fill(ctx, list.first.text);
      }
      _loading = false;
    });
  }

  Future<void> _next() async {
    if (_suggestions.isEmpty) return;
    final me = await ref.read(repoProvider).getMe();
    setState(() {
      _fromDraft = false;
      _index = (_index + 1) % _suggestions.length;
      _templateId = _suggestions[_index].id;
      _text = _fill(_ctx(me), _suggestions[_index].text);
    });
  }

  /// A fitting message picked at random from the best unsent ones.
  Future<void> _surprise() async {
    if (_suggestions.isEmpty) return;
    final me = await ref.read(repoProvider).getMe();
    final pool = min(6, _suggestions.length);
    var i = Random().nextInt(pool);
    if (pool > 1 && i == _index) i = (i + 1) % pool;
    setState(() {
      _fromDraft = false;
      _index = i;
      _templateId = _suggestions[i].id;
      _text = _fill(_ctx(me), _suggestions[i].text);
    });
  }

  Future<void> _edit() async {
    final c = TextEditingController(text: _text);
    var save = false;
    final canSave = t.entry != null && !t.belated;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Edit message'),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: c,
                minLines: 4,
                maxLines: 10,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              if (canSave)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: save,
                  onChanged: (v) => setD(() => save = v ?? false),
                  title: const Text('Save for this event'),
                  subtitle: const Text('Used automatically next time you share'),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Done')),
          ],
        ),
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    setState(() {
      _text = result.trim();
      _templateId = null;
    });
    if (save && t.entry != null) {
      await (ref.read(databaseProvider).update(ref.read(databaseProvider).events)
            ..where((e) => e.id.equals(t.entry!.event.id)))
          .write(EventsCompanion(draftMessage: Value(_text)));
      if (mounted) showToast(context, 'Saved for this event');
    }
  }

  /// "🎂 60th" to add or take out the age line, or "Add age" when the year isn't known.
  Widget _ageChip(BuildContext context) {
    final e = t.entry;
    if (e == null || t.festivalId != null) return const SizedBox.shrink();
    final birthday = e.type == EventType.birthday;
    if (!birthday && !e.type.isAnniversaryLike) return const SizedBox.shrink();
    final years = _years ?? t.years;
    if (years == null || years <= 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.cake_outlined, size: 18),
          label: Text(birthday ? 'Add age' : 'Add years married'),
          onPressed: _askAge,
        ),
      );
    }
    return Row(children: [
      FilterChip(
        avatar: Text(birthday ? '🎂' : '💞'),
        label: Text('Mention ${ordinal(years)}${birthday ? ' birthday' : ' anniversary'}'),
        selected: _age,
        showCheckmark: false,
        onSelected: (on) async {
          final me = await ref.read(repoProvider).getMe();
          final ctx = _ctx(me);
          setState(() {
            _age = on;
            _text = on
                ? ctx.withAge(_text, _lang, _ageWhere == AgeInWishes.off ? AgeInWishes.start : _ageWhere, _own)
                : ctx.withoutAge(_text, _lang, _own);
          });
        },
      ),
      TextButton.icon(
        onPressed: _askAge,
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: Text(birthday ? 'Correct age' : 'Correct years'),
      ),
    ]);
  }

  /// Asks how old they are turning (or years married) and saves the year.
  Future<void> _askAge() async {
    final e = t.entry!;
    final birthday = e.type == EventType.birthday;
    final date = t.date;
    final years =
        await askYears(context, birthday: birthday, name: e.title, on: date, initial: _years ?? t.years);
    if (years == null || !mounted) return;
    await saveYears(ref.read(repoProvider), e, years, date);
    final me = await ref.read(repoProvider).getMe();
    // Take out the line with the old age before adding the new one.
    final without = _ctx(me).withoutAge(_text, _lang, _own);
    setState(() {
      _years = years;
      _age = true;
      if (_ageWhere == AgeInWishes.off) _ageWhere = AgeInWishes.start;
    });
    final ctx = _ctx(me);
    setState(() => _text = ctx.withAge(without, _lang, _ageWhere, _own));
  }

  Future<void> _setLang(Lang l) async {
    await ref.read(databaseProvider).setSetting('messageLang', l.name);
    setState(() {
      _lang = l;
      _fromDraft = false;
    });
    await _loadSuggestions();
  }

  Future<void> _whatsapp() async {
    final to = _to;
    if (to?.effectiveWhatsapp == null) {
      showToast(context, 'No WhatsApp number saved. Try Copy instead.');
      return;
    }
    final apps = await WishService.installedWhatsapp();
    if (!mounted) return;
    if (apps.isEmpty) {
      showToast(context, 'WhatsApp is not installed. Try Text Message instead.');
      return;
    }
    var app = apps.first;
    final pref = to!.whatsappApp;
    if (apps.length > 1) {
      if (pref == 'business') {
        app = WhatsappApp.business;
      } else if (pref == 'whatsapp') {
        app = WhatsappApp.whatsapp;
      } else {
        final chosen = await showModalBottomSheet<WhatsappApp>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(title: const Text('WhatsApp'), onTap: () => Navigator.pop(ctx, WhatsappApp.whatsapp)),
              ListTile(title: const Text('WhatsApp Business'), onTap: () => Navigator.pop(ctx, WhatsappApp.business)),
              const SizedBox(height: 8),
            ]),
          ),
        );
        if (chosen == null) return;
        app = chosen;
        await ref.read(repoProvider).updatePerson(
            to.id, PeopleCompanion(whatsappApp: Value(chosen == WhatsappApp.business ? 'business' : 'whatsapp')));
      }
    }
    await WishService(ref).whatsapp(t, to, _text, app, templateId: _templateId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _sms() async {
    final to = _to;
    if (to?.callNumber == null && to?.whatsappNumber == null) {
      showToast(context, 'No phone number saved. Try Copy instead.');
      return;
    }
    await WishService(ref).sms(t, to!, _text, templateId: _templateId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _copy() async {
    await WishService(ref).copy(t, _to, _text, templateId: _templateId);
    if (!mounted) return;
    showToast(context, 'Copied');
    Navigator.pop(context);
  }

  Future<void> _card() async {
    final me = await ref.read(repoProvider).getMe();
    if (!mounted) return;
    final router = GoRouter.of(context);
    final req = CardRequest(cardDataFor(t, message: _text, me: me, to: _to), target: t, to: _to);
    Navigator.pop(context);
    router.push('/card', extra: req);
  }

  Future<void> _more() async {
    final svc = WishService(ref);
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('WhatsApp group'),
            subtitle: const Text('Choose a family group in WhatsApp'),
            onTap: () => Navigator.pop(ctx, 'group'),
          ),
          ListTile(leading: const Icon(Icons.send_outlined), title: const Text('Telegram'), onTap: () => Navigator.pop(ctx, 'telegram')),
          ListTile(leading: const Icon(Icons.mail_outline), title: const Text('Email'), onTap: () => Navigator.pop(ctx, 'email')),
          ListTile(leading: const Icon(Icons.ios_share), title: const Text('Other apps'), onTap: () => Navigator.pop(ctx, 'share')),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    var ok = true;
    switch (choice) {
      case 'group':
        ok = await svc.sendToApp(t, _to, _text, 'com.whatsapp', 'whatsapp') ||
            await svc.sendToApp(t, _to, _text, 'com.whatsapp.w4b', 'whatsapp');
      case 'telegram':
        ok = await svc.sendToApp(t, _to, _text, 'org.telegram.messenger', 'telegram');
      case 'email':
        await svc.email(t, _to, _text, t.entry?.typeLabel ?? 'Wishes');
      case 'share':
        await svc.systemShare(t, _to, _text);
    }
    if (!mounted) return;
    if (!ok) {
      showToast(context, 'That app is not installed.');
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final to = _to;
    final forOther = t.about != null && to != null && t.about!.id != to.id;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.belated ? 'Belated wishes' : 'Wish ${t.title}', style: context.text.headlineMedium),
              if (forOther)
                Text('Sending to ${to.shortName} (${to.relationLabel}) for ${t.about!.shortName}',
                    style: context.text.bodySmall),
              if (t.recipients.length > 1) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final p in t.recipients)
                    ChoiceChip(
                      avatar: PersonAvatar(person: p, size: 22),
                      label: Text(p.shortName),
                      selected: p.id == to?.id,
                      showCheckmark: false,
                      labelStyle: context.text.titleSmall?.copyWith(color: p.id == to?.id ? c.bg : c.text),
                      onSelected: (_) {
                        setState(() => _to = p);
                        _loadSuggestions(keepText: true);
                      },
                    ),
                ]),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16)),
                child: _loading
                    ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
                    : SelectableText(_text, style: context.text.bodyLarge),
              ),
              Row(children: [
                TextButton.icon(
                  onPressed: _suggestions.length > 1 ? _next : null,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Change'),
                ),
                TextButton.icon(onPressed: _edit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit')),
                IconButton(
                  tooltip: 'Surprise me',
                  onPressed: _suggestions.length > 1 ? _surprise : null,
                  icon: Icon(Icons.auto_awesome, color: c.goldText),
                ),
                const Spacer(),
                PopupMenuButton<Lang>(
                  tooltip: 'Language',
                  initialValue: _lang,
                  onSelected: _setLang,
                  itemBuilder: (_) => [for (final l in Lang.values) PopupMenuItem(value: l, child: Text(l.label))],
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      Text(_lang.short, style: context.text.titleSmall?.copyWith(color: c.muted)),
                      Icon(Icons.arrow_drop_down_rounded, color: c.muted),
                    ]),
                  ),
                ),
              ]),
              if (_fromDraft)
                Text('Your saved message for this event', style: context.text.bodySmall),
              if (!_loading) _ageChip(context),
              const SizedBox(height: 8),
              _BigOption(
                color: const Color(0xFF25A35A),
                icon: Icons.chat_rounded,
                title: 'WhatsApp',
                subtitle: to?.effectiveWhatsapp == null
                    ? 'No number saved'
                    : "Opens ${to!.shortName}'s chat with the message ready",
                onTap: _whatsapp,
              ),
              const SizedBox(height: 8),
              _BigOption(
                color: const Color(0xFF5E86B8),
                icon: Icons.sms_outlined,
                title: 'Text message',
                subtitle: (to?.callNumber ?? to?.whatsappNumber) == null
                    ? 'No number saved'
                    : 'Opens SMS to ${formatPhone(to!.callNumber ?? to.whatsappNumber)}',
                onTap: _sms,
              ),
              const SizedBox(height: 8),
              _BigOption(
                color: const Color(0xFF6E685D),
                icon: Icons.copy_rounded,
                title: 'Copy message',
                subtitle: 'Paste it anywhere',
                onTap: _copy,
              ),
              const SizedBox(height: 8),
              _BigOption(
                color: const Color(0xFFB08A45),
                icon: Icons.image_outlined,
                title: 'Greeting card',
                subtitle: 'Turn this message into a picture',
                onTap: _card,
              ),
              const SizedBox(height: 4),
              TextButton(onPressed: _more, child: const Text('More: WhatsApp group · Telegram · Email · Other apps')),
              Text(
                'You tap Send inside WhatsApp or Messages. If WhatsApp says the number is not on WhatsApp, use Text message.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigOption extends StatelessWidget {
  const _BigOption({required this.color, required this.icon, required this.title, required this.subtitle, required this.onTap});

  final Color color;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: context.text.titleLarge),
                Text(subtitle, style: context.text.bodySmall),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
