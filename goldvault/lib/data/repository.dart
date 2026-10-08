import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart';

import '../core/format.dart';
import 'constants.dart';
import 'models.dart';
import 'schema.dart';

/// Filter + sort for the inventory list.
class ItemQuery {
  final String text;
  final Set<String> categories;
  final Set<int> locationIds; // -1 = "not in a locker/home" (worn, lent ...)
  final Set<String> statuses;
  final Set<String> owners;
  final String sort; // serial / name / weight / date / purchase
  final bool descending;

  const ItemQuery({
    this.text = '',
    this.categories = const {},
    this.locationIds = const {},
    this.statuses = const {},
    this.owners = const {},
    this.sort = 'serial',
    this.descending = false,
  });

  bool get hasFilters =>
      categories.isNotEmpty || locationIds.isNotEmpty || statuses.isNotEmpty || owners.isNotEmpty;

  ItemQuery copyWith({
    String? text,
    Set<String>? categories,
    Set<int>? locationIds,
    Set<String>? statuses,
    Set<String>? owners,
    String? sort,
    bool? descending,
  }) =>
      ItemQuery(
        text: text ?? this.text,
        categories: categories ?? this.categories,
        locationIds: locationIds ?? this.locationIds,
        statuses: statuses ?? this.statuses,
        owners: owners ?? this.owners,
        sort: sort ?? this.sort,
        descending: descending ?? this.descending,
      );
}

/// Where an item is right now, plus when it last moved.
class WhereIs {
  final Item item;
  final Location? location;
  final Movement? lastMove;
  final DateTime? takenOut; // when it left the locker (if it is out now)
  const WhereIs(this.item, this.location, this.lastMove, [this.takenOut]);
}

class VisitWithMoves {
  final Visit visit;
  final List<Movement> deposited;
  final List<Movement> withdrawn;
  const VisitWithMoves(this.visit, this.deposited, this.withdrawn);
}

/// Single entry point for all local data. All writes bump [revision] so open
/// screens refresh, and mark the data dirty for the next Google Sheets sync.
class VaultRepo {
  VaultRepo(this.db);

  final Database db;
  final ValueNotifier<int> revision = ValueNotifier(0);

  String _now() => Fmt.isoDateTime(DateTime.now());

  Future<void> _changed() async {
    await setSetting('sync_dirty', '1');
    revision.value++;
  }

  // ---------------------------------------------------------------- settings

  Future<String?> getSetting(String key) async {
    final r = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return r.isEmpty ? null : r.first['value'] as String?;
  }

  Future<void> setSetting(String key, String? value) async {
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String?>> allSettings() async {
    final r = await db.query('settings');
    return {for (final m in r) m['key'] as String: m['value'] as String?};
  }

  Future<Prefs> prefs() async => Prefs(await allSettings());

  Future<void> setPref(String key, Object value) async {
    await setSetting(key, value is bool ? (value ? '1' : '0') : '$value');
    revision.value++;
  }

  Future<Rates> rates() async {
    final s = await allSettings();
    double v(String k) => double.tryParse(s[k] ?? '') ?? 0;
    return Rates(gold24: v('rate_gold24'), silver: v('rate_silver'), platinum: v('rate_platinum'));
  }

  /// Rates used for value estimates; empty (no values shown anywhere)
  /// unless "Show current prices & estimated value" is switched on.
  Future<Rates> valueRates() async => (await prefs()).showValues ? await rates() : const Rates();

  Future<void> saveRates(Rates r) async {
    await setSetting('rate_gold24', r.gold24.toString());
    await setSetting('rate_silver', r.silver.toString());
    await setSetting('rate_platinum', r.platinum.toString());
    await setSetting('rates_updated', _now());
    revision.value++;
  }

  // --------------------------------------------------------------- locations

  Future<List<Location>> locations({bool includeClosed = false}) async {
    final r = await db.query('locations',
        where: includeClosed ? null : "status = 'active'", orderBy: 'sort_order, id');
    return r.map(Location.fromMap).toList();
  }

  Future<Location?> location(int id) async {
    final r = await db.query('locations', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Location.fromMap(r.first);
  }

  Future<Map<int, Location>> locationMap() async =>
      {for (final l in await locations(includeClosed: true)) l.id!: l};

  Future<LockerInfo?> lockerInfo(int locationId) async {
    final r = await db.query('lockers', where: 'location_id = ?', whereArgs: [locationId]);
    return r.isEmpty ? null : LockerInfo.fromMap(r.first);
  }

  Future<Map<int, LockerInfo>> allLockerInfo() async {
    final r = await db.query('lockers');
    return {for (final m in r) m['location_id'] as int: LockerInfo.fromMap(m)};
  }

  Future<int> _nextColor(DatabaseExecutor e) async {
    final used = (await e.query('locations', columns: ['color'], where: "kind = 'locker'"))
        .map((e) => e['color'] as int)
        .toSet();
    for (final c in Opt.palette) {
      if (!used.contains(c)) return c;
    }
    return Opt.palette[used.length % Opt.palette.length];
  }

  Future<int> _nextOrder(DatabaseExecutor e) async {
    final r = await e.rawQuery('SELECT MAX(sort_order) AS m FROM locations');
    return ((r.first['m'] as int?) ?? 0) + 1;
  }

  /// Create or update a bank locker.
  Future<int> saveLocker({int? id, required String name, required LockerInfo info, int? color}) async {
    return db.transaction((txn) async {
      int locId;
      if (id == null) {
        locId = await txn.insert('locations', {
          'name': name.trim(),
          'kind': Opt.kindLocker,
          'color': color ?? await _nextColor(txn),
          'sort_order': await _nextOrder(txn),
        });
      } else {
        locId = id;
        await txn.update('locations', {'name': name.trim(), 'color': ?color},
            where: 'id = ?', whereArgs: [id]);
      }
      await txn.insert('lockers', info.toMap(locId), conflictAlgorithm: ConflictAlgorithm.replace);
      return locId;
    }).whenComplete(_changed);
  }

  /// Add a home sub-location (parentId = Home) or a new top-level place.
  Future<int> addPlace(String name, {int? parentId}) async {
    final parent = parentId == null ? null : await location(parentId);
    final id = await db.insert('locations', {
      'name': name.trim(),
      'kind': Opt.kindPlace,
      'parent_id': parentId,
      'color': parent?.color ?? Opt.palette[3],
      'sort_order': await _nextOrder(db),
    });
    await _changed();
    return id;
  }

  Future<void> renameLocation(int id, String name) async {
    await db.update('locations', {'name': name.trim()}, where: 'id = ?', whereArgs: [id]);
    await _changed();
  }

  /// Locations can only be deleted when nothing ever referenced them.
  Future<bool> canDeleteLocation(int id) async {
    final a = await db.rawQuery(
        'SELECT (SELECT COUNT(*) FROM items WHERE location_id = ?) + '
        '(SELECT COUNT(*) FROM movements WHERE from_location_id = ? OR to_location_id = ?) + '
        '(SELECT COUNT(*) FROM visits WHERE location_id = ?) + '
        '(SELECT COUNT(*) FROM locations WHERE parent_id = ?) AS n',
        [id, id, id, id, id]);
    return (a.first['n'] as int) == 0;
  }

  Future<bool> deleteLocation(int id) async {
    if (!await canDeleteLocation(id)) return false;
    await db.delete('lockers', where: 'location_id = ?', whereArgs: [id]);
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
    await _changed();
    return true;
  }

  /// Closes a locker. Any items still inside are first moved to [moveToId]
  /// (required when the locker is not empty). History is preserved.
  Future<void> closeLocker(int id, {int? moveToId, DateTime? at}) async {
    final items = await itemsAt(id);
    if (items.isNotEmpty && moveToId == null) {
      throw StateError('Locker still has ${items.length} items');
    }
    final when = at ?? DateTime.now();
    final dest = moveToId == null ? null : await location(moveToId);
    await db.transaction((txn) async {
      for (final i in items) {
        await _move(txn, i,
            toLocationId: moveToId,
            toStatus: dest!.isLocker ? Opt.inLocker : Opt.atHome,
            at: when,
            action: 'close',
            note: 'Locker closed');
      }
      await txn.update('locations', {'status': 'closed', 'closed_at': Fmt.isoDateTime(when)},
          where: 'id = ?', whereArgs: [id]);
    });
    await _changed();
  }

  Future<void> reopenLocation(int id) async {
    await db.update('locations', {'status': 'active', 'closed_at': null},
        where: 'id = ?', whereArgs: [id]);
    await _changed();
  }

  /// Advances an annual rent due date by one year after payment.
  Future<void> markRentPaid(int locationId) async {
    final info = await lockerInfo(locationId);
    if (info == null) return;
    final due = Fmt.parse(info.rentDueDate) ?? DateTime.now();
    final next = DateTime(due.year + 1, due.month, due.day);
    await db.update('lockers', {'rent_due_date': Fmt.isoDate(next)},
        where: 'location_id = ?', whereArgs: [locationId]);
    await _changed();
  }

  /// Totals per location id (active items only). Key null = out (worn/lent…).
  Future<Map<int?, Totals>> totalsByLocation() async {
    final r = await valueRates();
    final out = <int?, Totals>{};
    for (final i in await items(const ItemQuery())) {
      if (!i.isActive) continue;
      out.putIfAbsent(i.locationId, Totals.new).add(i, r);
    }
    return out;
  }

  // ------------------------------------------------------------------- items

  Future<String> peekNextSerial() async =>
      Fmt.serial(int.tryParse(await getSetting('next_serial') ?? '1') ?? 1);

  Future<String> _takeSerial(DatabaseExecutor txn) async {
    final r = await txn.query('settings', where: "key = 'next_serial'");
    var n = r.isEmpty ? 1 : int.tryParse(r.first['value'] as String? ?? '1') ?? 1;
    // Guard against collisions (e.g. after a manual restore).
    while ((await txn.query('items', where: 'serial = ?', whereArgs: [Fmt.serial(n)])).isNotEmpty) {
      n++;
    }
    await txn.insert('settings', {'key': 'next_serial', 'value': '${n + 1}'},
        conflictAlgorithm: ConflictAlgorithm.replace);
    return Fmt.serial(n);
  }

  Future<Item> createItem(Item item, {List<String> photos = const [], DateTime? at}) async {
    final now = at ?? DateTime.now();
    late Item saved;
    await db.transaction((txn) async {
      final serial = await _takeSerial(txn);
      final toInsert = item.copyWith(
          serial: serial, createdAt: Fmt.isoDateTime(now), updatedAt: Fmt.isoDateTime(now));
      final m = toInsert.toMap()..remove('id');
      final id = await txn.insert('items', m);
      saved = toInsert.copyWith(id: id);
      var order = 0;
      for (final p in photos) {
        await txn.insert('item_photos', {'item_id': id, 'file': p, 'sort_order': order++});
      }
      await txn.insert(
          'movements',
          Movement(
            itemId: id,
            toLocationId: item.locationId,
            toStatus: item.status,
            movedAt: Fmt.isoDateTime(now),
            action: 'create',
            note: 'Added to GoldVault',
          ).toMap());
    });
    await _changed();
    return saved;
  }

  /// Updates details. Location/status changes go through [moveItem] so that
  /// they are recorded in the movement history.
  Future<void> updateItem(Item item, {List<String>? photos}) async {
    final old = await this.item(item.id!);
    if (old == null) return;
    await db.transaction((txn) async {
      final m = item
          .copyWith(updatedAt: _now(), createdAt: old.createdAt, serial: old.serial)
          .toMap()
        ..remove('id');
      await txn.update('items', m, where: 'id = ?', whereArgs: [item.id]);
      if (old.locationId != item.locationId || old.status != item.status) {
        await txn.insert(
            'movements',
            Movement(
              itemId: item.id!,
              fromLocationId: old.locationId,
              toLocationId: item.locationId,
              fromStatus: old.status,
              toStatus: item.status,
              movedAt: _now(),
              action: 'move',
              note: item.statusNote,
            ).toMap());
      }
      if (photos != null) {
        await txn.delete('item_photos', where: 'item_id = ?', whereArgs: [item.id]);
        var order = 0;
        for (final p in photos) {
          await txn.insert('item_photos', {'item_id': item.id, 'file': p, 'sort_order': order++});
        }
      }
    });
    await _changed();
  }

  /// Only for entries made by mistake. Normal flow is to mark sold/gifted.
  Future<List<String>> deleteItem(int id) async {
    final photos = await photosFor(id);
    final it = await item(id);
    await db.transaction((txn) async {
      await txn.delete('item_photos', where: 'item_id = ?', whereArgs: [id]);
      await txn.delete('movements', where: 'item_id = ?', whereArgs: [id]);
      await txn.delete('items', where: 'id = ?', whereArgs: [id]);
    });
    await _changed();
    return [...photos.map((p) => p.file), if (it?.billPhoto != null) it!.billPhoto!];
  }

  Future<Item?> item(int id) async {
    final r = await db.query('items', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Item.fromMap(r.first);
  }

  Future<List<Item>> itemsAt(int locationId, {bool includeChildren = false}) async {
    final ids = [locationId];
    if (includeChildren) {
      final kids = await db.query('locations', where: 'parent_id = ?', whereArgs: [locationId]);
      ids.addAll(kids.map((e) => e['id'] as int));
    }
    final r = await db.query('items',
        where: 'location_id IN (${List.filled(ids.length, '?').join(',')}) AND status IN (?, ?)',
        whereArgs: [...ids, Opt.inLocker, Opt.atHome],
        orderBy: 'serial');
    return r.map(Item.fromMap).toList();
  }

  Future<List<Item>> items(ItemQuery q) async {
    final where = <String>[];
    final args = <Object?>[];
    if (q.statuses.isNotEmpty) {
      where.add('i.status IN (${List.filled(q.statuses.length, '?').join(',')})');
      args.addAll(q.statuses);
    }
    if (q.categories.isNotEmpty) {
      where.add('i.category IN (${List.filled(q.categories.length, '?').join(',')})');
      args.addAll(q.categories);
    }
    if (q.owners.isNotEmpty) {
      where.add('i.owner IN (${List.filled(q.owners.length, '?').join(',')})');
      args.addAll(q.owners);
    }
    if (q.locationIds.isNotEmpty) {
      final ids = q.locationIds.where((e) => e > 0).toList();
      final parts = <String>[];
      if (ids.isNotEmpty) {
        parts.add('i.location_id IN (${List.filled(ids.length, '?').join(',')}) '
            'OR l.parent_id IN (${List.filled(ids.length, '?').join(',')})');
        args
          ..addAll(ids)
          ..addAll(ids);
      }
      if (q.locationIds.contains(-1)) parts.add('i.location_id IS NULL');
      where.add('(${parts.join(' OR ')})');
    }
    final text = q.text.trim().toLowerCase();
    if (text.isNotEmpty) {
      final like = '%$text%';
      where.add('(LOWER(i.name) LIKE ? OR LOWER(i.serial) LIKE ? OR LOWER(IFNULL(i.owner,\'\')) LIKE ? '
          'OR LOWER(IFNULL(i.tags,\'\')) LIKE ? OR LOWER(IFNULL(l.name,\'\')) LIKE ? '
          'OR LOWER(IFNULL(i.huid,\'\')) LIKE ? OR LOWER(IFNULL(i.item_type,\'\')) LIKE ? '
          'OR LOWER(IFNULL(i.description,\'\')) LIKE ? OR LOWER(i.category) LIKE ?)');
      args.addAll(List.filled(9, like));
    }
    final dir = q.descending ? 'DESC' : 'ASC';
    final order = switch (q.sort) {
      'name' => 'LOWER(i.name) $dir, i.serial',
      'weight' => 'COALESCE(NULLIF(i.net_wt, 0), i.gross_wt, 0) $dir, i.serial',
      'date' => 'i.created_at $dir, i.serial',
      'purchase' => 'IFNULL(i.purchase_date, \'\') $dir, i.serial',
      'category' => 'i.category $dir, i.serial',
      'location' => 'IFNULL(l.name, \'~\') $dir, i.serial',
      _ => 'i.serial $dir',
    };
    final r = await db.rawQuery(
        'SELECT i.* FROM items i LEFT JOIN locations l ON l.id = i.location_id '
        '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} ORDER BY $order',
        args);
    return r.map(Item.fromMap).toList();
  }

  /// Built-in categories plus any the family created (e.g. "Brass").
  Future<List<String>> categories() async =>
      {...Opt.categories, ...await distinct('category')}.toList();

  /// Built-in ornament types plus custom ones already used.
  Future<List<String>> itemTypes() async =>
      {...Opt.itemTypes, ...await distinct('item_type')}.toList();

  Future<List<String>> owners() async {
    final r = await db.rawQuery(
        "SELECT DISTINCT owner FROM items WHERE owner IS NOT NULL AND owner != '' ORDER BY owner");
    return r.map((e) => e['owner'] as String).toList();
  }

  Future<List<String>> allTags() async {
    final r = await db.rawQuery("SELECT tags FROM items WHERE tags IS NOT NULL AND tags != ''");
    final s = <String>{};
    for (final m in r) {
      s.addAll((m['tags'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    return s.toList()..sort();
  }

  Future<List<String>> distinct(String column) async {
    const allowed = {'shop_name', 'occasion', 'gifted_by', 'item_type', 'purity', 'category'};
    if (!allowed.contains(column)) return [];
    final r = await db.rawQuery(
        "SELECT DISTINCT $column AS v FROM items WHERE $column IS NOT NULL AND $column != '' ORDER BY v");
    return r.map((e) => e['v'] as String).toList();
  }

  // ------------------------------------------------------------------ photos

  Future<List<ItemPhoto>> photosFor(int itemId) async {
    final r = await db.query('item_photos',
        where: 'item_id = ?', whereArgs: [itemId], orderBy: 'sort_order');
    return r.map(ItemPhoto.fromMap).toList();
  }

  /// Attach photos to an item (appended after existing ones).
  Future<void> addPhotos(int itemId, List<String> files) async {
    if (files.isEmpty) return;
    await db.transaction((txn) async {
      final r = await txn.rawQuery('SELECT MAX(sort_order) AS m FROM item_photos WHERE item_id = ?', [itemId]);
      var order = ((r.first['m'] as int?) ?? -1) + 1;
      for (final f in files) {
        await txn.insert('item_photos', {'item_id': itemId, 'file': f, 'sort_order': order++});
      }
    });
    await _changed();
  }

  /// Detach a photo; returns its file name so the caller can delete it.
  Future<String?> removePhoto(int photoId) async {
    final r = await db.query('item_photos', where: 'id = ?', whereArgs: [photoId]);
    if (r.isEmpty) return null;
    await db.delete('item_photos', where: 'id = ?', whereArgs: [photoId]);
    await _changed();
    return r.first['file'] as String;
  }

  /// Make a photo the item's main (first) photo.
  Future<void> setMainPhoto(int itemId, int photoId) async {
    final list = await photosFor(itemId);
    final ordered = [...list.where((p) => p.id == photoId), ...list.where((p) => p.id != photoId)];
    await db.transaction((txn) async {
      for (var i = 0; i < ordered.length; i++) {
        await txn.update('item_photos', {'sort_order': i}, where: 'id = ?', whereArgs: [ordered[i].id]);
      }
    });
    await _changed();
  }

  Future<void> setBillPhoto(int itemId, String? file) async {
    await db.update('items', {'bill_photo': file, 'updated_at': _now()}, where: 'id = ?', whereArgs: [itemId]);
    await _changed();
  }

  Future<Map<int, String>> firstPhotos() async {
    final r = await db.rawQuery(
        'SELECT item_id, file FROM item_photos p WHERE sort_order = '
        '(SELECT MIN(sort_order) FROM item_photos q WHERE q.item_id = p.item_id)');
    return {for (final m in r) m['item_id'] as int: m['file'] as String};
  }

  Future<List<String>> allPhotoFiles() async {
    final a = await db.query('item_photos', columns: ['file']);
    final b = await db.rawQuery('SELECT bill_photo AS file FROM items WHERE bill_photo IS NOT NULL');
    return [...a, ...b].map((e) => e['file'] as String).toList();
  }

  // --------------------------------------------------------------- movements

  Future<void> _move(
    DatabaseExecutor txn,
    Item i, {
    required int? toLocationId,
    required String toStatus,
    required DateTime at,
    required String action,
    int? visitId,
    String? note,
  }) async {
    final placed = Opt.placedStatuses.contains(toStatus);
    final newLoc = placed ? toLocationId : null;
    await txn.update(
        'items',
        {
          'location_id': newLoc,
          'status': toStatus,
          'status_note': (note == null || note.trim().isEmpty || placed) ? null : note.trim(),
          'updated_at': _now(),
        },
        where: 'id = ?',
        whereArgs: [i.id]);
    await txn.insert(
        'movements',
        Movement(
          itemId: i.id!,
          fromLocationId: i.locationId,
          toLocationId: newLoc,
          fromStatus: i.status,
          toStatus: toStatus,
          movedAt: Fmt.isoDateTime(at),
          visitId: visitId,
          action: action,
          note: note,
        ).toMap());
  }

  /// Move an item to a location and/or change its status (worn, lent, sold…).
  Future<void> moveItem(int itemId,
      {int? toLocationId, required String toStatus, DateTime? at, String? note}) async {
    final i = await item(itemId);
    if (i == null) return;
    if (Opt.placedStatuses.contains(toStatus) && toLocationId == null) {
      throw ArgumentError('A location is required for $toStatus');
    }
    await db.transaction((txn) => _move(txn, i,
        toLocationId: toLocationId,
        toStatus: toStatus,
        at: at ?? DateTime.now(),
        action: Opt.placedStatuses.contains(toStatus) ? 'move' : 'status',
        note: note));
    await _changed();
  }

  static const _movementSelect =
      'SELECT m.*, i.name AS item_name, i.serial AS item_serial, '
      'lf.name AS from_name, lt.name AS to_name FROM movements m '
      'JOIN items i ON i.id = m.item_id '
      'LEFT JOIN locations lf ON lf.id = m.from_location_id '
      'LEFT JOIN locations lt ON lt.id = m.to_location_id ';

  Future<List<Movement>> historyFor(int itemId) async {
    final r = await db.rawQuery(
        '$_movementSelect WHERE m.item_id = ? ORDER BY m.moved_at DESC, m.id DESC', [itemId]);
    return r.map(Movement.fromMap).toList();
  }

  Future<List<Movement>> recentMovements({int limit = 10}) async {
    final r = await db.rawQuery(
        "$_movementSelect WHERE m.action != 'create' ORDER BY m.moved_at DESC, m.id DESC LIMIT ?",
        [limit]);
    return r.map(Movement.fromMap).toList();
  }

  Future<List<Movement>> allMovements() async {
    final r = await db.rawQuery('$_movementSelect ORDER BY m.moved_at DESC, m.id DESC');
    return r.map(Movement.fromMap).toList();
  }

  Future<List<Movement>> movementsOn(DateTime day) async {
    final d = Fmt.isoDate(day);
    final r = await db.rawQuery(
        "$_movementSelect WHERE substr(m.moved_at, 1, 10) = ? ORDER BY m.moved_at, m.id", [d]);
    return r.map(Movement.fromMap).toList();
  }

  Future<Movement?> lastMove(int itemId) async {
    final r = await db.rawQuery(
        '$_movementSelect WHERE m.item_id = ? ORDER BY m.moved_at DESC, m.id DESC LIMIT 1',
        [itemId]);
    return r.isEmpty ? null : Movement.fromMap(r.first);
  }

  /// When each ornament that is NOT in a locker now was last taken out of one.
  Future<Map<int, DateTime>> takenOutTimes() async {
    final r = await db.rawQuery('''
      SELECT m.item_id AS id, MAX(m.moved_at) AS at FROM movements m
      JOIN items i ON i.id = m.item_id
      WHERE m.from_status = ? AND i.status != ?
      GROUP BY m.item_id''', [Opt.inLocker, Opt.inLocker]);
    return {for (final m in r) m['id'] as int: DateTime.parse(m['at'] as String)};
  }

  /// Ornaments with an open "put back in locker" reminder → that due time.
  Future<Map<int, DateTime>> returnByTimes(String defaultTime) async {
    final out = <int, DateTime>{};
    for (final r in await reminders()) {
      if (r.kind != 'keep' || !r.enabled) continue;
      final at = r.at(defaultTime);
      for (final id in r.itemIds) {
        final cur = out[id];
        if (cur == null || at.isBefore(cur)) out[id] = at;
      }
    }
    return out;
  }

  /// When the item last entered [status] (e.g. when it went for repair).
  Future<Movement?> lastMoveTo(int itemId, String status) async {
    final r = await db.rawQuery(
        '$_movementSelect WHERE m.item_id = ? AND m.to_status = ? ORDER BY m.moved_at DESC, m.id DESC LIMIT 1',
        [itemId, status]);
    return r.isEmpty ? null : Movement.fromMap(r.first);
  }

  /// "Where is my …?"
  Future<List<WhereIs>> whereIs(String text) async {
    final found = await items(ItemQuery(text: text, sort: 'name'));
    final locs = await locationMap();
    final taken = await takenOutTimes();
    final out = <WhereIs>[];
    for (final i in found.take(50)) {
      out.add(WhereIs(i, i.locationId == null ? null : locs[i.locationId], await lastMove(i.id!), i.isActive ? taken[i.id] : null));
    }
    return out;
  }

  // ------------------------------------------------------------------ visits

  /// Records a locker visit. Items in [deposit] move into the locker; items in
  /// [withdraw] move to [withdrawTo] with [withdrawStatus].
  Future<int> logVisit(
    Visit v, {
    List<int> deposit = const [],
    List<int> withdraw = const [],
    int? withdrawTo,
    String withdrawStatus = Opt.atHome,
    String? withdrawNote,
  }) async {
    if (withdraw.isNotEmpty && Opt.placedStatuses.contains(withdrawStatus) && withdrawTo == null) {
      throw ArgumentError('Choose where withdrawn items are kept');
    }
    final id = await db.transaction((txn) async {
      final vid = await txn.insert('visits', (v.toMap()..remove('id'))..['created_at'] = _now());
      final depositAt = v.at(v.timeIn);
      final withdrawAt = v.at(v.timeOut ?? v.timeIn);
      for (final itemId in deposit) {
        final r = await txn.query('items', where: 'id = ?', whereArgs: [itemId]);
        if (r.isEmpty) continue;
        await _move(txn, Item.fromMap(r.first),
            toLocationId: v.locationId,
            toStatus: Opt.inLocker,
            at: depositAt,
            action: 'deposit',
            visitId: vid);
      }
      for (final itemId in withdraw) {
        final r = await txn.query('items', where: 'id = ?', whereArgs: [itemId]);
        if (r.isEmpty) continue;
        await _move(txn, Item.fromMap(r.first),
            toLocationId: withdrawTo,
            toStatus: withdrawStatus,
            at: withdrawAt,
            action: 'withdraw',
            visitId: vid,
            note: withdrawNote);
      }
      // A logged visit fulfils any planned visit for this locker on that day.
      await txn.update('reminders', {'done': 1},
          where: "kind = 'planned_visit' AND repeat = 'none' AND location_id = ? AND due_date <= ? AND done = 0",
          whereArgs: [v.locationId, v.visitDate]);
      // "Put back in locker" reminders are done once all their items are in a locker.
      final keeps = await txn.query('reminders', where: "kind = 'keep' AND done = 0 AND item_ids IS NOT NULL");
      for (final k in keeps.map(Reminder.fromMap)) {
        final rows = await txn.query('items',
            where: 'id IN (${List.filled(k.itemIds.length, '?').join(',')})', whereArgs: k.itemIds);
        if (rows.isNotEmpty && rows.every((r) => r['status'] == Opt.inLocker)) {
          await txn.update('reminders', {'done': 1}, where: 'id = ?', whereArgs: [k.id]);
        }
      }
      return vid;
    });
    await _changed();
    return id;
  }

  Future<void> updateVisit(Visit v) async {
    await db.update('visits', v.toMap()..remove('id')..remove('created_at'),
        where: 'id = ?', whereArgs: [v.id]);
    await _changed();
  }

  /// Visits that moved items can't be deleted (history must stay intact).
  Future<bool> deleteVisit(int id) async {
    final n = await db.query('movements', where: 'visit_id = ?', whereArgs: [id]);
    if (n.isNotEmpty) return false;
    await db.delete('visits', where: 'id = ?', whereArgs: [id]);
    await _changed();
    return true;
  }

  Future<List<Visit>> visits({DateTime? from, DateTime? to, int? locationId}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('visit_date >= ?');
      args.add(Fmt.isoDate(from));
    }
    if (to != null) {
      where.add('visit_date <= ?');
      args.add(Fmt.isoDate(to));
    }
    if (locationId != null) {
      where.add('location_id = ?');
      args.add(locationId);
    }
    final r = await db.query('visits',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args,
        orderBy: 'visit_date DESC, time_in DESC');
    return r.map(Visit.fromMap).toList();
  }

  Future<VisitWithMoves?> visitDetail(int id) async {
    final r = await db.query('visits', where: 'id = ?', whereArgs: [id]);
    if (r.isEmpty) return null;
    final m = await db.rawQuery('$_movementSelect WHERE m.visit_id = ? ORDER BY m.id', [id]);
    final moves = m.map(Movement.fromMap).toList();
    return VisitWithMoves(
      Visit.fromMap(r.first),
      moves.where((e) => e.action == 'deposit').toList(),
      moves.where((e) => e.action == 'withdraw').toList(),
    );
  }

  Future<Map<int, int>> visitItemCounts() async {
    final r = await db.rawQuery(
        'SELECT visit_id, COUNT(*) AS n FROM movements WHERE visit_id IS NOT NULL GROUP BY visit_id');
    return {for (final m in r) m['visit_id'] as int: m['n'] as int};
  }

  // --------------------------------------------------------------- reminders

  Future<List<Reminder>> reminders({bool includeDone = false}) async {
    final r = await db.query('reminders',
        where: includeDone ? null : 'done = 0', orderBy: 'due_date');
    return r.map(Reminder.fromMap).toList();
  }

  Future<int> saveReminder(Reminder r) async {
    int id;
    if (r.id == null) {
      id = await db.insert('reminders', r.toMap()..remove('id'));
    } else {
      id = r.id!;
      await db.update('reminders', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
    }
    await _changed();
    return id;
  }

  Future<Reminder?> reminder(int id) async {
    final r = await db.query('reminders', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Reminder.fromMap(r.first);
  }

  /// Marking a repeating reminder done moves it to its next occurrence.
  Future<void> setReminderDone(int id, bool done) async {
    final r = await reminder(id);
    if (r == null) return;
    // "Until put back" reminders finish when done; other repeats roll forward.
    final next = done && !r.untilBack ? r.nextAfter(DateTime.parse(r.dueDate)) : null;
    if (next != null) {
      await db.update('reminders', {'due_date': Fmt.isoDate(next), 'done': 0}, where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update('reminders', {'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
    }
    await _changed();
  }

  /// Open reminders/alarms linked to one ornament.
  Future<List<Reminder>> remindersForItem(int itemId) async =>
      (await reminders()).where((r) => r.itemIds.contains(itemId)).toList();

  Future<void> setReminderEnabled(int id, bool enabled) async {
    await db.update('reminders', {'enabled': enabled ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
    await _changed();
  }

  // ---------------------------------------------------------------- holidays

  Future<List<Holiday>> holidays() async =>
      (await db.query('holidays', orderBy: 'COALESCE(date, md)')).map(Holiday.fromMap).toList();

  Future<int> saveHoliday(Holiday h) async {
    int id;
    if (h.id == null) {
      id = await db.insert('holidays', h.toMap()..remove('id'));
    } else {
      id = h.id!;
      await db.update('holidays', h.toMap(), where: 'id = ?', whereArgs: [h.id]);
    }
    await _changed();
    return id;
  }

  Future<void> deleteHoliday(int id) async {
    await db.delete('holidays', where: 'id = ?', whereArgs: [id]);
    await _changed();
  }

  Future<void> deleteReminder(int id) async {
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    await _changed();
  }

  Future<bool> wasNotified(String key) async =>
      (await db.query('notified', where: 'key = ?', whereArgs: [key])).isNotEmpty;

  Future<void> markNotified(String key) async => db.insert(
      'notified', {'key': key, 'at': _now()},
      conflictAlgorithm: ConflictAlgorithm.replace);

  // ------------------------------------------------------- backup/restore io

  /// Every table as plain rows (for encrypted backup).
  Future<Map<String, List<Map<String, Object?>>>> dumpAll() async {
    final out = <String, List<Map<String, Object?>>>{};
    for (final t in kTables) {
      out[t] = await db.query(t);
    }
    return out;
  }

  /// Replace everything with [data] (from a backup). Settings that belong to
  /// this device (sync/backup state) are kept.
  Future<void> restoreAll(Map<String, dynamic> data, {Set<String> keepSettings = const {}}) async {
    final kept = <String, String?>{};
    for (final k in keepSettings) {
      kept[k] = await getSetting(k);
    }
    await db.transaction((txn) async {
      for (final t in kTables.reversed) {
        await txn.delete(t);
      }
      final batch = txn.batch();
      for (final t in kTables) {
        final rows = (data[t] as List?) ?? const [];
        for (final row in rows) {
          batch.insert(t, Map<String, Object?>.from(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      for (final e in kept.entries) {
        if (e.value != null) {
          batch.insert('settings', {'key': e.key, 'value': e.value},
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      await batch.commit(noResult: true);
    });
    await _changed();
  }
}
