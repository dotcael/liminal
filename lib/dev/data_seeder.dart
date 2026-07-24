import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSeeder {
  static final _random = Random();

  static const _taskNames = [
    'Finish math assignment',
    'Read chapter 5',
    'Prepare presentation slides',
    'Review lecture notes',
    'Complete lab report',
    'Study for quiz',
    'Write essay draft',
    'Solve practice problems',
    'Watch tutorial videos',
    'Update project plan',
  ];

  static const _urgencies = ['Urgent', 'Soon', 'Later'];

  static Future<int> seedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('personal_tasks');
    final existing = raw != null ? (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

    final now = DateTime.now();
    final newTasks = <Map<String, dynamic>>[];

    for (var i = 0; i < 5; i++) {
      final daysFromNow = _random.nextInt(14);
      final due = DateTime(now.year, now.month, now.day).add(Duration(days: daysFromNow));
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      newTasks.add({
        'id': 'seed_${now.millisecondsSinceEpoch}_$i',
        'taskName': _taskNames[_random.nextInt(_taskNames.length)],
        'dueDate': '${dayNames[due.weekday - 1]}, ${months[due.month - 1]} ${due.day}',
        'urgency': _urgencies[_random.nextInt(_urgencies.length)],
        'category': 'Personal',
        'isCompleted': _random.nextDouble() < 0.2,
      });
    }

    final combined = [...newTasks, ...existing];
    await prefs.setString('personal_tasks', jsonEncode(combined));
    return newTasks.length;
  }

  static Future<bool> seedBroadcast() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final titles = ['Exam schedule updated', 'Library hours changed', 'Guest lecture tomorrow', 'Deadline extended', 'New study materials'];
    final bodies = [
      'Please check the updated schedule on the portal.',
      'The library will close at 6pm on weekends effective next week.',
      'Dr. Kagame will be giving a talk on distributed systems at 10am.',
      'The project deadline has been extended to next Friday.',
      'New resources have been uploaded to the shared drive.',
    ];
    final sources = ['Academic Office', 'Library Admin', 'CS Department', 'Registrar', 'Student Council'];
    final audiences = ['Software Engineering', 'Networking', 'Database', 'All dept.'];
    final categories = ['Academic', 'Financial'];

    final idx = _random.nextInt(titles.length);

    await FirebaseFirestore.instance.collection('broadcast').add({
      'title': titles[idx],
      'body': bodies[idx],
      'source': sources[_random.nextInt(sources.length)],
      'dueDate': 'Friday',
      'audience': audiences[_random.nextInt(audiences.length)],
      'category': categories[_random.nextInt(categories.length)],
      'urgency': _urgencies[_random.nextInt(_urgencies.length)],
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  static Future<void> clearTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personal_tasks', jsonEncode([]));
  }
}
