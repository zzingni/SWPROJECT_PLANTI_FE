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
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access == null) {
        throw Exception('accessToken 누락');
      }
      await TokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
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
