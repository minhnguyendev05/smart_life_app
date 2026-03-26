import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/app_secrets.dart';
import 'firebase_core_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseCoreService.ensureInitialized();
}

class PushNotificationService {
  final StreamController<String> _events = StreamController<String>.broadcast();
  final StreamController<String> _openedRoutes =
      StreamController<String>.broadcast();

  Stream<String> get events => _events.stream;
  Stream<String> get openedRoutes => _openedRoutes.stream;

  Future<void> initialize() async {
    if (!FirebaseCoreService.isReady) {
      return;
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kIsWeb && AppSecrets.fcmWebVapidKey.isNotEmpty) {
      await messaging.getToken(vapidKey: AppSecrets.fcmWebVapidKey);
    }

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _openedRoutes.add(_resolveRoute(initialMessage));
    }

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Thông báo mới';
      final body = message.notification?.body ?? 'Bạn có cập nhật mới.';
      _events.add('$title: $body');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _openedRoutes.add(_resolveRoute(message));
    });
  }

  String _resolveRoute(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route == null || route.trim().isEmpty) {
      return 'notifications';
    }
    return route;
  }
}
