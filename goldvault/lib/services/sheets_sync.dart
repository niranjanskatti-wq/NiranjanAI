import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;

import '../core/format.dart';
import '../data/repository.dart';
import 'google_service.dart';
import 'report_data.dart';

class SyncResult {
  final bool ok;
  final String message;
  final String? spreadsheetUrl;
  const SyncResult(this.ok, this.message, [this.spreadsheetUrl]);
}

/// One-way push of the local database into a Google Sheet. The app is the
/// master copy: each sync rewrites every tab with the current data.
class SheetsSync {
  SheetsSync(this.repo, this.google);

  final VaultRepo repo;
  final GoogleService google;

  static const fixedTabs = ['Inventory', 'Lockers', 'Locker Visits', 'Movement History', 'Locations'];

  Future<String?> spreadsheetId() => repo.getSetting('sheet_id');

  Future<String?> spreadsheetUrl() async {
    final id = await spreadsheetId();
    return id == null ? null : 'https://docs.google.com/spreadsheets/d/$id/edit';
  }

  Future<bool> isDirty() async => (await repo.getSetting('sync_dirty')) == '1';

  /// Called from UI (interactive) or background (silent).
  Future<SyncResult> syncNow({bool interactive = false}) async {
    final client = await google.client(interactive: interactive);
    if (client == null) return const SyncResult(false, 'not_signed_in');
    // Clear the flag first so edits made during the upload trigger another sync.
    await repo.setSetting('sync_dirty', '0');
    try {
      return await _sync(client);
    } catch (_) {
      await repo.setSetting('sync_dirty', '1');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<SyncResult> _sync(gauth.AuthClient client) async {
    final api = sheets.SheetsApi(client);
    final tables = await ReportBuilder(repo).build();
    final wanted = tables.map((t) => t.title).toList();

    // 1. Find or create the spreadsheet.
    var id = await spreadsheetId();
    sheets.Spreadsheet? ss;
    if (id != null) {
      try {
        ss = await api.spreadsheets.get(id, $fields: 'spreadsheetId,sheets.properties');
      } on sheets.DetailedApiRequestError catch (e) {
        if (e.status != 404 && e.status != 403) rethrow;
        ss = null; // deleted or no longer accessible: make a new one
      }
    }
    if (ss == null) {
      ss = await api.spreadsheets.create(sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: 'GoldVault Inventory', locale: 'en_IN'),
        sheets: [
          for (final t in wanted) sheets.Sheet(properties: sheets.SheetProperties(title: t)),
        ],
      ));
      id = ss.spreadsheetId!;
      await repo.setSetting('sheet_id', id);
      ss = await api.spreadsheets.get(id, $fields: 'spreadsheetId,sheets.properties');
    }

    // 2. Add missing tabs, remove tabs of lockers that were closed/renamed.
    final existing = {
      for (final s in ss.sheets ?? <sheets.Sheet>[]) s.properties!.title!: s.properties!.sheetId!
    };
    final requests = <sheets.Request>[];
    for (final t in wanted) {
      if (!existing.containsKey(t)) {
        requests.add(sheets.Request(
            addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: t))));
      }
    }
    for (final e in existing.entries) {
      if (e.key.startsWith(ReportBuilder.lockerTabPrefix) && !wanted.contains(e.key)) {
        requests.add(sheets.Request(deleteSheet: sheets.DeleteSheetRequest(sheetId: e.value)));
      }
    }
    if (requests.isNotEmpty) {
      await api.spreadsheets.batchUpdate(sheets.BatchUpdateSpreadsheetRequest(requests: requests), id!);
      ss = await api.spreadsheets.get(id, $fields: 'spreadsheetId,sheets.properties');
    }
    final ids = {for (final s in ss.sheets!) s.properties!.title!: s.properties!.sheetId!};

    // 3. Clear and rewrite all values.
    await api.spreadsheets.values.batchClear(
        sheets.BatchClearValuesRequest(ranges: wanted.map((t) => "'$t'").toList()), id!);
    await api.spreadsheets.values.batchUpdate(
      sheets.BatchUpdateValuesRequest(
        valueInputOption: 'RAW',
        data: [
          for (final t in tables)
            sheets.ValueRange(
              range: "'${t.title}'!A1",
              values: t.withHeader.map((r) => r.map((c) => c ?? '').toList()).toList(),
            ),
        ],
      ),
      id,
    );

    // 4. Header styling: bold gold header row, frozen.
    await api.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(requests: [
        for (final t in wanted) ...[
          sheets.Request(
            repeatCell: sheets.RepeatCellRequest(
              range: sheets.GridRange(sheetId: ids[t], startRowIndex: 0, endRowIndex: 1),
              cell: sheets.CellData(
                userEnteredFormat: sheets.CellFormat(
                  backgroundColor: sheets.Color(red: 0.07, green: 0.11, blue: 0.2),
                  textFormat: sheets.TextFormat(
                    bold: true,
                    foregroundColor: sheets.Color(red: 0.88, green: 0.69, blue: 0.29),
                  ),
                ),
              ),
              fields: 'userEnteredFormat(backgroundColor,textFormat)',
            ),
          ),
          sheets.Request(
            updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
              properties: sheets.SheetProperties(
                sheetId: ids[t],
                gridProperties: sheets.GridProperties(frozenRowCount: 1),
              ),
              fields: 'gridProperties.frozenRowCount',
            ),
          ),
        ],
      ]),
      id,
    );

    await repo.setSetting('last_sync', Fmt.isoDateTime(DateTime.now()));
    return SyncResult(true, 'ok', 'https://docs.google.com/spreadsheets/d/$id/edit');
  }

  /// Share the sheet with [email] as `reader` (view) or `writer` (edit).
  Future<void> share(String email, {required bool canEdit}) async {
    final id = await spreadsheetId();
    if (id == null) throw StateError('Sync once before sharing');
    final client = await google.client(interactive: true);
    if (client == null) throw StateError('not_signed_in');
    try {
      await drive.DriveApi(client).permissions.create(
            drive.Permission(type: 'user', role: canEdit ? 'writer' : 'reader', emailAddress: email.trim()),
            id,
            sendNotificationEmail: true,
          );
    } finally {
      client.close();
    }
  }
}
