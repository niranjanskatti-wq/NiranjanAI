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

final allGiftsProvider = StreamProvider<List<GiftIdea>>((ref) => ref.watch(repoProvider).watchAllGifts());

final groupsProvider = StreamProvider<List<PersonGroup>>((ref) => ref.watch(repoProvider).watchGroups());

/// groupId → member person ids.
final groupMembersProvider = StreamProvider<Map<int, Set<int>>>((ref) => ref.watch(repoProvider).watchGroupMembers());

/// Group ids a person belongs to.
final personGroupIdsProvider = Provider.family<Set<int>, int>((ref, personId) {
  final m = ref.watch(groupMembersProvider).value ?? const {};
  return {for (final e in m.entries) if (e.value.contains(personId)) e.key};
});

final noticesProvider =
    StreamProvider<List<ContactNotice>>((ref) => ref.watch(repoProvider).watchUnseenNotices());

final wishLogsProvider = StreamProvider<List<WishLog>>((ref) => ref.watch(repoProvider).watchWishLogs());

/// "eventId|yyyy-mm-dd" keys of occurrences marked as wished.
final wishedKeysProvider = Provider<Set<String>>((ref) {
  final logs = ref.watch(wishLogsProvider).value ?? const [];
  return {
    for (final l in logs)
      if (l.confirmed && l.occasionDate != null) '${l.eventId ?? l.festivalId}|${l.occasionDate}',
  };
});

/// Today's date; emits again when the clock passes midnight.
final todayProvider = StreamProvider<Day>((ref) {
  final controller = StreamController<Day>();
  var last = Day.today();
  controller.add(last);
  final timer = Timer.periodic(const Duration(seconds: 20), (_) {
    final now = Day.today();
    if (now != last) {
      last = now;
      controller.add(now);
    }
  });
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
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
