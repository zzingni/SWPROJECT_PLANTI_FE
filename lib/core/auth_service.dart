import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class AuthService {
  static const _secure = FlutterSecureStorage();

  /// 로그인 API 호출 + 토큰 저장 + FCM 토큰 등록
  static Future<void> handleLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'loginId': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 1. 토큰 저장
      await TokenStorage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      // 2. userId 저장
      if (data['userId'] != null) {
        await TokenStorage.setUserId(data['userId'].toString());
      }

      // 3. FCM 토큰 가져오기
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await registerFcmTokenToBackend(fcmToken);
      }
    } else {
      throw Exception('로그인 실패: status=${response.statusCode}');
    }
  }

  /// 백엔드로 FCM 토큰 등록
  static Future<void> registerFcmTokenToBackend(String fcmToken) async {
    final accessToken = await TokenStorage.accessToken;
    if (accessToken == null) return;

    await http.post(
      Uri.parse('http://10.0.2.2:8080/api/fcm/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );
  }
}
