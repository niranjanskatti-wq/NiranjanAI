import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/calendar_sync/calendar_sync.dart';
import 'package:smriti/features/export/export_service.dart';
import 'package:smriti/features/export/import_service.dart';
import 'package:smriti/features/widget/home_widget_service.dart';
import 'package:smriti/features/widget/widget_glow.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('groups: members, per-person groups, names for export, cleanup on delete', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final appa = await r.insertPerson(PeopleCompanion.insert(name: 'Ramesh Katti'));
    final ravi = await r.insertPerson(PeopleCompanion.insert(name: 'Ravi Kumar'));
    final family = await r.addGroup('Family');
    final office = await r.addGroup('Office');
    await r.setGroupMembers(family, {appa, ravi});
    await r.setPersonGroups(ravi, {family, office});
    expect((await r.watchGroupMembers().first)[family], {appa, ravi});
    expect((await r.watchGroupMembers().first)[office], {ravi});
    expect((await r.groupNamesByPerson())[ravi], ['Family', 'Office']);

    await r.addToGroupNamed(appa, 'office');
    expect((await r.watchGroups().first).length, 2, reason: 'matches the existing group, ignoring case');
    expect((await r.watchGroupMembers().first)[office], {appa, ravi});

    await r.deleteGroup(office);
    expect((await r.groupNamesByPerson())[ravi], ['Family']);
    await r.deletePerson(appa);
    expect((await r.watchGroupMembers().first)[family], {ravi});
    await db.close();
  });

  test('groups survive an Excel round trip', () async {
    final a = AppDatabase(NativeDatabase.memory());
    final r = Repository(a);
    final p = await r.insertPerson(PeopleCompanion.insert(name: 'Priya Kumar'));
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 4, month: 5), personIds: [p]);
    await r.addToGroupNamed(p, 'College friends');
    await r.addToGroupNamed(p, 'Bengaluru');
    final bytes = await ExportService(a, groupNames: await r.groupNamesByPerson()).build(const ExportOptions());
    final b = AppDatabase(NativeDatabase.memory());
    await ImportService(b).apply(await ImportService(b).preview(bytes));
    final names = (await Repository(b).groupNamesByPerson()).values.single;
    expect(names, ['Bengaluru', 'College friends']);
    await a.close();
    await b.close();
  });

  test('gift ideas keep budget and occasion; deleting the event keeps the idea', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final p = await r.insertPerson(PeopleCompanion.insert(name: 'Appa'));
    final ev = await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 3, month: 10), personIds: [p]);
    await r.addGift(p, 'Reading glasses', budget: 2500, eventId: ev);
    var g = (await r.watchGifts(p).first).single;
    expect((g.budget, g.eventId, g.purchased), (2500, ev, false));
    await r.updateGift(g.id, idea: 'Glasses', budget: 3000, eventId: ev, purchased: true);
    g = (await r.watchGifts(p).first).single;
    expect((g.idea, g.budget, g.purchased), ('Glasses', 3000, true));
    await r.deleteEvent(ev);
    g = (await r.watchGifts(p).first).single;
    expect(g.eventId, isNull);
    await db.close();
  });

  test('widget gets the next dates in order with a label', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final p = await r.insertPerson(PeopleCompanion.insert(name: 'Ramesh Katti', nickname: const Value('Appa'), birthYear: const Value(1965)));
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 3, month: 10, year: const Value(1965)), personIds: [p]);
    await r.saveEvent(
        data: EventsCompanion.insert(kind: 'other', type: 'insurance', title: const Value('Car insurance'), day: 1, month: 10),
        personIds: const []);
    final items = HomeWidgetService.items(await r.watchEntries().first, const Day(2026, 9, 29));
    expect(items.map((i) => i['d']), ['2026-10-01', '2026-10-03']);
    expect(items[1]['t'], 'Appa');
    expect(items[1]['l'], contains('Birthday'));
    expect(items[1]['l'], startsWith('🎂 Turning 61'), reason: 'age first, so a narrow widget still shows it');
    expect(items[1]['y'], '61', reason: 'the bullseye shows 60 → 61');
    await db.close();
  });

  test('widgets: unimportant people only from the day before, festivals and other dates always', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final vip = await r.insertPerson(PeopleCompanion.insert(name: 'Shanta', stars: const Value(5)));
    final far = await r.insertPerson(PeopleCompanion.insert(name: 'Colleague', stars: const Value(2)));
    final soon = await r.insertPerson(PeopleCompanion.insert(name: 'Neighbour', stars: const Value(3)));
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 20, month: 10), personIds: [vip]);
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 12, month: 10), personIds: [far]);
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 10, month: 10), personIds: [soon]);
    await r.saveEvent(
        data: EventsCompanion.insert(kind: 'other', type: 'insurance', title: const Value('Car insurance'), day: 15, month: 10),
        personIds: const []);
    final entries = await r.watchEntries().first;
    final items = HomeWidgetService.items(entries, const Day(2026, 10, 10), minStars: 4);
    expect(items.map((i) => i['t']), ['Neighbour', 'Car insurance', 'Shanta'], reason: 'the 2-star birthday in 2 days is left out');
    expect(items.first['m'], '1', reason: 'today, but only for the Today widget');
    expect(items[1]['m'], isNull);
    expect(HomeWidgetService.items(entries, const Day(2026, 10, 10), minStars: 1).length, 4);
    expect(WidgetLook.parse(const WidgetLook().withMinStars(5).toJson()).minStars, 5);
    expect(WidgetLook.parse('{"nextBig":true}').minStars, 4);
    await db.close();
  });

  test('phone calendar items: yearly, monthly and one-time', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final ravi = await r.insertPerson(PeopleCompanion.insert(name: 'Ravi'));
    final priya = await r.insertPerson(PeopleCompanion.insert(name: 'Priya'));
    await r.saveEvent(
        data: EventsCompanion.insert(kind: 'couple', type: 'weddingAnniversary', day: 16, month: 10, year: const Value(2001)),
        personIds: [ravi, priya]);
    await r.saveEvent(
        data: EventsCompanion.insert(kind: 'other', type: 'rent', title: const Value('Rent'), day: 5, month: 1, repeat: const Value('monthly')),
        personIds: const []);
    await r.saveEvent(
        data: EventsCompanion.insert(
            kind: 'other', type: 'passport', title: const Value('Passport'), day: 5, month: 3, year: const Value(2029), repeat: const Value('once')),
        personIds: const []);
    final items = {for (final e in await r.watchEntries().first) e.title: CalendarItem.of(e, thisYear: 2026)};
    final couple = items.values.firstWhere((i) => i.title.contains('Ravi'));
    expect(couple.title, 'Ravi & Priya · Wedding Anniversary');
    expect((couple.year, couple.month, couple.day, couple.rrule), (2001, 10, 16, 'FREQ=YEARLY'));
    expect(items['Rent']!.rrule, 'FREQ=MONTHLY');
    expect(items['Rent']!.year, 2026);
    expect((items['Passport']!.year, items['Passport']!.rrule), (2029, null));
    expect(couple.hash(1), isNot(couple.hash(2)));
    await db.close();
  });
}
