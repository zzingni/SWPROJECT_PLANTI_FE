import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart' show Post, PostListResponse, PostDetail, Comment;

/// JWT 토큰에서 사용자 ID를 추출하는 유틸리티 함수
int? extractUserIdFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    // payload 부분 디코딩
    final payload = parts[1];
    // Base64 URL 디코딩 (패딩 추가)
    String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 1:
        normalized += '===';
        break;
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
    }

    final decoded = utf8.decode(base64Decode(normalized));
    final json = jsonDecode(decoded) as Map<String, dynamic>;

    // user_id 또는 userId 필드에서 값 추출
    return json['user_id'] as int? ?? json['userId'] as int?;
  } catch (e) {
    print('토큰에서 사용자 ID 추출 실패: $e');
    return null;
  }
}

/// 게시글 관련 API 서비스 클래스
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

  Future<PostDetail> fetchPostDetail({
    required int postId,
    required int boardId,
    String? accessToken,
  }) async {
    // currentUserId 추출
    int? currentUserId;
    if (accessToken != null) {
      currentUserId = extractUserIdFromToken(accessToken);
    }

    if (currentUserId == null) {
      throw Exception('토큰에서 사용자 ID를 추출할 수 없습니다.');
    }

    final uri = Uri.parse('$baseUrl/api/posts/$postId').replace(queryParameters: {
      'boardId': '$boardId',
      'currentUserId': '$currentUserId',
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
      return PostDetail.fromJson(json);
    } on FormatException catch (e) {
      print('JSON 파싱 에러: $e');
      rethrow;
    } catch (e) {
      print('네트워크 에러: $e');
      rethrow;
    }
  }

  Future<void> createPost({
    required int boardId,
    required String title,
    required String content,
    String? imageUrl,
    String? accessToken,
  }) async {
    // currentUserId 추출
    int? currentUserId;
    if (accessToken != null) {
      currentUserId = extractUserIdFromToken(accessToken);
    }

    if (currentUserId == null) {
      throw Exception('토큰에서 사용자 ID를 추출할 수 없습니다.');
    }

    final uri = Uri.parse('$baseUrl/api/posts');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final body = jsonEncode({
      'boardId': boardId,
      'userId': currentUserId,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
    });

    try {
      final resp = await _client.post(uri, headers: headers, body: body).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      // 디버그 로깅
      print('게시글 작성 API 요청 URL: $uri');
      print('요청 본문: $body');
      print('응답 상태 코드: ${resp.statusCode}');

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        final errorBody = _peek(resp.body);
        print('에러 응답 본문: $errorBody');
        throw Exception('HTTP ${resp.statusCode}: $errorBody');
      }
    } catch (e) {
      print('게시글 작성 에러: $e');
      rethrow;
    }
  }

  Future<void> createComment({
    required int postId,
    required String content,
    String? accessToken,
  }) async {
    // currentUserId 추출
    int? currentUserId;
    if (accessToken != null) {
      currentUserId = extractUserIdFromToken(accessToken);
    }

    if (currentUserId == null) {
      throw Exception('토큰에서 사용자 ID를 추출할 수 없습니다.');
    }

    final uri = Uri.parse('$baseUrl/api/comments');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final body = jsonEncode({
      'postId': postId,
      'userId': currentUserId,
      'content': content,
    });

    try {
      final resp = await _client.post(uri, headers: headers, body: body).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      // 디버그 로깅
      print('댓글 작성 API 요청 URL: $uri');
      print('요청 본문: $body');
      print('응답 상태 코드: ${resp.statusCode}');

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        final errorBody = _peek(resp.body);
        print('에러 응답 본문: $errorBody');
        throw Exception('HTTP ${resp.statusCode}: $errorBody');
      }
    } catch (e) {
      print('댓글 작성 에러: $e');
      rethrow;
    }
  }


  Future<void> updateComment({
    required int commentId,
    required String content,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/comments/$commentId');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final body = jsonEncode({
      'content': content,
    });

    try {
      final resp = await _client.put(uri, headers: headers, body: body).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      // 디버그 로깅
      print('댓글 수정 API 요청 URL: $uri');
      print('요청 본문: $body');
      print('응답 상태 코드: ${resp.statusCode}');

      if (resp.statusCode != 200 && resp.statusCode != 204) {
        final errorBody = _peek(resp.body);
        print('에러 응답 본문: $errorBody');
        throw Exception('HTTP ${resp.statusCode}: $errorBody');
      }
    } catch (e) {
      print('댓글 수정 에러: $e');
      rethrow;
    }
  }

  Future<void> deleteComment({
    required int commentId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/comments/$commentId');

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final resp = await _client.delete(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      // 디버그 로깅
      print('댓글 삭제 API 요청 URL: $uri');
      print('응답 상태 코드: ${resp.statusCode}');

      if (resp.statusCode != 200 && resp.statusCode != 204) {
        final errorBody = _peek(resp.body);
        print('에러 응답 본문: $errorBody');
        throw Exception('HTTP ${resp.statusCode}: $errorBody');
      }
    } catch (e) {
      print('댓글 삭제 에러: $e');
      rethrow;
    }
  }

  Future<void> updatePost({
    required int postId,
    required String title,
    required String content,
    String? imageUrl,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/posts/$postId');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final body = jsonEncode({
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
    });

    try {
      final resp = await _client.put(uri, headers: headers, body: body).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      // 디버그 로깅
      print('게시글 수정 API 요청 URL: $uri');
      print('요청 본문: $body');
      print('응답 상태 코드: ${resp.statusCode}');

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        final errorBody = _peek(resp.body);
        print('에러 응답 본문: $errorBody');
        throw Exception('HTTP ${resp.statusCode}: $errorBody');
      }
    } catch (e) {
      print('게시글 수정 에러: $e');
      rethrow;
    }
  }

  Future<void> deletePost({
    required int postId,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/posts/$postId');

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final resp = await _client.delete(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      // 디버그 로깅
      print('게시글 삭제 API 요청 URL: $uri');
      print('응답 상태 코드: ${resp.statusCode}');

      if (resp.statusCode != 200 && resp.statusCode != 204) {
        final errorBody = _peek(resp.body);
        print('에러 응답 본문: $errorBody');
        throw Exception('HTTP ${resp.statusCode}: $errorBody');
      }
    } catch (e) {
      print('게시글 삭제 에러: $e');
      rethrow;
    }
  }


  /// 게시글 좋아요 토글
  /// 좋아요를 누르면 좋아요가 추가되고, 이미 좋아요를 눌렀다면 취소.
  Future<void> toggleLike({
    required int postId,
    String? accessToken,
  }) async {
    // currentUserId 추출
    int? currentUserId;
    if (accessToken != null) {
      currentUserId = extractUserIdFromToken(accessToken);
    }

    if (currentUserId == null) {
      throw Exception('토큰에서 사용자 ID를 추출할 수 없습니다.');
    }

    final uri = Uri.parse('$baseUrl/api/posts/like');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    // PostLikeRequest body 생성
    final body = jsonEncode({
      'postId': postId,
      'userId': currentUserId,
    });

    try {
      final resp = await _client.post(uri, headers: headers, body: body).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
        },
      );

      // 디버그 로깅
      print('좋아요 토글 API 요청 URL: $uri');
      print('요청 본문: $body');
      print('응답 상태 코드: ${resp.statusCode}');

      if (resp.statusCode != 200 && resp.statusCode != 201 && resp.statusCode != 204) {
        final errorBody = _peek(resp.body);
        print('에러 응답 본문: $errorBody');
        throw Exception('HTTP ${resp.statusCode}: $errorBody');
      }
    } catch (e) {
      print('좋아요 토글 에러: $e');
      rethrow;
    }
  }

  static String _peek(String s, [int n = 150]) {
    return s.length <= n ? s.substring(0, n) : s;
  }
}
