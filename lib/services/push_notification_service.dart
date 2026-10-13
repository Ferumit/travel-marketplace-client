import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../navigation/app_router.dart';
import '../repository/firestore_data_repository.dart';
import 'auth_service.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Called in main() BEFORE runApp(). Only does minimal sync work so that
  /// runApp() is never blocked.
  Future<void> init() async {
    // Configure local notifications — fast, no network
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await _localNotifications.initialize(settings: initSettings);

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Schedule all heavy FCM work to run AFTER runApp() — never blocks startup
    Future.microtask(_setupFCMInBackground);
  }

  /// All heavy Firebase / network / permission work runs here, in the background,
  /// after the UI is already painting.
  Future<void> _setupFCMInBackground() async {
    try {
      // 1. Create Android high-importance channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'high_importance_channel',
            'Высокая важность',
            description: 'Этот канал используется для важных уведомлений.',
            importance: Importance.max,
          ));

      // 2. Request notification permission
      final NotificationSettings settings = await _fcm
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 5));
      debugPrint('Notification permission: ${settings.authorizationStatus}');

      // 3. On Apple platforms, wait for APNS token before asking for FCM token
      bool apnsReady = true;
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final String? apns = await _fcm
            .getAPNSToken()
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
        if (apns == null) {
          debugPrint(
              'APNS token not available (simulator or missing entitlement) — skipping FCM token.');
          apnsReady = false;
        } else {
          debugPrint('APNS Token: $apns');
        }
      }

      // 4. Get FCM token
      if (apnsReady) {
        try {
          final String? token =
              await _fcm.getToken().timeout(const Duration(seconds: 5));
          debugPrint('FCM Token: $token');
          if (token != null) _saveTokenToFirestore(token);
        } catch (e, stack) {
          debugPrint('Error getting FCM token: $e');
          FirebaseCrashlytics.instance.recordError(e, stack, reason: 'PushNotificationService.getToken', fatal: false);
        }
      }

      // 5. Listen for token refresh
      _fcm.onTokenRefresh.listen((String token) {
        debugPrint('FCM Token refreshed: $token');
        _saveTokenToFirestore(token);
      });

      // 6. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground FCM message: ${message.data}');
        final android = message.notification?.android;
        if (android != null) {
          _localNotifications.show(
            id: message.notification.hashCode,
            title: message.notification!.title,
            body: message.notification!.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'Высокая важность',
                channelDescription:
                    'Этот канал используется для важных уведомлений.',
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      // 7. App opened via notification tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // 8. Initial message when app was fully terminated
      try {
        final RemoteMessage? initial = await _fcm
            .getInitialMessage()
            .timeout(const Duration(seconds: 3));
        if (initial != null) _handleNotificationClick(initial);
      } catch (_) {
        // Timeout on simulator — safe to ignore
      }

      debugPrint('[PushNotificationService] FCM setup complete');
    } catch (e, stack) {
      debugPrint('[PushNotificationService] Background FCM setup error: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'PushNotificationService._setupFCMInBackground', fatal: false);
    }
  }

  void _saveTokenToFirestore(String token) {
    final user = AuthService.instance.currentFirebaseUser;
    if (user != null) {
      FirestoreDataRepository.instance.saveFcmToken(user.uid, token);
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Notification clicked: ${message.data}');
    final type = message.data['type'];
    final tripId = message.data['tripId'];
    if (tripId != null) {
      if (type == 'chat') {
        appRouter.push('/messenger', extra: {'tripId': tripId});
      } else if (type == 'trip_status') {
        appRouter.push('/active/$tripId');
      } else {
        appRouter.push('/active_trips');
      }
    }
  }
}
