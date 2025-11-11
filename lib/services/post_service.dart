import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class PostService {
  PostService(this._client, {required this.baseUrl});
  final http.Client _client;
  final String baseUrl;

  void close() => _client.close();

  Future<PostListResponse> fetchPosts({
    required int boardId,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String direction = 'DESC',
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/posts').replace(queryParameters: {
      'boardId': '$boardId',
      'page': '$page',
      'size': '$size',
      'sortBy': sortBy,
      'direction': direction,
    });

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final resp = await _client.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      final ct = resp.headers['content-type'] ?? '';

      // 디버그 로깅
      print('API 요청 URL: $uri');
      print('응답 상태 코드: ${resp.statusCode}');
      print('응답 Content-Type: $ct');

      if (resp.statusCode != 200) {
        final errorBody = _peek(resp.body);
        print('에러 응답 본문: $errorBody');
        throw Exception('HTTP ${resp.statusCode}: $errorBody');
      }

      if (!ct.contains('json') && resp.body.isNotEmpty) {
        throw FormatException('예상하지 못한 응답 형식 ($ct): ${_peek(resp.body)}');
      }

      if (resp.body.isEmpty) {
        throw Exception('응답이 비어있습니다.');
      }

      final Map<String, dynamic> json = jsonDecode(resp.body) as Map<String, dynamic>;
      return PostListResponse.fromJson(json);
    } on FormatException catch (e) {
      print('JSON 파싱 에러: $e');
      rethrow;
    } catch (e) {
      print('네트워크 에러: $e');
      rethrow;
    }
  }

  static String _peek(String s, [int n = 150]) =>
      s.length <= n ? s : s.substring(0, n);
}

