import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<String?> initialize({
    required void Function(RemoteMessage message) onMessage,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Push notification Firebase saat ini dikonfigurasi untuk Android.',
      );
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw StateError('Izin notifikasi ditolak di perangkat.');
    }

    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(onMessage);
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      onMessage,
    );

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) onMessage(initialMessage);

    // Firebase Console's test sender still targets an FCM registration token.
    // ignore: deprecated_member_use
    return messaging.getToken();
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _foregroundSubscription = null;
    _openedSubscription = null;
  }
}
