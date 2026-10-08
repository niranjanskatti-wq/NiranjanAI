import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;

import '../data/repository.dart';

/// Google Sign-In wrapper. Only Sheets/Drive features use it; the rest of the
/// app never touches the network.
///
/// `drive.file` lets the app see only the files it created itself (the
/// GoldVault sheet and the "GoldVault Backups" folder), nothing else in the
/// user's Drive.
///
/// The signed-in account is remembered so background work (WorkManager, no
/// Activity) can get tokens through the authorization API without any UI.
class GoogleService {
  GoogleService(this.repo);
  final VaultRepo repo;

  static const scopes = <String>[
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/spreadsheets',
  ];

  /// Web OAuth client id from Google Cloud console, passed at build time:
  /// `flutter build apk --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
  static const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Email of the connected Google account (null = not connected).
  final ValueNotifier<String?> email = ValueNotifier(null);
  String? _userId;
  Future<void>? _init;

  bool get configured => serverClientId.isNotEmpty;

  Future<void> load() async {
    email.value = await repo.getSetting('google_email');
    _userId = await repo.getSetting('google_id');
  }

  Future<void> init() => _init ??= () async {
        try {
          await GoogleSignIn.instance.initialize(serverClientId: serverClientId.isEmpty ? null : serverClientId);
        } catch (e) {
          debugPrint('Google init failed: $e');
        }
      }();

  /// Interactive sign-in + scope consent. Must be called from a button tap.
  Future<String> signIn() async {
    await init();
    final a = await GoogleSignIn.instance.authenticate(scopeHint: scopes);
    await a.authorizationClient.authorizeScopes(scopes);
    await repo.setSetting('google_email', a.email);
    await repo.setSetting('google_id', a.id);
    _userId = a.id;
    email.value = a.email;
    return a.email;
  }

  Future<void> signOut() async {
    await init();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    await repo.setSetting('google_email', null);
    await repo.setSetting('google_id', null);
    _userId = null;
    email.value = null;
  }

  Future<String?> _token({required bool prompt}) async {
    final e = email.value;
    if (e == null) return null;
    final t = await GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes(
      ClientAuthorizationTokensForScopesParameters(
        request: AuthorizationRequestDetails(scopes: scopes, userId: _userId, email: e, promptIfUnauthorized: prompt),
      ),
    );
    return t?.accessToken;
  }

  /// HTTP client for googleapis. [interactive] allows sign-in / consent UI;
  /// background work always passes false and gets null if that is needed.
  Future<gauth.AuthClient?> client({bool interactive = false}) async {
    await init();
    if (email.value == null) {
      if (!interactive) return null;
      await signIn();
    }
    String? token;
    try {
      token = await _token(prompt: interactive);
    } catch (e) {
      debugPrint('Google authorization failed: $e');
      if (!interactive) return null;
    }
    if (token == null && interactive) {
      await signIn();
      token = await _token(prompt: true);
    }
    if (token == null) return null;
    return gauth.authenticatedClient(
      http.Client(),
      gauth.AccessCredentials(
        gauth.AccessToken('Bearer', token, DateTime.now().toUtc().add(const Duration(minutes: 50))),
        null,
        scopes,
      ),
    );
  }
}
