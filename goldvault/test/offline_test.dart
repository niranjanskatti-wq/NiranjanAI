import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goldvault/data/constants.dart';
import 'package:goldvault/data/models.dart';
import 'package:goldvault/services/reminder_engine.dart';

import 'helpers.dart';

/// Simulates airplane mode: every attempt to open a network connection fails.
class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw const SocketException('Airplane mode (test): network is disabled');
  }
}

void main() {
  test('Stage 1 works end-to-end with no network (airplane mode)', () async {
    final net = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      final svc = await testServices();
      final repo = svc.repo;

      // 1. Add a new locker and a home sub-location.
      final icici = await repo.saveLocker(
          name: 'ICICI Locker', info: const LockerInfo(bank: 'ICICI', lockerNo: '77', rentDueDate: '2026-11-01'));
      final home = (await repo.locations()).firstWhere((l) => l.name == 'Home');
      final cupboard = await repo.addPlace('Pooja room cupboard', parentId: home.id);

      // 2. Quick-add, full purchase and duplicate flows.
      final quick = await repo.createItem(
          const Item(name: 'Chain', category: 'Gold', grossWt: 12, status: Opt.atHome, needsDetails: true).copyWith(locationId: cupboard));
      final bought = await repo.createItem(Item(
        name: 'Bangle',
        category: 'Gold',
        purity: '22K',
        grossWt: 24.5,
        netWt: 24.1,
        pieces: 1,
        purchaseDate: '2026-10-01',
        shopName: 'Bhima',
        billNo: 'B-991',
        ratePerGram: 6800,
        makingCharges: 9000,
        gst: 5200,
        totalPrice: 178000,
        locationId: cupboard,
        status: Opt.atHome,
        owner: 'Amma',
      ));
      final copy = await repo.createItem(bought.copyWith(id: null, serial: ''));
      expect([quick.serial, bought.serial, copy.serial], ['GV-0001', 'GV-0002', 'GV-0003']);

      // 3. Visit: deposit both bangles into the new locker.
      await repo.logVisit(const Visit(locationId: 0, visitDate: '2026-10-08', timeIn: '11:00', timeOut: '11:40')
          .withLocker(icici), deposit: [bought.id!, copy.id!]);
      expect((await repo.itemsAt(icici)).length, 2);

      // 4. Dashboard numbers, search, calendar data, reminders.
      final totals = await repo.totalsByLocation();
      expect(totals[icici]!.gold, closeTo(48.2, 0.001));
      expect((await repo.whereIs('bangle')).every((w) => w.location?.id == icici), isTrue);
      expect((await repo.movementsOn(DateTime(2026, 10, 8))).where((m) => m.action == 'deposit').length, 2);
      expect(await ReminderEngine(repo).upcoming(now: DateTime(2026, 10, 20)), isNotEmpty);

      // 5. Exports work offline too.
      expect(await (await svc.export.excel()).exists(), isTrue);

      // 6. Cloud features fail gracefully (not signed in) instead of crashing.
      final r = await svc.sheets.syncNow();
      expect(r.ok, isFalse);
      expect(await repo.getSetting('sync_dirty'), '1'); // will sync once online
    }, net);
    expect(net.attempts, 0, reason: 'Stage 1 must never touch the network');
  });
}

extension on Visit {
  Visit withLocker(int id) => Visit(locationId: id, visitDate: visitDate, timeIn: timeIn, timeOut: timeOut);
}
