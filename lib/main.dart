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

// BUG FIX: global key so FCM notification taps can navigate anywhere (feed)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // ensures flutter engine is fully ready before any async work runs
  WidgetsFlutterBinding.ensureInitialized();

  // boots firebase using the auto-generated platform config from flutterfire cli
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable App Check to prevent API abuse from non-app clients.
  // Uses DeviceCheck on iOS/macOS and Play Integrity on Android.
  // Requires: flutter pub get && enabling App Check in the Firebase Console.
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  } catch (e) {
    // App Check activation can fail if not configured in the Firebase Console.
    // The app continues to work — Firestore rules still enforce auth.
    debugPrint('App Check activation skipped: $e');
  }

  // NotificationService.init() requests alert/badge/sound permission on iOS the
  // first time the app launches, so reminders work while the app is closed.
  await NotificationService.init();
  await ReminderPrefs.load();
  NotificationService.requestPermissions();

  // FCM tap routing — pushes about a broadcast open the feed
  FcmService.onNotificationTap = (_) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const FeedScreen()),
    );
  };

  runApp(const LiminalApp());
}

// BUG FIX: made stateful so the app can switch between dark and light themes
// without needing Provider or a state management library
class LiminalApp extends StatefulWidget {
  // app shell never changes state so stateless 
  const LiminalApp({super.key});

  @override
  LiminalAppState createState() => LiminalAppState();
}

// BUG FIX: public state class so ProfileScreen can call toggleTheme()
// via context.findAncestorStateOfType<LiminalAppState>()
class LiminalAppState extends State<LiminalApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  // BUG FIX: default was 1.3 — text rendered 30% bigger than every other app
  // on the phone, which read as "off". 1.0 respects the OS text setting;
  // users can still scale up in Settings.
  double _textScaleFactor = 1.0;

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
      _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
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

      // BUG FIX: now uses the extracted AppTheme + themeMode state
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowMaterialGrid: DevPrefs.debugPaint,

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_textScaleFactor),
          ),
          child: child!,
        );
      },

      // BUG FIX: re-enabled splash screen — hardcoded ShellScreen bypassed auth,
      // which meant FirebaseAuth.currentUser was null and Firestore rules
      // (require auth) blocked every read/write including the feed stream
      // named routes registered here — splash decides where to send the user next
//    routes: {
//   '/splash': (context) => const SplashScreen(),
// //'/auth':   (context) => const AuthScreen(),
//   '/home':   (context) => const HomeScreen(name: 'Test User', role: 'Admin'),
//  // '/feed': (context) => const FeedScreen(),
// },
      // app always opens at splash first
      // initialRoute: 'splash',
// BUG FIX: home: const ShellScreen(name: 'Developer', role: 'student'),     
           home: const SplashScreen(),

    );
  }
}