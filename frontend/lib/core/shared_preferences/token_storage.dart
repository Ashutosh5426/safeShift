import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static String? _cachedToken;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('jwt_token');
  }

  static String? get token => _cachedToken;

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    _cachedToken = token;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    _cachedToken = null;
  }
}
