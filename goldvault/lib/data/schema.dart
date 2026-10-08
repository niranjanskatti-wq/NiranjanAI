import 'package:sqflite_sqlcipher/sqlite_api.dart';

import '../core/format.dart';
import 'constants.dart';

const int kSchemaVersion = 1;

/// All tables, in dependency order. Used for creation, JSON backup and wipe.
const List<String> kTables = [
  'settings',
  'locations',
  'lockers',
  'items',
  'item_photos',
  'visits',
  'movements',
  'reminders',
  'notified',
];

Future<void> createSchema(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE settings(
      key TEXT PRIMARY KEY,
      value TEXT
    )''');
  await db.execute('''
    CREATE TABLE locations(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      parent_id INTEGER REFERENCES locations(id),
      color INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      closed_at TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0
    )''');
  await db.execute('''
    CREATE TABLE lockers(
      location_id INTEGER PRIMARY KEY REFERENCES locations(id),
      bank TEXT NOT NULL,
      branch TEXT,
      branch_address TEXT,
      locker_no TEXT,
      size TEXT,
      key_no TEXT,
      opened_date TEXT,
      holders TEXT,
      joint_holders TEXT,
      nominee TEXT,
      annual_rent REAL,
      rent_due_date TEXT,
      bank_contact TEXT,
      notes TEXT
    )''');
  await db.execute('''
    CREATE TABLE items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      serial TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      item_type TEXT,
      category TEXT NOT NULL,
      purity TEXT,
      gross_wt REAL,
      net_wt REAL,
      stone_wt REAL,
      pieces INTEGER NOT NULL DEFAULT 1,
      description TEXT,
      stones TEXT,
      huid TEXT,
      purchase_date TEXT,
      shop_name TEXT,
      bill_no TEXT,
      rate_per_gram REAL,
      making_charges REAL,
      gst REAL,
      total_price REAL,
      bill_photo TEXT,
      owner TEXT,
      occasion TEXT,
      gifted_by TEXT,
      location_id INTEGER REFERENCES locations(id),
      status TEXT NOT NULL,
      status_note TEXT,
      tags TEXT,
      notes TEXT,
      needs_details INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    )''');
  await db.execute('CREATE INDEX idx_items_location ON items(location_id)');
  await db.execute('''
    CREATE TABLE item_photos(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_id INTEGER NOT NULL REFERENCES items(id),
      file TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
    )''');
  await db.execute('''
    CREATE TABLE visits(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      location_id INTEGER NOT NULL REFERENCES locations(id),
      visit_date TEXT NOT NULL,
      time_in TEXT,
      time_out TEXT,
      visitors TEXT,
      purpose TEXT,
      notes TEXT,
      created_at TEXT
    )''');
  await db.execute('CREATE INDEX idx_visits_date ON visits(visit_date)');
  await db.execute('''
    CREATE TABLE movements(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_id INTEGER NOT NULL REFERENCES items(id),
      from_location_id INTEGER,
      to_location_id INTEGER,
      from_status TEXT,
      to_status TEXT NOT NULL,
      moved_at TEXT NOT NULL,
      visit_id INTEGER,
      action TEXT NOT NULL,
      note TEXT
    )''');
  await db.execute('CREATE INDEX idx_mov_item ON movements(item_id, moved_at)');
  await db.execute('CREATE INDEX idx_mov_visit ON movements(visit_id)');
  await db.execute('''
    CREATE TABLE reminders(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kind TEXT NOT NULL,
      title TEXT NOT NULL,
      due_date TEXT NOT NULL,
      location_id INTEGER,
      done INTEGER NOT NULL DEFAULT 0,
      notes TEXT
    )''');
  await db.execute('''
    CREATE TABLE notified(
      key TEXT PRIMARY KEY,
      at TEXT
    )''');
}

/// Pre-creates SBI locker, HDFC locker and Home with common sub-locations.
Future<void> seedDefaults(DatabaseExecutor db) async {
  final sbi = await db.insert('locations', {
    'name': 'SBI Bank Locker',
    'kind': Opt.kindLocker,
    'color': Opt.palette[0],
    'sort_order': 1,
  });
  await db.insert('lockers', {'location_id': sbi, 'bank': 'SBI', 'size': 'Medium'});
  final hdfc = await db.insert('locations', {
    'name': 'HDFC Bank Locker',
    'kind': Opt.kindLocker,
    'color': Opt.palette[1],
    'sort_order': 2,
  });
  await db.insert('lockers', {'location_id': hdfc, 'bank': 'HDFC', 'size': 'Medium'});
  final home = await db.insert('locations', {
    'name': 'Home',
    'kind': Opt.kindHome,
    'color': Opt.palette[3],
    'sort_order': 3,
  });
  var order = 0;
  for (final sub in ['Almirah', 'Safe', 'Drawer']) {
    await db.insert('locations', {
      'name': sub,
      'kind': Opt.kindPlace,
      'parent_id': home,
      'color': Opt.palette[3],
      'sort_order': ++order,
    });
  }
  await db.insert('settings', {'key': 'next_serial', 'value': '1'});
  await db.insert('settings', {
    'key': 'created_at',
    'value': Fmt.isoDateTime(DateTime.now()),
  });
}
