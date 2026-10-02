import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../reminders/notification_service.dart';
import 'backup_service.dart';

/// Keeps a copy of the newest backup in Google Drive (or any place picked in
/// Android's "Save to" screen). The file is picked once; Smriti then
/// overwrites it after every backup, and Drive keeps older versions.
class DriveBackup {
  static const _channel = MethodChannel('smriti/drive');

  /// The picked file, or null when Drive backup is off.
  static Future<String?> uri(AppDatabase db) async {
    final u = await db.getSetting('driveUri');
    return (u == null || u.isEmpty) ? null : u;
  }

  /// Opens "Save to": the user picks Google Drive and a folder. Returns the file name, or null.
  static Future<String?> choose(AppDatabase db) async {
    if (!NotificationService.supported) return null;
    final picked = await _channel.invokeMethod<String>('pick', {'title': 'Smriti backup.zip'});
    if (picked == null) return null;
    final name = await _channel.invokeMethod<String>('name', {'uri': picked}) ?? 'Smriti backup.zip';
    await db.setSetting('driveUri', picked);
    await db.setSetting('driveName', name);
    await db.setSetting('driveLast', '');
    return name;
  }

  static Future<void> turnOff(AppDatabase db) async {
    await db.setSetting('driveUri', '');
    await db.setSetting('driveLast', '');
  }

  /// Copies [file] to the picked Drive file. False if it couldn't (no internet
  /// is fine: Drive uploads when it can; no permission means pick again).
  static Future<bool> upload(AppDatabase db, File file) async {
    final u = await uri(db);
    if (u == null || !NotificationService.supported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('write', {'uri': u, 'path': file.path}) ?? false;
      if (ok) {
        await db.setSetting('driveLast', DateTime.now().toIso8601String());
        await db.setSetting('driveError', '');
      } else {
        await db.setSetting('driveError', 'Could not save to Drive. Tap "Choose Drive file" again.');
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// After a backup made in the background, or when Drive is behind: uploads the newest backup.
  static Future<void> catchUp(AppDatabase db) async {
    if (await uri(db) == null) return;
    final lastBackup = DateTime.tryParse(await db.getSetting('lastBackup') ?? '');
    final lastDrive = DateTime.tryParse(await db.getSetting('driveLast') ?? '');
    if (lastBackup == null || (lastDrive != null && !lastDrive.isBefore(lastBackup))) return;
    final files = await BackupService.list(await BackupService.folder());
    if (files.isNotEmpty) await upload(db, files.first);
  }

  static String describe(DateTime? last) =>
      last == null ? 'Not saved to Drive yet' : 'Last saved to Drive ${DateFormat('d MMM, h:mm a').format(last)}';
}
