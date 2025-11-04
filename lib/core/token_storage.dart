import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccess = 'accessToken';
  static const _kRefresh = 'refreshToken';
  static const _kUserId = 'userId';
  static const _storage = FlutterSecureStorage();

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _kRefresh, value: refreshToken);
    }
  }

  static Future<String?> get accessToken async =>
      await _storage.read(key: _kAccess);

  static Future<String?> get refreshToken async =>
      await _storage.read(key: _kRefresh);

  static Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUserId);
  }

  // userId 저장/조회 ---
  static Future<void> setUserId(String id) async {
    await _storage.write(key: _kUserId, value: id);
  }

  static Future<String?> get userId async =>
      await _storage.read(key: _kUserId);
}

