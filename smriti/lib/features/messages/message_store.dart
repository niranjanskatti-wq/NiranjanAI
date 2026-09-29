import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import 'message_engine.dart';

/// Built-in messages from assets/messages/*.json.
final libraryProvider = FutureProvider<MessageLibrary>((ref) => MessageLibrary.load());

final userMessagesProvider = StreamProvider<List<UserMessage>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.userMessages)..orderBy([(m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc)]))
      .watch();
});

final favouriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.favouriteMessages).watch().map((rows) => {for (final r in rows) r.templateId});
});

MessageTemplate userTemplate(UserMessage m) => MessageTemplate(
      id: 'u${m.id}',
      occasion: Occasion.parse(m.occasion) ?? Occasion.general,
      relations: m.relations.split(',').where((r) => r.isNotEmpty).toList(),
      tone: Tone.parse(m.tone),
      lang: Lang.parse(m.lang),
      text: m.body,
      festival: m.festival,
      custom: true,
    );

/// Everything the suggestion engine needs about the user's own messages.
class MessagePrefs {
  const MessagePrefs({required this.extra, required this.hidden, required this.favourites});

  final List<MessageTemplate> extra;

  /// Built-in ids replaced by an edited copy.
  final Set<String> hidden;
  final Set<String> favourites;

  static Future<MessagePrefs> load(AppDatabase db) async {
    final users = await db.select(db.userMessages).get();
    final favs = await db.select(db.favouriteMessages).get();
    return MessagePrefs(
      extra: users.map(userTemplate).toList(),
      hidden: {for (final u in users) ?u.baseId},
      favourites: {
        for (final f in favs) f.templateId,
        for (final u in users)
          if (u.favourite) 'u${u.id}',
      },
    );
  }
}

class MessageStore {
  MessageStore(this.db);

  final AppDatabase db;

  Future<void> toggleFavourite(MessageTemplate t, bool on) async {
    if (t.custom) {
      final id = int.parse(t.id.substring(1));
      await (db.update(db.userMessages)..where((m) => m.id.equals(id)))
          .write(UserMessagesCompanion(favourite: Value(on)));
    } else if (on) {
      await db.into(db.favouriteMessages).insertOnConflictUpdate(FavouriteMessagesCompanion.insert(templateId: t.id));
    } else {
      await (db.delete(db.favouriteMessages)..where((f) => f.templateId.equals(t.id))).go();
    }
  }

  /// Saves a new or edited message. Editing a built-in one stores a copy
  /// that replaces it everywhere.
  Future<void> save({
    MessageTemplate? original,
    required Occasion occasion,
    required List<String> relations,
    required Tone tone,
    required Lang lang,
    String? festival,
    required String text,
  }) async {
    final data = UserMessagesCompanion(
      occasion: Value(occasion.key),
      relations: Value(relations.isEmpty ? 'any' : relations.join(',')),
      tone: Value(tone.name),
      lang: Value(lang.name),
      festival: Value(occasion == Occasion.festival ? festival : null),
      body: Value(text),
    );
    if (original != null && original.custom) {
      final id = int.parse(original.id.substring(1));
      await (db.update(db.userMessages)..where((m) => m.id.equals(id))).write(data);
    } else {
      await db.into(db.userMessages).insert(data.copyWith(baseId: Value(original?.id)));
    }
  }

  Future<void> delete(MessageTemplate t) async {
    if (!t.custom) return;
    final id = int.parse(t.id.substring(1));
    await (db.delete(db.userMessages)..where((m) => m.id.equals(id))).go();
  }
}
