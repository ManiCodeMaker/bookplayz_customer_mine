import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {}

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _fcm.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    if (kDebugMode) {
      _fcm.getToken().then((t) {
        debugPrint('══════════ FCM TOKEN (copy below) ══════════');
        debugPrint('$t');
        debugPrint('═════════════════════════════════════════════');
      }).catchError((Object e) {
        debugPrint('[FCM] getToken FAILED: $e');
      });
    }

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    // FCM can rotate the token at any time — keep the backend's copy fresh
    // so pushes don't silently stop until the next login.
    _fcm.onTokenRefresh.listen((token) {
      if (SessionManager.instance.isLoggedIn) {
        PushDevicesApi.registerDevice(token);
      }
    });

    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _local.show(
        id: n.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  Future<String?> getToken() => _fcm.getToken();

  /// Re-registers the current token after a session restore, covering tokens
  /// that rotated while the app was closed (onTokenRefresh won't re-fire).
  Future<void> syncTokenIfLoggedIn() async {
    if (!SessionManager.instance.isLoggedIn) return;
    final token = await getToken();
    if (token != null) await PushDevicesApi.registerDevice(token);
  }
}
