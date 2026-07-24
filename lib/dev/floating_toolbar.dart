import 'package:flutter/material.dart';
import 'dev_prefs.dart';
import 'command_palette.dart';
import 'data_seeder.dart';
import 'dev_log.dart';
import 'firestore_explorer.dart';
import '../main.dart';

class FloatingDevToolbar extends StatefulWidget {
  final String realRole;

  const FloatingDevToolbar({super.key, required this.realRole});

  @override
  State<FloatingDevToolbar> createState() => _FloatingDevToolbarState();
}

class _FloatingDevToolbarState extends State<FloatingDevToolbar> {
  bool _expanded = false;
  double _x = 0;
  double _y = 0;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (!_initialized) {
      _x = size.width - 60;
      _y = size.height * 0.45;
      _initialized = true;
    }

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _x = (_x + details.delta.dx).clamp(0, size.width - 44);
            _y = (_y + details.delta.dy).clamp(0, size.height - 44);
          });
        },
        child: _expanded ? _buildExpanded() : _buildCollapsed(),
      ),
    );
  }

  Widget _buildCollapsed() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = true),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a5a),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF4a4aaa), width: 1),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: const Center(
          child: Text('D', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFa0a0ee))),
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4a4aaa), width: 0.8),
        boxShadow: const [BoxShadow(color: Color(0x60000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toolbarButton(Icons.close, 'Close', () => setState(() => _expanded = false), isClose: true),
          const SizedBox(height: 4),
          _divider(),
          _toolbarButton(Icons.terminal, 'Cmd', _openPalette),
          _divider(),
          _toolbarButton(Icons.swap_horiz, 'Role', _cycleRole),
          _divider(),
          _toolbarButton(Icons.download, 'Seed', _seedTasks),
          _divider(),
          _toolbarButton(Icons.add_alert, 'Test', _testBroadcast),
          _divider(),
          _toolbarButton(Icons.storage, 'DB', _openExplorer),
          _divider(),
          _toolbarButton(Icons.bug_report, 'Debug', _toggleDebug),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 10), color: const Color(0xFF2d2d4a));

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onTap, {bool isClose = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: isClose ? const Color(0xFFd87a5a) : const Color(0xFF7b7bcc)),
          ),
        ),
      ),
    );
  }

  void _openPalette() {
    showDialog(
      context: context,
      builder: (_) => CommandPalette(realRole: widget.realRole),
    );
  }

  Future<void> _cycleRole() async {
    final current = DevPrefs.roleOverride ?? '';
    final roles = ['', 'student', 'rep', 'developer'];
    final idx = (roles.indexOf(current) + 1) % roles.length;
    final next = roles[idx];
    await DevPrefs.setRoleOverride(next.isEmpty ? null : next);
    DevLog.log('Role sim: ${next.isEmpty ? "reset to ${widget.realRole}" : next}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.isEmpty ? 'Role reset' : 'Now viewing as $next', style: const TextStyle(fontSize: 11)),
          backgroundColor: const Color(0xFF2a2a5a),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _seedTasks() async {
    final count = await DataSeeder.seedTasks();
    DevLog.log('Seeded $count tasks');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count test tasks added', style: const TextStyle(fontSize: 11)), backgroundColor: const Color(0xFF2a2a5a)),
      );
    }
  }

  Future<void> _testBroadcast() async {
    final ok = await DataSeeder.seedBroadcast();
    if (ok) DevLog.log('Sent test broadcast');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Test broadcast sent!' : 'Not logged in', style: const TextStyle(fontSize: 11)), backgroundColor: const Color(0xFF2a2a5a)),
      );
    }
  }

  void _openExplorer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FirestoreExplorer(),
    );
  }

  void _toggleDebug() {
    final appState = context.findAncestorStateOfType<LiminalAppState>();
    if (appState == null) return;
    appState.toggleDebugPaint();
    DevLog.log('Toggled debug paint');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug paint: ${DevPrefs.debugPaint ? "ON" : "OFF"}', style: const TextStyle(fontSize: 11)),
          backgroundColor: const Color(0xFF2a2a5a),
        ),
      );
    }
  }
}
