import 'package:dio/dio.dart';

import 'api_paths.dart';
import 'auth_token_store.dart';
import 'sg_api_client.dart';

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
    } on DioException catch (e) {
      throw AuthException(_messageFromDio(e));
    }
  }

  Future<void> logout() => _tokens.clear();

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
