import 'package:flutter/material.dart';
import '../main.dart';
import '../services/reminder_prefs.dart';
import '../services/notification_service.dart';
import '../widgets/haptics.dart';
import '../widgets/pressable.dart';
import '../widgets/reminder_slider.dart';

/// Settings — Appearance, Display and Notifications, pulled out of Profile.
///
/// Opened from the gear icon on Home and Profile. Keeps Profile focused on
/// identity + role while app-wide preferences live here.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _border => Theme.of(context).dividerColor;
  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textMuted => Theme.of(context).colorScheme.onSurfaceVariant;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: _border, width: 0.5)),
        title: const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThemeSection(),
              const SizedBox(height: 24),
              _buildDisplaySection(),
              const SizedBox(height: 24),
              _buildNotificationSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: _textMuted,
          letterSpacing: 0.5,
        ),
      );

  Widget _buildThemeSection() {
    final appState = context.findAncestorStateOfType<LiminalAppState>();
    final isDark = appState != null ? appState.isDarkMode : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Appearance'),
        const SizedBox(height: 8),
        AppPressable(
          haptic: false,
          onTap: () {
            Haptics.select();
            appState?.toggleTheme();
          },
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
                // BUG FIX: was a hand-drawn fake switch (two containers in a
                // Row) — a real adaptive switch animates on its own and reads
                // as native on both platforms (CupertinoSwitch on iOS)
                Switch.adaptive(
                  value: isDark,
                  activeThumbColor: const Color(0xFF8888dd),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) {
                    Haptics.select();
                    appState?.toggleTheme();
                  },
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
                  Text('A', style: TextStyle(fontSize: 10, color: _textMuted)),
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
                        onChanged: (v) {
                          Haptics.select();
                          appState?.setTextScaleFactor(v);
                        },
                      ),
                    ),
                  ),
                  Text('A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textMuted)),
                ],
              ),
              const SizedBox(height: 4),
              Text('${factor.toStringAsFixed(2)}×', style: TextStyle(fontSize: 9, color: _textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Notifications'),
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
                  const Icon(Icons.notifications_outlined, size: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reminders', style: TextStyle(fontSize: 11, color: _textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          'Get notified before tasks are due',
                          style: TextStyle(fontSize: 9, color: _textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: ReminderPrefs.enabled,
                    activeColor: _accent,
                    onChanged: (value) {
                      ReminderPrefs.setEnabled(value);
                      if (value) NotificationService.requestPermissions();
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ReminderSlider(
                minutes: ReminderPrefs.preReminderMinutes,
                accent: _accent,
                border: _border,
                textMuted: _textMuted,
                onChanged: (minutes) {
                  ReminderPrefs.setPreReminderMinutes(minutes);
                  setState(() {});
                },
              ),
              const SizedBox(height: 6),
              Text(
                ReminderPrefs.enabled
                    ? 'Applied to all new tasks. Override per task in the Add sheet.'
                    : 'Master reminders off — nothing will be scheduled.',
                style: TextStyle(fontSize: 9, color: _textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}