import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/token_storage.dart';
import '../../core/auth_client.dart';

class AuthApi {
  static const _base = 'http://10.0.2.2:8080';

  /// JSON 로그인
  static Future<void> loginJson({
    required String loginId,
    required String password,
  }) async {
    final url = Uri.parse('$_base/api/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'loginId': loginId,
        'password': password,
      }),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);

      // Access Token 추출 및 널 체크
      final String? accessToken = data['token'] as String?;
      // Access Token이 필수로 누락되었는지 확인 (401 오류가 아닌데도 토큰이 없는 경우)
      if (accessToken == null || accessToken.isEmpty) {
        // 토큰이 누락된 경우
        throw Exception('로그인 성공 응답에서 Access Token(token)이 누락되었습니다.');
      }

      // 토큰 저장 (추출한 변수 이름 사용)
      await TokenStorage.saveAccessToken(
        accessToken: accessToken
      );

      return;
    }
    throw Exception('로그인 실패 (${res.statusCode}): ${res.body}');
    }

  /// 인증 필요한 API 호출
  static Future<String> fetchMe() async {
    final client = AuthClient();
    final url = Uri.parse('$_base/api/me');
    final res = await client.get(url);
    if (res.statusCode == 200) return res.body;
    throw Exception('내 정보 조회 실패 (${res.statusCode})');
  }
}
