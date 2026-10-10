import 'dart:convert';

import '../../data/database.dart';

enum ReminderKind {
  midnight('Midnight alarm'),
  morning('Morning reminder'),
  custom('Custom time on the day'),
  daysBefore('Days before'),
  gift('Gift reminder');

  const ReminderKind(this.label);
  final String label;

  static ReminderKind parse(String v) =>
      ReminderKind.values.firstWhere((k) => k.name == v, orElse: () => ReminderKind.morning);
}

/// A reminder setting independent of the database row.
class ReminderSpec {
  const ReminderSpec(this.kind, {this.daysBefore = 0, this.minute = 480, this.enabled = true});

  final ReminderKind kind;
  final int daysBefore;
  final int minute;
  final bool enabled;

  factory ReminderSpec.fromRow(Reminder r) =>
      ReminderSpec(ReminderKind.parse(r.kind), daysBefore: r.daysBefore, minute: r.minuteOfDay, enabled: r.enabled);

  factory ReminderSpec.fromJson(Map<String, dynamic> j) => ReminderSpec(
        ReminderKind.parse(j['kind'] as String),
        daysBefore: (j['days'] as num?)?.toInt() ?? 0,
        minute: (j['min'] as num?)?.toInt() ?? 480,
      );

  Map<String, dynamic> toJson() => {'kind': kind.name, 'days': daysBefore, 'min': minute};

  ReminderSpec copyWith({int? daysBefore, int? minute, bool? enabled}) => ReminderSpec(kind,
      daysBefore: daysBefore ?? this.daysBefore, minute: minute ?? this.minute, enabled: enabled ?? this.enabled);

  /// Midnight fires at 23:59:50 the evening before; its minute is fixed.
  bool get onTheDay => kind == ReminderKind.morning || kind == ReminderKind.custom || kind == ReminderKind.midnight;
}

/// Factory defaults: a morning reminder on the day for people; 7 and 1 days
/// before for important dates. Changeable in Settings.
const defaultPersonReminders = [ReminderSpec(ReminderKind.morning, minute: 480)];
const defaultOtherReminders = [
  ReminderSpec(ReminderKind.daysBefore, daysBefore: 7, minute: 540),
  ReminderSpec(ReminderKind.daysBefore, daysBefore: 1, minute: 540),
];

List<ReminderSpec> decodeSpecs(String? json, List<ReminderSpec> fallback) {
  if (json == null) return fallback;
  try {
    return [for (final j in jsonDecode(json) as List) ReminderSpec.fromJson(j as Map<String, dynamic>)];
  } catch (_) {
    return fallback;
  }
}

String encodeSpecs(List<ReminderSpec> specs) => jsonEncode([for (final s in specs) s.toJson()]);

String fmtMinute(int m) {
  final h = m ~/ 60, min = m % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${min.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

/// Short description like "Morning 8:00 AM · 7 days before".
String describeSpecs(List<ReminderSpec> specs) {
  final on = specs.where((s) => s.enabled).toList();
  if (on.isEmpty) return 'No reminders';
  return on.map((s) => switch (s.kind) {
        ReminderKind.midnight => 'Midnight alarm',
        ReminderKind.morning => 'Morning ${fmtMinute(s.minute)}',
        ReminderKind.custom => 'On the day ${fmtMinute(s.minute)}',
        ReminderKind.daysBefore => '${s.daysBefore} day${s.daysBefore == 1 ? '' : 's'} before',
        ReminderKind.gift => 'Gift ${s.daysBefore} days before',
      }).join(' · ');
}

/// Sounds the user can choose per event (files in android/app/src/main/res/raw).
enum AlarmSound {
  tickTock('tick_tock', 'Tick-tock'),
  softBell('soft_bell', 'Soft bell'),
  templeBell('temple_bell', 'Temple bell'),
  chime('chime', 'Chime'),
  birthdayTune('birthday_tune', 'Birthday tune'),
  vibrate('', 'Vibration only');

  const AlarmSound(this.file, this.label);
  final String file, label;

  static AlarmSound parse(String? v) =>
      AlarmSound.values.firstWhere((s) => s.name == v, orElse: () => AlarmSound.tickTock);
}
