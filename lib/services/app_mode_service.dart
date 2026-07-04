import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user chose Captain or Passenger (no login UI for passenger).
class AppModeService {
  static const _personaKey = 'app_persona';

  static Future<String?> getPersona() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_personaKey);
  }

  static Future<void> setPersona(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_personaKey, value);
  }

  static Future<void> clearPersona() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_personaKey);
  }
}
