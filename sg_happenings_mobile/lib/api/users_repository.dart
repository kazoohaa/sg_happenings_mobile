import 'package:dio/dio.dart';

import 'api_paths.dart';
import 'sg_api_client.dart';
import 'user_me.dart';

class UsersRepository {
  UsersRepository(this._api);

  final SgApiClient _api;

  /// Loads the signed-in user. Tries [ApiPaths.usersMe], then `/auth/me`.
  Future<UserMe> getMe() async {
    try {
      final response = await _api.dio.get<dynamic>(ApiPaths.usersMe);
      final data = response.data;
      if (data is! Map) {
        throw UsersApiException('Unexpected profile response.');
      }
      return UserMe.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final response = await _api.dio.get<dynamic>('/auth/me');
          final data = response.data;
          if (data is! Map) {
            throw UsersApiException('Unexpected profile response.');
          }
          return UserMe.fromJson(Map<String, dynamic>.from(data));
        } on DioException catch (e2) {
          throw UsersApiException(_dioMessage(e2));
        }
      }
      throw UsersApiException(_dioMessage(e));
    }
  }

  static String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      final d = data['detail'];
      if (d is String) return d;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server.';
      default:
        break;
    }
    return e.message ?? 'Failed to load profile.';
  }
}

class UsersApiException implements Exception {
  UsersApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
