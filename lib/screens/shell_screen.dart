import 'package:flutter/material.dart';
import '../dev/dev_prefs.dart';
import '../dev/floating_toolbar.dart';
import '../widgets/haptics.dart';
import '../widgets/pressable.dart';
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
  static const _navItems = [
    _NavItem(label: 'Home',    icon: Icons.home_rounded,        activeIcon: Icons.home_rounded),
    _NavItem(label: 'Feed',    icon: Icons.explore_outlined,    activeIcon: Icons.explore_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_outline,      activeIcon: Icons.person_rounded),
  ];

  static const _navBarHeight = 56.0;

  int _currentIndex = 0;
  bool _showNavBar = true;

  bool get _isDev {
    final override = DevPrefs.roleOverride;
    return (override ?? widget.role) == 'developer';
  }

  @override
  void initState() {
    super.initState();
    DevPrefs.roleOverrideNotifier.addListener(_onRoleChanged);
  }

  void _onRoleChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    DevPrefs.roleOverrideNotifier.removeListener(_onRoleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final border = theme.dividerColor;
    final textMuted = theme.colorScheme.onSurfaceVariant;
    final activeColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          final delta = notification.scrollDelta ?? 0;
          if (delta.abs() > 3) {
            if (delta > 0 && _showNavBar) {
              setState(() => _showNavBar = false);
            } else if (delta < 0 && !_showNavBar) {
              setState(() => _showNavBar = true);
            }
          }
          return false;
        },
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: _showNavBar ? _navBarHeight : 0),
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeScreen(name: widget.name, role: widget.role),
                  FeedScreen(),
                  ProfileScreen(name: widget.name, role: widget.role),
                ],
              ),
            ),
            if (_isDev && DevPrefs.isDebugBuild)
              FloatingDevToolbar(realRole: widget.role),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: AnimatedSlide(
                offset: _showNavBar ? Offset.zero : const Offset(0, 1.2),
                duration: const Duration(milliseconds: 200),
                child: _buildNavBar(bg, border, textMuted, activeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(Color bg, Color border, Color textMuted, Color activeColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      padding: const EdgeInsets.only(top: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length,
              (i) => _buildNavItem(_navItems[i], index: i, textMuted: textMuted, activeColor: activeColor)),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, {required int index, required Color textMuted, required Color activeColor}) {
    final isActive = _currentIndex == index;
    return AppPressable(
      haptic: false,
      onTap: () {
        if (isActive) return;
        Haptics.select();
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isActive ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              size: 20,
              color: isActive ? activeColor : textMuted,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? activeColor : textMuted,
            ),
            child: Text(item.label, maxLines: 1),
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
