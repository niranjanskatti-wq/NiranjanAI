import '../core/format.dart';
import '../data/models.dart';
import '../data/repository.dart';

/// A table with a header row, shared by Google Sheets, Excel and PDF output.
class ReportTable {
  final String title;
  final List<String> header;
  final List<List<Object?>> rows;
  ReportTable(this.title, this.header, this.rows);

  List<List<Object?>> get withHeader => [header, ...rows];
}

const _statusLabel = {
  'in_locker': 'In locker',
  'at_home': 'At home',
  'worn': 'Being worn',
  'repair': 'Given for repair',
  'lent': 'Lent',
  'pledged': 'Pledged',
  'sold': 'Sold',
  'exchanged': 'Exchanged',
  'gifted': 'Gifted',
};

String statusLabelEn(String s) => _statusLabel[s] ?? s;

/// Builds all report tables from the local database. Lockers each get their
/// own table named `Locker - {name}`.
class ReportBuilder {
  ReportBuilder(this.repo);
  final VaultRepo repo;

  static const lockerTabPrefix = 'Locker - ';

  Future<List<ReportTable>> build({bool includeLockerTabs = true}) async {
    final locs = await repo.locationMap();
    final lockers = await repo.allLockerInfo();
    final items = await repo.items(const ItemQuery());
    final rates = await repo.valueRates();

    String locName(int? id) {
      if (id == null) return '';
      final l = locs[id];
      if (l == null) return '';
      final parent = l.parentId == null ? null : locs[l.parentId];
      return parent == null ? l.name : '${parent.name} › ${l.name}';
    }

    List<Object?> itemRow(Item i) => [
          i.serial,
          i.name,
          i.itemType ?? '',
          i.category,
          i.purity ?? '',
          i.grossWt,
          i.netWt,
          i.stoneWt,
          i.pieces,
          locName(i.locationId),
          statusLabelEn(i.status),
          i.statusNote ?? '',
          i.owner ?? '',
          i.huid ?? '',
          i.purchaseDate ?? '',
          i.shopName ?? '',
          i.billNo ?? '',
          i.ratePerGram,
          i.makingCharges,
          i.gst,
          i.totalPrice,
          if (rates.isSet) rates.valueOf(i).roundToDouble(),
          i.occasion ?? '',
          i.giftedBy ?? '',
          i.tags ?? '',
          i.description ?? '',
          i.notes ?? '',
        ];

    final itemHeader = [
      'Serial No',
      'Name',
      'Type',
      'Category',
      'Purity',
      'Gross wt (g)',
      'Net wt (g)',
      'Stone wt (g)',
      'Pieces',
      'Location',
      'Status',
      'Status note',
      'Owner',
      'HUID',
      'Purchase date',
      'Shop',
      'Bill no',
      'Rate/g (₹)',
      'Making (₹)',
      'GST (₹)',
      'Total price (₹)',
      if (rates.isSet) 'Est. value (₹)',
      'Occasion',
      'Gifted by',
      'Tags',
      'Description',
      'Notes',
    ];

    final tables = <ReportTable>[
      ReportTable('Inventory', itemHeader, items.map(itemRow).toList()),
    ];

    // Lockers
    final lockerRows = <List<Object?>>[];
    final totals = await repo.totalsByLocation();
    for (final l in locs.values.where((l) => l.isLocker)) {
      final info = lockers[l.id];
      final t = totals[l.id];
      lockerRows.add([
        l.name,
        info?.bank ?? '',
        info?.branch ?? '',
        info?.branchAddress ?? '',
        info?.lockerNo ?? '',
        info?.size ?? '',
        info?.keyNo ?? '',
        info?.openedDate ?? '',
        info?.holders ?? '',
        info?.jointHolders ?? '',
        info?.nominee ?? '',
        info?.annualRent,
        info?.rentDueDate ?? '',
        info?.bankContact ?? '',
        l.isClosed ? 'Closed ${l.closedAt?.substring(0, 10) ?? ''}' : 'Active',
        t?.items ?? 0,
        _r3(t?.gold),
        _r3(t?.silver),
        info?.notes ?? '',
      ]);
    }
    tables.add(ReportTable('Lockers', const [
      'Locker',
      'Bank',
      'Branch',
      'Branch address',
      'Locker no',
      'Size',
      'Key no',
      'Opened on',
      'Holders',
      'Joint holders',
      'Nominee',
      'Annual rent (₹)',
      'Rent due',
      'Bank contact',
      'Status',
      'Items',
      'Gold (g)',
      'Silver (g)',
      'Notes',
    ], lockerRows));

    // Visits
    final visitRows = <List<Object?>>[];
    for (final v in await repo.visits()) {
      final d = await repo.visitDetail(v.id!);
      visitRows.add([
        v.visitDate,
        locName(v.locationId),
        v.timeIn ?? '',
        v.timeOut ?? '',
        v.visitors ?? '',
        v.purpose ?? '',
        d!.deposited.map((m) => '${m.itemSerial} ${m.itemName}').join('; '),
        d.withdrawn.map((m) => '${m.itemSerial} ${m.itemName}').join('; '),
        v.notes ?? '',
      ]);
    }
    tables.add(ReportTable('Locker Visits', const [
      'Date',
      'Locker',
      'Time in',
      'Time out',
      'Visited by',
      'Purpose',
      'Deposited',
      'Withdrawn',
      'Notes',
    ], visitRows));

    // Movement history
    final moveRows = <List<Object?>>[];
    for (final m in await repo.allMovements()) {
      moveRows.add([
        m.movedAt.replaceFirst('T', ' ').substring(0, 16),
        m.itemSerial,
        m.itemName,
        _actionLabel(m.action),
        m.fromLocationId == null ? statusLabelEn(m.fromStatus ?? '') : locName(m.fromLocationId),
        m.toLocationId == null ? statusLabelEn(m.toStatus) : locName(m.toLocationId),
        m.note ?? '',
      ]);
    }
    tables.add(ReportTable('Movement History',
        const ['Date & time', 'Serial No', 'Item', 'Action', 'From', 'To', 'Note'], moveRows));

    // Locations
    final locRows = <List<Object?>>[];
    for (final l in locs.values) {
      final t = totals[l.id];
      locRows.add([
        locName(l.id),
        l.kind == 'locker' ? 'Bank locker' : (l.parentId == null ? 'Place' : 'Sub-location'),
        l.isClosed ? 'Closed' : 'Active',
        t?.items ?? 0,
        _r3(t?.gold),
        _r3(t?.silver),
        if (rates.isSet) (t?.value ?? 0).roundToDouble(),
      ]);
    }
    final out = totals[null];
    if (out != null) {
      locRows.add(['Out (worn / repair / lent / pledged)', '', '', out.items, _r3(out.gold),
          _r3(out.silver), if (rates.isSet) out.value.roundToDouble()]);
    }
    tables.add(ReportTable('Locations', [
      'Location',
      'Type',
      'Status',
      'Items',
      'Gold (g)',
      'Silver (g)',
      if (rates.isSet) 'Est. value (₹)',
    ], locRows));

    if (includeLockerTabs) {
      for (final l in locs.values.where((l) => l.isLocker && !l.isClosed)) {
        final inside = items.where((i) => i.locationId == l.id && i.isActive);
        tables.add(ReportTable(
          lockerTabName(l),
          const ['Serial No', 'Name', 'Category', 'Purity', 'Gross wt (g)', 'Net wt (g)', 'Pieces', 'Owner', 'HUID'],
          inside
              .map((i) => [i.serial, i.name, i.category, i.purity ?? '', i.grossWt, i.netWt, i.pieces, i.owner ?? '', i.huid ?? ''])
              .toList(),
        ));
      }
    }
    return tables;
  }

  /// Sheet titles can't contain some characters and max out at 100 chars.
  static String lockerTabName(Location l) {
    final clean = l.name.replaceAll(RegExp(r"[\[\]\*\?/\\:']"), ' ').trim();
    final t = '$lockerTabPrefix$clean';
    return t.length > 90 ? t.substring(0, 90) : t;
  }

  static double? _r3(double? v) => v == null ? null : (v * 1000).roundToDouble() / 1000;

  static String _actionLabel(String a) => switch (a) {
        'create' => 'Added',
        'deposit' => 'Kept in locker',
        'withdraw' => 'Taken out',
        'move' => 'Moved',
        'status' => 'Status changed',
        'close' => 'Moved (locker closed)',
        _ => a,
      };

  static String generatedLine() => 'Generated ${Fmt.dateTime(DateTime.now())}';
}
