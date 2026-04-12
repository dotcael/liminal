import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LiminalApp());
}

class LiminalApp extends StatelessWidget {
  const LiminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4a4aaa),
          brightness: Brightness.dark,
        ),
      ),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
      },
      initialRoute: '/splash',
    );
  }
}