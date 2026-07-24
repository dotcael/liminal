import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DevLog {
  static final List<_LogEntry> _entries = [];
  static bool _loaded = false;

  static List<_LogEntry> get entries => List.unmodifiable(_entries);

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('dev_activity_log');
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _entries.addAll(list.map((e) => _LogEntry.fromJson(e as Map<String, dynamic>)));
    }
    _loaded = true;
  }

  static Future<void> log(String action, {String? detail}) async {
    final entry = _LogEntry(
      action: action,
      detail: detail,
      timestamp: DateTime.now(),
    );
    _entries.insert(0, entry);

    final prefs = await SharedPreferences.getInstance();
    final keep = _entries.take(50).toList();
    await prefs.setString('dev_activity_log', jsonEncode(keep.map((e) => e.toJson()).toList()));
  }

  static Future<void> clear() async {
    _entries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dev_activity_log');
  }
}

class _LogEntry {
  final String action;
  final String? detail;
  final DateTime timestamp;

  const _LogEntry({
    required this.action,
    this.detail,
    required this.timestamp,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Map<String, dynamic> toJson() => {
    'action': action,
    'detail': detail,
    'timestamp': timestamp.toIso8601String(),
  };

  factory _LogEntry.fromJson(Map<String, dynamic> json) => _LogEntry(
    action: json['action'] as String,
    detail: json['detail'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
