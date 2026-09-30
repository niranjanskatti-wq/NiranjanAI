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
