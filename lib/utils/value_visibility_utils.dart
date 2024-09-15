import 'package:shared_preferences/shared_preferences.dart';

class ValueVisibilityService {
  static Future<bool> loadVisibilityPreference(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false; 
  }

  static Future<void> saveVisibilityPreference(String key, bool isHidden) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, isHidden);
  }
}
