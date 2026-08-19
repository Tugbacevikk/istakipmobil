import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const String _keyServerUrl = 'server_url';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';
  static const String _keyUserRole = 'user_role';

  // Default server address (can be updated by user in settings screen)
  static const String defaultServerUrl = 'http://10.0.2.2:5000'; // 10.0.2.2 for Android emulator -> localhost

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl) ?? defaultServerUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Ensure clean URL without trailing slash
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    await prefs.setString(_keyServerUrl, cleanUrl);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> setSession({required bool isLoggedIn, String? username, String? role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    if (username != null) await prefs.setString(_keyUsername, username);
    if (role != null) await prefs.setString(_keyUserRole, role);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyUserRole);
  }
}
