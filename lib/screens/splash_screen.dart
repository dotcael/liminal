import 'package:flutter/material.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(hours: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Ring 1
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2d2d4a), width: 0.5),
              ),
            ),
          ),
          // Ring 2
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2d2d4a), width: 0.5),
              ),
            ),
          ),
          // Center content
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
                  // child is INSIDE the outer Container, same level as decoration
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
                      child: Center(
                        child: Text(
                          'L',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFc8c8f4),
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // App name
                const SizedBox(height: 32),
                Text(
                  'liminal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFe8e8f4),
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'stay connected, stay informed',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6b6b9a),
                    letterSpacing: 2,
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
