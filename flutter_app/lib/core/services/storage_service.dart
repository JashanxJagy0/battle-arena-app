import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  StorageService({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage;

  // ─── Secure Token Storage ───────────────────────────────────────────────────

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _keyAccessToken),
      _secureStorage.delete(key: _keyRefreshToken),
    ]);
  }

  // ─── SharedPreferences ──────────────────────────────────────────────────────

  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyThemeMode = 'theme_mode';
  static const _keyUserId = 'user_id';

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_keyOnboardingComplete, value);
  }

  bool get isOnboardingComplete => _prefs.getBool(_keyOnboardingComplete) ?? false;

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'dark';

  Future<void> setUserId(String userId) async {
    await _prefs.setString(_keyUserId, userId);
  }

  String? get userId => _prefs.getString(_keyUserId);

  Future<void> clearAll() async {
    await Future.wait([
      clearTokens(),
      _prefs.clear(),
    ]);
  }
}
