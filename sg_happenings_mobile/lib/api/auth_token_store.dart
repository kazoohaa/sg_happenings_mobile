import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the bearer token in memory and in secure storage.
class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'access_token';
  static const _posterKey = 'is_event_poster';
  static const _posterApplicationPendingKey = 'poster_application_pending';

  final FlutterSecureStorage _storage;
  String? _cached;
  bool? _cachedPoster;
  bool? _cachedPosterApplicationPending;

  /// Incremented when poster-application pending state may have changed (for UI like Profile).
  final ValueNotifier<int> posterApplicationPendingRevision = ValueNotifier<int>(0);

  String? get accessToken => _cached;

  /// Last known poster flag from login or [setEventPoster]. Null if unknown.
  bool? get isEventPosterCached => _cachedPoster;

  /// True after the user submitted an event-poster application that is pending review.
  bool get hasPendingPosterApplicationSubmitted => _cachedPosterApplicationPending == true;

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
    final pap = await _storage.read(key: _posterApplicationPendingKey);
    if (pap == 'true') {
      _cachedPosterApplicationPending = true;
    } else if (pap == 'false') {
      _cachedPosterApplicationPending = false;
    } else {
      _cachedPosterApplicationPending = null;
    }
    posterApplicationPendingRevision.value++;
  }

  Future<void> setAccessToken(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> setEventPoster(bool value) async {
    _cachedPoster = value;
    await _storage.write(key: _posterKey, value: value ? 'true' : 'false');
  }

  Future<void> setPosterApplicationPending(bool value) async {
    _cachedPosterApplicationPending = value;
    await _storage.write(key: _posterApplicationPendingKey, value: value ? 'true' : 'false');
    posterApplicationPendingRevision.value++;
  }

  Future<void> clear() async {
    _cached = null;
    _cachedPoster = null;
    _cachedPosterApplicationPending = null;
    await _storage.delete(key: _key);
    await _storage.delete(key: _posterKey);
    await _storage.delete(key: _posterApplicationPendingKey);
    posterApplicationPendingRevision.value++;
  }
}
