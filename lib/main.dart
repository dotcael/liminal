// John 3:16-17

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/feed_screen.dart';
import 'dev/dev_prefs.dart';
import 'dev/dev_log.dart';
import 'services/notification_service.dart';
import 'services/reminder_prefs.dart';
import 'services/fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  } catch (e) {
    debugPrint('App Check activation skipped: $e');
  }

  await NotificationService.init();
  await ReminderPrefs.load();
  NotificationService.requestPermissions();

  FcmService.onNotificationTap = (_) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const FeedScreen()),
    );
  };

  runApp(const LiminalApp());
}

class LiminalApp extends StatefulWidget {
  const LiminalApp({super.key});

  @override
  LiminalAppState createState() => LiminalAppState();
}

class LiminalAppState extends State<LiminalApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  double _textScaleFactor = 1.15;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  double get textScaleFactor => _textScaleFactor;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.15;
    });
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void setTextScaleFactor(double factor) {
    setState(() {
      _textScaleFactor = factor;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('textScaleFactor', factor);
    });
  }

  void toggleDebugPaint() {
    DevPrefs.setDebugPaint(!DevPrefs.debugPaint);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liminal',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowMaterialGrid: DevPrefs.debugPaint,

      builder: (context, child) {
        final systemScale = MediaQuery.textScalerOf(context).scale(1.0);
        final effectiveScale = systemScale * _textScaleFactor;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(effectiveScale),
          ),
          child: child!,
        );
      },

           home: const SplashScreen(),

    );
  }
}
