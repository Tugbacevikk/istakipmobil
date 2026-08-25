import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const String _keyServerUrl = 'server_url';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  static const String _keyUserRole = 'user_role';
  static const String _keyIsDarkMode = 'is_dark_mode';

  static String? _cachedServerUrl;
  static bool? _cachedIsDarkMode;
  static String? _cachedUsername;
  static String? _cachedUserRole;
  static bool? _cachedIsLoggedIn;

  static String get defaultServerUrl {
    if (kIsWeb) {
      final Uri uri = Uri.base;
      if (uri.host.isNotEmpty) {
        final portStr = (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
        return '${uri.scheme}://${uri.host}$portStr';
      }
      return 'http://localhost:5000';
    }
    return 'http://192.168.30.168:5000';
  }

  static Future<String> getServerUrl() async {
    if (kIsWeb) {
      _cachedServerUrl = defaultServerUrl;
      return _cachedServerUrl!;
    }
    if (_cachedServerUrl != null) return _cachedServerUrl!;
    final prefs = await SharedPreferences.getInstance();
    _cachedServerUrl = prefs.getString(_keyServerUrl) ?? defaultServerUrl;
    return _cachedServerUrl!;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      if (kDebugMode) {
        cleanUrl = 'http://$cleanUrl';
      } else {
        cleanUrl = 'https://$cleanUrl';
      }
    }
    _cachedServerUrl = cleanUrl;
    await prefs.setString(_keyServerUrl, cleanUrl);
  }

  static Future<bool> isLoggedIn() async {
    if (_cachedIsLoggedIn != null) return _cachedIsLoggedIn!;
    final prefs = await SharedPreferences.getInstance();
    _cachedIsLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    return _cachedIsLoggedIn!;
  }

  static Future<void> setSession({required bool isLoggedIn, String? username, String? role}) async {
    _cachedIsLoggedIn = isLoggedIn;
    if (username != null) _cachedUsername = username;
    if (role != null) _cachedUserRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    if (username != null) await prefs.setString(_keyUsername, username);
    if (role != null) await prefs.setString(_keyUserRole, role);
  }

  static Future<String?> getUsername() async {
    if (_cachedUsername != null) return _cachedUsername;
    final prefs = await SharedPreferences.getInstance();
    _cachedUsername = prefs.getString(_keyUsername);
    return _cachedUsername;
  }

  static Future<String?> getUserRole() async {
    if (_cachedUserRole != null) return _cachedUserRole;
    final prefs = await SharedPreferences.getInstance();
    _cachedUserRole = prefs.getString(_keyUserRole);
    return _cachedUserRole;
  }

  static Future<void> logout() async {
    _cachedIsLoggedIn = false;
    _cachedUsername = null;
    _cachedUserRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyUserRole);
  }

  static Future<bool> isDarkMode() async {
    if (_cachedIsDarkMode != null) return _cachedIsDarkMode!;
    final prefs = await SharedPreferences.getInstance();
    _cachedIsDarkMode = prefs.getBool(_keyIsDarkMode) ?? true;
    return _cachedIsDarkMode!;
  }

  static Future<void> setDarkMode(bool isDark) async {
    _cachedIsDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDarkMode, isDark);
  }
}
