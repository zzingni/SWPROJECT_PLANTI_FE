import 'dart:async';
import 'dart:convert';

import 'package:fe/notification/palnt_notifiaction_banner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';


const AndroidNotificationChannel _plantNotificationChannel = AndroidNotificationChannel(
  'plant_watering_channel',
  '반려식물 물주기 알림',
  description: '반려식물 물주기 및 환경 알림을 위한 채널',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await PushNotificationService.instance._showSystemNotification(message);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  GlobalKey<NavigatorState>? _navigatorKey;
  OverlayEntry? _bannerEntry;
  Timer? _dismissTimer;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    await _ensureFirebaseInitialized();

    await _messaging.setAutoInitEnabled(true);
    await _requestPermission();
    await _configureLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _showSystemNotification(initialMessage);
      _navigateByMessage(initialMessage);
    }
  }

  Future<void> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (error, stackTrace) {
      debugPrint('Firebase 초기화 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('FCM 권한 상태: ${settings.authorizationStatus}');
    } catch (error) {
      debugPrint('알림 권한 요청 실패: $error');
    }
  }

  Future<void> _configureLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    final androidPlugin =
    _localNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_plantNotificationChannel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showSystemNotification(message);
    _showBanner(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateByMessage(message);
  }

  Future<void> _showSystemNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? '반려식물 알림';
    final body = notification?.body ?? message.data['body'] ?? '반려식물에게 물을 주세요!';
    final payload = message.data.isEmpty ? null : jsonEncode(message.data);

    final androidDetails = AndroidNotificationDetails(
      _plantNotificationChannel.id,
      _plantNotificationChannel.name,
      channelDescription: _plantNotificationChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      color: const Color(0xFF4CAF50),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotificationsPlugin.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  void _showBanner(RemoteMessage message) {
    final overlayState = _navigatorKey?.currentState?.overlay;
    if (overlayState == null) return;

    _dismissBanner();

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? '반려식물이 목이 말라요!';
    final body = notification?.body ?? message.data['body'] ?? '지금 물을 주면 더 건강해져요.';
    final dateLabel = DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(DateTime.now());

    _bannerEntry = OverlayEntry(
      builder: (context) => PlantNotificationBanner(
        dateLabel: dateLabel,
        title: title,
        message: body,
        onDismissed: _dismissBanner,
      ),
    );

    overlayState.insert(_bannerEntry!);
    _dismissTimer = Timer(const Duration(seconds: 6), _dismissBanner);
  }

  void _dismissBanner() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _bannerEntry?.remove();
    _bannerEntry = null;
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateByData(data);
    } catch (error) {
      debugPrint('알림 payload 파싱 실패: $error');
    }
  }

  void _navigateByMessage(RemoteMessage message) {
    if (message.data.isEmpty) return;
    _navigateByData(message.data);
  }

  void _navigateByData(Map<String, dynamic> data) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    final target = data['route'] as String?;
    if (target == null) return;

    navigator.pushNamed(target, arguments: data);
  }
}

