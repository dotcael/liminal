// BUG FIX: light theme now uses literal inverses of the dark palette —
// dark navy bg (#1a1a2e) → light lavender (#e8e8f4),
// dark surface (#22223a) → light surface (#d0d0e8),
// light text (#e8e8f4) → dark navy text (#1a1a2e),
// accent indigo (#4a4aaa) stays the same so both themes feel like liminal
import 'package:flutter/material.dart';

class AppTheme {
  // dark theme is the original liminal palette — untouched
  static ThemeData get dark => _chrome(
        base: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1a1a2e),
          dividerColor: const Color(0xFF2d2d4a),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4a4aaa),
            onPrimary: Color(0xFFffffff),
            surface: Color(0xFF22223a),
            onSurface: Color(0xFFe8e8f4),
            surfaceContainerHighest: Color(0xFF22223a),
            onSurfaceVariant: Color(0xFF6b6b9a),
            outline: Color(0xFF4a4a6a),
            secondary: Color(0xFF6b6bcc),
            onSecondary: Color(0xFFffffff),
            error: Colors.red,
            onError: Color(0xFFffffff),
          ),
        ),
      );

  // light theme — every color is the literal opposite/light alt of dark
  static ThemeData get light => _chrome(
        base: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFe8e8f4), // inverse of dark bg
          dividerColor: const Color(0xFFb8b8d4),            // inverse of dark border
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4a4aaa),                     // same accent indigo
            onPrimary: Color(0xFFffffff),
            surface: Color(0xFFd0d0e8),                     // inverse of dark surface
            onSurface: Color(0xFF1a1a2e),                   // inverse of light text
            surfaceContainerHighest: Color(0xFFd0d0e8),
            onSurfaceVariant: Color(0xFF4a4a7a),            // inverse of muted text
            outline: Color(0xFF3a3a5a),                     // inverse of dim text
            secondary: Color(0xFF6b6bcc),
            onSecondary: Color(0xFFffffff),
            error: Colors.red,
            onError: Color(0xFFffffff),
          ),
        ),
      );

  // Shared popup/chrome feel for both themes:
  // - dialogs, date/time pickers, sheets and snackbars all come pre-styled in
  //   the liminal palette so no popup ever falls back to stock Material purple
  // - page transitions: Cupertino (swipe-back-from-edge) on iOS,
  //   zoom-fade on Android — each platform gets its native motion
  static ThemeData _chrome({required ThemeData base}) {
    final scheme = base.colorScheme;
    final surface = scheme.surfaceContainerHighest;
    final border = base.dividerColor;

    return base.copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 11.5,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: false,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        dayStyle: const TextStyle(fontSize: 12),
        yearStyle: const TextStyle(fontSize: 12),
        headerHeadlineStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        headerForegroundColor: scheme.onSurface,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.3);
          }
          return scheme.onSurface;
        }),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        dialBackgroundColor: scheme.surface.withValues(alpha: 0.6),
        hourMinuteColor: scheme.surface.withValues(alpha: 0.6),
        hourMinuteTextColor: scheme.onSurface,
        dialHandColor: scheme.primary,
        dayPeriodColor: scheme.surfaceContainerHighest,
        dayPeriodTextColor: scheme.onSurface,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 0.5),
        ),
        dayPeriodBorderSide: BorderSide(color: border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
