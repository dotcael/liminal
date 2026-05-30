// John 3:16-17
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _bg = Color(0xFF1a1a2e);
  static const _textMuted = Color(0xFF6b6b9a);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: const Center(
        child: Text(
          'Profile — coming soon',
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
      ),
    );
  }
}