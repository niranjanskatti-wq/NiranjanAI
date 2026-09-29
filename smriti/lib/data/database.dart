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

  /// "auto" (ask if both are installed), "whatsapp" or "business".
  TextColumn get whatsappApp => text().withDefault(const Constant('auto'))();
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

  /// Planned spend in rupees.
  IntColumn get budget => integer().nullable()();

  /// Which occasion the gift is for.
  IntColumn get eventId => integer().nullable().references(Events, #id, onDelete: KeyAction.setNull)();
}

/// Family, Office, College friends… A person can be in several.
@DataClassName('PersonGroup')
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class GroupMembers extends Table {
  IntColumn get groupId => integer().references(Groups, #id, onDelete: KeyAction.cascade)();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {groupId, personId};
}

/// One-line notices such as "Chinnu's number changed in your contacts".
class ContactNotices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get message => text()();
  BoolColumn get seen => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One reminder switched on for an event.
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id, onDelete: KeyAction.cascade)();

  /// midnight, morning, custom, daysBefore, gift.
  TextColumn get kind => text()();

  /// 0 = on the day.
  IntColumn get daysBefore => integer().withDefault(const Constant(0))();

  /// Time of day in minutes after midnight (480 = 8:00 AM).
  IntColumn get minuteOfDay => integer().withDefault(const Constant(480))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}

/// Messages the user wrote, or edited copies of built-in ones ([baseId]).
class UserMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get occasion => text()();

  /// Comma-separated relation names or families, or "any".
  TextColumn get relations => text().withDefault(const Constant('any'))();
  TextColumn get tone => text().withDefault(const Constant('short'))();
  TextColumn get lang => text().withDefault(const Constant('en'))();
  TextColumn get festival => text().nullable()();
  TextColumn get body => text()();

  /// Built-in message this replaces, if it is an edit.
  TextColumn get baseId => text().nullable()();
  BoolColumn get favourite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Built-in messages marked as favourite.
class FavouriteMessages extends Table {
  TextColumn get templateId => text()();

  @override
  Set<Column> get primaryKey => {templateId};
}

/// Your changes to a built-in festival (assets/festivals/festivals.json).
class FestivalOverrides extends Table {
  TextColumn get festivalId => text()();
  BoolColumn get enabled => boolean().nullable()();
  TextColumn get name => text().nullable()();

  /// JSON map of year → "yyyy-mm-dd" for dates you corrected.
  TextColumn get dates => text().nullable()();

  /// Comma-separated relations to suggest in Wish Mode.
  TextColumn get suggest => text().nullable()();

  @override
  Set<Column> get primaryKey => {festivalId};
}

/// Festivals and special days you added yourself.
class CustomFestivals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Same date every year (month/day), or specific dates in [dates].
  IntColumn get month => integer().nullable()();
  IntColumn get day => integer().nullable()();
  TextColumn get dates => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get suggest => text().withDefault(const Constant(''))();
}

/// A Wish Mode run that can be paused and continued.
class WishSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// Festival key ("b:diwali_lakshmi_puja" / "c:3"), or null for "Today".
  TextColumn get festivalId => text().nullable()();
  TextColumn get occasionDate => text()();
  BoolColumn get finished => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WishSessionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WishSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();

  /// For "Today" sessions: the event being wished.
  IntColumn get eventId => integer().nullable()();
  IntColumn get position => integer()();

  /// pending, wished, skipped.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get message => text().nullable()();
}

/// Photos from each year's celebration, shown on the person's profile.
class PhotoMemories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get personId => integer().references(People, #id, onDelete: KeyAction.cascade)();
  IntColumn get year => integer()();
  TextColumn get path => text()();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Every call or share, and whether the event was marked as wished.
class WishLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Person the call or message went to.
  IntColumn get personId => integer().nullable().references(People, #id, onDelete: KeyAction.setNull)();
  IntColumn get eventId => integer().nullable().references(Events, #id, onDelete: KeyAction.setNull)();

  /// Festival id from assets/festivals (Phase 5).
  TextColumn get festivalId => text().nullable()();

  /// The occurrence this was for, "yyyy-mm-dd".
  TextColumn get occasionDate => text().nullable()();

  /// call, whatsapp, sms, copy, share, card, manual.
  TextColumn get method => text()();
  TextColumn get message => text().nullable()();
  TextColumn get templateId => text().nullable()();

  /// True once the user confirms "Mark as wished".
  BoolColumn get confirmed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  People, Events, EventPeople, GiftIdeas, ContactNotices, WishLogs, Reminders, UserMessages, FavouriteMessages,
  FestivalOverrides, CustomFestivals, WishSessions, WishSessionItems, PhotoMemories, Groups, GroupMembers, Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'smriti'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Skips a column that is already there, so a half-finished upgrade can be run again.
          Future<void> addColumn(TableInfo<Table, dynamic> table, GeneratedColumn column) async {
            final cols = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
            if (cols.any((c) => c.read<String>('name') == column.name)) return;
            await m.addColumn(table, column);
          }

          if (from < 2) {
            await addColumn(people, people.whatsappApp);
            await m.createTable(wishLogs);
          }
          if (from < 3) {
            await m.createTable(reminders);
            // Events made before reminders existed get the default morning reminder.
            await customStatement(
                "INSERT INTO reminders (event_id, kind, days_before, minute_of_day, enabled) "
                "SELECT id, 'morning', 0, 480, 1 FROM events WHERE kind != 'other'");
            await customStatement(
                "INSERT INTO reminders (event_id, kind, days_before, minute_of_day, enabled) "
                "SELECT id, 'daysBefore', d, 540, 1 FROM events, (SELECT 7 AS d UNION SELECT 1) WHERE kind = 'other'");
          }
          if (from < 4) {
            await m.createTable(userMessages);
            await m.createTable(favouriteMessages);
          }
          if (from < 5) {
            await m.createTable(festivalOverrides);
            await m.createTable(customFestivals);
            await m.createTable(wishSessions);
            await m.createTable(wishSessionItems);
          }
          if (from < 6) {
            await m.createTable(photoMemories);
          }
          if (from < 7) {
            await addColumn(giftIdeas, giftIdeas.budget);
            await addColumn(giftIdeas, giftIdeas.eventId);
            await m.createTable(groups);
            await m.createTable(groupMembers);
          }
        },
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
