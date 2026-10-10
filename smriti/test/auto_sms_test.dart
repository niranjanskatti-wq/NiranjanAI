import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/autosms/auto_sms.dart';
import 'package:smriti/features/messages/message_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('texts are planned at every chosen time, with names, ages and your own words', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final now = DateTime(2026, 10, 1, 12);
    final appa = await r.insertPerson(PeopleCompanion.insert(
        name: 'Ramesh Katti', nickname: const Value('Appa'), birthYear: const Value(1966), callNumber: const Value('+919845000001')));
    final noNumber = await r.insertPerson(PeopleCompanion.insert(name: 'Girish'));
    final bday = await r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 19, month: 11), personIds: [appa]);
    final g = await r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 9, month: 11), personIds: [noNumber]);

    Future<void> add(int person, int? event, int minute, {String? message, String? date, bool on = true}) =>
        db.into(db.scheduledSms).insert(ScheduledSmsCompanion.insert(
              personId: person,
              eventId: Value(event),
              date: Value(date),
              minuteOfDay: minute,
              message: Value(message),
              enabled: Value(on),
            ));
    await add(appa, bday, 0); // midnight
    await add(appa, bday, 540); // 9 AM
    await add(appa, bday, 1080, message: 'Love you {nickname}! {age_th} looks great on you.');
    await add(appa, bday, 1200, on: false);
    await add(noNumber, g, 540); // no number: skipped
    await add(appa, null, 600, date: '2026-10-05', message: 'See you at lunch, {nickname}');
    await add(appa, null, 600, date: '2026-09-01'); // already passed

    expect(await smsJobs(db, now), isEmpty, reason: 'switched off in Settings');
    await db.setSetting('autoSms', 'true');
    final lib = await MessageLibrary.load();
    expect(lib.all, isNotEmpty);
    final jobs = await smsJobs(db, now, lib: lib);

    expect(jobs.first.at, DateTime(2026, 10, 5, 10), reason: 'one-time text first');
    expect(jobs.first.text, 'See you at lunch, Appa');
    final thisYear = jobs.where((j) => j.date.year == 2026 && j.eventId == bday).toList();
    expect(thisYear.map((j) => j.at.hour).toList(), [0, 9, 18]);
    expect(thisYear[0].text, contains('60'), reason: 'the age is in every Smriti-written text');
    expect(thisYear[0].text, contains('Appa'));
    expect(thisYear[1].text, contains('60'));
    expect(thisYear[0].text, isNot(thisYear[1].text), reason: 'a different wish at each time');
    expect(thisYear[2].text, 'Love you Appa! 60th looks great on you.');
    expect(jobs.where((j) => j.date.year == 2027).length, 3, reason: 'next year is lined up too');
    expect(jobs.every((j) => j.number == '+919845000001'), isTrue);
    expect(jobs.map((j) => j.id).toSet().length, jobs.length, reason: 'each alarm has its own id');

    // A prepared message is used for the first time of the day.
    await r.updateEvent(bday, const EventsCompanion(draftMessage: Value('Happy birthday Appa, from all of us')));
    final again = await smsJobs(db, now, lib: lib);
    expect(again.firstWhere((j) => j.eventId == bday).text, startsWith('Happy 60th birthday, Appa! 🎂\n\nHappy birthday Appa, from all of us'));
    await db.close();
  });
}
