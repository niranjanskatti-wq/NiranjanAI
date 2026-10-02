import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/providers.dart';

/// A session with its progress, for "Continue Diwali wishes (12 of 40)".
class SessionProgress {
  SessionProgress(this.session, this.total, this.done);

  final WishSession session;
  final int total, done;
}

final openSessionsProvider = StreamProvider<List<SessionProgress>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.wishSessions).join([
    leftOuterJoin(db.wishSessionItems, db.wishSessionItems.sessionId.equalsExp(db.wishSessions.id)),
  ])
    ..where(db.wishSessions.finished.equals(false));
  return q.watch().map((rows) {
    final m = <int, (WishSession, int, int)>{};
    for (final r in rows) {
      final s = r.readTable(db.wishSessions);
      final it = r.readTableOrNull(db.wishSessionItems);
      final cur = m[s.id] ?? (s, 0, 0);
      m[s.id] = (s, cur.$2 + (it == null ? 0 : 1), cur.$3 + (it != null && it.status != 'pending' ? 1 : 0));
    }
    return [for (final v in m.values) SessionProgress(v.$1, v.$2, v.$3)]
      ..sort((a, b) => b.session.createdAt.compareTo(a.session.createdAt));
  });
});

final sessionProvider = StreamProvider.family<WishSession?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.wishSessions)..where((s) => s.id.equals(id))).watchSingleOrNull();
});

final sessionItemsProvider = StreamProvider.family<List<WishSessionItem>, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.wishSessionItems)
        ..where((i) => i.sessionId.equals(id))
        ..orderBy([(i) => OrderingTerm(expression: i.position)]))
      .watch();
});

class WishModeRepo {
  WishModeRepo(this.db);

  final AppDatabase db;

  /// Starts a session. [people] are (personId, eventId) pairs in order.
  Future<int> create({
    required String title,
    String? festivalKey,
    required String date,
    required List<(int, int?)> people,
  }) =>
      db.transaction(() async {
        final id = await db.into(db.wishSessions).insert(
              WishSessionsCompanion.insert(title: title, festivalId: Value(festivalKey), occasionDate: date),
            );
        for (var i = 0; i < people.length; i++) {
          await db.into(db.wishSessionItems).insert(WishSessionItemsCompanion.insert(
                sessionId: id,
                personId: people[i].$1,
                eventId: Value(people[i].$2),
                position: i,
              ));
        }
        return id;
      });

  Future<void> setStatus(int itemId, String status, {String? message}) =>
      (db.update(db.wishSessionItems)..where((i) => i.id.equals(itemId))).write(WishSessionItemsCompanion(
        status: Value(status),
        message: message == null ? const Value.absent() : Value(message),
      ));

  Future<void> finish(int sessionId) => (db.update(db.wishSessions)..where((s) => s.id.equals(sessionId)))
      .write(const WishSessionsCompanion(finished: Value(true)));

  Future<void> delete(int sessionId) => (db.delete(db.wishSessions)..where((s) => s.id.equals(sessionId))).go();
}
