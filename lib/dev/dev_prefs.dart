import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevPrefs {
  static String? roleOverride;
  static bool bypassAudience = false;
  static bool showRawIds = false;
  static bool debugPaint = false;

  static final ValueNotifier<String?> roleOverrideNotifier = ValueNotifier(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    roleOverride = prefs.getString('dev_role_override');
    roleOverrideNotifier.value = roleOverride;
    bypassAudience = prefs.getBool('dev_bypass_audience') ?? false;
    showRawIds = prefs.getBool('dev_show_raw_ids') ?? false;
    debugPaint = prefs.getBool('dev_debug_paint') ?? false;
  }

  static Future<void> setRoleOverride(String? role) async {
    roleOverride = role;
    roleOverrideNotifier.value = role;
    final prefs = await SharedPreferences.getInstance();
    if (role == null) {
      await prefs.remove('dev_role_override');
    } else {
      await prefs.setString('dev_role_override', role);
    }
  }

  static Future<void> setBypassAudience(bool v) async {
    bypassAudience = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_bypass_audience', v);
  }

  static Future<void> setShowRawIds(bool v) async {
    showRawIds = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_show_raw_ids', v);
  }

  static Future<void> setDebugPaint(bool v) async {
    debugPaint = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dev_debug_paint', v);
  }

  static String effectiveRole(String realRole) => roleOverride ?? realRole;
  static bool isDev(String realRole) => effectiveRole(realRole) == 'developer';
}
