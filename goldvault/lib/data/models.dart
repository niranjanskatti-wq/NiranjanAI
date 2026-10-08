import 'constants.dart';

double? _d(Object? v) => v == null ? null : (v as num).toDouble();
int? _i(Object? v) => v == null ? null : (v as num).toInt();
String? _s(Object? v) => v as String?;
String? _blank(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

class Location {
  final int? id;
  final String name;
  final String kind; // locker / home / place
  final int? parentId;
  final int color;
  final String status; // active / closed
  final String? closedAt;
  final int sortOrder;

  const Location({
    this.id,
    required this.name,
    required this.kind,
    this.parentId,
    required this.color,
    this.status = 'active',
    this.closedAt,
    this.sortOrder = 0,
  });

  bool get isLocker => kind == Opt.kindLocker;
  bool get isClosed => status == 'closed';

  factory Location.fromMap(Map<String, Object?> m) => Location(
        id: _i(m['id']),
        name: m['name'] as String,
        kind: m['kind'] as String,
        parentId: _i(m['parent_id']),
        color: _i(m['color']) ?? Opt.palette.first,
        status: _s(m['status']) ?? 'active',
        closedAt: _s(m['closed_at']),
        sortOrder: _i(m['sort_order']) ?? 0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'kind': kind,
        'parent_id': parentId,
        'color': color,
        'status': status,
        'closed_at': closedAt,
        'sort_order': sortOrder,
      };

  Location copyWith({String? name, int? color, String? status, String? closedAt}) =>
      Location(
        id: id,
        name: name ?? this.name,
        kind: kind,
        parentId: parentId,
        color: color ?? this.color,
        status: status ?? this.status,
        closedAt: closedAt ?? this.closedAt,
        sortOrder: sortOrder,
      );
}

class LockerInfo {
  final int? locationId;
  final String bank;
  final String? branch;
  final String? branchAddress;
  final String? lockerNo;
  final String? size;
  final String? keyNo;
  final String? openedDate;
  final String? holders;
  final String? jointHolders;
  final String? nominee;
  final double? annualRent;
  final String? rentDueDate;
  final String? bankContact;
  final String? notes;

  const LockerInfo({
    this.locationId,
    required this.bank,
    this.branch,
    this.branchAddress,
    this.lockerNo,
    this.size,
    this.keyNo,
    this.openedDate,
    this.holders,
    this.jointHolders,
    this.nominee,
    this.annualRent,
    this.rentDueDate,
    this.bankContact,
    this.notes,
  });

  factory LockerInfo.fromMap(Map<String, Object?> m) => LockerInfo(
        locationId: _i(m['location_id']),
        bank: _s(m['bank']) ?? 'Other',
        branch: _s(m['branch']),
        branchAddress: _s(m['branch_address']),
        lockerNo: _s(m['locker_no']),
        size: _s(m['size']),
        keyNo: _s(m['key_no']),
        openedDate: _s(m['opened_date']),
        holders: _s(m['holders']),
        jointHolders: _s(m['joint_holders']),
        nominee: _s(m['nominee']),
        annualRent: _d(m['annual_rent']),
        rentDueDate: _s(m['rent_due_date']),
        bankContact: _s(m['bank_contact']),
        notes: _s(m['notes']),
      );

  Map<String, Object?> toMap(int locationId) => {
        'location_id': locationId,
        'bank': bank,
        'branch': _blank(branch),
        'branch_address': _blank(branchAddress),
        'locker_no': _blank(lockerNo),
        'size': size,
        'key_no': _blank(keyNo),
        'opened_date': openedDate,
        'holders': _blank(holders),
        'joint_holders': _blank(jointHolders),
        'nominee': _blank(nominee),
        'annual_rent': annualRent,
        'rent_due_date': rentDueDate,
        'bank_contact': _blank(bankContact),
        'notes': _blank(notes),
      };

  LockerInfo withRentDue(String? date) => LockerInfo(
        locationId: locationId,
        bank: bank,
        branch: branch,
        branchAddress: branchAddress,
        lockerNo: lockerNo,
        size: size,
        keyNo: keyNo,
        openedDate: openedDate,
        holders: holders,
        jointHolders: jointHolders,
        nominee: nominee,
        annualRent: annualRent,
        rentDueDate: date,
        bankContact: bankContact,
        notes: notes,
      );
}

class Item {
  final int? id;
  final String serial;
  final String name;
  final String? itemType;
  final String category;
  final String? purity;
  final double? grossWt;
  final double? netWt;
  final double? stoneWt;
  final int pieces;
  final String? description;
  final String? stones;
  final String? huid;
  final String? purchaseDate;
  final String? shopName;
  final String? billNo;
  final double? ratePerGram;
  final double? makingCharges;
  final double? gst;
  final double? totalPrice;
  final String? billPhoto;
  final String? owner;
  final String? occasion;
  final String? giftedBy;
  final int? locationId;
  final String status;
  final String? statusNote;
  final String? tags; // comma separated
  final String? notes;
  final bool needsDetails;
  final String? createdAt;
  final String? updatedAt;

  const Item({
    this.id,
    this.serial = '',
    required this.name,
    this.itemType,
    required this.category,
    this.purity,
    this.grossWt,
    this.netWt,
    this.stoneWt,
    this.pieces = 1,
    this.description,
    this.stones,
    this.huid,
    this.purchaseDate,
    this.shopName,
    this.billNo,
    this.ratePerGram,
    this.makingCharges,
    this.gst,
    this.totalPrice,
    this.billPhoto,
    this.owner,
    this.occasion,
    this.giftedBy,
    this.locationId,
    required this.status,
    this.statusNote,
    this.tags,
    this.notes,
    this.needsDetails = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => Opt.activeStatuses.contains(status);
  bool get isDisposed => Opt.disposedStatuses.contains(status);
  Metal get metal => metalOf(category, purity);

  /// Weight used for metal totals: net if known, else gross minus stones.
  double get metalWeight {
    if (netWt != null && netWt! > 0) return netWt!;
    final g = grossWt ?? 0;
    final s = stoneWt ?? 0;
    return (g - s) < 0 ? 0 : g - s;
  }

  List<String> get tagList => (tags ?? '')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  factory Item.fromMap(Map<String, Object?> m) => Item(
        id: _i(m['id']),
        serial: m['serial'] as String,
        name: m['name'] as String,
        itemType: _s(m['item_type']),
        category: m['category'] as String,
        purity: _s(m['purity']),
        grossWt: _d(m['gross_wt']),
        netWt: _d(m['net_wt']),
        stoneWt: _d(m['stone_wt']),
        pieces: _i(m['pieces']) ?? 1,
        description: _s(m['description']),
        stones: _s(m['stones']),
        huid: _s(m['huid']),
        purchaseDate: _s(m['purchase_date']),
        shopName: _s(m['shop_name']),
        billNo: _s(m['bill_no']),
        ratePerGram: _d(m['rate_per_gram']),
        makingCharges: _d(m['making_charges']),
        gst: _d(m['gst']),
        totalPrice: _d(m['total_price']),
        billPhoto: _s(m['bill_photo']),
        owner: _s(m['owner']),
        occasion: _s(m['occasion']),
        giftedBy: _s(m['gifted_by']),
        locationId: _i(m['location_id']),
        status: m['status'] as String,
        statusNote: _s(m['status_note']),
        tags: _s(m['tags']),
        notes: _s(m['notes']),
        needsDetails: (_i(m['needs_details']) ?? 0) == 1,
        createdAt: _s(m['created_at']),
        updatedAt: _s(m['updated_at']),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'serial': serial,
        'name': name.trim(),
        'item_type': itemType,
        'category': category,
        'purity': purity,
        'gross_wt': grossWt,
        'net_wt': netWt,
        'stone_wt': stoneWt,
        'pieces': pieces,
        'description': _blank(description),
        'stones': _blank(stones),
        'huid': _blank(huid),
        'purchase_date': purchaseDate,
        'shop_name': _blank(shopName),
        'bill_no': _blank(billNo),
        'rate_per_gram': ratePerGram,
        'making_charges': makingCharges,
        'gst': gst,
        'total_price': totalPrice,
        'bill_photo': billPhoto,
        'owner': _blank(owner),
        'occasion': _blank(occasion),
        'gifted_by': _blank(giftedBy),
        'location_id': locationId,
        'status': status,
        'status_note': _blank(statusNote),
        'tags': _blank(tags),
        'notes': _blank(notes),
        'needs_details': needsDetails ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Item copyWith({
    int? id,
    String? serial,
    String? name,
    int? locationId,
    bool clearLocation = false,
    String? status,
    String? statusNote,
    String? billPhoto,
    bool clearBillPhoto = false,
    bool? needsDetails,
    String? createdAt,
    String? updatedAt,
  }) {
    final m = toMap();
    m['id'] = id ?? this.id;
    m['serial'] = serial ?? this.serial;
    m['name'] = name ?? this.name;
    m['location_id'] = clearLocation ? null : (locationId ?? this.locationId);
    m['status'] = status ?? this.status;
    m['status_note'] = statusNote ?? this.statusNote;
    m['bill_photo'] = clearBillPhoto ? null : (billPhoto ?? this.billPhoto);
    m['needs_details'] = (needsDetails ?? this.needsDetails) ? 1 : 0;
    m['created_at'] = createdAt ?? this.createdAt;
    m['updated_at'] = updatedAt ?? this.updatedAt;
    return Item.fromMap(m);
  }
}

class ItemPhoto {
  final int? id;
  final int itemId;
  final String file;
  final int sortOrder;
  const ItemPhoto({this.id, required this.itemId, required this.file, this.sortOrder = 0});

  factory ItemPhoto.fromMap(Map<String, Object?> m) => ItemPhoto(
        id: _i(m['id']),
        itemId: _i(m['item_id'])!,
        file: m['file'] as String,
        sortOrder: _i(m['sort_order']) ?? 0,
      );
}

class Visit {
  final int? id;
  final int locationId;
  final String visitDate; // yyyy-MM-dd
  final String? timeIn; // HH:mm
  final String? timeOut;
  final String? visitors;
  final String? purpose;
  final String? notes;
  final String? createdAt;

  const Visit({
    this.id,
    required this.locationId,
    required this.visitDate,
    this.timeIn,
    this.timeOut,
    this.visitors,
    this.purpose,
    this.notes,
    this.createdAt,
  });

  DateTime get date => DateTime.parse(visitDate);

  DateTime at(String? hhmm) {
    final d = date;
    if (hhmm == null || !hhmm.contains(':')) return d;
    final p = hhmm.split(':');
    return DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
  }

  factory Visit.fromMap(Map<String, Object?> m) => Visit(
        id: _i(m['id']),
        locationId: _i(m['location_id'])!,
        visitDate: m['visit_date'] as String,
        timeIn: _s(m['time_in']),
        timeOut: _s(m['time_out']),
        visitors: _s(m['visitors']),
        purpose: _s(m['purpose']),
        notes: _s(m['notes']),
        createdAt: _s(m['created_at']),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'location_id': locationId,
        'visit_date': visitDate,
        'time_in': timeIn,
        'time_out': timeOut,
        'visitors': _blank(visitors),
        'purpose': _blank(purpose),
        'notes': _blank(notes),
        'created_at': createdAt,
      };
}

class Movement {
  final int? id;
  final int itemId;
  final int? fromLocationId;
  final int? toLocationId;
  final String? fromStatus;
  final String toStatus;
  final String movedAt; // ISO local date-time
  final int? visitId;
  final String action; // create / deposit / withdraw / move / status / close
  final String? note;

  // Joined display fields
  final String? itemName;
  final String? itemSerial;
  final String? fromName;
  final String? toName;

  const Movement({
    this.id,
    required this.itemId,
    this.fromLocationId,
    this.toLocationId,
    this.fromStatus,
    required this.toStatus,
    required this.movedAt,
    this.visitId,
    required this.action,
    this.note,
    this.itemName,
    this.itemSerial,
    this.fromName,
    this.toName,
  });

  DateTime get at => DateTime.parse(movedAt);

  factory Movement.fromMap(Map<String, Object?> m) => Movement(
        id: _i(m['id']),
        itemId: _i(m['item_id'])!,
        fromLocationId: _i(m['from_location_id']),
        toLocationId: _i(m['to_location_id']),
        fromStatus: _s(m['from_status']),
        toStatus: m['to_status'] as String,
        movedAt: m['moved_at'] as String,
        visitId: _i(m['visit_id']),
        action: m['action'] as String,
        note: _s(m['note']),
        itemName: _s(m['item_name']),
        itemSerial: _s(m['item_serial']),
        fromName: _s(m['from_name']),
        toName: _s(m['to_name']),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'item_id': itemId,
        'from_location_id': fromLocationId,
        'to_location_id': toLocationId,
        'from_status': fromStatus,
        'to_status': toStatus,
        'moved_at': movedAt,
        'visit_id': visitId,
        'action': action,
        'note': _blank(note),
      };
}

/// A user reminder / alarm.
/// kind: keep (put jewellery in locker), take (take out of locker),
///       planned_visit, custom.
class Reminder {
  final int? id;
  final String kind;
  final String title;
  final String dueDate; // yyyy-MM-dd (next occurrence)
  final String? time; // HH:mm, null = use the default alert time
  final String repeat; // none / weekly / monthly / yearly
  final int? locationId;
  final List<int> itemIds;
  final bool alarm; // ring like an alarm until opened
  final bool enabled;
  final bool done;
  final String? notes;

  /// Minutes before the due time to alert (0 = at the time). Several allowed.
  final List<int> alerts;

  /// 'alarm' (alarm volume, keeps ringing), 'notify' (normal sound), 'silent'.
  final String? sound;
  final bool vibrate;

  /// Snooze length in minutes offered on the notification (0 = no snooze).
  final int snooze;

  const Reminder({
    this.id,
    required this.kind,
    required this.title,
    required this.dueDate,
    this.time,
    this.repeat = 'none',
    this.locationId,
    this.itemIds = const [],
    this.alarm = true,
    this.enabled = true,
    this.done = false,
    this.notes,
    this.alerts = const [0],
    this.sound,
    this.vibrate = true,
    this.snooze = 10,
  });

  static const kinds = ['keep', 'take', 'planned_visit', 'custom'];
  static const sounds = ['alarm', 'notify', 'silent'];

  /// Preset "alert me" choices in minutes before the due time.
  static const alertPresets = [0, 15, 60, 180, 1440, 2880, 10080];
  static const snoozeChoices = [0, 5, 10, 15, 30, 60];

  String get soundMode => sound ?? (alarm ? 'alarm' : 'notify');

  static List<int> parseAlerts(String? s) {
    final l = (s ?? '0').split(',').map((e) => int.tryParse(e.trim())).whereType<int>().where((e) => e >= 0).toSet().toList()
      ..sort();
    return l.isEmpty ? const [0] : l;
  }
  static const repeats = ['none', 'until_back', 'daily', 'weekly', 'monthly', 'yearly'];

  /// Keeps ringing every day after the due time until the ornaments are back
  /// in a locker (or it is marked done).
  bool get untilBack => repeat == 'until_back';

  /// When this reminder fires, using [defaultTime] if it has none.
  DateTime at(String defaultTime) {
    final d = DateTime.parse(dueDate);
    final p = (time ?? defaultTime).split(':');
    return DateTime(d.year, d.month, d.day, int.tryParse(p[0]) ?? 9, p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  /// The occurrence after [d] for repeating reminders (null if one-off).
  DateTime? nextAfter(DateTime d) => switch (repeat) {
        'daily' || 'until_back' => DateTime(d.year, d.month, d.day + 1, d.hour, d.minute),
        'weekly' => DateTime(d.year, d.month, d.day + 7, d.hour, d.minute),
        'monthly' => DateTime(d.year, d.month + 1, d.day, d.hour, d.minute),
        'yearly' => DateTime(d.year + 1, d.month, d.day, d.hour, d.minute),
        _ => null,
      };

  factory Reminder.fromMap(Map<String, Object?> m) => Reminder(
        id: _i(m['id']),
        kind: m['kind'] as String,
        title: m['title'] as String,
        dueDate: m['due_date'] as String,
        time: _s(m['time']),
        repeat: _s(m['repeat']) ?? 'none',
        locationId: _i(m['location_id']),
        itemIds: (_s(m['item_ids']) ?? '').split(',').map(int.tryParse).whereType<int>().toList(),
        alarm: (_i(m['alarm']) ?? 1) == 1,
        enabled: (_i(m['enabled']) ?? 1) == 1,
        done: (_i(m['done']) ?? 0) == 1,
        notes: _s(m['notes']),
        alerts: parseAlerts(_s(m['alerts'])),
        sound: _s(m['sound']),
        vibrate: (_i(m['vibrate']) ?? 1) == 1,
        snooze: _i(m['snooze']) ?? 10,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'alerts': (alerts.isEmpty ? const [0] : alerts).join(','),
        'sound': sound,
        'vibrate': vibrate ? 1 : 0,
        'snooze': snooze,
        'kind': kind,
        'title': title,
        'due_date': dueDate,
        'time': time,
        'repeat': repeat,
        'location_id': locationId,
        'item_ids': itemIds.isEmpty ? null : itemIds.join(','),
        'alarm': alarm ? 1 : 0,
        'enabled': enabled ? 1 : 0,
        'done': done ? 1 : 0,
        'notes': _blank(notes),
      };

  Reminder copyWith({String? dueDate, bool? done, bool? enabled}) => Reminder.fromMap({
        ...toMap(),
        'id': id,
        'due_date': dueDate ?? this.dueDate,
        'done': (done ?? this.done) ? 1 : 0,
        'enabled': (enabled ?? this.enabled) ? 1 : 0,
      });
}

/// A bank holiday: one-off ([date]) or every year ([md] = "MM-dd").
class Holiday {
  final int? id;
  final String name;
  final String? date;
  final String? md;
  final bool enabled;
  const Holiday({this.id, required this.name, this.date, this.md, this.enabled = true});

  bool get yearly => md != null;

  bool fallsOn(DateTime d) {
    if (md != null) return md == '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return date == '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  factory Holiday.fromMap(Map<String, Object?> m) => Holiday(
        id: _i(m['id']),
        name: m['name'] as String,
        date: _s(m['date']),
        md: _s(m['md']),
        enabled: (_i(m['enabled']) ?? 1) == 1,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name.trim(),
        'date': date,
        'md': md,
        'enabled': enabled ? 1 : 0,
      };
}

/// Every on/off switch and number the family can customise, with defaults.
class Prefs {
  Prefs(this._s);
  final Map<String, String?> _s;

  bool _b(String k, bool d) => _s[k] == null ? d : _s[k] == '1';
  int _n(String k, int d) => int.tryParse(_s[k] ?? '') ?? d;

  // Display
  bool get showValues => _b('show_values', false);
  bool get dashBreakdown => _b('dash_breakdown', true);
  bool get dashReminders => _b('dash_reminders', true);
  bool get dashRecent => _b('dash_recent', true);
  bool get holidaysOnVisitCal => _b('holidays_on_visit_cal', true);
  bool get showOutTime => _b('show_out_time', true);
  bool get returnByDefault => _b('return_by_default', false);
  int get returnByDays => _n('return_by_days', 7);

  // Notifications
  bool get notifications => _b('notif_enabled', true);
  String get alertTime => _s['alert_time'] ?? '09:00';
  bool get alarmByDefault => _b('alarm_default', true);
  String get defaultSound => _s['default_sound'] ?? (alarmByDefault ? 'alarm' : 'notify');
  List<int> get defaultAlerts => Reminder.parseAlerts(_s['default_alerts']);
  int get defaultSnooze => _n('default_snooze', 10);
  bool get defaultVibrate => _b('default_vibrate', true);
  bool get rentAlerts => _b('rent_alerts', true);
  int get rentLeadDays => _n('rent_lead_days', 15);
  bool get notReturnedAlerts => _b('not_returned_alerts', true);
  int get notReturnedDays => _n('not_returned_days', 30);
  bool get plannedAlerts => _b('planned_alerts', true);
  int get plannedLeadDays => _n('planned_lead_days', 1);
  bool get holidayAlerts => _b('holiday_alerts', true);
  int get holidayLeadDays => _n('holiday_lead_days', 2);
  bool get holidayWeekendAlerts => _b('holiday_weekend_alerts', false);
  bool get backupNotifications => _b('backup_notifications', true);

  // Bank holiday rules (RBI: all Sundays, 2nd & 4th Saturdays)
  bool get sundaysClosed => _b('closed_sundays', true);
  bool get saturdays24Closed => _b('closed_sat_2_4', true);

  // Security
  int get autoLockSeconds => _n('auto_lock_seconds', 60);
}

/// Aggregates shown on location cards and the dashboard.
class Totals {
  int items = 0;
  int pieces = 0;
  double gold = 0;
  double silver = 0;
  double platinum = 0;
  double value = 0;

  void add(Item i, Rates r) {
    items++;
    pieces += i.pieces;
    final w = i.metalWeight;
    switch (i.metal) {
      case Metal.gold:
        gold += w;
        break;
      case Metal.silver:
        silver += w;
        break;
      case Metal.platinum:
        platinum += w;
        break;
      case Metal.none:
        break;
    }
    value += r.valueOf(i);
  }
}

/// Manually entered market rates (₹ per gram of pure metal).
class Rates {
  final double gold24;
  final double silver;
  final double platinum;
  const Rates({this.gold24 = 0, this.silver = 0, this.platinum = 0});

  bool get isSet => gold24 > 0 || silver > 0 || platinum > 0;

  double valueOf(Item i) {
    final w = i.metalWeight;
    final f = Opt.purityFactor(i.purity);
    switch (i.metal) {
      case Metal.gold:
        return w * f * gold24;
      case Metal.silver:
        return w * f * silver;
      case Metal.platinum:
        return w * f * platinum;
      case Metal.none:
        return i.totalPrice ?? 0;
    }
  }
}
