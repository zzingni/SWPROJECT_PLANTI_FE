import 'dart:async';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

/// 매 요청에 Authorization: Bearer <token> 자동 부착
class AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await TokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }
}
