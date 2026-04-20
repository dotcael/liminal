// John 3:16-17

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/feed_screen.dart';

void main() async {
  // ensures flutter engine is fully ready before any async work runs
  WidgetsFlutterBinding.ensureInitialized();

  // boots firebase using the auto-generated platform config from flutterfire cli
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const LiminalApp());
}

class LiminalApp extends StatelessWidget {
  // app shell never changes state so stateless 
  const LiminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liminal',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // deep navy base — overrides material's default scaffold color
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),

        // generates a full color scheme from the indigo seed
        // keeps buttons, highlights, and accents on-palette automatically
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4a4aaa),
          brightness: Brightness.dark,
        ),
      ),

      // named routes registered here — splash decides where to send the user next
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(name: 'Test User', role: 'Admin'),      },

      // app always opens at splash first
      // initialRoute: '/splash'
    //  home: const HomeScreen(name: 'Test User', role: 'Admin'),
      home: const FeedScreen(),
    );
  }
}