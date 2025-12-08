import 'package:shared_preferences/shared_preferences.dart';

class ChokepointSession {
  static const _kKey = 'active_chokepoint';
  static const _kAuth = 'auth_token';

  // --- existing ---
  Future<void> setActive(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, value.trim());
  }

  Future<String?> getActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  Future<bool> hasActive() async => (await getActive())?.isNotEmpty == true;

  // --- token helpers ---
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAuth, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAuth);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuth);
  }

  Future<bool> isLoggedIn() async => (await getToken())?.isNotEmpty == true;
}
