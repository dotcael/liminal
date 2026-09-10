import 'package:flutter/material.dart';

import 'haptics.dart';

/// Tappable wrapper that responds like a native control: scales down slightly
/// and dims while the finger is down, with an optional haptic tick.
///
/// Drop-in replacement for bare GestureDetectors so every interactive element
/// acknowledges the touch. Platform-neutral by design — the press acknowledgment
/// matters even more with a Quest 2 controller ray than with a fingertip.
class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Fire a light haptic when tapped. Disable for controls that fire their
  /// own haptic signature (sliders, switches).
  final bool haptic;

  /// Scale while pressed. 1.0 disables the scale and keeps only the dim.
  final double pressedScale;

  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = true,
    this.pressedScale = 0.97,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) Haptics.tap();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.8 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}
