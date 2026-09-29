import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Anyone to remember, including the app's owner ([isMe]).
@DataClassName('Person')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get nickname => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get relationship => text().withDefault(const Constant('friend'))();
  TextColumn get customRelationship => text().nullable()();
  IntColumn get stars => integer().withDefault(const Constant(3))();
  IntColumn get birthYear => integer().nullable()();

  /// IANA time zone, e.g. "America/New_York". Null means the owner's.
  TextColumn get timeZone => text().nullable()();

  /// Normalised numbers (+91…). A null WhatsApp number means "same as call".
  TextColumn get callNumber => text().nullable()();
  TextColumn get whatsappNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get likes => text().nullable()();
  TextColumn get dislikes => text().nullable()();
  TextColumn get clothingSize => text().nullable()();
  TextColumn get favouriteSweets => text().nullable()();

  /// Phone contact this person is linked to, if any.
  TextColumn get contactId => text().nullable()();

  /// Android lookup key: finds the contact again if its id changes.
  TextColumn get contactLookupKey => text().nullable()();

  /// Comma-separated field names the user edited by hand ("callNumber",
  /// "whatsappNumber"). Contact sync never silently overwrites these.
  TextColumn get editedFields => text().withDefault(const Constant(''))();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// A birthday, anniversary, renewal or any other date.
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// [EventKind] name: person, couple or other.
  TextColumn get kind => text()();

  /// [EventType] name.
  TextColumn get type => text()();

  /// Label for custom types, e.g. "Housewarming".
  TextColumn get customLabel => text().nullable()();

  /// Title for non-person events, e.g. "Car insurance".
  TextColumn get title => text().nullable()();
  IntColumn get day => integer()();
  IntColumn get month => integer()();

  /// Start year: optional for yearly/monthly, required for one-time.
  IntColumn get year => integer().nullable()();

  /// [Repeat] name.
  TextColumn get repeat => text().withDefault(const Constant('yearly'))();

  /// [Feb29Rule] name.
  TextColumn get feb29Rule => text().withDefault(const Constant('feb28'))();

  /// Own rating; null means use the person's.
  IntColumn get stars => integer().nullable()();
  TextColumn get notes => text().nullable()();

  /// Person whose number Call and Share use (Phase 2).
  IntColumn get sendWishesToId => integer().nullable()();

  /// "mine" or "theirs" midnight (Phase 3).
  TextColumn get alarmClock => text().withDefault(const Constant('mine'))();
  TextColumn get draftMessage => text().nullable()();
  BoolColumn get belatedNudge => boolean().withDefault(const Constant(true))();
  TextColumn get sound => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Links an event to its person, or both people of a couple.
class EventPeople extends Table {
  IntColumn get eventId => integer().references(Events, #id, onDelete: KeyAction.cascade)();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();

  /// 0 = primary, 1 = partner. Sets the order in "Ravi & Priya".
  IntColumn get role => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {eventId, personId};
}

class GiftIdeas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get idea => text()();
  BoolColumn get purchased => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One-line notices such as "Chinnu's number changed in your contacts".
class ContactNotices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get message => text()();
  BoolColumn get seen => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [People, Events, EventPeople, GiftIdeas, ContactNotices, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'smriti'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---------- settings ----------
  Future<String?> getSetting(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Stream<String?> watchSetting(String key) => (select(settings)..where((s) => s.key.equals(key)))
      .watchSingleOrNull()
      .map((s) => s?.value);

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
