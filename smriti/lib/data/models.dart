import '../core/util/occurrence.dart';
import 'database.dart';
import 'enums.dart';

extension PersonX on Person {
  Relationship get relation => Relationship.parse(relationship);

  /// What the app calls this person: nickname first.
  String get shortName => (nickname?.trim().isNotEmpty ?? false) ? nickname!.trim() : name;

  String get relationLabel => relation == Relationship.custom
      ? (customRelationship?.trim().isNotEmpty ?? false ? customRelationship!.trim() : 'Custom')
      : relation.label;

  /// WhatsApp number, falling back to the call number.
  String? get effectiveWhatsapp => whatsappNumber ?? callNumber;

  Set<String> get editedFieldSet =>
      editedFields.split(',').where((f) => f.isNotEmpty).toSet();

  String get initials {
    final parts = shortName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters1.toUpperCase();
    return (parts.first.characters1 + parts.last.characters1).toUpperCase();
  }
}

extension on String {
  /// First user-visible character (keeps Devanagari/Kannada clusters simple).
  String get characters1 => isEmpty ? '' : String.fromCharCode(runes.first);
}

/// An event together with its people, ordered by role.
class EventEntry {
  EventEntry(this.event, this.people);

  final Event event;
  final List<Person> people;

  EventKind get kind => EventKind.parse(event.kind);
  EventType get type => EventType.parse(event.type);
  Repeat get repeat => Repeat.parse(event.repeat);
  Feb29Rule get feb29 => Feb29Rule.parse(event.feb29Rule);

  Person? get primary => people.isEmpty ? null : people.first;
  bool get isMine => people.isNotEmpty && people.every((p) => p.isMe);

  String get typeLabel =>
      (event.customLabel?.trim().isNotEmpty ?? false) ? event.customLabel!.trim() : type.label;

  /// Headline: person's name, "Ravi & Priya", or the event title.
  String get title {
    switch (kind) {
      case EventKind.other:
        return (event.title?.trim().isNotEmpty ?? false) ? event.title!.trim() : typeLabel;
      case EventKind.couple:
        return people.map((p) => p.isMe ? 'You' : p.shortName).join(' & ');
      case EventKind.person:
        final p = primary;
        if (p == null) return typeLabel;
        return p.isMe ? 'You' : p.shortName;
    }
  }

  /// Relationship line, e.g. "Father" or "Uncle & Aunt".
  String get relationLine {
    if (kind == EventKind.other) return typeLabel;
    if (isMine) return 'You';
    return people.map((p) => p.isMe ? 'You' : p.relationLabel).toSet().join(' & ');
  }

  int get stars {
    if (event.stars != null) return event.stars!;
    final others = people.where((p) => !p.isMe).map((p) => p.stars);
    return others.isEmpty ? 3 : others.reduce((a, b) => a > b ? a : b);
  }

  /// Year the counted thing started: the birth year for a birthday with no
  /// event year, otherwise the event's own year.
  int? get startYear {
    if (event.year != null) return event.year;
    if (type == EventType.birthday && kind == EventKind.person) return primary?.birthYear;
    return null;
  }

  Day? nextFrom(Day from) => nextOccurrence(
        repeat: repeat,
        month: event.month,
        day: event.day,
        year: repeat == Repeat.once ? event.year : startYear,
        feb29: feb29,
        from: from,
      );

  bool get isArchived => people.isNotEmpty && people.every((p) => p.isArchived);
}

/// One upcoming happening of an event.
class Upcoming {
  Upcoming(this.entry, this.date, this.daysLeft);

  final EventEntry entry;
  final Day date;
  final int daysLeft;

  int? get years => entry.repeat == Repeat.monthly ? null : yearsOn(date, entry.startYear);
  bool get milestone => isMilestone(entry.type, years);
  bool get isToday => daysLeft == 0;

  /// "Turning 60", "35 years", or null.
  String? get yearsPhrase {
    final y = years;
    if (y == null) return null;
    if (entry.type == EventType.birthday) return entry.isMine ? 'You turn $y' : 'Turning $y';
    if (entry.type.isAnniversaryLike) return '${ordinal(y)} anniversary';
    return '$y years';
  }
}

List<Upcoming> computeUpcoming(Iterable<EventEntry> entries, Day today, {bool includeArchived = false}) {
  final out = <Upcoming>[];
  for (final e in entries) {
    if (e.isArchived && !includeArchived) continue;
    final d = e.nextFrom(today);
    if (d != null) out.add(Upcoming(e, d, today.daysUntil(d)));
  }
  out.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : b.entry.stars.compareTo(a.entry.stars);
  });
  return out;
}
