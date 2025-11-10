import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'palnt_notifiaction_banner.dart'; // 기존 배너 위젯

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // 백그라운드에서 알림을 탭했을 때 호출됨 (Android)
  debugPrint('Background notification tapped (bg isolate): ${response.payload}');
}

const AndroidNotificationChannel _plantNotificationChannel = AndroidNotificationChannel(
  'plant_watering_channel',
  '반려식물 물주기 알림',
  description: '반려식물 물주기 및 환경 알림을 위한 채널',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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
    print('>>> PushNotificationService.init start');
    _navigatorKey = navigatorKey;

    await _ensureFirebaseInitialized();
    print('>>> Firebase ensured');

    await _requestPermission();
    print('>>> Notification permission requested');

    await _configureLocalNotifications();
    print('>>> Local notifications configured');

    // Foreground 메시지는 service 내부의 handleForegroundMessage로 위임
    FirebaseMessaging.onMessage.listen((message) {
      print('>>> PushNotificationService.onMessage received: ${message.notification?.title} / ${message.data}');
      try {
        handleForegroundMessage(message);
      } catch (e, st) {
        print('>>> Error in handleForegroundMessage: $e');
        print(st);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('>>> PushNotificationService.onMessageOpenedApp: ${message.data}');
      try {
        _handleMessageOpenedApp(message);
      } catch (e, st) {
        print('>>> Error in onMessageOpenedApp handler: $e');
        print(st);
      }
    });

    print('>>> PushNotificationService.init finished, listeners registered');

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('>>> PushNotificationService: initialMessage present: ${initialMessage.data}');
      await _showSystemNotification(initialMessage);
      _navigateByMessage(initialMessage);
    }
  }

  // 공개된 핸들러: 외부에서 메시지를 위임할 때도 사용하도록 함
  void handleForegroundMessage(RemoteMessage message) {
    print('>>> handleForegroundMessage called');
    _showSystemNotification(message);
    _showBanner(message);
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
  }

  Future<void> _configureLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    // onDidReceiveNotificationResponse: 포그라운드/사용자 탭 처리
    // onDidReceiveBackgroundNotificationResponse: 반드시 top-level 함수 사용
    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // 앱이 포그라운드이거나 사용자가 알림 탭으로 앱을 연 경우 처리
        _handleNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_plantNotificationChannel);
  }

  Future<void> _showSystemNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? '반려식물 알림';
    final body = notification?.body ?? message.data['body'] ?? '반려식물에게 물을 주세요!';
    final payload = message.data.isEmpty ? null : jsonEncode(message.data);
    print('알림 호출!');

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
    print('overlayState: $overlayState, navigatorKey: ${_navigatorKey}');
    if (overlayState == null) return;
    print('배너 호출! overlayState: $overlayState');
    print('배너 호출!');

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

  void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateByMessage(message);
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
