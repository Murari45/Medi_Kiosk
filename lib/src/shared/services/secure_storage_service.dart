import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keyAuthToken = 'auth_jwt_token';
  static const String _keyUserId = 'logged_in_user_id';
  static const String _keyUserRole = 'logged_in_user_role';
  static const String _keyAppLang = 'selected_app_language';

  Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(key: _keyAuthToken, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuthToken, token);
    }
  }

  Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: _keyAuthToken);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAuthToken);
    }
  }

  Future<void> saveSessionUser(String userId, String role) async {
    try {
      await _secureStorage.write(key: _keyUserId, value: userId);
      await _secureStorage.write(key: _keyUserRole, value: role);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserRole, role);
    }
  }

  Future<String?> getSavedUserId() async {
    try {
      return await _secureStorage.read(key: _keyUserId);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserId);
    }
  }

  Future<String?> getSavedUserRole() async {
    try {
      return await _secureStorage.read(key: _keyUserRole);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserRole);
    }
  }

  Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLang, langCode);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppLang) ?? 'en';
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
  }
}
