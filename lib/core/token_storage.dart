import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class TokenStorage {
  static const _kAccess = 'accessToken';
  static const _kUserId = 'userId';
  static const _storage = FlutterSecureStorage();


  static Future<void> saveAccessToken({
    required String accessToken,
  }) async {
    // Access Token만 저장
    await _storage.write(key: _kAccess, value: accessToken);
  }

  static Future<String?> get accessToken async =>
      await _storage.read(key: _kAccess);

  static Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kUserId);
  }

  // userId 저장/조회 ---
  static Future<void> setUserId(String id) async {
    await _storage.write(key: _kUserId, value: id);
  }

  static Future<String?> get userId async =>
      await _storage.read(key: _kUserId);
}

