import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;

import '../../core/util/occurrence.dart';
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
        } else if (a.callNumber != null && a.callNumber == b.callNumber) {
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

  /// Moves everything from [extra] onto [keep] (skipping dates [keep] already has), then removes [extra].
  Future<void> merge(Person keep, Person extra) => db.transaction(() async {
        final keepEntries = await repo.watchEntriesForPerson(keep.id).first;
        for (final e in await repo.watchEntriesForPerson(extra.id).first) {
          final already = keepEntries.any(
              (k) => k.type == e.type && k.event.day == e.event.day && k.event.month == e.event.month);
          if (already && e.people.length == 1) {
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
