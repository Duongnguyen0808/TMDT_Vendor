import 'dart:convert';

import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin vendorLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _vendorAndroidChannel =
    AndroidNotificationChannel(
  'vendor_high_importance',
  'Thông báo cửa hàng',
  description: 'Cảnh báo đơn mới, shipper nhận đơn và cập nhật quan trọng.',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> vendorFirebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final GetStorage _box = GetStorage();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _configureLocalNotifications();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermissions();
    await _cacheInitialToken();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    _messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
    });

    _box.listenKey('accessToken', (_) {
      syncTokenWithBackend();
    });
  }

  static Future<void> _configureLocalNotifications() async {
    if (!kIsWeb) {
      await vendorLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_vendorAndroidChannel);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await vendorLocalNotificationsPlugin.initialize(initSettings);
  }

  static Future<void> _requestPermissions() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  static Future<void> _cacheInitialToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _persistToken(token);
      }
    } catch (_) {}
  }

  static Future<void> _persistToken(String token) async {
    final current = _box.read('fcmToken');
    if (current != token) {
      await _box.write('fcmToken', token);
    }
    await syncTokenWithBackend();
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Thông báo';
    final body = notification?.body ?? message.data['body'] ?? '';

    if (!kIsWeb) {
      final androidDetails = AndroidNotificationDetails(
        _vendorAndroidChannel.id,
        _vendorAndroidChannel.name,
        channelDescription: _vendorAndroidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: notification?.android?.smallIcon ?? '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails();
      final details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);
      await vendorLocalNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );
    }
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    // Có thể điều hướng tới màn hình quản lý đơn nếu cần.
  }

  static Future<void> syncTokenWithBackend() async {
    final authToken = _box.read('accessToken');
    final fcmToken = _box.read('fcmToken');
    if (authToken is! String || authToken.isEmpty) return;
    if (fcmToken is! String || fcmToken.isEmpty) return;

    final projectId = Firebase.apps.isNotEmpty
        ? Firebase.app().options.projectId ??
            DefaultFirebaseOptions.currentPlatform.projectId
        : DefaultFirebaseOptions.currentPlatform.projectId;

    final payload = jsonEncode({
      'fcmToken': fcmToken,
      'projectId': projectId,
    });

    try {
      await http.post(
        Uri.parse('$appBaseUrl/api/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: payload,
      );
      await _box.write('vendorFcmSyncedAt', DateTime.now().toIso8601String());
    } catch (_) {}
  }
}
