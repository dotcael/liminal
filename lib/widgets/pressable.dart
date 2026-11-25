import 'package:flutter/material.dart';

import 'haptics.dart';

class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  final bool haptic;

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
