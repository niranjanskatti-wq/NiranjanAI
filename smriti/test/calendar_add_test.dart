import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/calendar/quick_add.dart';
import 'package:smriti/features/contacts/duplicates.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('adding from the calendar: new names become people, known names are reused', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final q = QuickAdd(db);
    final mom = await r.insertPerson(PeopleCompanion.insert(name: 'Shanta Katti', nickname: const Value('Mom')));

    await q.save(kind: QuickKind.birthday, day: 19, month: 11, name: 'Mom', year: 1966);
    await q.save(kind: QuickKind.birthday, day: 9, month: 3, name: 'Girish Mama', relation: Relationship.uncle, year: 1604);
    await q.save(kind: QuickKind.anniversary, day: 16, month: 10, name: 'Ravi', partner: 'Priya', year: 2001);
    await q.save(kind: QuickKind.other, day: 5, month: 3, title: 'Passport', repeat: Repeat.once, year: 2029);

    final people = await r.allPeople();
    expect(people.map((p) => p.name).toSet(), {'Shanta Katti', 'Girish Mama', 'Ravi', 'Priya'});
    expect(people.firstWhere((p) => p.id == mom).birthYear, 1966);
    final girish = people.firstWhere((p) => p.name == 'Girish Mama');
    expect((girish.relationship, girish.birthYear), ('uncle', null), reason: '1604 is not a real year');

    final entries = await r.watchEntries().first;
    expect(entries.map((e) => '${e.kind.name}:${e.type.name}:${e.title}').toSet(), {
      'person:birthday:Mom',
      'person:birthday:Girish Mama',
      'couple:weddingAnniversary:Ravi & Priya',
      'other:otherDate:Passport',
    });

    // Changing an existing birthday replaces it rather than adding a second one.
    final old = await q.existingBirthday(mom);
    await q.save(kind: QuickKind.birthday, day: 20, month: 11, name: 'Mom', replaceEventId: old!.event.id);
    final births = (await r.watchEntriesForPerson(mom).first).where((e) => e.type == EventType.birthday).toList();
    expect(births.single.event.day, 20);
    await db.close();
  });

  test('finds same-day birthday/anniversary and people saved twice, and merges them', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final a = await r.insertPerson(PeopleCompanion.insert(name: 'Bharti Katti', callNumber: const Value('+919845000001')));
    final b = await r.insertPerson(PeopleCompanion.insert(name: 'bharti  katti', birthYear: const Value(1980)));
    final c = await r.insertPerson(PeopleCompanion.insert(name: 'BK', callNumber: const Value('+919845000001')));
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 27, month: 9), personIds: [a]);
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'weddingAnniversary', day: 27, month: 9), personIds: [a]);
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 27, month: 9), personIds: [b]);
    await r.addGift(b, 'Saree');

    var entries = await r.watchEntries().first;
    expect(Duplicates.sameDay(entries).single.person.id, a);
    final pairs = Duplicates.people(await r.allPeople(), entries);
    expect(pairs.length, 1, reason: 'each person is in at most one pair at a time');
    expect((pairs.single.keep.id, pairs.single.extra.id, pairs.single.reason), (a, b, 'Same name'));

    await Duplicates(db).merge(pairs.single.keep, pairs.single.extra);
    final people = await r.allPeople();
    expect(people.map((p) => p.id).toSet(), {a, c});
    final kept = people.firstWhere((p) => p.id == a);
    expect(kept.birthYear, 1980, reason: 'details from the copy are kept');
    entries = await r.watchEntries().first;
    expect(entries.where((e) => e.type == EventType.birthday).length, 1, reason: 'the same birthday is not doubled');
    expect((await r.watchGifts(a).first).single.idea, 'Saree');

    // Next round finds the same-number pair.
    final next = Duplicates.people(await r.allPeople(), entries);
    expect(next.single.reason, 'Same phone number');
    await db.close();
  });
}
