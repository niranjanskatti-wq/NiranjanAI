import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../messages/message_engine.dart';
import '../messages/message_store.dart';
import 'wish_service.dart';

/// Ready-to-send messages for a target and recipient, best first.
class Suggestions {
  Suggestions(this.ctx, this.list, this.occasions);

  final MessageContext ctx;
  final List<MessageTemplate> list;
  final List<Occasion> occasions;

  String textAt(int i) => list.isEmpty ? fallbackMessage(ctx, occasions.first) : ctx.fill(list[i % list.length].text);
  String? idAt(int i) => list.isEmpty ? null : list[i % list.length].id;
}

Future<Suggestions> suggestFor(WidgetRef ref, WishTarget t, Person? to, Lang lang) async {
  final repo = ref.read(repoProvider);
  final lib = await MessageLibrary.load();
  final prefs = await MessagePrefs.load(ref.read(databaseProvider));
  final me = await repo.getMe();
  final logs = to == null ? const <WishLog>[] : await repo.wishLogsFor(to.id);
  final MessageContext ctx;
  if (t.entry != null) {
    ctx = MessageContext.forEntry(t.entry!, years: t.years, me: me, festival: t.festivalName);
  } else {
    final p = t.about ?? to;
    ctx = MessageContext(
      name: p?.name.trim().split(RegExp(r'\s+')).first,
      nickname: p?.shortName,
      relation: p?.relation,
      festival: t.festivalName,
      myName: me?.name.trim().split(RegExp(r'\s+')).first,
    );
  }
  final occasions = t.festivalId != null
      ? [Occasion.festival]
      : t.entry == null
          ? [Occasion.general]
          : occasionsFor(t.entry!, milestone: t.milestone, belated: t.belated);
  final list = lib.suggest(
    occasions: occasions,
    lang: lang,
    ctx: ctx,
    alreadySent: sentKeys(logs),
    festivalId: t.festivalId,
    extra: prefs.extra,
    hidden: prefs.hidden,
    favourites: prefs.favourites,
  );
  return Suggestions(ctx, list, occasions);
}
