import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/export/export_service.dart';
import 'package:smriti/features/export/import_service.dart';

Future<void> seed(AppDatabase db) async {
  final r = Repository(db);
  await r.insertPerson(PeopleCompanion.insert(name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
  final appa = await r.insertPerson(PeopleCompanion.insert(
      name: 'Ramesh Katti', nickname: const Value('Appa'), relationship: const Value('father'), stars: const Value(5),
      birthYear: const Value(1966), callNumber: const Value('+919845012345'), notes: const Value('Loves Mysore Pak')));
  await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 3, month: 10), personIds: [appa]);
  final leap = await r.insertPerson(PeopleCompanion.insert(name: 'Leap Baby', relationship: const Value('niece')));
  await r.saveEvent(
      data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 29, month: 2, feb29Rule: const Value('mar1')),
      personIds: [leap]);
  final ravi = await r.insertPerson(PeopleCompanion.insert(name: 'Ravi Kumar', relationship: const Value('uncle')));
  final priya = await r.insertPerson(PeopleCompanion.insert(name: 'Priya Kumar', relationship: const Value('aunt')));
  await r.saveEvent(
      data: EventsCompanion.insert(kind: 'couple', type: 'weddingAnniversary', day: 16, month: 10, year: const Value(2001)),
      personIds: [ravi, priya]);
  await r.saveEvent(
      data: EventsCompanion.insert(kind: 'other', type: 'rent', title: const Value('Rent'), day: 31, month: 1, repeat: const Value('monthly')),
      personIds: const []);
  await r.saveEvent(
      data: EventsCompanion.insert(kind: 'other', type: 'passport', title: const Value('Passport'), day: 5, month: 3, year: const Value(2029), repeat: const Value('once')),
      personIds: const []);
  await r.addGift(appa, 'Reading glasses');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('export then import into an empty app recreates everything, with no duplicates on a second import', () async {
    final a = AppDatabase(NativeDatabase.memory());
    await seed(a);
    final bytes = await ExportService(a).build(const ExportOptions(), today: const Day(2026, 9, 29));
    await File('${Directory.systemTemp.path}/smriti_export_test.xlsx').writeAsBytes(bytes);

    final b = AppDatabase(NativeDatabase.memory());
    await Repository(b).insertPerson(PeopleCompanion.insert(name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
    final rows = await ImportService(b).preview(bytes);
    expect(rows.where((r) => r.status == ImportStatus.error), isEmpty, reason: rows.map((r) => '${r.summary} ${r.problem}').join('\n'));
    await ImportService(b).apply(rows);

    Future<List<String>> events(AppDatabase db) async => (await Repository(db).watchEntries().first)
        .map((e) => '${e.kind.name}|${e.type.name}|${e.event.day}-${e.event.month}|${e.event.year}|${e.repeat.name}|'
            '${e.people.map((p) => p.name).join('&')}|${e.event.title}')
        .toList()
      ..sort();
    expect(await events(b), await events(a));

    final appa = (await Repository(b).allPeople()).firstWhere((p) => p.name == 'Ramesh Katti');
    expect(appa.nickname, 'Appa');
    expect(appa.callNumber, '+919845012345');
    expect(appa.birthYear, 1966);
    expect(appa.stars, 5);
    expect(appa.notes, 'Loves Mysore Pak');
    expect((await b.select(b.giftIdeas).get()).single.idea, 'Reading glasses');
    expect((await Repository(b).allPeople()).length, (await Repository(a).allPeople()).length);

    // Importing the same file again adds nothing.
    final again = await ImportService(b).preview(bytes);
    expect(again.where((r) => r.status == ImportStatus.ready), isEmpty);
    await a.close();
    await b.close();
  });

  test('filters: star rating and leaving out numbers and notes', () async {
    final a = AppDatabase(NativeDatabase.memory());
    await seed(a);
    final bytes = await ExportService(a).build(
        const ExportOptions(minStars: 5, includeNumbers: false, includeNotes: false),
        today: const Day(2026, 9, 29));
    final b = AppDatabase(NativeDatabase.memory());
    final rows = await ImportService(b).preview(bytes);
    final ready = rows.where((r) => r.status == ImportStatus.ready).map((r) => r.summary).toList();
    expect(ready.any((s) => s.contains('Ramesh Katti')), isTrue);
    expect(ready.any((s) => s.contains('Ravi')), isFalse);
    await ImportService(b).apply(rows);
    final appa = (await Repository(b).allPeople()).firstWhere((p) => p.name == 'Ramesh Katti');
    expect(appa.callNumber, isNull);
    expect(appa.notes, isNull);
    await a.close();
    await b.close();
  });

  test('template imports its example rows and reports bad rows', () async {
    final b = AppDatabase(NativeDatabase.memory());
    final rows = await ImportService(b).preview(ExportService.template());
    expect(rows.where((r) => r.status == ImportStatus.ready).length, greaterThanOrEqualTo(4));
    await ImportService(b).apply(rows);
    final entries = await Repository(b).watchEntries().first;
    expect(entries.any((e) => e.kind.name == 'couple' && e.people.length == 2), isTrue);
    expect(entries.any((e) => e.event.title == 'Car insurance'), isTrue);
    await b.close();
  });
}
