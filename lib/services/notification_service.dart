import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'task_reminders';
  static const _channelName = 'Task reminders';
  static const _channelDescription = 'Reminders for your tasks';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static tz.TZDateTime _tzFrom(DateTime dt) =>
      tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, dt.millisecondsSinceEpoch);

  static int _idFor(String taskId, {required bool isPre}) {
    final base = taskId.hashCode & 0x3fffffff;
    return isPre ? base * 2 : base * 2 + 1;
  }

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    final ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
    return true;
  }

  static Future<void> scheduleTaskReminders({
    required String taskId,
    required String taskName,
    required DateTime dueDate,
    int? preReminderMinutes,
  }) async {
    final now = DateTime.now();
    if (!dueDate.isAfter(now)) return;

    await cancelTaskReminders(taskId);

    if (preReminderMinutes != null &&
        preReminderMinutes > 0 &&
        dueDate.difference(now).inMinutes > preReminderMinutes) {
      final preDate = dueDate.subtract(Duration(minutes: preReminderMinutes));
      await _plugin.zonedSchedule(
        _idFor(taskId, isPre: true),
        'Upcoming: $taskName',
        '"$taskName" is due in $preReminderMinutes minute(s)',
        _tzFrom(preDate),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    await _plugin.zonedSchedule(
      _idFor(taskId, isPre: false),
      'Task due: $taskName',
      '"$taskName" is due now!',
      _tzFrom(dueDate),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelTaskReminders(String taskId) async {
    await _plugin.cancel(_idFor(taskId, isPre: true));
    await _plugin.cancel(_idFor(taskId, isPre: false));
  }

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _details);
  }

  static Future<void> reRequestPermissions() => requestPermissions();
}
