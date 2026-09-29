import 'package:drift/drift.dart';

import 'database.dart';
import 'enums.dart';
import 'models.dart';

/// All reads and writes the screens need, on top of [AppDatabase].
class Repository {
  Repository(this.db);

  final AppDatabase db;

  // ---------- people ----------
  Stream<List<Person>> watchPeople({bool archived = false}) => (db.select(db.people)
        ..where((p) => p.isMe.equals(false) & p.isArchived.equals(archived))
        ..orderBy([(p) => OrderingTerm(expression: p.name.lower())]))
      .watch();

  Stream<Person?> watchPerson(int id) =>
      (db.select(db.people)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<Person?> getPerson(int id) =>
      (db.select(db.people)..where((p) => p.id.equals(id))).getSingleOrNull();

  Stream<Person?> watchMe() =>
      (db.select(db.people)..where((p) => p.isMe.equals(true))..limit(1)).watchSingleOrNull();

  Future<Person?> getMe() =>
      (db.select(db.people)..where((p) => p.isMe.equals(true))..limit(1)).getSingleOrNull();

  Future<List<Person>> linkedPeople() =>
      (db.select(db.people)..where((p) => p.contactId.isNotNull())).get();

  Future<List<Person>> allPeople() => db.select(db.people).get();

  Future<int> insertPerson(PeopleCompanion p) => db.into(db.people).insert(p);

  Future<void> updatePerson(int id, PeopleCompanion p) =>
      (db.update(db.people)..where((t) => t.id.equals(id)))
          .write(p.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> setArchived(int id, bool archived) =>
      updatePerson(id, PeopleCompanion(isArchived: Value(archived)));

  /// Deletes a person and any event that no longer has anyone attached.
  Future<void> deletePerson(int id) => db.transaction(() async {
        final eventIds = await (db.select(db.eventPeople)..where((l) => l.personId.equals(id)))
            .map((l) => l.eventId)
            .get();
        await (db.delete(db.people)..where((p) => p.id.equals(id))).go();
        for (final eid in eventIds) {
          final left = await (db.select(db.eventPeople)..where((l) => l.eventId.equals(eid))).get();
          if (left.isEmpty) await (db.delete(db.events)..where((e) => e.id.equals(eid))).go();
        }
      });

  // ---------- events ----------
  Stream<List<EventEntry>> watchEntries() {
    final q = db.select(db.events).join([
      leftOuterJoin(db.eventPeople, db.eventPeople.eventId.equalsExp(db.events.id)),
      leftOuterJoin(db.people, db.people.id.equalsExp(db.eventPeople.personId)),
    ])
      ..orderBy([OrderingTerm(expression: db.eventPeople.role)]);
    return q.watch().map(_group);
  }

  Stream<List<EventEntry>> watchEntriesForPerson(int personId) =>
      watchEntries().map((all) => all.where((e) => e.people.any((p) => p.id == personId)).toList());

  Stream<EventEntry?> watchEntry(int eventId) =>
      watchEntries().map((all) => all.where((e) => e.event.id == eventId).firstOrNull);

  List<EventEntry> _group(List<TypedResult> rows) {
    final events = <int, Event>{};
    final people = <int, List<Person>>{};
    for (final r in rows) {
      final e = r.readTable(db.events);
      events[e.id] = e;
      final p = r.readTableOrNull(db.people);
      final list = people.putIfAbsent(e.id, () => []);
      if (p != null) list.add(p);
    }
    return [for (final e in events.values) EventEntry(e, people[e.id] ?? const [])];
  }

  /// Creates or updates an event and sets its people (primary first).
  Future<int> saveEvent({int? id, required EventsCompanion data, required List<int> personIds}) =>
      db.transaction(() async {
        final eventId = id ?? await db.into(db.events).insert(data);
        if (id != null) {
          await (db.update(db.events)..where((e) => e.id.equals(id))).write(data);
        }
        await (db.delete(db.eventPeople)..where((l) => l.eventId.equals(eventId))).go();
        for (var i = 0; i < personIds.length; i++) {
          await db.into(db.eventPeople).insert(
                EventPeopleCompanion.insert(eventId: eventId, personId: personIds[i], role: Value(i)),
              );
        }
        return eventId;
      });

  Future<void> deleteEvent(int id) => (db.delete(db.events)..where((e) => e.id.equals(id))).go();

  /// True when this person already has an event of [type] on [month]/[day].
  Future<bool> hasEvent(int personId, EventType type, int month, int day) async {
    final q = db.select(db.events).join([
      innerJoin(db.eventPeople, db.eventPeople.eventId.equalsExp(db.events.id)),
    ])
      ..where(db.eventPeople.personId.equals(personId) &
          db.events.type.equals(type.name) &
          db.events.month.equals(month) &
          db.events.day.equals(day));
    return (await q.get()).isNotEmpty;
  }

  // ---------- gift ideas ----------
  Stream<List<GiftIdea>> watchGifts(int personId) => (db.select(db.giftIdeas)
        ..where((g) => g.personId.equals(personId))
        ..orderBy([(g) => OrderingTerm(expression: g.createdAt)]))
      .watch();

  Future<void> addGift(int personId, String idea) =>
      db.into(db.giftIdeas).insert(GiftIdeasCompanion.insert(personId: personId, idea: idea));

  Future<void> setGiftPurchased(int id, bool purchased) =>
      (db.update(db.giftIdeas)..where((g) => g.id.equals(id)))
          .write(GiftIdeasCompanion(purchased: Value(purchased)));

  Future<void> deleteGift(int id) => (db.delete(db.giftIdeas)..where((g) => g.id.equals(id))).go();

  // ---------- notices ----------
  Stream<List<ContactNotice>> watchUnseenNotices() => (db.select(db.contactNotices)
        ..where((n) => n.seen.equals(false))
        ..orderBy([(n) => OrderingTerm(expression: n.createdAt, mode: OrderingMode.desc)]))
      .watch();

  Future<void> addNotice(int personId, String message) => db
      .into(db.contactNotices)
      .insert(ContactNoticesCompanion.insert(personId: personId, message: message));

  Future<void> markNoticeSeen(int id) => (db.update(db.contactNotices)..where((n) => n.id.equals(id)))
      .write(const ContactNoticesCompanion(seen: Value(true)));
}
