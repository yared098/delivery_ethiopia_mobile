import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess  = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kAccount = 'account_json';

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveAccountJson(String json) =>
      _storage.write(key: _kAccount, value: json);

  Future<String?> get accessToken  => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);
  Future<String?> get accountJson  => _storage.read(key: _kAccount);

  Future<bool> get hasSession async {
    final a = await accessToken;
    final r = await refreshToken;
    return a != null && r != null;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kAccount);
  }
}
