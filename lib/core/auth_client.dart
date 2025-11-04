import 'dart:async';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

/// 매 요청에 Authorization: Bearer <token> 자동 부착
class AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String? token;
    try {
      token = await TokenStorage.accessToken;
    } catch (e) {
      print('TokenStorage error: $e');
    }

    print('AuthClient -> ${request.method} ${request.url}');
    print('AuthClient BEFORE headers: ${request.headers}');
    print('AuthClient token: $token');

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    print('AuthClient AFTER headers: ${request.headers}');
    return _inner.send(request);
  }
}
