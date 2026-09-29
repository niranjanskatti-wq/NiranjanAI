import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/calendar_sync/calendar_import.dart';
import 'package:smriti/features/festivals/festival_model.dart';

CalendarEvent ev(String title, int d, int m,
        {int year = 2019, String? rrule = 'FREQ=YEARLY', String calendar = 'me@gmail.com', String owner = 'me@gmail.com', String description = ''}) =>
    CalendarEvent(
        id: title.hashCode, title: title, year: year, month: m, day: d, rrule: rrule,
        calendar: calendar, owner: owner, description: description);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('guesses birthdays, anniversaries and other dates from titles', () {
    GuessKind k(String t) => guessEvent(ev(t, 1, 1), thisYear: 2026).kind;
    List<String> n(String t) => guessEvent(ev(t, 1, 1), thisYear: 2026).names;

    expect(k("Appa's birthday"), GuessKind.birthday);
    expect(n("Appa's birthday"), ['Appa']);
    expect(n('Birthday - Ravi Kumar'), ['Ravi Kumar']);
    expect(n('Happy Birthday Chinnu 🎂'), ['Chinnu']);
    expect(n("Priya b'day"), ['Priya']);
    expect(n('अम्मा जन्मदिन'), ['अम्मा']);
    expect(guessEvent(ev('My birthday', 1, 1)).forMe, isTrue);

    expect(k('Ravi & Priya wedding anniversary'), GuessKind.anniversary);
    expect(n('Ravi & Priya wedding anniversary'), ['Ravi', 'Priya']);
    expect(n('Anniversary: Suresh and Latha'), ['Suresh', 'Latha']);
    expect(guessEvent(ev('Our wedding anniversary', 1, 1)).forMe, isTrue);

    expect(k('Car insurance renewal'), GuessKind.other);
    expect(guessEvent(ev('Rent', 5, 1, rrule: 'FREQ=MONTHLY;BYMONTHDAY=5')).repeat, Repeat.monthly);
  });

  test('birth year is trusted only from the contacts birthday calendar', () {
    final typed = guessEvent(ev("Appa's birthday", 3, 10, year: 2019), thisYear: 2026);
    expect(typed.year, isNull, reason: 'the year a person created the event is not the birth year');
    final contacts = guessEvent(
        ev('Ramesh Katti', 3, 10, year: 1965, calendar: 'Birthdays', owner: '#contacts@group.v.calendar.google.com'),
        thisYear: 2026);
    expect((contacts.kind, contacts.year), (GuessKind.birthday, 1965));
    expect(contacts.names, ['Ramesh Katti']);
  });

  test('leaves out holidays, Smriti copies and duplicates; import adds the rest', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    await r.insertPerson(PeopleCompanion.insert(name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
    final appa = await r.insertPerson(PeopleCompanion.insert(name: 'Ramesh Katti', nickname: const Value('Appa')));
    await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 3, month: 10), personIds: [appa]);

    final events = [
      ev("Appa's birthday", 3, 10), // already in Smriti
      ev('Diwali', 8, 11, calendar: 'Holidays in India', owner: 'en.indian#holiday@group.v.calendar.google.com'),
      ev('Ramesh Katti · Birthday', 3, 10, description: 'From Smriti'),
      ev("Chinnu's birthday", 12, 10),
      ev("Chinnu's birthday", 12, 10, calendar: 'Family'), // same event in two calendars
      ev('Ravi & Priya anniversary', 16, 10),
      ev('Our anniversary', 20, 5),
      ev('Passport renewal', 5, 3, year: 2027, rrule: null),
    ];
    final guesses = buildGuesses(events, await r.watchEntries().first, await r.allPeople(), thisYear: 2026);
    expect(guesses.map((g) => g.display),
        ['Passport renewal', 'Your anniversary', "Appa", 'Chinnu', 'Ravi & Priya']);
    final dup = guesses.firstWhere((g) => g.display == 'Appa');
    expect((dup.duplicate, dup.selected), (true, false));

    final added = await CalendarImport.apply(db, guesses);
    expect(added, 4);
    final entries = await r.watchEntries().first;
    final titles = entries.map((e) => '${e.type.name}:${e.title}:${e.repeat.name}').toSet();
    expect(titles, containsAll(['birthday:Chinnu:yearly', 'weddingAnniversary:Ravi & Priya:yearly', 'otherDate:Passport renewal:once']));
    expect(entries.where((e) => e.type == EventType.birthday).length, 2, reason: "Appa's birthday was not added twice");
    final ours = entries.firstWhere((e) => e.event.month == 5);
    expect(ours.isMine, isTrue);
    expect(entries.firstWhere((e) => e.title == 'Passport renewal').event.year, 2027);

    // Importing again finds everything already there.
    final again = buildGuesses(events, await r.watchEntries().first, await r.allPeople(), thisYear: 2026);
    expect(again.where((g) => !g.duplicate), isEmpty);
    await db.close();
  });

  test('"What to show" hides festivals and other dates but never people', () {
    bool show(EventKind k, {bool f = true, bool i = true}) => visibleKind(
        _Fake(k), festivals: f, important: i);
    expect(show(EventKind.festival, f: false), isFalse);
    expect(show(EventKind.other, i: false), isFalse);
    expect(show(EventKind.person, f: false, i: false), isTrue);
    expect(show(EventKind.couple, f: false, i: false), isTrue);
  });
}

class _Fake extends EventEntry {
  _Fake(EventKind k)
      : super(
            Event(
                id: 1, kind: k.name, type: 'birthday', day: 1, month: 1, repeat: 'yearly', feb29Rule: 'feb28',
                alarmClock: 'mine', belatedNudge: false, createdAt: DateTime(2000)),
            const []);
}
