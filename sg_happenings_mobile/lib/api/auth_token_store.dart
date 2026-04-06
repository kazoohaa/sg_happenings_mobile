import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the bearer token in memory and in secure storage.
class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'access_token';
  static const _posterKey = 'is_event_poster';

  final FlutterSecureStorage _storage;
  String? _cached;
  bool? _cachedPoster;

  String? get accessToken => _cached;

  /// Last known poster flag from login or [setEventPoster]. Null if unknown.
  bool? get isEventPosterCached => _cachedPoster;

  Future<void> restore() async {
    _cached = await _storage.read(key: _key);
    final p = await _storage.read(key: _posterKey);
    if (p == 'true') {
      _cachedPoster = true;
    } else if (p == 'false') {
      _cachedPoster = false;
    } else {
      _cachedPoster = null;
    }
  }

  Future<void> setAccessToken(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> setEventPoster(bool value) async {
    _cachedPoster = value;
    await _storage.write(key: _posterKey, value: value ? 'true' : 'false');
  }

  Future<void> clear() async {
    _cached = null;
    _cachedPoster = null;
    await _storage.delete(key: _key);
    await _storage.delete(key: _posterKey);
  }
}
