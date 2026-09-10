import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'haptics.dart';

/// Adaptive due-date (+time) picker — the app's one entry point for picking
/// a date anywhere.
///
/// iOS: a single bottom sheet with a combined Cupertino wheel picker —
/// one popup instead of two chained full-screen Material dialogs.
/// Android (incl. Quest 2): the native Material flow — themed M3 date picker,
/// then themed M3 time picker, both styled by the app theme.
///
/// Returns the picked DateTime, or null if cancelled.
Future<DateTime?> showAdaptiveDateTimePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  bool dateOnly = false,
  String title = 'Due date',
}) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return _showIosSheet(
      context,
      initial: initial,
      first: first,
      dateOnly: dateOnly,
      title: title,
    );
  }
  return _pickMaterial(
    context,
    initial: initial,
    first: first,
    dateOnly: dateOnly,
  );
}

// ── iOS: combined wheel sheet ─────────────────────────────────────────────────

Future<DateTime?> _showIosSheet(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required bool dateOnly,
  required String title,
}) {
  var picked = initial;

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final surface = theme.colorScheme.surfaceContainerHighest;
      final border = theme.dividerColor;
      final accent = theme.colorScheme.primary;
      final text = theme.colorScheme.onSurface;
      final muted = theme.colorScheme.onSurfaceVariant;

      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    CupertinoButton(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      onPressed: () {
                        Haptics.tap();
                        Navigator.of(sheetContext).pop(null);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          color: muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      onPressed: () {
                        Haptics.success();
                        Navigator.of(sheetContext).pop(picked);
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: dateOnly ? 160 : 200,
                child: CupertinoDatePicker(
                  mode: dateOnly
                      ? CupertinoDatePickerMode.date
                      : CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: false,
                  initialDateTime: initial,
                  minimumDate: first,
                  maximumDate: DateTime(first.year + 5),
                  onDateTimeChanged: (value) {
                    picked = value;
                    Haptics.select();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

// ── Android / Quest: themed Material flow ─────────────────────────────────────

Future<DateTime?> _pickMaterial(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required bool dateOnly,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: DateTime(first.year + 5),
  );
  if (date == null || !context.mounted) return null;

  if (dateOnly) {
    Haptics.success();
    return DateTime(date.year, date.month, date.day);
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );

  return DateTime(
    date.year,
    date.month,
    date.day,
    time?.hour ?? 23,
    time?.minute ?? 59,
  );
}
