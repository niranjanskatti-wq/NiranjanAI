import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/contacts/duplicates.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('removes certain doubles on its own and leaves unsure ones', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    Future<int> birthday(int person, int day, int month) => r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: day, month: month), personIds: [person]);

    // One number saved under two names, same birthday: merged.
    final a = await r.insertPerson(PeopleCompanion.insert(name: 'Bharti Katti', callNumber: const Value('+919845000001')));
    final b = await r.insertPerson(PeopleCompanion.insert(name: 'Bharti Aunty', callNumber: const Value('98450 00001')));
    await birthday(a, 27, 9);
    final bEvent = await birthday(b, 27, 9);
    await r.markWished(eventId: bEvent, occasionDate: '2026-09-27', personId: b);

    // The same birthday saved twice for one person: one copy removed.
    final c = await r.insertPerson(PeopleCompanion.insert(name: 'Girish'));
    await birthday(c, 9, 3);
    await birthday(c, 9, 3);

    // Same number but a different date (maybe two people sharing a phone): left for the user.
    final d = await r.insertPerson(PeopleCompanion.insert(name: 'Appa', callNumber: const Value('+919845000009')));
    final e = await r.insertPerson(PeopleCompanion.insert(name: 'Amma', callNumber: const Value('+919845000009')));
    await birthday(d, 1, 1);
    await birthday(e, 2, 2);

    expect(await Duplicates(db).autoClean(), 2);
    final people = await r.allPeople();
    expect(people.map((p) => p.name).toSet(), {'Bharti Katti', 'Girish', 'Appa', 'Amma'});
    final entries = await r.watchEntries().first;
    expect(entries.where((x) => x.people.single.id == a).length, 1);
    expect(entries.where((x) => x.people.single.id == c).length, 1);
    final logs = await db.select(db.wishLogs).get();
    expect(logs.single.eventId, entries.firstWhere((x) => x.people.single.id == a).event.id,
        reason: '"wished" moves to the copy that is kept');
    expect(Duplicates.people(people, entries).single.reason, 'Same phone number');
    expect(entries.where((x) => x.type == EventType.birthday).length, 4);

    expect(await Duplicates(db).autoClean(), 0, reason: 'nothing left to clean');
    await db.close();
  });
}
