import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shell_screen.dart';
import '../dev/dev_prefs.dart';
import '../dev/dev_log.dart';
import '../services/fcm_service.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
@override
void initState() {
  super.initState();
  _checkAuthAndNavigate();
}
Future<void> _checkAuthAndNavigate() async {
  // BUG FIX: conventional splash duration — was a hard 3s, which felt slow.
  // 1s is just enough for the logo to register without dragging startup.
  await Future.delayed(const Duration(seconds: 1));

  await DevPrefs.load();
  await DevLog.load();

  final user = FirebaseAuth.instance.currentUser;

  if (!mounted) return;


  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final name = doc.data()?['name'] ?? 'there';
    final role = doc.data()?['role'] ?? 'student';

    // BUG FIX (Phase C): wire FCM token + push listeners for the signed-in user
    FcmService.configureListeners();
    FcmService.ensureToken();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ShellScreen(name: name, role: role),
      ),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Ring 1
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2d2d4a),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
          // BUG FIX: removed duplicate oval ring (250x347) that was labelled Ring 2 —
          // it overlapped the actual circle ring below and was visibly wrong since
          // BoxShape.circle was used on a non-square container
          // Ring 2
          Positioned(
            top: MediaQuery.of(context).size.height * 0.20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2d2d4a),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),

          //  CENTER CONTENT (
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Outer circle
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF23234a),
                    border: Border.all(
                      color: const Color(0xFF3a3a6a),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2a2a5a),
                        border: Border.all(
                          color: const Color(0xFF4a4aaa),
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'L',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFc8c8f4),
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // App name
                const SizedBox(height: 32),

                const Text(
                  'Liminal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFe8e8f4),
                    letterSpacing: 5,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'stay on track, stay informed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b6b9a),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          //  Footer moved OUTSIDE the Column into Stack
          // This allows it to be positioned independently
          Positioned(
            bottom: 40, //  pins it to bottom of screen
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(width: 30, height: 1, color: const Color(0xFF2d2d4a)),
                const SizedBox(height: 12),
                const Text(
                  'For KouZoya 🌹',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF4a4aaa),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
