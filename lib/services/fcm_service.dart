import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Top-level handler required by FCM for background/terminated messages while
/// the isolate is alive. We can't touch Flutter UI here, but OS-delivered
/// push banners (notification payloads) are shown automatically — the function
/// just needs to exist and return quickly.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {}

/// Owns all Firebase Messaging wiring: permission, token storage in
/// Firestore, and routing foreground pushes into the local-notifications
/// system so they render even while the app is open.
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// App sets this so a tapped push can navigate (e.g. to the feed).
  static ValueChanged<RemoteMessage>? onNotificationTap;

  static Future<void> configureListeners() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

    // tapped from the notification center while app was alive
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

    // tapped while the app was terminated — route after cold start
    final initial = await _messaging.getInitialMessage();
    if (initial != null) onNotificationTap?.call(initial);
  }

  /// Persists the current FCM token on the user's Firestore doc so the
  /// broadcast Cloud Function can target their device. Also keeps the token
  /// up to date on every refresh.
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

  /// Removes the stored token when a user signs out.
  static Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'fcmToken': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }
}