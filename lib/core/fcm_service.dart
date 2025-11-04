import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

Future<void> registerFcmToken(String userId, String accessToken) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 디바이스 FCM 토큰 가져오기
  String? fcmToken = await messaging.getToken();
  if (fcmToken == null) {
    print("FCM 토큰 가져오기 실패");
    return;
  }

  print("FCM 토큰: $fcmToken");

  // 백엔드로 전송
  final response = await http.post(
    Uri.parse('http://10.0.2.2:8080/api/user/fcm-token'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: '{"userId": "$userId", "fcmToken": "$fcmToken"}',
  );

  if (response.statusCode == 200) {
    print("FCM 토큰 등록 성공");
  } else {
    print("FCM 토큰 등록 실패: ${response.statusCode}");
  }
}