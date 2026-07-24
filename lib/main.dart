// John 3:16-17

import 'package:firebase_core/firebase_core.dart';
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
import 'dev/dev_prefs.dart';
import 'dev/dev_log.dart';
import 'services/notification_service.dart';

void main() async {
  // ensures flutter engine is fully ready before any async work runs
  WidgetsFlutterBinding.ensureInitialized();

  // boots firebase using the auto-generated platform config from flutterfire cli
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // boots local notification scheduling
  await NotificationService.init();

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