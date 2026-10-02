import 'package:flutter/material.dart';

/// Relationship of a person to the app's owner. Stored by [name] in the database.
enum Relationship {
  father('Father'),
  mother('Mother'),
  wife('Wife'),
  husband('Husband'),
  son('Son'),
  daughter('Daughter'),
  brother('Brother'),
  sister('Sister'),
  grandfather('Grandfather'),
  grandmother('Grandmother'),
  uncle('Uncle'),
  aunt('Aunt'),
  cousin('Cousin'),
  niece('Niece'),
  nephew('Nephew'),
  inLaw('In-law'),
  bestFriend('Best Friend'),
  friend('Friend'),
  colleague('Colleague'),
  boss('Boss'),
  client('Client'),
  mentor('Mentor'),
  neighbour('Neighbour'),
  custom('Custom'),
  self('You');

  const Relationship(this.label);
  final String label;

  static Relationship parse(String? v) =>
      Relationship.values.firstWhere((r) => r.name == v, orElse: () => Relationship.friend);

  /// Relationships offered in pickers (excludes [self]).
  static List<Relationship> get choices => values.where((r) => r != self).toList();
}

/// Whether an event belongs to one person, a couple, or nobody.
enum EventKind {
  person,
  couple,
  other,
  festival;

  static EventKind parse(String? v) =>
      EventKind.values.firstWhere((k) => k.name == v, orElse: () => EventKind.person);
}

/// What the event is. Person/couple types first, then non-person categories.
enum EventType {
  birthday('Birthday', Icons.cake_outlined, EventGroup.birthday),
  weddingAnniversary('Wedding Anniversary', Icons.favorite_outline, EventGroup.anniversary),
  engagement('Engagement', Icons.diamond_outlined, EventGroup.anniversary),
  workAnniversary('Work Anniversary', Icons.work_outline, EventGroup.anniversary),
  graduation('Graduation', Icons.school_outlined, EventGroup.other),
  firstMeeting('First Meeting', Icons.handshake_outlined, EventGroup.anniversary),
  custom('Custom', Icons.star_outline, EventGroup.other),
  // Non-person ("important dates")
  insurance('Insurance Renewal', Icons.shield_outlined, EventGroup.important),
  vehicleService('Vehicle Service', Icons.directions_car_outlined, EventGroup.important),
  passport('Passport Expiry', Icons.flight_outlined, EventGroup.important),
  licence('Licence Expiry', Icons.badge_outlined, EventGroup.important),
  bill('Bill Due', Icons.receipt_long_outlined, EventGroup.important),
  policy('Policy Renewal', Icons.description_outlined, EventGroup.important),
  rent('Rent', Icons.home_outlined, EventGroup.important),
  subscription('Subscription', Icons.autorenew, EventGroup.important),
  otherDate('Other', Icons.event_note_outlined, EventGroup.important),
  festival('Festival', Icons.celebration_outlined, EventGroup.festival);

  const EventType(this.label, this.icon, this.group);
  final String label;
  final IconData icon;
  final EventGroup group;

  static EventType parse(String? v) =>
      EventType.values.firstWhere((t) => t.name == v, orElse: () => EventType.custom);

  static List<EventType> get personTypes =>
      [birthday, weddingAnniversary, engagement, workAnniversary, graduation, firstMeeting, custom];
  static List<EventType> get coupleTypes => [weddingAnniversary, engagement, firstMeeting, custom];
  static List<EventType> get otherTypes =>
      values.where((t) => t.group == EventGroup.important).toList();

  bool get isFestival => this == festival;

  bool get isAnniversaryLike => group == EventGroup.anniversary;
}

/// Colour family used for dots, icons and rings.
enum EventGroup { birthday, anniversary, festival, important, other }

enum Repeat {
  yearly('Every year'),
  monthly('Every month'),
  once('One time');

  const Repeat(this.label);
  final String label;

  static Repeat parse(String? v) =>
      Repeat.values.firstWhere((r) => r.name == v, orElse: () => Repeat.yearly);
}

/// Where a 29 February date falls in years without one.
enum Feb29Rule {
  feb28('28 February'),
  mar1('1 March');

  const Feb29Rule(this.label);
  final String label;

  static Feb29Rule parse(String? v) =>
      Feb29Rule.values.firstWhere((r) => r.name == v, orElse: () => Feb29Rule.feb28);
}
