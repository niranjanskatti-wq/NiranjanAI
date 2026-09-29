import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

Day _parseDay(String s) {
  final p = s.split('-');
  return Day(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// A built-in or custom festival, with your corrections applied.
class Festival {
  Festival({
    required this.key,
    required this.names,
    required this.enabled,
    required this.dates,
    required this.suggest,
    this.note = '',
    this.custom = false,
    this.month,
    this.day,
    this.calendarDates = const {},
    this.editedYears = const {},
  });

  /// `b:asset-id` for built-in, `c:id` for your own.
  final String key;
  final Map<String, String> names;
  final bool enabled;

  /// Date per year (built-in dates with your corrections, or your own dates).
  final Map<int, Day> dates;

  /// The calendar's own dates before corrections (built-in only).
  final Map<int, Day> calendarDates;
  final Set<int> editedYears;
  final List<String> suggest;
  final String note;
  final bool custom;

  /// Same date every year (your own festivals only).
  final int? month, day;

  String get name => names['en'] ?? key;
  String nameIn(String lang) => names[lang] ?? name;
  String? get assetId => key.startsWith('b:') ? key.substring(2) : null;
  int? get customId => key.startsWith('c:') ? int.tryParse(key.substring(2)) : null;

  /// The id used in message files and wish history.
  String get messageId => assetId ?? key;

  Day? nextFrom(Day from) {
    if (month != null && day != null) {
      return nextOccurrence(repeat: Repeat.yearly, month: month!, day: day!, from: from);
    }
    final upcoming = dates.values.where((d) => d >= from).toList()..sort();
    return upcoming.firstOrNull;
  }

  /// Every date in [from]…[to] (for the calendar).
  Iterable<Day> between(Day from, Day to) sync* {
    var d = nextFrom(from);
    while (d != null && !(to < d)) {
      yield d;
      d = nextFrom(d.addDays(1));
    }
  }
}

/// Makes a festival look like an event so it can share the home list,
/// calendar and countdown.
class FestivalEntry extends EventEntry {
  FestivalEntry(this.festival, int fakeId)
      : super(
          Event(
            id: fakeId,
            kind: EventKind.festival.name,
            type: EventType.festival.name,
            title: festival.name,
            day: 1,
            month: 1,
            repeat: Repeat.yearly.name,
            feb29Rule: Feb29Rule.feb28.name,
            alarmClock: 'mine',
            belatedNudge: false,
            createdAt: DateTime(2000),
          ),
          const [],
        );

  final Festival festival;

  @override
  Day? nextFrom(Day from) => festival.nextFrom(from);

  @override
  int get stars => 3;
}

// ---------- loading ----------

/// A festival as written in assets/festivals/festivals.json.
class AssetFestival {
  AssetFestival(this.id, this.names, this.enabled, this.suggest, this.note, this.dates);

  final String id;
  final Map<String, String> names;
  final bool enabled;
  final List<String> suggest;
  final String note;
  final Map<int, Day> dates;
}

final _assetProvider = FutureProvider<List<AssetFestival>>((ref) async {
  final j = jsonDecode(await rootBundle.loadString('assets/festivals/festivals.json')) as Map<String, dynamic>;
  return [
    for (final f in j['festivals'] as List)
      AssetFestival(
        f['id'] as String,
        (f['name'] as Map).map((k, v) => MapEntry(k as String, v as String)),
        f['enabled'] as bool? ?? true,
        [for (final s in (f['suggest'] as List? ?? const [])) s as String],
        f['note'] as String? ?? '',
        {
          for (final e in (f['dates'] as Map).entries)
            if (e.value != null) int.parse(e.key as String): _parseDay(e.value as String),
        },
      ),
  ];
});

final _overridesProvider = StreamProvider<List<FestivalOverride>>(
    (ref) => ref.watch(databaseProvider).select(ref.watch(databaseProvider).festivalOverrides).watch());

final _customProvider = StreamProvider<List<CustomFestival>>(
    (ref) => ref.watch(databaseProvider).select(ref.watch(databaseProvider).customFestivals).watch());

Map<int, Day> _decodeDates(String? json) {
  if (json == null) return {};
  try {
    return (jsonDecode(json) as Map).map((k, v) => MapEntry(int.parse(k as String), _parseDay(v as String)));
  } catch (_) {
    return {};
  }
}

String _encodeDates(Map<int, Day> m) => jsonEncode(m.map((k, v) => MapEntry('$k', v.toString())));

List<Festival> buildFestivals(List<AssetFestival> assets, List<FestivalOverride> overrides, List<CustomFestival> customs) {
  final ov = {for (final o in overrides) o.festivalId: o};
  return [
    for (final a in assets)
      () {
        final o = ov[a.id];
        final fixed = _decodeDates(o?.dates);
        return Festival(
          key: 'b:${a.id}',
          names: {...a.names, if (o?.name != null) 'en': o!.name!},
          enabled: o?.enabled ?? a.enabled,
          dates: {...a.dates, ...fixed},
          calendarDates: a.dates,
          editedYears: fixed.keys.toSet(),
          suggest: o?.suggest == null ? a.suggest : o!.suggest!.split(',').where((s) => s.isNotEmpty).toList(),
          note: a.note,
        );
      }(),
    for (final c in customs)
      Festival(
        key: 'c:${c.id}',
        names: {'en': c.name},
        enabled: c.enabled,
        dates: _decodeDates(c.dates),
        month: c.month,
        day: c.day,
        suggest: c.suggest.split(',').where((s) => s.isNotEmpty).toList(),
        custom: true,
      ),
  ];
}

final festivalsProvider = Provider<List<Festival>>((ref) {
  final assets = ref.watch(_assetProvider).value ?? const [];
  final overrides = ref.watch(_overridesProvider).value ?? const [];
  final customs = ref.watch(_customProvider).value ?? const [];
  return buildFestivals(assets, overrides, customs);
});

/// Switched-on festivals as events for the home list and calendar.
final festivalEntriesProvider = Provider<List<FestivalEntry>>((ref) {
  final list = ref.watch(festivalsProvider).where((f) => f.enabled).toList();
  return [for (var i = 0; i < list.length; i++) FestivalEntry(list[i], -(i + 1))];
});

/// People events plus festivals.
final allEntriesProvider = Provider<List<EventEntry>>(
    (ref) => [...?ref.watch(entriesProvider).value, ...ref.watch(festivalEntriesProvider)]);

// ---------- changes ----------

class FestivalRepo {
  FestivalRepo(this.db);

  final AppDatabase db;

  Future<FestivalOverride?> _ov(String id) =>
      (db.select(db.festivalOverrides)..where((o) => o.festivalId.equals(id))).getSingleOrNull();

  Future<void> _writeOv(String id, FestivalOverridesCompanion data) async {
    final existing = await _ov(id);
    if (existing == null) {
      await db.into(db.festivalOverrides).insert(data.copyWith(festivalId: Value(id)));
    } else {
      await (db.update(db.festivalOverrides)..where((o) => o.festivalId.equals(id))).write(data);
    }
  }

  Future<void> setEnabled(Festival f, bool on) async {
    if (f.custom) {
      await (db.update(db.customFestivals)..where((c) => c.id.equals(f.customId!)))
          .write(CustomFestivalsCompanion(enabled: Value(on)));
    } else {
      await _writeOv(f.assetId!, FestivalOverridesCompanion(enabled: Value(on)));
    }
  }

  /// Corrects one year's date; null puts back the calendar date.
  Future<void> setDate(Festival f, int year, Day? date) async {
    if (f.custom) {
      final dates = {...f.dates};
      if (date == null) {
        dates.remove(year);
      } else {
        dates[year] = date;
      }
      await (db.update(db.customFestivals)..where((c) => c.id.equals(f.customId!)))
          .write(CustomFestivalsCompanion(dates: Value(_encodeDates(dates))));
      return;
    }
    final o = await _ov(f.assetId!);
    final fixed = _decodeDates(o?.dates);
    if (date == null) {
      fixed.remove(year);
    } else {
      fixed[year] = date;
    }
    await _writeOv(f.assetId!, FestivalOverridesCompanion(dates: Value(fixed.isEmpty ? null : _encodeDates(fixed))));
  }

  Future<void> setName(Festival f, String name) async {
    if (f.custom) {
      await (db.update(db.customFestivals)..where((c) => c.id.equals(f.customId!)))
          .write(CustomFestivalsCompanion(name: Value(name)));
    } else {
      await _writeOv(f.assetId!, FestivalOverridesCompanion(name: Value(name)));
    }
  }

  Future<void> setSuggest(Festival f, List<String> relations) async {
    if (f.custom) {
      await (db.update(db.customFestivals)..where((c) => c.id.equals(f.customId!)))
          .write(CustomFestivalsCompanion(suggest: Value(relations.join(','))));
    } else {
      await _writeOv(f.assetId!, FestivalOverridesCompanion(suggest: Value(relations.join(','))));
    }
  }

  /// Your own festival: same date every year, or specific dates.
  Future<int> addCustom({required String name, int? month, int? day, Map<int, Day> dates = const {}}) =>
      db.into(db.customFestivals).insert(CustomFestivalsCompanion.insert(
            name: name,
            month: Value(month),
            day: Value(day),
            dates: Value(dates.isEmpty ? null : _encodeDates(dates)),
          ));

  Future<void> setYearlyDate(Festival f, int month, int day) =>
      (db.update(db.customFestivals)..where((c) => c.id.equals(f.customId!)))
          .write(CustomFestivalsCompanion(month: Value(month), day: Value(day)));

  Future<void> deleteCustom(Festival f) =>
      (db.delete(db.customFestivals)..where((c) => c.id.equals(f.customId!))).go();

  /// Loads festivals outside of widgets (background alarm refresh).
  static Future<List<Festival>> loadAll(AppDatabase db) async {
    final j = jsonDecode(await rootBundle.loadString('assets/festivals/festivals.json')) as Map<String, dynamic>;
    final assets = [
      for (final f in j['festivals'] as List)
        AssetFestival(
          f['id'] as String,
          (f['name'] as Map).map((k, v) => MapEntry(k as String, v as String)),
          f['enabled'] as bool? ?? true,
          [for (final s in (f['suggest'] as List? ?? const [])) s as String],
          f['note'] as String? ?? '',
          {
            for (final e in (f['dates'] as Map).entries)
              if (e.value != null) int.parse(e.key as String): _parseDay(e.value as String),
          },
        ),
    ];
    return buildFestivals(assets, await db.select(db.festivalOverrides).get(), await db.select(db.customFestivals).get());
  }
}
