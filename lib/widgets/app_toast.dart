import 'dart:async';

import 'package:flutter/material.dart';

import 'haptics.dart';

/// Floating pill toast — the app's single unified transient message.
///
/// Replaces Fluttertoast (an Android-only visual) with a platform-neutral
/// pill that animates up from the bottom, matches the app's design language
/// on iOS and Android/Quest, and can't be missed behind the nav bar.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static _ToastViewState? _state;
  static Timer? _timer;

  static void show(BuildContext context, String message, {bool isError = false}) {
    isError ? Haptics.warning() : Haptics.tap();

    _timer?.cancel();
    _state?.dismiss();
    _removeEntry();

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        isError: isError,
        background: isError
            ? const Color(0xFF5a2418)
            : dark
                ? const Color(0xFF2e2e56)
                : const Color(0xFF1a1a2e),
        foreground: isError
            ? const Color(0xFFffd9cc)
            : dark
                ? const Color(0xFFe8e8f4)
                : const Color(0xFFe8e8f4),
        onState: (state) => _state = state,
      ),
    );

    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);

    _timer = Timer(Duration(milliseconds: isError ? 2800 : 2000), () {
      _state?.dismiss();
    });
  }

  static void _removeEntry() {
    _entry?.remove();
    _entry = null;
    _state = null;
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final bool isError;
  final Color background;
  final Color foreground;
  final ValueChanged<_ToastViewState> onState;

  const _ToastView({
    required this.message,
    required this.isError,
    required this.background,
    required this.foreground,
    required this.onState,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> {
  bool _visible = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.onState(this);
    // enter on the next frame so the transition actually animates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void dismiss() {
    if (!mounted || _leaving) return;
    setState(() => _leaving = true);
    Future.delayed(const Duration(milliseconds: 250), AppToast._removeEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 88,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSlide(
            offset: _visible && !_leaving ? Offset.zero : const Offset(0, 0.4),
            duration: const Duration(milliseconds: 250),
            curve: _visible && !_leaving ? Curves.easeOutCubic : Curves.easeIn,
            child: AnimatedOpacity(
              opacity: _visible && !_leaving ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isError
                        ? const Color(0xFF8a3a3a)
                        : const Color(0xFF4a4a6a),
                    width: 0.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isError) ...[
                      const Icon(Icons.error_outline, size: 13, color: Color(0xFFd87a5a)),
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: widget.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
