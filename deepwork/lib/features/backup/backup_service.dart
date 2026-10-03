import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/settings.dart';
import '../../core/util/format.dart';
import '../../data/backup_format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../services/drive.dart';

// Weekly backup scheduling. Android can't run it reliably in the background, so the backup runs the
// next time the app is opened online once it's due. Offline failures retry silently next time.

/// Most recent occurrence of the backup weekday at 00:00 that is <= now.
DateTime lastScheduled(int day, [DateTime? now]) {
  final d = startOfDay(now ?? DateTime.now());
  return addDays(d, -((weekday0(d) - day + 7) % 7));
}

bool isBackupDue(AppSettings s, [DateTime? now]) {
  if (!s.on('backup') || !s.b('backup.connected')) return false;
  final last = s['backup.lastBackupAt'] as num?;
  if (last == null) return true;
  return last < lastScheduled(s.i('backup.day'), now).millisecondsSinceEpoch;
}

DateTime nextBackupDate(AppSettings s, [DateTime? now]) {
  final n = now ?? DateTime.now();
  if (isBackupDue(s, n)) return n;
  return addDays(lastScheduled(s.i('backup.day'), n), 7);
}

enum BackupOutcome { ok, needsAuth, offline, error, busy, disabled }

bool _running = false;

Future<(BackupOutcome, String?)> runBackup(SettingsController settings, AppDatabase db, {required bool interactive}) async {
  if (_running) return (BackupOutcome.busy, null);
  final s = settings.current;
  if (!s.on('backup') || !s.b('backup.connected')) return (BackupOutcome.disabled, null);
  _running = true;
  final now = DateTime.now().millisecondsSinceEpoch;
  try {
    var token = await DriveClient.instance.silentToken();
    if (token == null) {
      if (!interactive) {
        await settings.edit((m) => m['backup']['needsReconnect'] = true);
        return (BackupOutcome.needsAuth, null);
      }
      token = await DriveClient.instance.interactiveToken();
    }
    final file = await buildBackup(db, settings.current);
    await DriveClient.instance.uploadBackup(token, backupFilename(), file.encode());
    await DriveClient.instance.pruneBackups(token, settings.current.i('backup.retention'));
    await settings.edit((m) {
      m['backup']['lastBackupAt'] = DateTime.now().millisecondsSinceEpoch;
      m['backup']['lastAttemptAt'] = now;
      m['backup']['lastError'] = null;
      m['backup']['needsReconnect'] = false;
    });
    return (BackupOutcome.ok, null);
  } on SocketException {
    await settings.edit((m) => m['backup']['lastAttemptAt'] = now);
    return (BackupOutcome.offline, 'You appear to be offline. The backup will retry automatically.');
  } on http.ClientException {
    await settings.edit((m) => m['backup']['lastAttemptAt'] = now);
    return (BackupOutcome.offline, 'You appear to be offline. The backup will retry automatically.');
  } on DriveAuthException catch (e) {
    await settings.edit((m) {
      m['backup']['needsReconnect'] = true;
      m['backup']['lastAttemptAt'] = now;
      m['backup']['lastError'] = e.message;
    });
    return (BackupOutcome.needsAuth, e.message);
  } catch (e) {
    final msg = e.toString();
    await settings.edit((m) {
      m['backup']['lastAttemptAt'] = now;
      m['backup']['lastError'] = msg;
    });
    return (BackupOutcome.error, msg);
  } finally {
    _running = false;
  }
}
