import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static ValueChanged<RemoteMessage>? onNotificationTap;

  static Future<void> configureListeners() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message);
    });

    // foreground message — render through local notifications
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      final stableId =
          (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch)
              .toUnsigned(31);
      NotificationService.showNow(
        id: stableId,
        title: n.title ?? 'Liminal',
        body: n.body ?? '',
      );
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) onNotificationTap?.call(initial);
  }

  static Future<void> ensureToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Future<void> persist(String token) async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }

    final token = await _messaging.getToken();
    if (token != null) await persist(token);

    _messaging.onTokenRefresh.listen(persist);
  }

  static Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'fcmToken': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }
}
