// John 3:16-17
// BUG FIX: replaced the old colored-square nav with real material icons
// outlined variant for inactive tabs, filled for the active one
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import '../dev/dev_prefs.dart';
import '../dev/floating_toolbar.dart';

class ShellScreen extends StatefulWidget {
  final String name;
  final String role;

  const ShellScreen({super.key, required this.name, required this.role});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  // BUG FIX: added icon data for each nav item
  static const _navItems = [
    _NavItem(label: 'Home',    icon: Icons.home_rounded,        activeIcon: Icons.home_rounded),
    _NavItem(label: 'Feed',    icon: Icons.explore_outlined,    activeIcon: Icons.explore_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_outline,      activeIcon: Icons.person_rounded),
  ];

  // tracks which tab is visible — 0 = Home, 1 = Feed, 2 = Profile
  int _currentIndex = 0;

  bool get _isDev {
    final override = DevPrefs.roleOverride;
    return (override ?? widget.role) == 'developer';
  }

  @override
  Widget build(BuildContext context) {
    // BUG FIX: pull theme colors fresh each build so light/dark toggle works
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final border = theme.dividerColor;
    final textMuted = theme.colorScheme.onSurfaceVariant;
    final activeColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(name: widget.name, role: widget.role),
              FeedScreen(),
              ProfileScreen(name: widget.name, role: widget.role),
            ],
          ),
          if (_isDev)
            FloatingDevToolbar(realRole: widget.role),
        ],
      ),
      bottomNavigationBar: _buildNavBar(bg, border, textMuted, activeColor),
    );
  }

  Widget _buildNavBar(Color bg, Color border, Color textMuted, Color activeColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length,
            (i) => _buildNavItem(_navItems[i], index: i, textMuted: textMuted, activeColor: activeColor)),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, {required int index, required Color textMuted, required Color activeColor}) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? item.activeIcon : item.icon,
            size: 20,
            color: isActive ? activeColor : textMuted,
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 9,
              color: isActive ? activeColor : textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// BUG FIX: helper data class so icon definitions live in one place
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
