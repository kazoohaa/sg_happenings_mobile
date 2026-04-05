import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the bearer token in memory and in secure storage.
class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'access_token';

  final FlutterSecureStorage _storage;
  String? _cached;

  String? get accessToken => _cached;

  Future<void> restore() async {
    _cached = await _storage.read(key: _key);
  }

  Future<void> setAccessToken(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}
