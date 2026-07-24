// BUG FIX: light theme now uses literal inverses of the dark palette —
// dark navy bg (#1a1a2e) → light lavender (#e8e8f4),
// dark surface (#22223a) → light surface (#d0d0e8),
// light text (#e8e8f4) → dark navy text (#1a1a2e),
// accent indigo (#4a4aaa) stays the same so both themes feel like liminal
import 'package:flutter/material.dart';

class AppTheme {
  // dark theme is the original liminal palette — untouched
  static ThemeData get dark => ThemeData(
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
      );

  // light theme — every color is the literal opposite/light alt of dark
  static ThemeData get light => ThemeData(
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
      );
}
