import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_paths.dart';
import 'auth_token_store.dart';

/// HTTP client for the SG Happenings FastAPI backend.
class SgApiClient {
  SgApiClient({Dio? dio, AuthTokenStore? tokenStore})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (tokenStore != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final token = tokenStore.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            if (ApiConfig.serviceApiKey.isNotEmpty) {
              options.headers['X-API-Key'] = ApiConfig.serviceApiKey;
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  /// Quick check that the device can reach the API (not the database).
  Future<Response<dynamic>> getHealth() => _dio.get(ApiPaths.health);
}
