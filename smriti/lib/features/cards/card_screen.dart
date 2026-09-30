import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../wish/wish_service.dart';
import 'card_templates.dart';

/// What the card screen needs: the words, and the wish to log when shared.
class CardRequest {
  const CardRequest(this.data, {this.target, this.to});

  final CardData data;
  final WishTarget? target;
  final Person? to;
}

String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

/// Sensible first words for a card about [t].
CardData cardDataFor(WishTarget t, {String message = '', Person? me, Person? to}) {
  final e = t.entry;
  final years = t.years;
  var kind = CardKind.general;
  String headline;
  if (t.festivalId != null || e?.type == EventType.festival) {
    kind = CardKind.festival;
    final f = (t.festivalName ?? e?.title ?? 'Festival').split(' (').first.replaceAll(' begins', '');
    headline = 'Happy $f';
  } else if (e == null) {
    headline = 'Best wishes';
  } else {
    switch (e.type) {
      case EventType.birthday:
        kind = t.milestone ? CardKind.milestone : CardKind.birthday;
        headline = years != null && years > 0 ? 'Happy ${ordinal(years)} Birthday' : 'Happy Birthday';
      case EventType.weddingAnniversary || EventType.firstMeeting:
        kind = t.milestone ? CardKind.milestone : CardKind.anniversary;
        headline = years != null && years > 0 ? 'Happy ${ordinal(years)} Anniversary' : 'Happy Anniversary';
      case EventType.engagement:
        kind = CardKind.anniversary;
        headline = 'Happy Engagement Anniversary';
      case EventType.workAnniversary:
        headline = years != null && years > 0 ? 'Happy ${ordinal(years)} Work Anniversary' : 'Happy Work Anniversary';
      case EventType.graduation:
        headline = 'Congratulations';
      default:
        headline = (e.event.customLabel?.trim().isNotEmpty ?? false) ? e.event.customLabel!.trim() : 'Best wishes';
    }
  }
  if (t.belated) headline = 'Belated ${headline.replaceFirst('Happy ', '').toLowerCase()} wishes';
  final people = e?.people.where((p) => !p.isMe).toList() ?? const <Person>[];
  final name = people.isNotEmpty ? people.map((p) => p.shortName).join(' & ') : (t.about ?? to)?.shortName ?? '';
  return CardData(
    kind: kind,
    headline: headline,
    name: name,
    message: message,
    footer: me == null ? '' : '— ${_first(me.name)}',
    years: years,
    festivalId: t.festivalId,
  );
}

/// Opens the card maker for a wish.
Future<void> openCardFor(BuildContext context, WidgetRef ref, WishTarget t, {String message = '', Person? to}) async {
  final me = await ref.read(repoProvider).getMe();
  if (!context.mounted) return;
  await context.push(
    '/card',
    extra: CardRequest(
      cardDataFor(t, message: message, me: me, to: to),
      target: t,
      to: to,
    ),
  );
}

/// Pick a design, adjust the words, then share or save the picture.
class CardStudioScreen extends ConsumerStatefulWidget {
  const CardStudioScreen({super.key, required this.request});

  final CardRequest request;

  @override
  ConsumerState<CardStudioScreen> createState() => _CardStudioScreenState();
}

class _CardStudioScreenState extends ConsumerState<CardStudioScreen> {
  final _key = GlobalKey();
  late CardData _d = widget.request.data;
  late final List<CardTemplate> _designs = templatesFor(_d);
  late CardTemplate _t = _designs.first;
  bool _busy = false;

  Future<Uint8List> _capture() async {
    final b = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 1080 / b.size.width);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  String get _fileName => 'Smriti card ${DateTime.now().millisecondsSinceEpoch}.png';

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      HapticFeedback.lightImpact();
      final name = _fileName;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: name, mimeType: 'image/png')],
          fileNameOverrides: [name],
        ),
      );
      final t = widget.request.target;
      if (t != null) await WishService(ref).cardShared(t, widget.request.to, _d.message);
    } catch (e) {
      if (mounted) showToast(context, 'Could not share: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (!await Gal.hasAccess(toAlbum: true)) await Gal.requestAccess(toAlbum: true);
      await Gal.putImageBytes(bytes, album: 'Smriti', name: _fileName.replaceAll('.png', ''));
      HapticFeedback.lightImpact();
      if (mounted) showToast(context, 'Saved to Gallery › Smriti');
    } catch (e) {
      if (mounted) showToast(context, 'Could not save: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _edit() async {
    final head = TextEditingController(text: _d.headline);
    final name = TextEditingController(text: _d.name);
    final msg = TextEditingController(text: _d.message);
    final foot = TextEditingController(text: _d.footer);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Words on the card', style: ctx.text.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: head,
                decoration: const InputDecoration(labelText: 'Top line'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: msg,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: foot,
                decoration: const InputDecoration(labelText: 'Signed'),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      setState(
        () => _d = _d.copyWith(
          headline: head.text.trim(),
          name: name.text.trim(),
          message: msg.text.trim(),
          footer: foot.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Greeting card'),
        actions: [TextButton.icon(onPressed: _edit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Words'))],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: GestureDetector(
                  onTap: _edit,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: RepaintBoundary(
                      key: _key,
                      child: GreetingCard(template: _t, data: _d),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _designs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final t = _designs[i];
                final on = t.id == _t.id;
                return GestureDetector(
                  onTap: () => setState(() => _t = t),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        decoration: BoxDecoration(
                          border: Border.all(color: on ? c.gold : c.line, width: on ? 2.5 : 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: GreetingCard(
                            template: t,
                            data: _d.copyWith(message: ''),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 80,
                        child: Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.text.labelSmall?.copyWith(color: on ? c.text : c.muted),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share picture'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
