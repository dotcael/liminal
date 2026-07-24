import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dev_prefs.dart';
import 'dev_log.dart';
import 'data_seeder.dart';
import '../main.dart';

class CommandPalette extends StatefulWidget {
  final String realRole;

  const CommandPalette({super.key, required this.realRole});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  String _input = '';

  static const _commands = [
    _Cmd('/whoami', 'Show your user info'),
    _Cmd('/theme dark', 'Switch to dark mode'),
    _Cmd('/theme light', 'Switch to light mode'),
    _Cmd('/role student', 'Impersonate student'),
    _Cmd('/role rep', 'Impersonate rep'),
    _Cmd('/role dev', 'Impersonate dev'),
    _Cmd('/role reset', 'Use your real role'),
    _Cmd('/tasks seed', 'Generate 5 test tasks'),
    _Cmd('/tasks clear', 'Wipe all local tasks'),
    _Cmd('/broadcast test', 'Send a dummy broadcast'),
    _Cmd('/log', 'Show dev activity log'),
    _Cmd('/help', 'Show all commands'),
  ];

  List<_Cmd> get _filtered {
    if (_input.isEmpty) return _commands;
    final q = _input.toLowerCase();
    return _commands.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _execute(String cmd) async {
    final parts = cmd.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return;

    switch (parts[0]) {
      case '/whoami':
        final info = await _getUserInfo();
        if (mounted) {
          _showResult('UID: ${info['uid']}\nEmail: ${info['email']}\nRole: ${info['role']}');
        }
        break;

      case '/theme':
        if (parts.length < 2) {
          _showToast('Usage: /theme dark | /theme light');
          return;
        }
        final appState = context.findAncestorStateOfType<LiminalAppState>();
        if (appState == null) return;
        final isDark = parts[1] == 'dark';
        if (appState.isDarkMode != isDark) appState.toggleTheme();
        _showToast('Switched to ${isDark ? 'dark' : 'light'} mode');
        DevLog.log('Command: /theme ${parts[1]}');
        if (mounted) Navigator.pop(context);
        break;

      case '/role':
        if (parts.length < 2) {
          _showToast('Usage: /role student | /role rep | /role dev | /role reset');
          return;
        }
        if (parts[1] == 'reset') {
          await DevPrefs.setRoleOverride(null);
          _showToast('Role reset to ${widget.realRole}');
        } else if (['student', 'rep', 'developer'].contains(parts[1])) {
          final mapped = parts[1] == 'dev' ? 'developer' : parts[1];
          await DevPrefs.setRoleOverride(mapped);
          _showToast('Now viewing as $mapped');
        } else {
          _showToast('Unknown role: ${parts[1]}');
          return;
        }
        DevLog.log('Command: /role ${parts[1]}');
        if (mounted) Navigator.pop(context);
        break;

      case '/tasks':
        if (parts.length < 2) {
          _showToast('Usage: /tasks seed | /tasks clear');
          return;
        }
        if (parts[1] == 'seed') {
          final count = await DataSeeder.seedTasks();
          _showToast('$count test tasks added');
          DevLog.log('Command: seeded $count tasks');
          if (mounted) Navigator.pop(context);
        } else if (parts[1] == 'clear') {
          await DataSeeder.clearTasks();
          _showToast('All local tasks cleared');
          DevLog.log('Command: cleared tasks');
          if (mounted) Navigator.pop(context);
        } else {
          _showToast('Unknown subcommand: /tasks ${parts[1]}');
        }
        break;

      case '/broadcast':
        if (parts.length < 2 || parts[1] != 'test') {
          _showToast('Usage: /broadcast test');
          return;
        }
        final ok = await DataSeeder.seedBroadcast();
        _showToast(ok ? 'Test broadcast sent!' : 'Not logged in');
        if (ok) DevLog.log('Command: sent test broadcast');
        if (mounted) Navigator.pop(context);
        break;

      case '/log':
        final entries = DevLog.entries;
        if (entries.isEmpty) {
          _showResult('No activity yet.');
        } else {
          final text = entries.take(20).map((e) => '[${e.timeFormatted}] ${e.action}${e.detail != null ? ' — ${e.detail}' : ''}').join('\n');
          _showResult(text);
        }
        break;

      case '/help':
        final text = _commands.map((c) => '${c.name}  — ${c.desc}').join('\n');
        _showResult(text);
        break;

      default:
        _showToast('Unknown command: ${parts[0]}. Try /help');
    }
  }

  Future<Map<String, String>> _getUserInfo() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) return {'uid': '—', 'email': '—', 'role': '—'};

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'] as String? ?? 'student';

    return {
      'uid': user.uid,
      'email': user.email ?? '—',
      'role': role,
    };
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: const Color(0xFF2a2a5a),
      textColor: const Color(0xFFe8e8f4),
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void _showResult(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFFe8e8f4), fontFamily: 'monospace', height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF7b7bcc))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: Color(0xFF7b7bcc)),
                const SizedBox(width: 8),
                const Text('Command Palette', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFe8e8f4))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 16, color: Color(0xFF6b6b9a)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF22223a),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3a3a6a), width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(fontSize: 13, color: Color(0xFFe8e8f4), fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Type a command...',
                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF4a4a6a), fontFamily: 'monospace'),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) => setState(() => _input = v),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) _execute(v.trim());
                },
              ),
            ),
            const SizedBox(height: 10),
            if (_filtered.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, i) {
                    final cmd = _filtered[i];
                    return GestureDetector(
                      onTap: () => _execute(cmd.name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: _input.isNotEmpty ? const Color(0xFF2a2a5a) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(cmd.name, style: TextStyle(
                              fontSize: 11,
                              color: _input.isNotEmpty ? const Color(0xFFa0a0ee) : const Color(0xFF7b7bcc),
                              fontFamily: 'monospace',
                            )),
                            const SizedBox(width: 8),
                            Text(cmd.desc, style: const TextStyle(fontSize: 10, color: Color(0xFF6b6b9a))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cmd {
  final String name;
  final String desc;
  const _Cmd(this.name, this.desc);
}
