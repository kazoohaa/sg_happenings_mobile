import 'package:dio/dio.dart';

import 'api_paths.dart';
import 'auth_token_store.dart';
import 'jwt_payload.dart';
import 'sg_api_client.dart';
import 'user_me.dart';

/// Set `AUTH_LOGIN_AS_FORM=true` when the API uses OAuth2-style
/// `application/x-www-form-urlencoded` (e.g. `OAuth2PasswordRequestForm`).
const bool _loginAsForm = bool.fromEnvironment('AUTH_LOGIN_AS_FORM', defaultValue: false);

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final SgApiClient _api;
  final AuthTokenStore _tokens;

  /// Registers a new user. Returns `true` if the server returned an access token (auto sign-in).
  /// Returns `false` if registration succeeded without a token — caller should send the user to login.
  /// [role] must match your API (e.g. `"User"`). Change if [UserCreate.role] uses another default.
  Future<bool> register({
    required String username,
    required String name,
    required String email,
    required String password,
    String role = 'User',
  }) async {
    final u = username.trim();
    final displayName = name.trim();
    final em = email.trim();
    if (u.isEmpty) {
      throw AuthException('Enter a username.');
    }
    if (displayName.isEmpty) {
      throw AuthException('Enter your name.');
    }
    if (em.isEmpty) {
      throw AuthException('Enter your email.');
    }
    if (!_looksLikeEmail(em)) {
      throw AuthException('Enter a valid email address.');
    }
    if (password.isEmpty) {
      throw AuthException('Enter a password.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    try {
      final response = await _api.dio.post<dynamic>(
        ApiPaths.authRegister,
        data: {
          'username': u,
          'name': displayName,
          'email': em,
          'password': password,
          'role': role,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = response.data;
      if (data is! Map) {
        return false;
      }
      final map = Map<String, dynamic>.from(data);
      final token = map['access_token'] as String? ??
          map['accessToken'] as String? ??
          map['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _tokens.setAccessToken(token);
        await _persistPosterHint(map, token);
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw AuthException(_messageFromDio(e));
    }
  }

  static bool _looksLikeEmail(String s) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  }

  /// Shared with [SignUpPage] form validation (same rules as [register]).
  static bool isValidEmailForUi(String s) => _looksLikeEmail(s);

  Future<void> login({required String username, required String password}) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw AuthException('Enter your username.');
    }
    if (password.isEmpty) {
      throw AuthException('Enter your password.');
    }

    try {
      final response = await _api.dio.post<dynamic>(
        ApiPaths.authLogin,
        data: {'username': trimmed, 'password': password},
        options: _loginAsForm
            ? Options(contentType: Headers.formUrlEncodedContentType)
            : Options(contentType: Headers.jsonContentType),
      );

      final data = response.data;
      if (data is! Map) {
        throw AuthException('Unexpected response from server.');
      }

      final token = data['access_token'] as String? ??
          data['accessToken'] as String? ??
          data['token'] as String?;

      if (token == null || token.isEmpty) {
        throw AuthException('Login succeeded but no access token was returned.');
      }

      await _tokens.setAccessToken(token);
      await _persistPosterHint(Map<String, dynamic>.from(data), token);
    } on DioException catch (e) {
      throw AuthException(_messageFromDio(e));
    }
  }

  Future<void> logout() => _tokens.clear();

  Future<void> _persistPosterHint(Map<String, dynamic> data, String token) async {
    var flag = UserMe.inferExplicitPosterFlag(data);
    if (flag == null) {
      final u = UserMe.fromJson(data);
      if (u.isEventPoster) flag = true;
    }
    if (flag == null) {
      final payload = decodeJwtPayload(token);
      if (payload != null) {
        flag = UserMe.inferExplicitPosterFlag(payload);
        if (flag == null) {
          final u = UserMe.fromJson(payload);
          if (u.isEventPoster) flag = true;
        }
      }
    }
    if (flag != null) {
      await _tokens.setEventPoster(flag);
    }
  }

  static String _messageFromDio(DioException e) {
    final data = e.response?.data;
    final detail = _detailString(data);
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check the API address and network.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Is the API running and reachable from this device?';
      default:
        break;
    }
    return e.message ?? 'Login failed.';
  }

  static String? _detailString(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) {
        return first['msg'] as String;
      }
      return first.toString();
    }
    return null;
  }
}
