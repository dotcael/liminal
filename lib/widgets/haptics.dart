import 'package:flutter/services.dart';

class Haptics {
  Haptics._();

  static void tap() => HapticFeedback.lightImpact();

  static void select() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.mediumImpact();

  static void warning() => HapticFeedback.heavyImpact();
}
