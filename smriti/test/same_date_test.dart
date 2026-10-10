import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/contacts/duplicates.dart';
import 'package:smriti/features/messages/message_engine.dart';
import 'package:smriti/features/reminders/reminder_model.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('wishes use the nickname, else the first name without titles', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final a = await r.insertPerson(PeopleCompanion.insert(name: 'Bharti Katti Mysore', nickname: const Value('Bharti Aunty')));
    final b = await r.insertPerson(PeopleCompanion.insert(name: 'Dr. Suresh Rao'));
    final c = await r.insertPerson(PeopleCompanion.insert(name: 'Smt Shanta Katti'));
    expect((await r.getPerson(a))!.wishName, 'Bharti Aunty');
    expect((await r.getPerson(b))!.wishName, 'Suresh');
    expect((await r.getPerson(c))!.wishName, 'Shanta');
    final id = await r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 27, month: 9), personIds: [a]);
    final ctx = MessageContext.forEntry((await r.watchEntry(id).first)!, years: null);
    expect(ctx.fill('Happy birthday, {name}! Love you {nickname}'), 'Happy birthday, Bharti Aunty! Love you Bharti Aunty');
    await db.close();
  });

  test('different names on the same birthday are offered for merging, keeping the one with a number', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    Future<void> bday(int p, int d, int m) => r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: d, month: m), personIds: [p]);
    final noNum = await r.insertPerson(PeopleCompanion.insert(name: 'Bharti Aunty'));
    final withNum = await r.insertPerson(PeopleCompanion.insert(name: 'Bharti Katti', callNumber: const Value('+919845000001')));
    final third = await r.insertPerson(PeopleCompanion.insert(name: 'B. Katti'));
    final other = await r.insertPerson(PeopleCompanion.insert(name: 'Girish'));
    await bday(noNum, 27, 9);
    await bday(withNum, 27, 9);
    await bday(third, 27, 9);
    await bday(other, 9, 3);
    await r.markWished(eventId: (await r.watchEntriesForPerson(noNum).first).single.event.id, occasionDate: '2026-09-27', personId: noNum);

    var groups = Duplicates.sameDate(await r.allPeople(), await r.watchEntries().first);
    expect(groups.length, 1);
    final g = groups.single;
    expect(g.keep.id, withNum, reason: 'the one with the phone number');
    expect(g.others.map((p) => p.id).toSet(), {noNum, third});

    // "Different people" hides the group.
    expect(Duplicates.sameDate(await r.allPeople(), await r.watchEntries().first, skip: {g.key}), isEmpty);

    await Duplicates(db).mergeGroup(g);
    final people = await r.allPeople();
    expect(people.map((p) => p.name).toSet(), {'Bharti Katti', 'Girish'});
    final entries = await r.watchEntries().first;
    expect(entries.where((e) => e.type == EventType.birthday && e.event.day == 27).length, 1);
    final log = (await db.select(db.wishLogs).get()).single;
    expect(log.personId, withNum, reason: 'wish history moved over');
    expect(log.eventId, entries.firstWhere((e) => e.event.day == 27).event.id);
    groups = Duplicates.sameDate(await r.allPeople(), await r.watchEntries().first);
    expect(groups, isEmpty);
    await db.close();
  });

  test('several reminders on the day are kept and described', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final p = await r.insertPerson(PeopleCompanion.insert(name: 'Shanta'));
    final id = await r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 19, month: 11), personIds: [p]);
    final specs = [
      const ReminderSpec(ReminderKind.midnight),
      const ReminderSpec(ReminderKind.morning, minute: 480),
      const ReminderSpec(ReminderKind.custom, minute: 720),
      const ReminderSpec(ReminderKind.custom, minute: 1080),
      const ReminderSpec(ReminderKind.custom, minute: 1260),
    ];
    await r.setReminders(id, specs);
    final saved = await (db.select(db.reminders)..where((x) => x.eventId.equals(id))).get();
    expect(saved.where((x) => x.kind == 'custom').map((x) => x.minuteOfDay).toSet(), {720, 1080, 1260});
    expect(describeSpecs(specs), contains('On the day 9:00 PM'));
    await db.close();
  });
}
