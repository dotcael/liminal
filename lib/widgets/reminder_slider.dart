import 'package:flutter/material.dart';

import 'haptics.dart';

/// Compact pre-reminder timing slider (0–120 min, 5-min steps).
///
/// Dragging the thumb picks any minute offset; 0 renders as "Off". Used for
/// both the default (Settings > Notifications) and per-task override (Add
/// sheet) so the timing control stays consistent and minimal.
class ReminderSlider extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  final Color? accent;
  final Color? border;
  final Color? textMuted;

  const ReminderSlider({
    super.key,
    required this.minutes,
    required this.onChanged,
    this.accent,
    this.border,
    this.textMuted,
  });

  String get _label {
    if (minutes <= 0) return 'Off';
    if (minutes == 1) return '1 min before';
    if (minutes >= 60) {
      final h = minutes / 60;
      final whole = h.round();
      return h == whole ? '$whole hr before' : '${(minutes / 60).toStringAsFixed(1)} hr before';
    }
    return '$minutes min before';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final accent = this.accent ?? scheme.primary;
    final border = this.border ?? scheme.outlineVariant;
    final textMuted = this.textMuted ?? scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Remind me', style: TextStyle(fontSize: 10, color: textMuted)),
              const Spacer(),
              Text(
                _label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: minutes <= 0 ? textMuted : accent,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: border,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            ),
            child: Slider(
              value: minutes.toDouble().clamp(0, 120),
              min: 0,
              max: 120,
              divisions: 24,
              label: _label,
              onChanged: (v) {
                // one tick per detent — mirrors the native picker wheel feel
                Haptics.select();
                onChanged(v.round());
              },
            ),
          ),
        ],
      ),
    );
  }
}