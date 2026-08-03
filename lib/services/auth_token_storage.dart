import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

abstract interface class AuthTokenStorage {
  Future<AuthTokens?> loadTokens();
  Future<void> saveTokens(AuthTokens tokens);
  Future<void> clearTokens();
}

class SecureAuthTokenStorage implements AuthTokenStorage {
  static const String keyAccessToken = 'otaku_log_access_token_v1';
  static const String keyRefreshToken = 'otaku_log_refresh_token_v1';
  static const String keyTokenMeta = 'otaku_log_token_meta_v1';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _fallbackPrefs;

  SecureAuthTokenStorage({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? fallbackPrefs,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _fallbackPrefs = fallbackPrefs;

  Future<SharedPreferences> _getPrefs() async {
    return _fallbackPrefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<AuthTokens?> loadTokens() async {
    try {
      final access = await _secureStorage.read(key: keyAccessToken);
      final refresh = await _secureStorage.read(key: keyRefreshToken);
      final metaRaw = await _secureStorage.read(key: keyTokenMeta);

      if (access != null && refresh != null) {
        int expiresIn = 900;
        String tokenType = 'Bearer';
        DateTime? savedAt;
        if (metaRaw != null) {
          try {
            final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
            expiresIn = (meta['expiresInSeconds'] as num?)?.toInt() ?? 900;
            tokenType = meta['tokenType']?.toString() ?? 'Bearer';
            if (meta['savedAt'] != null) {
              savedAt = DateTime.tryParse(meta['savedAt'].toString());
            }
          } catch (_) {}
        }
        return AuthTokens(
          accessToken: access,
          refreshToken: refresh,
          tokenType: tokenType,
          expiresInSeconds: expiresIn,
          savedAt: savedAt ?? DateTime.now().toUtc(),
        );
      }
    } catch (_) {
      // If secure storage fails (e.g. Linux/Test fallback), use SharedPreferences
    }

    try {
      final prefs = await _getPrefs();
      final access = prefs.getString(keyAccessToken);
      final refresh = prefs.getString(keyRefreshToken);
      final metaRaw = prefs.getString(keyTokenMeta);

      if (access != null && refresh != null) {
        int expiresIn = 900;
        String tokenType = 'Bearer';
        DateTime? savedAt;
        if (metaRaw != null) {
          try {
            final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
            expiresIn = (meta['expiresInSeconds'] as num?)?.toInt() ?? 900;
            tokenType = meta['tokenType']?.toString() ?? 'Bearer';
            if (meta['savedAt'] != null) {
              savedAt = DateTime.tryParse(meta['savedAt'].toString());
            }
          } catch (_) {}
        }
        return AuthTokens(
          accessToken: access,
          refreshToken: refresh,
          tokenType: tokenType,
          expiresInSeconds: expiresIn,
          savedAt: savedAt ?? DateTime.now().toUtc(),
        );
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    final metaRaw = jsonEncode({
      'tokenType': tokens.tokenType,
      'expiresInSeconds': tokens.expiresInSeconds,
      'savedAt': tokens.savedAt.toUtc().toIso8601String(),
    });

    bool secureSuccess = false;
    try {
      await _secureStorage.write(
          key: keyAccessToken, value: tokens.accessToken);
      await _secureStorage.write(
          key: keyRefreshToken, value: tokens.refreshToken);
      await _secureStorage.write(key: keyTokenMeta, value: metaRaw);
      secureSuccess = true;
    } catch (_) {}

    if (!secureSuccess) {
      try {
        final prefs = await _getPrefs();
        await prefs.setString(keyAccessToken, tokens.accessToken);
        await prefs.setString(keyRefreshToken, tokens.refreshToken);
        await prefs.setString(keyTokenMeta, metaRaw);
      } catch (_) {}
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: keyAccessToken);
      await _secureStorage.delete(key: keyRefreshToken);
      await _secureStorage.delete(key: keyTokenMeta);
    } catch (_) {}

    try {
      final prefs = await _getPrefs();
      await prefs.remove(keyAccessToken);
      await prefs.remove(keyRefreshToken);
      await prefs.remove(keyTokenMeta);
    } catch (_) {}
  }
}

class InMemoryAuthTokenStorage implements AuthTokenStorage {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> loadTokens() async => _tokens;

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clearTokens() async {
    _tokens = null;
  }
}
