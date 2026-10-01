import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;

import '../../core/util/occurrence.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/repository.dart';

String nameKey(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// A person whose birthday and wedding anniversary fall on the same day, which
/// usually means one of them was saved by mistake in contacts.
class SameDayClash {
  const SameDayClash(this.person, this.birthday, this.anniversary);
  final Person person;
  final EventEntry birthday, anniversary;
}

/// Two people who look like the same person (same name or same phone number).
class DuplicatePeople {
  const DuplicatePeople(this.keep, this.extra, this.reason);
  final Person keep, extra;
  final String reason;
}

/// Single-person anniversaries that are really one couple's: two on the same day,
/// or one where the person's husband or wife is known from the family tree.
class CoupleSuggestion {
  const CoupleSuggestion(this.first, this.second, this.firstEvent, this.secondEvent, this.reason);
  final Person first, second;
  final EventEntry firstEvent;

  /// The partner's own copy, removed when combining (null if they had none).
  final EventEntry? secondEvent;
  final String reason;
}

/// Different people with the same birthday (or other date) on the same day:
/// often one person saved twice under different names.
class SameDateGroup {
  const SameDateGroup(this.type, this.day, this.month, this.keep, this.others);
  final EventType type;
  final int day, month;

  /// The one kept when merging: the one with a phone number, then the one with more saved.
  final Person keep;
  final List<Person> others;

  List<Person> get all => [keep, ...others];

  /// Remembers "Different people".
  String get key => '${type.name}|$month|$day|${(all.map((p) => p.id).toList()..sort()).join('-')}';
}

class Duplicates {
  Duplicates(this.db) : repo = Repository(db);

  final AppDatabase db;
  final Repository repo;

  static List<SameDayClash> sameDay(List<EventEntry> entries) {
    final out = <SameDayClash>[];
    final byPerson = <int, List<EventEntry>>{};
    for (final e in entries.where((e) => e.kind == EventKind.person && e.people.length == 1)) {
      (byPerson[e.people.single.id] ??= []).add(e);
    }
    for (final list in byPerson.values) {
      final b = list.where((e) => e.type == EventType.birthday);
      for (final bd in b) {
        final a = list
            .where((e) => e.type.isAnniversaryLike && e.event.day == bd.event.day && e.event.month == bd.event.month)
            .firstOrNull;
        if (a != null) out.add(SameDayClash(bd.people.single, bd, a));
      }
    }
    return out;
  }

  static bool _single(EventEntry e) =>
      e.kind == EventKind.person && e.people.length == 1 && e.type == EventType.weddingAnniversary && !e.people.single.isMe;

  /// [spouses]: personId → their husband/wife from the family tree.
  static List<CoupleSuggestion> couples(List<EventEntry> entries, Map<int, Person> spouses) {
    final singles = entries.where(_single).toList();
    final out = <CoupleSuggestion>[];
    final used = <int>{};
    // 1. Husband/wife known and anniversaries on the same day (or only one of them has it).
    for (final e in singles) {
      final p = e.people.single;
      final partner = spouses[p.id];
      if (partner == null || used.contains(e.event.id)) continue;
      final theirs = singles
          .where((x) => x.people.single.id == partner.id && x.event.day == e.event.day && x.event.month == e.event.month)
          .firstOrNull;
      final partnerHasOther = entries.any((x) =>
          x.type.isAnniversaryLike && x.people.any((q) => q.id == partner.id) && x.event.id != theirs?.event.id);
      if (theirs == null && partnerHasOther) continue;
      out.add(CoupleSuggestion(p, partner, e, theirs, '${partner.shortName} is ${p.shortName}’s husband or wife'));
      used.add(e.event.id);
      if (theirs != null) used.add(theirs.event.id);
    }
    // 2. Two single anniversaries on the same day.
    for (var i = 0; i < singles.length; i++) {
      for (var j = i + 1; j < singles.length; j++) {
        final a = singles[i], b = singles[j];
        if (used.contains(a.event.id) || used.contains(b.event.id)) continue;
        if (a.event.day != b.event.day || a.event.month != b.event.month) continue;
        if (a.people.single.id == b.people.single.id) continue;
        out.add(CoupleSuggestion(a.people.single, b.people.single, a, b, 'Both have an anniversary on the same day'));
        used.addAll([a.event.id, b.event.id]);
      }
    }
    return out;
  }

  /// Turns [s.firstEvent] into one couple anniversary and removes the partner's copy.
  Future<void> combine(CoupleSuggestion s) => db.transaction(() async {
        final year = realYear(s.firstEvent.event.year) ?? realYear(s.secondEvent?.event.year);
        await repo.updateEvent(
            s.firstEvent.event.id, EventsCompanion(kind: Value(EventKind.couple.name), year: Value(year)));
        await db.into(db.eventPeople).insertOnConflictUpdate(
            EventPeopleCompanion.insert(eventId: s.firstEvent.event.id, personId: s.second.id, role: const Value(1)));
        final other = s.secondEvent;
        if (other != null) {
          await (db.update(db.wishLogs)..where((w) => w.eventId.equals(other.event.id)))
              .write(WishLogsCompanion(eventId: Value(s.firstEvent.event.id)));
          await repo.deleteEvent(other.event.id);
        }
      });

  /// Groups of different people sharing a birthday (or other single-person date)
  /// on the same day. Wedding anniversaries are left to [couples].
  static List<SameDateGroup> sameDate(List<Person> people, List<EventEntry> entries, {Set<String> skip = const {}}) {
    int weight(Person p) =>
        (p.callNumber != null ? 1000 : 0) +
        entries.where((e) => e.people.any((x) => x.id == p.id)).length * 10 +
        (realYear(p.birthYear) != null ? 2 : 0) +
        (p.photoPath != null ? 1 : 0);
    final groups = <String, (EventEntry, Set<Person>)>{};
    for (final e in entries) {
      if (e.kind != EventKind.person || e.people.length != 1 || e.isArchived) continue;
      if (e.type == EventType.weddingAnniversary || e.type == EventType.otherDate) continue;
      final p = e.people.single;
      if (p.isMe) continue;
      final k = '${e.type.name}|${e.event.month}|${e.event.day}';
      final g = groups[k] ??= (e, <Person>{});
      g.$2.add(p);
    }
    final out = <SameDateGroup>[];
    for (final (e, ps) in groups.values) {
      final unique = {for (final p in ps) p.id: p}.values.toList();
      if (unique.length < 2) continue;
      unique.sort((a, b) => weight(b).compareTo(weight(a)));
      final g = SameDateGroup(e.type, e.event.day, e.event.month, unique.first, unique.skip(1).toList());
      if (!skip.contains(g.key)) out.add(g);
    }
    out.sort((a, b) => a.month != b.month ? a.month - b.month : a.day - b.day);
    return out;
  }

  /// Merges everyone in [g] into [g.keep].
  Future<void> mergeGroup(SameDateGroup g) async {
    for (final p in g.others) {
      await merge(g.keep, p);
    }
  }

  /// Pairs of people who are probably the same person. The one with more saved keeps.
  static List<DuplicatePeople> people(List<Person> people, List<EventEntry> entries) {
    int weight(Person p) =>
        entries.where((e) => e.people.any((x) => x.id == p.id)).length * 10 +
        (p.callNumber != null ? 3 : 0) +
        (realYear(p.birthYear) != null ? 2 : 0) +
        (p.photoPath != null ? 1 : 0);
    final out = <DuplicatePeople>[];
    final used = <int>{};
    final list = people.where((p) => !p.isMe).toList();
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i], b = list[j];
        if (used.contains(a.id) || used.contains(b.id)) continue;
        String? reason;
        if (nameKey(a.name) == nameKey(b.name)) {
          reason = 'Same name';
        } else if (samePhone(a.callNumber, b.callNumber)) {
          reason = 'Same phone number';
        }
        if (reason == null) continue;
        final keepA = weight(a) >= weight(b);
        out.add(DuplicatePeople(keepA ? a : b, keepA ? b : a, reason));
        used.addAll([a.id, b.id]);
      }
    }
    return out;
  }

  static String _dateKey(EventEntry e) =>
      '${e.type.name}|${e.event.month}|${e.event.day}|${nameKey(e.event.customLabel ?? '')}|${nameKey(e.event.title ?? '')}';

  /// Pairs that are certainly the same person: same number or same name, and
  /// the same date saved for both (e.g. one contact imported twice).
  static List<DuplicatePeople> certain(List<Person> people, List<EventEntry> entries) {
    final dates = <int, Set<String>>{};
    for (final e in entries.where((e) => e.kind == EventKind.person && e.people.length == 1)) {
      (dates[e.people.single.id] ??= {}).add(_dateKey(e));
    }
    return Duplicates.people(people, entries)
        .where((d) => (dates[d.keep.id] ?? const {}).intersection(dates[d.extra.id] ?? const {}).isNotEmpty)
        .toList();
  }

  /// Copies of one date for the same people: returns the extra copies to remove.
  /// The copy with the year (then the oldest) is kept.
  static List<(EventEntry keep, EventEntry extra)> doubleDates(List<EventEntry> entries) {
    final groups = <String, List<EventEntry>>{};
    for (final e in entries.where((e) => e.people.isNotEmpty)) {
      final ids = (e.people.map((p) => p.id).toList()..sort()).join(',');
      (groups['$ids|${_dateKey(e)}'] ??= []).add(e);
    }
    final out = <(EventEntry, EventEntry)>[];
    for (final list in groups.values.where((l) => l.length > 1)) {
      list.sort((a, b) {
        final ya = realYear(a.event.year) != null ? 0 : 1, yb = realYear(b.event.year) != null ? 0 : 1;
        return ya != yb ? ya - yb : a.event.id - b.event.id;
      });
      for (final extra in list.skip(1)) {
        out.add((list.first, extra));
      }
    }
    return out;
  }

  /// Removes certain doubles on its own: the same person saved twice with the
  /// same date, and the same date saved twice for one person. Returns how many
  /// were removed. Unsure cases stay in the Duplicates screen.
  Future<int> autoClean() async {
    var removed = 0;
    for (var pass = 0; pass < 20; pass++) {
      final pairs = certain(await repo.allPeople(), await repo.watchEntries().first);
      if (pairs.isEmpty) break;
      for (final d in pairs) {
        await merge(d.keep, d.extra);
        removed++;
      }
    }
    for (final (keep, extra) in doubleDates(await repo.watchEntries().first)) {
      await db.transaction(() async {
        await (db.update(db.wishLogs)..where((w) => w.eventId.equals(extra.event.id)))
            .write(WishLogsCompanion(eventId: Value(keep.event.id)));
        if (realYear(keep.event.year) == null && realYear(extra.event.year) != null) {
          await repo.updateEvent(keep.event.id, EventsCompanion(year: Value(extra.event.year)));
        }
        await repo.deleteEvent(extra.event.id);
      });
      removed++;
    }
    return removed;
  }

  static bool _cleaning = false;

  /// [autoClean] that never runs twice at once and never throws.
  static Future<int> cleanSafely(AppDatabase db) async {
    if (_cleaning) return 0;
    _cleaning = true;
    try {
      return await Duplicates(db).autoClean();
    } catch (_) {
      return 0;
    } finally {
      _cleaning = false;
    }
  }

  /// Moves everything from [extra] onto [keep] (skipping dates [keep] already has), then removes [extra].
  Future<void> merge(Person keep, Person extra) => db.transaction(() async {
        final keepEntries = await repo.watchEntriesForPerson(keep.id).first;
        for (final e in await repo.watchEntriesForPerson(extra.id).first) {
          final already = keepEntries
              .where((k) => k.people.length == 1 && _dateKey(k) == _dateKey(e))
              .firstOrNull;
          if (already != null && e.people.length == 1) {
            await (db.update(db.wishLogs)..where((w) => w.eventId.equals(e.event.id)))
                .write(WishLogsCompanion(eventId: Value(already.event.id)));
            await repo.deleteEvent(e.event.id);
          } else if (e.people.any((p) => p.id == keep.id)) {
            // Both already on this event (e.g. a couple): just drop the extra copy.
            await (db.delete(db.eventPeople)
                  ..where((ep) => ep.eventId.equals(e.event.id) & ep.personId.equals(extra.id)))
                .go();
          } else {
            await (db.update(db.eventPeople)
                  ..where((ep) => ep.eventId.equals(e.event.id) & ep.personId.equals(extra.id)))
                .write(EventPeopleCompanion(personId: Value(keep.id)));
          }
        }
        await (db.update(db.giftIdeas)..where((g) => g.personId.equals(extra.id)))
            .write(GiftIdeasCompanion(personId: Value(keep.id)));
        await (db.update(db.wishLogs)..where((w) => w.personId.equals(extra.id)))
            .write(WishLogsCompanion(personId: Value(keep.id)));
        await repo.updatePerson(
          keep.id,
          PeopleCompanion(
            callNumber: Value(keep.callNumber ?? extra.callNumber),
            whatsappNumber: Value(keep.whatsappNumber ?? extra.whatsappNumber),
            birthYear: Value(realYear(keep.birthYear) ?? realYear(extra.birthYear)),
            nickname: Value(keep.nickname ?? extra.nickname),
            photoPath: Value(keep.photoPath ?? extra.photoPath),
            notes: Value(keep.notes ?? extra.notes),
          ),
        );
        await repo.deletePerson(extra.id);
      });
}
