import 'dart:convert';
import 'package:fe/models/palnt_info.dart';
import 'package:http/http.dart' as http;
import 'package:fe/core/token_storage.dart';

/// 식물 정보 검색 서비스 클래스
class PlantService {
  PlantService(this._client, {required this.baseUrl});
  final http.Client _client;
  final String baseUrl;

  void close() => _client.close();

  Future<PlantInfo> searchPlant(String plantName) async {
    final uri = Uri.parse('$baseUrl/api/garden/search');

    // TokenStorage에서 토큰 불러오기
    final token = await TokenStorage.accessToken;

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({'plantName': plantName});

    final resp = await _client.post(
      uri,
      headers: headers,
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }

    final List<dynamic> jsonList = jsonDecode(resp.body);

    // 결과 없는 경우 처리
    if (jsonList.isEmpty) {
      throw Exception('검색 결과 없음');
    }

    // 리스트의 첫 번째 객체를 파싱
    return PlantInfo.fromJson(jsonList.first);
  }
}