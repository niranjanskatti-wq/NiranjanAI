import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';

import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../contacts/contacts_helper.dart';

/// An event as read from a calendar on the phone.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.year,
    required this.month,
    required this.day,
    this.rrule,
    this.calendar = '',
    this.owner = '',
    this.description = '',
  });

  factory CalendarEvent.fromMap(Map<Object?, Object?> m) => CalendarEvent(
        id: (m['id'] as num).toInt(),
        title: m['title'] as String? ?? '',
        year: (m['year'] as num).toInt(),
        month: (m['month'] as num).toInt(),
        day: (m['day'] as num).toInt(),
        rrule: m['rrule'] as String?,
        calendar: m['calendar'] as String? ?? '',
        owner: m['owner'] as String? ?? '',
        description: m['description'] as String? ?? '',
      );

  final int id;
  final String title;
  final int year, month, day;
  final String? rrule;
  final String calendar, owner, description;

  Repeat get repeat {
    final r = rrule ?? '';
    if (r.contains('FREQ=YEARLY')) return Repeat.yearly;
    if (r.contains('FREQ=MONTHLY')) return Repeat.monthly;
    return Repeat.once;
  }

  /// Google's holiday calendars; Smriti has its own festivals.
  bool get isHolidayCalendar =>
      owner.contains('#holiday@') || RegExp(r'holiday|festival', caseSensitive: false).hasMatch(calendar);

  /// The "Birthdays" calendar made from contacts, where the year is the real birth year.
  bool get isBirthdayCalendar =>
      owner.contains('#contacts@') || RegExp(r'birthday', caseSensitive: false).hasMatch(calendar);

  /// Dates Smriti itself copied into the calendar.
  bool get fromSmriti => description.trim() == 'From Smriti';
}

enum GuessKind {
  birthday('Birthday'),
  anniversary('Anniversary'),
  other('Other date');

  const GuessKind(this.label);
  final String label;
}

/// What Smriti thinks a calendar event is. The user can change it before importing.
class ImportGuess {
  ImportGuess({
    required this.event,
    required this.kind,
    required this.names,
    required this.title,
    this.year,
    this.forMe = false,
    this.duplicate = false,
  }) : selected = !duplicate;

  final CalendarEvent event;
  GuessKind kind;
  List<String> names;
  String title;
  int? year;
  bool forMe, duplicate, selected;

  int get day => event.day;
  int get month => event.month;

  /// Birthdays and anniversaries repeat yearly whatever the calendar says.
  Repeat get repeat => kind == GuessKind.other ? event.repeat : Repeat.yearly;

  String get display => switch (kind) {
        GuessKind.other => title,
        _ when forMe => kind == GuessKind.birthday ? 'You' : 'Your anniversary',
        _ => names.isEmpty ? title : names.join(' & '),
      };
}

final _birthdayWords = RegExp(
    r"\b(happy|birthday|bday|b'day|b-day|birth day|janmadina|janmdin|hbd)\b|जन्मदिन|ಹುಟ್ಟುಹಬ್ಬ|ಜನ್ಮದಿನ",
    caseSensitive: false);
final _anniversaryWords =
    RegExp(r'\b(happy|wedding|marriage|anniversary|anniv|vivah|shaadi|day)\b|सालगिरह|ವಾರ್ಷಿಕೋತ್ಸವ', caseSensitive: false);
final _isBirthday = RegExp(r"birthday|bday|b'day|b-day|birth day|janmadina|janmdin|\bhbd\b|जन्मदिन|ಹುಟ್ಟುಹಬ್ಬ|ಜನ್ಮದಿನ",
    caseSensitive: false);
final _isAnniversary = RegExp(r'anniversary|anniv|wedding day|marriage day|सालगिरह|ವಾರ್ಷಿಕೋತ್ಸವ', caseSensitive: false);
final _mine = RegExp(r"\b(my|our|me|mine)\b", caseSensitive: false);

String _clean(String s, RegExp words) => s
    .replaceAll(RegExp(r"['’]s\b", caseSensitive: false), '')
    .replaceAll(words, ' ')
    .replaceAll(RegExp(r'\b(of|to|the)\b', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'[-–—:|()\[\]!🎂🎉🎈💍❤️]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Guesses the kind of day and whose it is from the event title.
ImportGuess guessEvent(CalendarEvent e, {int? thisYear}) {
  final now = thisYear ?? DateTime.now().year;
  final realYear = e.isBirthdayCalendar && e.year >= 1900 && e.year < now ? e.year : null;
  if (_isBirthday.hasMatch(e.title) || e.isBirthdayCalendar) {
    final name = _clean(e.title, _birthdayWords);
    final mine = _mine.hasMatch(e.title) && name.replaceAll(_mine, '').trim().isEmpty;
    return ImportGuess(
      event: e,
      kind: GuessKind.birthday,
      names: mine || name.isEmpty ? const [] : [name],
      title: e.title,
      year: realYear,
      forMe: mine,
    );
  }
  if (_isAnniversary.hasMatch(e.title)) {
    final rest = _clean(e.title, _anniversaryWords);
    final mine = _mine.hasMatch(rest) && rest.replaceAll(_mine, '').trim().isEmpty;
    final names = mine
        ? const <String>[]
        : rest.split(RegExp(r'\s*(?:&|\+|,|/|\band\b)\s*', caseSensitive: false)).where((n) => n.trim().isNotEmpty).toList();
    return ImportGuess(
      event: e,
      kind: GuessKind.anniversary,
      names: names.take(2).toList(),
      title: e.title,
      forMe: mine || (names.isEmpty && rest.isEmpty),
    );
  }
  return ImportGuess(event: e, kind: GuessKind.other, names: const [], title: e.title, year: e.year);
}

String _key(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Finds an existing person by full name, nickname, or a first name only one person has.
Person? matchPerson(String name, List<Person> people) {
  final k = _key(name);
  if (k.isEmpty) return null;
  for (final p in people) {
    if (_key(p.name) == k || _key(p.nickname ?? '') == k) return p;
  }
  final byFirst = people.where((p) => _key(p.name).split(' ').first == k).toList();
  return byFirst.length == 1 ? byFirst.single : null;
}

/// Turns calendar events into import suggestions, leaving out holidays, Smriti's own copies
/// and anything already in Smriti.
List<ImportGuess> buildGuesses(List<CalendarEvent> events, List<EventEntry> existing, List<Person> people, {int? thisYear}) {
  final seen = <String>{};
  final out = <ImportGuess>[];
  final me = people.where((p) => p.isMe).firstOrNull;
  for (final e in events) {
    if (e.isHolidayCalendar || e.fromSmriti) continue;
    final g = guessEvent(e, thisYear: thisYear);
    final key = '${g.kind.name}|${g.day}|${g.month}|${_key(g.display)}';
    if (!seen.add(key)) continue;
    g.duplicate = isDuplicate(g, existing, people, me);
    g.selected = !g.duplicate;
    out.add(g);
  }
  out.sort((a, b) => a.month != b.month ? a.month.compareTo(b.month) : a.day.compareTo(b.day));
  return out;
}

bool isDuplicate(ImportGuess g, List<EventEntry> existing, List<Person> people, Person? me) {
  final sameDay = existing.where((x) => x.event.day == g.day && x.event.month == g.month);
  switch (g.kind) {
    case GuessKind.birthday:
      final who = g.forMe ? me : (g.names.isEmpty ? null : matchPerson(g.names.first, people));
      return who != null && sameDay.any((x) => x.type == EventType.birthday && x.people.any((p) => p.id == who.id));
    case GuessKind.anniversary:
      final ids = g.forMe
          ? {?me?.id}
          : {for (final n in g.names) ?matchPerson(n, people)?.id};
      return ids.isNotEmpty && sameDay.any((x) => x.type.isAnniversaryLike && x.people.any((p) => ids.contains(p.id)));
    case GuessKind.other:
      return sameDay.any((x) => _key(x.title) == _key(g.title));
  }
}

/// Reads the phone's calendars and saves the chosen events.
class CalendarImport {
  static const _ch = MethodChannel('smriti/calendar');

  static Future<List<CalendarEvent>> read() async {
    final list = await _ch.invokeListMethod<Map<Object?, Object?>>('importable') ?? const [];
    return [for (final m in list) CalendarEvent.fromMap(m)];
  }

  /// Saves the selected suggestions; returns how many dates were added.
  static Future<int> apply(AppDatabase db, List<ImportGuess> guesses) async {
    final repo = Repository(db);
    var people = await repo.allPeople();
    final me = people.where((p) => p.isMe).firstOrNull;
    List<PickedContact> contacts = const [];
    try {
      if (await ContactsHelper.hasPermission()) contacts = await ContactsHelper.all();
    } catch (_) {}

    Future<int> personFor(String name) async {
      final found = matchPerson(name, people);
      if (found != null) return found.id;
      final contact = contacts.where((c) => _key(c.name) == _key(name)).firstOrNull;
      final id = await repo.insertPerson(PeopleCompanion.insert(
        name: name,
        callNumber: Value(normalizePhone(contact?.numbers.firstOrNull?.number)),
        contactId: Value(contact?.id),
        contactLookupKey: Value(contact?.lookupKey),
      ));
      people = await repo.allPeople();
      return id;
    }

    var added = 0;
    for (final g in guesses.where((g) => g.selected)) {
      switch (g.kind) {
        case GuessKind.birthday:
          final int? id = g.forMe ? me?.id : (g.names.isEmpty ? null : await personFor(g.names.first));
          if (id == null) continue;
          if (g.year != null) {
            final p = people.firstWhere((p) => p.id == id);
            if (p.birthYear == null) await repo.updatePerson(p.id, PeopleCompanion(birthYear: Value(g.year)));
          }
          await repo.saveEvent(
            data: EventsCompanion.insert(kind: EventKind.person.name, type: EventType.birthday.name, day: g.day, month: g.month),
            personIds: [id],
          );
        case GuessKind.anniversary:
          final ids = g.forMe ? [?me?.id] : [for (final n in g.names) await personFor(n)];
          if (ids.isEmpty) continue;
          await repo.saveEvent(
            data: EventsCompanion.insert(
              kind: (ids.length > 1 ? EventKind.couple : EventKind.person).name,
              type: EventType.weddingAnniversary.name,
              day: g.day,
              month: g.month,
              year: Value(g.year),
            ),
            personIds: ids,
          );
        case GuessKind.other:
          await repo.saveEvent(
            data: EventsCompanion.insert(
              kind: EventKind.other.name,
              type: EventType.otherDate.name,
              title: Value(g.title),
              day: g.day,
              month: g.month,
              repeat: Value(g.repeat.name),
              year: Value(g.repeat == Repeat.once ? g.year : null),
            ),
            personIds: const [],
          );
      }
      added++;
    }
    return added;
  }
}
