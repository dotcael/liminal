import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> scheduleTaskDueNotification({
    required String taskId,
    required String taskName,
    required DateTime dueDate,
  }) async {
    final id = taskId.hashCode;

    final now = DateTime.now();
    if (dueDate.isBefore(now)) return;

    final location = tz.local;
    final scheduledDate = tz.TZDateTime.from(dueDate, location);

    await _plugin.zonedSchedule(
      id,
      'Task due: $taskName',
      '"$taskName" is due now!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_due',
          'Task Due',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> cancelNotification(String taskId) async {
    await _plugin.cancel(taskId.hashCode);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
