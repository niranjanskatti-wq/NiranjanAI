import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';

/// Languages the library ships with.
enum Lang {
  en('English', 'EN'),
  hi('हिन्दी', 'हि'),
  kn('ಕನ್ನಡ', 'ಕ');

  const Lang(this.label, this.short);
  final String label, short;

  static Lang parse(String? v) => Lang.values.firstWhere((l) => l.name == v, orElse: () => Lang.en);
}

/// Occasion a message is written for (matches "occasion" in assets/messages/*.json).
enum Occasion {
  birthday('Birthday'),
  milestoneBirthday('Milestone birthday'),
  anniversary('Anniversary (spouse)'),
  coupleAnniversary('Couple anniversary'),
  workAnniversary('Work anniversary'),
  engagement('Engagement'),
  congratulations('Congratulations'),
  belated('Belated wishes'),
  festival('Festival'),
  thankYou('Thank you'),
  general('General');

  const Occasion(this.label);
  final String label;

  String get key => switch (this) {
        milestoneBirthday => 'milestone_birthday',
        coupleAnniversary => 'couple_anniversary',
        workAnniversary => 'work_anniversary',
        thankYou => 'thank_you',
        _ => name,
      };

  static Occasion? parse(String v) => Occasion.values.where((o) => o.key == v).firstOrNull;
}

/// Where the "Happy 60th birthday" line goes in a wish.
enum AgeInWishes {
  start('At the start'),
  end('At the end'),
  off('Don\'t add');

  const AgeInWishes(this.label);
  final String label;

  static AgeInWishes parse(String? v) => AgeInWishes.values.asNameMap()[v] ?? AgeInWishes.start;
}

/// Your own wording for the age line, with {age_th}, {age}, {years_th},
/// {years_married}, {nickname} filled in. Null uses Smriti's line.
class AgeLines {
  const AgeLines({this.birthday, this.anniversary});
  final String? birthday, anniversary;

  static Future<AgeLines> load(AppDatabase db) async =>
      AgeLines(birthday: await db.getSetting('ageLineBirthday'), anniversary: await db.getSetting('ageLineAnniversary'));

  static const birthdayDefault = 'Happy {age_th} birthday, {nickname}! 🎂';
  static const anniversaryDefault = 'Happy {years_th} anniversary! {years_married} beautiful years together 💞';
}

enum Tone {
  emotional('Emotional'),
  funny('Funny'),
  short('Short & Sweet'),
  formal('Formal'),
  poetic('Poetic'),
  blessing('Blessing');

  const Tone(this.label);
  final String label;

  static Tone parse(String? v) => Tone.values.firstWhere((t) => t.name == v, orElse: () => Tone.short);
}

/// Relationship families used to tag messages.
String relationGroup(Relationship r) => switch (r) {
      Relationship.father || Relationship.mother => 'parent',
      Relationship.wife || Relationship.husband => 'spouse',
      Relationship.son || Relationship.daughter => 'child',
      Relationship.brother || Relationship.sister => 'sibling',
      Relationship.grandfather || Relationship.grandmother => 'grandparent',
      Relationship.uncle || Relationship.aunt || Relationship.inLaw => 'elder',
      Relationship.niece || Relationship.nephew => 'young',
      Relationship.cousin => 'cousin',
      Relationship.bestFriend || Relationship.friend || Relationship.neighbour => 'friend',
      Relationship.colleague || Relationship.boss || Relationship.client || Relationship.mentor => 'work',
      Relationship.custom || Relationship.self => 'any',
    };

class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.occasion,
    required this.relations,
    required this.tone,
    required this.lang,
    required this.text,
    this.festival,
    this.custom = false,
  });

  final String id;
  final Occasion occasion;
  final List<String> relations; // relation names, groups, or "any"
  final Tone tone;
  final Lang lang;
  final String text;
  final String? festival; // festival id for festival messages
  final bool custom;

  static MessageTemplate? fromJson(Map<String, dynamic> j, Lang lang) {
    final occ = Occasion.parse(j['occasion'] as String? ?? '');
    if (occ == null) return null;
    return MessageTemplate(
      id: j['id'] as String,
      occasion: occ,
      relations: [for (final r in (j['relations'] as List? ?? const ['any'])) r as String],
      tone: Tone.parse(j['tone'] as String?),
      lang: lang,
      text: j['text'] as String,
      festival: j['festival'] as String?,
    );
  }

  /// 3 = exact relation, 2 = relation family, 1 = anyone, 0 = not suitable.
  int fit(Relationship? r) {
    if (r == null) return relations.contains('any') ? 1 : 0;
    if (relations.contains(r.name)) return 3;
    if (relations.contains(relationGroup(r))) return 2;
    return relations.contains('any') ? 1 : 0;
  }

  Set<String> get placeholders => RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();
}

/// Values for {name}, {age}… when filling a message.
class MessageContext {
  const MessageContext({
    this.name,
    this.nickname,
    this.relation,
    this.age,
    this.yearsMarried,
    this.coupleNames,
    this.festival,
    this.myName,
    this.type,
  });

  final String? name, nickname, coupleNames, festival, myName;
  final Relationship? relation;
  final int? age, yearsMarried;

  /// The occasion, used for the age line ("Happy 60th birthday").
  final EventType? type;

  /// A warm opening line with the age or years, e.g. "Happy 60th birthday, Appa! 🎂".
  /// Null when the age isn't known.
  String? ageLine(Lang lang, [AgeLines own = const AgeLines()]) {
    final who = nickname ?? name;
    final a = age, y = yearsMarried;
    // Your own wording from Settings › Wishes, with the age filled in.
    final mine = a != null && a > 0
        ? own.birthday
        : (y != null && y > 0 && type != EventType.workAnniversary ? own.anniversary : null);
    if (mine != null && mine.trim().isNotEmpty) return fill(mine.trim());
    if (a != null && a > 0) {
      return switch (lang) {
        Lang.en => 'Happy ${ordinal(a)} birthday${who == null ? '' : ', $who'}! 🎂',
        Lang.hi => '${who == null ? '' : '$who, '}आपको $aवें जन्मदिन की हार्दिक शुभकामनाएँ! 🎂',
        Lang.kn => '${who == null ? '' : '$who, '}$aನೇ ಹುಟ್ಟುಹಬ್ಬದ ಹಾರ್ದಿಕ ಶುಭಾಶಯಗಳು! 🎂',
      };
    }
    if (y != null && y > 0) {
      if (type == EventType.workAnniversary) {
        return switch (lang) {
          Lang.en => 'Congratulations on $y ${y == 1 ? 'year' : 'years'}! 🎉',
          Lang.hi => '$y साल पूरे होने पर हार्दिक बधाई! 🎉',
          Lang.kn => '$y ವರ್ಷಗಳ ಸೇವೆಗೆ ಹಾರ್ದಿಕ ಅಭಿನಂದನೆಗಳು! 🎉',
        };
      }
      return switch (lang) {
        Lang.en => 'Happy ${ordinal(y)} anniversary! ${y == 1 ? 'One beautiful year' : '$y beautiful years'} together 💞',
        Lang.hi => 'शादी की $yवीं सालगिरह मुबारक हो! $y खूबसूरत साल साथ 💞',
        Lang.kn => '$yನೇ ವಿವಾಹ ವಾರ್ಷಿಕೋತ್ಸವದ ಶುಭಾಶಯಗಳು! $y ಸುಂದರ ವರ್ಷಗಳ ಜೊತೆ 💞',
      };
    }
    return null;
  }

  /// [text] with the age line added at the start or end, unless the message
  /// already mentions the number.
  String withAge(String text, Lang lang, AgeInWishes where, [AgeLines own = const AgeLines()]) {
    final line = ageLine(lang, own);
    final n = age ?? yearsMarried;
    if (line == null || n == null || where == AgeInWishes.off) return text;
    if (RegExp('(^|[^0-9])$n([^0-9]|\$)').hasMatch(text)) return text;
    final t = text.trim();
    if (t.isEmpty) return line;
    return where == AgeInWishes.end ? '$t\n\n$line' : '$line\n\n$t';
  }

  /// [text] without the age line (when it was switched off).
  String withoutAge(String text, Lang lang, [AgeLines own = const AgeLines()]) {
    final line = ageLine(lang, own);
    if (line == null) return text;
    return text.replaceFirst('$line\n\n', '').replaceFirst('\n\n$line', '').replaceFirst(line, '').trim();
  }

  Map<String, String?> get values => {
        'name': name,
        'nickname': nickname ?? name,
        'relation': relation?.label,
        'age': age?.toString(),
        'age_th': age == null ? null : ordinal(age!),
        'years_married': yearsMarried?.toString(),
        'years_th': yearsMarried == null ? null : ordinal(yearsMarried!),
        'couple_names': coupleNames,
        'festival': festival,
        'my_name': myName,
      };

  bool canFill(MessageTemplate t) => t.placeholders.every((p) => values[p] != null);

  String fill(String text) =>
      text.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => values[m.group(1)] ?? m.group(0)!);

  /// Builds the context for wishing [entry] on [date] from [me].
  static MessageContext forEntry(EventEntry entry, {required int? years, Person? me, String? festival}) {
    final people = entry.people.where((p) => !p.isMe).toList();
    final p = people.firstOrNull;
    final first = p?.name.trim().split(RegExp(r'\s+')).first;
    return MessageContext(
      name: first,
      nickname: p?.shortName,
      relation: p?.relation,
      age: entry.type == EventType.birthday ? years : null,
      yearsMarried: entry.type.isAnniversaryLike ? years : null,
      coupleNames: entry.kind == EventKind.couple ? people.map((x) => x.shortName).join(' & ') : null,
      festival: festival,
      myName: me?.name.trim().split(RegExp(r'\s+')).first,
      type: entry.type,
    );
  }
}

/// The occasion to use for an event, most specific first.
List<Occasion> occasionsFor(EventEntry e, {required bool milestone, bool belated = false}) {
  if (belated) return [Occasion.belated, Occasion.general];
  final spouse = e.people.any((p) => p.relation == Relationship.wife || p.relation == Relationship.husband);
  return switch (e.type) {
    EventType.birthday => [if (milestone) Occasion.milestoneBirthday, Occasion.birthday],
    EventType.weddingAnniversary || EventType.firstMeeting => e.kind == EventKind.couple || !spouse
        ? [Occasion.coupleAnniversary, Occasion.general]
        : [Occasion.anniversary, Occasion.general],
    EventType.engagement => [Occasion.engagement, Occasion.coupleAnniversary, Occasion.general],
    EventType.workAnniversary => [Occasion.workAnniversary, Occasion.congratulations],
    EventType.graduation => [Occasion.congratulations],
    _ => [Occasion.congratulations, Occasion.general],
  };
}

/// Loads the bundled message files once.
class MessageLibrary {
  MessageLibrary._(this.all);

  /// A library over [list] only (tests, custom sets).
  factory MessageLibrary.fromList(List<MessageTemplate> list) => MessageLibrary._(list);

  final List<MessageTemplate> all;

  static MessageLibrary? _cache;

  static Future<MessageLibrary> load() async {
    if (_cache != null) return _cache!;
    final list = <MessageTemplate>[];
    for (final lang in Lang.values) {
      try {
        final raw = await rootBundle.loadString('assets/messages/${lang.name}.json');
        final j = jsonDecode(raw) as Map<String, dynamic>;
        for (final m in j['messages'] as List) {
          final t = MessageTemplate.fromJson(m as Map<String, dynamic>, lang);
          if (t != null) list.add(t);
        }
      } catch (_) {
        // A missing or broken file just means fewer messages.
      }
    }
    return _cache = MessageLibrary._(list);
  }

  /// Suitable messages, best first: exact relation, then family, then anyone;
  /// messages already sent to this person go last.
  List<MessageTemplate> suggest({
    required List<Occasion> occasions,
    required Lang lang,
    required MessageContext ctx,
    Set<String> alreadySent = const {},
    String? festivalId,
    List<MessageTemplate> extra = const [],
    Set<String> hidden = const {},
    Set<String> favourites = const {},
  }) {
    for (final occ in occasions) {
      final found = [...extra, ...all]
          .where((t) =>
              !hidden.contains(t.id) &&
              t.lang == lang &&
              t.occasion == occ &&
              (occ != Occasion.festival || t.festival == null || t.festival == festivalId) &&
              t.fit(ctx.relation) > 0 &&
              ctx.canFill(t))
          .toList();
      if (found.isEmpty) continue;
      int score(MessageTemplate t) =>
          (alreadySent.contains(t.id) || alreadySent.contains(ctx.fill(t.text)) ? 0 : 100) +
          (occ == Occasion.festival && t.festival == festivalId ? 10 : 0) +
          t.fit(ctx.relation) * 5 +
          (favourites.contains(t.id) ? 8 : 0) +
          (t.custom ? 4 : 0);
      found.sort((a, b) => score(b).compareTo(score(a)));
      return found;
    }
    return const [];
  }
}

/// Fallback when the library has nothing for a combination.
String fallbackMessage(MessageContext ctx, Occasion occ) => switch (occ) {
      Occasion.birthday || Occasion.milestoneBirthday => 'Happy birthday, ${ctx.values['nickname'] ?? ''}! Wishing you a wonderful year ahead.',
      Occasion.anniversary => 'Happy anniversary! Every year with you is my favourite.',
      Occasion.coupleAnniversary => 'Happy anniversary${ctx.coupleNames == null ? '' : ', ${ctx.coupleNames}'}! Wishing you many more happy years together.',
      Occasion.belated => 'Sorry this is late, ${ctx.values['nickname'] ?? ''}! Belated wishes and lots of love.',
      Occasion.festival => 'Happy ${ctx.festival ?? 'festival'}! Wishing you and your family joy and good health.',
      Occasion.thankYou => 'Thank you so much for the lovely wishes! It made my day.',
      _ => 'Congratulations, ${ctx.values['nickname'] ?? ''}! Wishing you all the best.',
    };

/// Sent texts and template ids for a person, for "don't repeat" suggestions.
Set<String> sentKeys(Iterable<WishLog> logs) => {
      for (final l in logs) ...[?l.templateId, ?l.message],
    };
