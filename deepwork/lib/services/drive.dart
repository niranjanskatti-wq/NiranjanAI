import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Google Drive backup — the app's only network feature. Uses the narrow drive.file scope, so the
/// app can only see files it created. On Android, Google identifies the app by its package name and
/// signing certificate (an "Android" OAuth client in your Google Cloud project), so no client ID is
/// needed in the code.
const driveFileScope = 'https://www.googleapis.com/auth/drive.file';
const driveFolderName = 'Deepwork Backups';
const _api = 'https://www.googleapis.com/drive/v3';
const _upload = 'https://www.googleapis.com/upload/drive/v3';

class DriveAuthException implements Exception {
  DriveAuthException([this.message = 'Google sign-in expired. Reconnect to keep backing up.']);
  final String message;
  @override
  String toString() => message;
}

class DriveException implements Exception {
  DriveException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DriveBackupFile {
  DriveBackupFile(this.id, this.name, this.modifiedTime, this.size);
  final String id, name;
  final DateTime modifiedTime;
  final int? size;
}

class DriveClient {
  DriveClient._();
  static final instance = DriveClient._();

  bool _initialized = false;
  String? _folderId;

  Future<void> _init() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  /// A token without any UI, if access was granted before; otherwise null.
  Future<String?> silentToken() async {
    try {
      await _init();
      final a = await GoogleSignIn.instance.authorizationClient.authorizationForScopes([driveFileScope]);
      return a?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Shows Google's consent screen when needed.
  Future<String> interactiveToken() async {
    try {
      await _init();
      final a = await GoogleSignIn.instance.authorizationClient.authorizeScopes([driveFileScope]);
      return a.accessToken;
    } on GoogleSignInException catch (e) {
      throw DriveException(switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'Google sign-in was cancelled.',
        GoogleSignInExceptionCode.clientConfigurationError || GoogleSignInExceptionCode.providerConfigurationError =>
          'Google rejected this app. Add an Android OAuth client for package com.niranjan.deepwork with this app’s SHA-1 in Google Cloud Console (see Settings → Backup).',
        _ => 'Google sign-in failed${e.description != null ? ': ${e.description}' : '.'}',
      });
    }
  }

  Future<void> disconnect(String? token) async {
    _folderId = null;
    if (token != null) {
      try {
        await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: token);
        await http.post(Uri.parse('https://oauth2.googleapis.com/revoke?token=${Uri.encodeQueryComponent(token)}'));
      } catch (_) {
        // Offline: the token expires on its own within an hour.
      }
    }
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
  }

  Future<http.Response> _send(String token, String method, String url, {Map<String, String>? headers, Object? body}) async {
    final req = http.Request(method, Uri.parse(url));
    req.headers['Authorization'] = 'Bearer $token';
    if (headers != null) req.headers.addAll(headers);
    if (body is String) req.body = body;
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode == 401) {
      try {
        await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: token);
      } catch (_) {}
      throw DriveAuthException();
    }
    if (res.statusCode >= 400) {
      var msg = 'Google Drive error (${res.statusCode})';
      try {
        msg = (jsonDecode(res.body) as Map)['error']['message'] as String? ?? msg;
      } catch (_) {}
      if (res.statusCode == 403 && msg.toLowerCase().contains('insufficient')) throw DriveAuthException('Drive permission was not granted. Reconnect and allow access.');
      throw DriveException(msg);
    }
    return res;
  }

  Future<String?> accountEmail(String token) async {
    try {
      final r = await _send(token, 'GET', '$_api/about?fields=user(emailAddress,displayName)');
      final u = (jsonDecode(r.body) as Map)['user'] as Map?;
      return (u?['emailAddress'] ?? u?['displayName']) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String> _folder(String token) async {
    if (_folderId != null) return _folderId!;
    final q = Uri.encodeQueryComponent("name='$driveFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false");
    final r = await _send(token, 'GET', '$_api/files?q=$q&fields=files(id,name)&spaces=drive');
    final files = (jsonDecode(r.body) as Map)['files'] as List;
    if (files.isNotEmpty) return _folderId = (files.first as Map)['id'] as String;
    final c = await _send(token, 'POST', '$_api/files?fields=id',
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': driveFolderName, 'mimeType': 'application/vnd.google-apps.folder'}));
    return _folderId = (jsonDecode(c.body) as Map)['id'] as String;
  }

  Future<List<DriveBackupFile>> listBackups(String token) async {
    final folder = await _folder(token);
    final q = Uri.encodeQueryComponent("'$folder' in parents and trashed=false and mimeType='application/json'");
    final r = await _send(token, 'GET', '$_api/files?q=$q&orderBy=modifiedTime%20desc&pageSize=200&fields=files(id,name,modifiedTime,size,appProperties)');
    final files = (jsonDecode(r.body) as Map)['files'] as List;
    return [
      for (final f in files.cast<Map>())
        if ((f['appProperties'] as Map?)?['deepwork'] == 'backup' || RegExp(r'^deepwork-backup-.*\.json$').hasMatch(f['name'] as String))
          DriveBackupFile(f['id'] as String, f['name'] as String, DateTime.parse(f['modifiedTime'] as String).toLocal(), int.tryParse('${f['size']}')),
    ];
  }

  Future<void> uploadBackup(String token, String filename, String json) async {
    final folder = await _folder(token);
    final existing = (await listBackups(token)).where((f) => f.name == filename).firstOrNull;
    final boundary = 'deepwork${DateTime.now().microsecondsSinceEpoch}';
    final meta = existing != null
        ? {'name': filename, 'mimeType': 'application/json'}
        : {
            'name': filename,
            'mimeType': 'application/json',
            'parents': [folder],
            'appProperties': {'deepwork': 'backup'},
          };
    final body = '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${jsonEncode(meta)}\r\n'
        '--$boundary\r\nContent-Type: application/json\r\n\r\n$json\r\n--$boundary--';
    await _send(
      token,
      existing != null ? 'PATCH' : 'POST',
      existing != null ? '$_upload/files/${existing.id}?uploadType=multipart' : '$_upload/files?uploadType=multipart',
      headers: {'Content-Type': 'multipart/related; boundary=$boundary'},
      body: body,
    );
  }

  /// Keeps the newest [keep] backups and deletes older ones the app created.
  Future<int> pruneBackups(String token, int keep) async {
    final files = await listBackups(token);
    final old = files.skip(keep < 1 ? 1 : keep).toList();
    for (final f in old) {
      await _send(token, 'DELETE', '$_api/files/${f.id}');
    }
    return old.length;
  }

  Future<String> download(String token, String id) async => (await _send(token, 'GET', '$_api/files/$id?alt=media')).body;
}
