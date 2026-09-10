import 'package:flutter/services.dart';

/// Central haptics helper — every surface triggers feedback through here so
/// the app has one consistent "touch signature".
///
/// All calls are safe no-ops on platforms without haptic hardware
/// (e.g. Quest 2 running the Android build with a controller).
class Haptics {
  Haptics._();

  /// Generic tap: buttons, cards, list rows.
  static void tap() => HapticFeedback.lightImpact();

  /// Selection change: tab switches, chip picks, wheel ticks.
  static void select() => HapticFeedback.selectionClick();

  /// Success / completion: task done, submitted, confirmed.
  static void success() => HapticFeedback.mediumImpact();

  /// Warning / destructive: errors, delete confirmations.
  static void warning() => HapticFeedback.heavyImpact();
}
