import 'package:shared_preferences/shared_preferences.dart';

class ReminderPrefs {
  static bool enabled = true;
  static int preReminderMinutes = 30;

  static const double sliderMin = 0;
  static const double sliderMax = 120;
  static const int sliderDivisions = 24;
  static const int defaultMinutes = 30;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('reminder_enabled') ?? true;
    preReminderMinutes = prefs.getInt('reminder_pre_minutes') ?? defaultMinutes;
  }

  static Future<void> setEnabled(bool value) async {
    enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', value);
  }

  static Future<void> setPreReminderMinutes(int minutes) async {
    preReminderMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_pre_minutes', minutes);
  }

  static bool get remindersAllowed => enabled && preReminderMinutes > 0;
}
