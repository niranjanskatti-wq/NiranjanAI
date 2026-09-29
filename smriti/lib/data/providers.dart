import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/util/occurrence.dart';
import 'database.dart';
import 'models.dart';
import 'repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repoProvider = Provider<Repository>((ref) => Repository(ref.watch(databaseProvider)));

final peopleProvider = StreamProvider<List<Person>>((ref) => ref.watch(repoProvider).watchPeople());

final archivedPeopleProvider =
    StreamProvider<List<Person>>((ref) => ref.watch(repoProvider).watchPeople(archived: true));

final personProvider =
    StreamProvider.family<Person?, int>((ref, id) => ref.watch(repoProvider).watchPerson(id));

final meProvider = StreamProvider<Person?>((ref) => ref.watch(repoProvider).watchMe());

final entriesProvider =
    StreamProvider<List<EventEntry>>((ref) => ref.watch(repoProvider).watchEntries());

final entriesForPersonProvider = StreamProvider.family<List<EventEntry>, int>(
    (ref, id) => ref.watch(repoProvider).watchEntriesForPerson(id));

final entryProvider =
    StreamProvider.family<EventEntry?, int>((ref, id) => ref.watch(repoProvider).watchEntry(id));

final giftsProvider =
    StreamProvider.family<List<GiftIdea>, int>((ref, id) => ref.watch(repoProvider).watchGifts(id));

final noticesProvider =
    StreamProvider<List<ContactNotice>>((ref) => ref.watch(repoProvider).watchUnseenNotices());

/// Today's date; emits again when the clock passes midnight.
final todayProvider = StreamProvider<Day>((ref) async* {
  var last = Day.today();
  yield last;
  await for (final _ in Stream.periodic(const Duration(seconds: 20))) {
    final now = Day.today();
    if (now != last) {
      last = now;
      yield now;
    }
  }
});

final upcomingProvider = Provider<AsyncValue<List<Upcoming>>>((ref) {
  final entries = ref.watch(entriesProvider);
  final today = ref.watch(todayProvider).value ?? Day.today();
  return entries.whenData((list) => computeUpcoming(list, today));
});

final themeModeProvider = StreamProvider<ThemeMode>((ref) => ref
    .watch(databaseProvider)
    .watchSetting('themeMode')
    .map((v) => ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system)));

/// Null while loading; true once the welcome screen has been completed.
final onboardedProvider = StreamProvider<bool>(
    (ref) => ref.watch(databaseProvider).watchSetting('onboarded').map((v) => v == 'true'));
