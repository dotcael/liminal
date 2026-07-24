// John 3:16-17
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'auth_screen.dart';
import '../main.dart';
import '../dev/dev_prefs.dart';
import '../dev/dev_log.dart';
import '../dev/data_seeder.dart';
import '../dev/command_palette.dart';
import '../dev/firestore_explorer.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String role;

  const ProfileScreen({super.key, required this.name, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _border => Theme.of(context).dividerColor;
  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _textDim => Theme.of(context).colorScheme.outline;

  String _department = '';
  String _email = '';
  bool _isLoading = true;

  bool get _isRep => _effectiveRole == 'rep';
  bool get _isDev => _effectiveRole == 'developer';
  String get _effectiveRole => DevPrefs.roleOverride ?? widget.role;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      _department = doc.data()?['department'] as String? ?? '';
      _email = doc.data()?['email'] as String? ?? user.email ?? '';
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _accent))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 24),
          _buildThemeSection(),
          const SizedBox(height: 24),
          _buildDisplaySection(),
          const SizedBox(height: 24),
          if (_isDev) ...[
            _buildDevSection(),
          ] else ...[
            _isRep ? _buildRepSection() : _buildStudentSection(),
          ],
          const SizedBox(height: 32),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final roleBadge = _isDev
        ? _buildDevBadge()
        : _isRep
            ? _buildRepBadge()
            : _buildStudentBadge();

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isDev ? const Color(0xFF2a1a3a) : const Color(0xFF2a2a5a),
            border: Border.all(
              color: _isDev ? const Color(0xFF8a4aaa) : const Color(0xFF4a4aaa),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: _isDev ? const Color(0xFFc87aee) : const Color(0xFFa0a0ee),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            roleBadge,
          ],
        ),
      ],
    );
  }

  Widget _buildRepBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a5a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Rep',
        style: TextStyle(
          fontSize: 10,
          color: const Color(0xFF8888dd),
        ),
      ),
    );
  }

  Widget _buildStudentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1a3a28),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Student',
        style: TextStyle(
          fontSize: 10,
          color: const Color(0xFF5abba0),
        ),
      ),
    );
  }

  Widget _buildDevBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3a1a5a),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8a4aaa), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 10, color: Color(0xFFc87aee)),
          const SizedBox(width: 4),
          Text(
            'Developer',
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFFc87aee),
            ),
          ),
          if (DevPrefs.roleOverride != null && DevPrefs.roleOverride != widget.role) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF5a2a2a),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SIM ${DevPrefs.roleOverride!.toUpperCase()}',
                style: const TextStyle(fontSize: 7, color: Color(0xFFd87a5a)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        children: [
          _buildInfoRow('Email', _email),
          const SizedBox(height: 12),
          _buildInfoRow('Department', _department.isEmpty ? '—' : _department),
          if (DevPrefs.roleOverride != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Original Role', widget.role),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: _textMuted)),
        Text(value, style: TextStyle(fontSize: 11, color: _textPrimary)),
      ],
    );
  }

  Widget _buildThemeSection() {
    final appState = context.findAncestorStateOfType<LiminalAppState>();
    final isDark = appState != null ? appState.isDarkMode : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Appearance'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => appState?.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      size: 16,
                      color: isDark ? const Color(0xFF8888dd) : const Color(0xFFc49040),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isDark ? 'Dark mode' : 'Light mode',
                      style: TextStyle(fontSize: 11, color: _textPrimary),
                    ),
                  ],
                ),
                Container(
                  width: 36, height: 20,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3a3a7a) : const Color(0xFFc49040),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Row(
                    mainAxisAlignment: isDark ? MainAxisAlignment.start : MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFe8e8f4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplaySection() {
    final appState = context.findAncestorStateOfType<LiminalAppState>();
    final factor = appState?.textScaleFactor ?? 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Display'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.text_fields, size: 14, color: _textMuted),
                  const SizedBox(width: 8),
                  Text('Text size', style: TextStyle(fontSize: 11, color: _textPrimary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('A', style: TextStyle(fontSize: 10, color: _textDim)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _accent,
                        inactiveTrackColor: _border,
                        thumbColor: _accent,
                        overlayColor: _accent.withValues(alpha: 0.12),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: factor,
                        min: 0.8,
                        max: 1.5,
                        divisions: 14,
                        onChanged: (v) => appState?.setTextScaleFactor(v),
                      ),
                    ),
                  ),
                  Text('A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDim)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${factor.toStringAsFixed(2)}×',
                style: TextStyle(fontSize: 9, color: _textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Broadcast settings'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Text(
            'Broadcast preferences coming in a later iteration.',
            style: TextStyle(fontSize: 11, color: _textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Subscriptions'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Text(
            'Subscription preferences coming in a later iteration.',
            style: TextStyle(fontSize: 11, color: _textMuted),
          ),
        ),
      ],
    );
  }

  // ─────────── DEV OPTIONS ───────────

  Widget _buildDevSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Dev Options'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3a2a5a), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoleSimulator(),
              const SizedBox(height: 16),
              _buildDevToggles(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildDevLog(),
              const SizedBox(height: 16),
              _buildFirestoreButton(),
              const SizedBox(height: 16),
              _buildDevInfo(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSimulator() {
    final current = _effectiveRole;
    final roles = ['student', 'rep', 'developer'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.swap_horiz, size: 13, color: Color(0xFF7b7bcc)),
            const SizedBox(width: 6),
            Text('Role Simulator', style: TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: roles.map((r) {
            final isActive = current == r;
            final colors = isActive
                ? r == 'developer'
                    ? const [Color(0xFF4a2a7a), Color(0xFF8a4aaa)]
                    : r == 'rep'
                        ? [const Color(0xFF2a2a5a), const Color(0xFF8888dd)]
                        : [const Color(0xFF1a3a28), const Color(0xFF5abba0)]
                : <Color>[const Color(0xFF1a1a2e), const Color(0xFF4a4a6a)];

            return Expanded(
              child: GestureDetector(
                onTap: () async {
                  final newOverride = isActive ? null : r;
                  await DevPrefs.setRoleOverride(newOverride);
                  DevLog.log('Role sim: ${newOverride ?? "reset"}');
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: colors[0],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors[1],
                      width: isActive ? 0.8 : 0.3,
                    ),
                  ),
                  child: Text(
                    r == 'developer' ? 'Dev' : r[0].toUpperCase() + r.substring(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors[1],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDevToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.toggle_on, size: 13, color: Color(0xFF7b7bcc)),
            const SizedBox(width: 6),
            Text('Toggles', style: TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3)),
          ],
        ),
        const SizedBox(height: 8),
        _buildToggleRow(
          'Bypass audience filter',
          'See all broadcasts regardless of department',
          DevPrefs.bypassAudience,
          (v) async {
            await DevPrefs.setBypassAudience(v);
            DevLog.log(v ? 'Bypass audience ON' : 'Bypass audience OFF');
            setState(() {});
          },
        ),
        const SizedBox(height: 6),
        _buildToggleRow(
          'Show raw Firestore IDs',
          'Display doc IDs in feed cards',
          DevPrefs.showRawIds,
          (v) async {
            await DevPrefs.setShowRawIds(v);
            DevLog.log(v ? 'Show raw IDs ON' : 'Show raw IDs OFF');
            setState(() {});
          },
        ),
        const SizedBox(height: 6),
        _buildToggleRow(
          'Debug paint grid',
          'Show Material grid overlay',
          DevPrefs.debugPaint,
          (v) {
            final appState = context.findAncestorStateOfType<LiminalAppState>();
            appState?.toggleDebugPaint();
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, String desc, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: _textPrimary)),
                  const SizedBox(height: 1),
                  Text(desc, style: TextStyle(fontSize: 9, color: _textDim)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36, height: 20,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF4a2a7a) : const Color(0xFF2d2d4a),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                mainAxisAlignment: value ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? const Color(0xFFc87aee) : const Color(0xFF6b6b9a),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, size: 13, color: Color(0xFF7b7bcc)),
            const SizedBox(width: 6),
            Text('Quick Actions', style: TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildActionChip(Icons.download, 'Seed Tasks', () async {
              final count = await DataSeeder.seedTasks();
              DevLog.log('Seeded $count tasks');
              _showToast('$count test tasks added');
            }),
            _buildActionChip(Icons.add_alert, 'Test Broadcast', () async {
              final ok = await DataSeeder.seedBroadcast();
              if (ok) DevLog.log('Test broadcast sent');
              _showToast(ok ? 'Test broadcast sent!' : 'Not logged in');
            }),
            _buildActionChip(Icons.delete_sweep, 'Clear Tasks', () => _confirmClearTasks()),
            _buildActionChip(Icons.terminal, 'Command Palette', () {
              showDialog(
                context: context,
                builder: (_) => CommandPalette(realRole: widget.role),
              );
            }),
            _buildActionChip(Icons.refresh, 'Reload Profile', () async {
              setState(() => _isLoading = true);
              await _loadProfile();
              _showToast('Profile reloaded');
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a4a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3a3a5a), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF7b7bcc)),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFc8c8e0))),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Clear tasks?', style: TextStyle(fontSize: 14, color: Color(0xFFe8e8f4))),
        content: const Text('This will delete all your local tasks. This cannot be undone.', style: TextStyle(fontSize: 11, color: Color(0xFF6b6b9a))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6b6b9a)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear', style: TextStyle(color: Color(0xFFd87a5a)))),
        ],
      ),
    );

    if (confirmed == true) {
      await DataSeeder.clearTasks();
      DevLog.log('Cleared all tasks');
      _showToast('Tasks cleared');
    }
  }

  Widget _buildDevLog() {
    final entries = DevLog.entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 13, color: Color(0xFF7b7bcc)),
            const SizedBox(width: 6),
            Text('Activity Log', style: TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3)),
            const Spacer(),
            if (entries.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  await DevLog.clear();
                  setState(() {});
                  _showToast('Log cleared');
                },
                child: const Text('clear', style: TextStyle(fontSize: 9, color: Color(0xFF6b6b9a))),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (entries.isEmpty)
          Text('No activity yet.', style: TextStyle(fontSize: 10, color: _textDim))
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16162a),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView(
              shrinkWrap: true,
              children: entries.take(15).map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.timeFormatted, style: const TextStyle(fontSize: 8, color: Color(0xFF4a4a6a), fontFamily: 'monospace')),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${e.action}${e.detail != null ? ' — ${e.detail}' : ''}',
                          style: const TextStyle(fontSize: 9, color: Color(0xFF8a8aba), fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFirestoreButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.storage, size: 13, color: Color(0xFF7b7bcc)),
            const SizedBox(width: 6),
            Text('Firestore Explorer', style: TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const FirestoreExplorer(),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a4a),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3a3a5a), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.open_in_new, size: 13, color: Color(0xFF7b7bcc)),
                const SizedBox(width: 6),
                Text('Browse Firestore collections', style: TextStyle(fontSize: 10, color: const Color(0xFFc8c8e0))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevInfo() {
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, size: 13, color: Color(0xFF7b7bcc)),
            const SizedBox(width: 6),
            Text('Dev Info', style: TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF16162a),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _devInfoRow('UID', user?.uid.substring(0, 20) ?? '—'),
              _devInfoRow('Email', _email),
              _devInfoRow('Real role', widget.role),
              _devInfoRow('Effective role', _effectiveRole),
              _devInfoRow('Theme mode', context.findAncestorStateOfType<LiminalAppState>()?.isDarkMode == true ? 'Dark' : 'Light'),
              _devInfoRow('Debug paint', DevPrefs.debugPaint ? 'ON' : 'OFF'),
              _devInfoRow('Bypass audience', DevPrefs.bypassAudience ? 'ON' : 'OFF'),
              _devInfoRow('Show raw IDs', DevPrefs.showRawIds ? 'ON' : 'OFF'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _devInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6b6b9a), fontFamily: 'monospace')),
          Text(value, style: const TextStyle(fontSize: 9, color: Color(0xFFa0a0c0), fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        color: _textDim,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8a3a3a), width: 0.5),
        ),
        child: Text(
          'Log out',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFFd87a5a),
          ),
        ),
      ),
    );
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: const Color(0xFF2a2a5a),
      textColor: const Color(0xFFe8e8f4),
      toastLength: Toast.LENGTH_LONG,
    );
  }
}
