// John 3:16-17
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';

class ShellScreen extends StatefulWidget {
  final String name;
  final String role;

  const ShellScreen({super.key, required this.name, required this.role});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  static const _bg = Color(0xFF1a1a2e);
  static const _border = Color(0xFF2d2d4a);
  static const _textMuted = Color(0xFF6b6b9a);

  // tracks which tab is visible — 0 = Home, 1 = Feed, 2 = Profile
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // IndexedStack keeps all screens mounted and in memory
      // only the child at currentIndex is visible — the others are hidden but alive
      // this means scroll position and state are preserved when switching tabs
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(name: widget.name, role: widget.role),
          const FeedScreen(),
          ProfileScreen(name: widget.name, role: widget.role),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('Home', index: 0),
          _buildNavItem('Feed', index: 1),
          _buildNavItem('Profile', index: 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, {required int index}) {
    final isActive = _currentIndex == index;
    return GestureDetector(
     
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF3a3a7a)
                  : const Color(0xFF2d2d4a),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isActive ? const Color(0xFF7b7bcc) : _textMuted,
            ),
          ),
        ],
      ),
    );
  }
}