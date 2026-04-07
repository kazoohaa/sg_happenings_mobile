import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'api_paths.dart';
import 'category_option.dart';
import 'create_event_payload.dart';
import 'event_application_create_payload.dart';
import 'event_list_item.dart';
import 'sg_api_client.dart';
import 'submission_row.dart';

class EventPosterRepository {
  EventPosterRepository(this._api);

  final SgApiClient _api;

  Future<List<CategoryOption>> listCategories() async {
    try {
      final response = await _api.dio.get<dynamic>(ApiPaths.categories);
      final data = response.data;
      final maps = _mapsFromEnvelope(data, keys: const ['categories', 'items']);
      return maps.map(CategoryOption.fromJson).where((c) => c.id.isNotEmpty).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw PosterApiException(_dioMessage(e));
    }
  }

  /// Events you can edit (approved / published / live — same shape as public list).
  Future<List<EventListItem>> listMyApprovedEvents() async {
    try {
      final response = await _api.dio.get<dynamic>(ApiPaths.eventPosterEvents);
      final maps = _mapsFromEnvelope(response.data, keys: const ['events', 'items']);
      return maps.map((m) => EventListItem.fromJson(m)).toList();
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  Future<List<SubmissionRow>> listPendingSubmissions() async {
    try {
      final response = await _api.dio.get<dynamic>(ApiPaths.eventPosterPending);
      final maps = _mapsFromEnvelope(response.data, keys: const [
        'submissions',
        'pending',
        'items',
        'events',
      ]);
      return maps.map(SubmissionRow.fromJson).toList();
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  Future<List<SubmissionRow>> listSubmissionHistory() async {
    try {
      final response = await _api.dio.get<dynamic>(ApiPaths.eventPosterHistory);
      final maps = _mapsFromEnvelope(response.data, keys: const [
        'submissions',
        'history',
        'items',
      ]);
      return maps.map(SubmissionRow.fromJson).toList();
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  /// Submits a new event for review (`reviewed_status`: Pending).
  Future<void> createEventApplication(EventApplicationCreatePayload payload) async {
    final body = payload.toJson();
    if (kDebugMode) {
      debugPrint(
        '[EventPOST] POST ${ApiConfig.baseUrl}${ApiPaths.eventApplications}',
      );
      debugPrint('[EventPOST] body keys: ${body.keys.toList()}');
    }
    try {
      final response = await _api.dio.post<dynamic>(
        ApiPaths.eventApplications,
        data: body,
      );
      if (kDebugMode) {
        debugPrint(
          '[EventPOST] createEventApplication OK status=${response.statusCode}',
        );
        debugPrint('[EventPOST] response: ${response.data}');
      }
    } on DioException catch (e) {
      _debugLogDio('createEventApplication', e);
      throw PosterApiException(_dioMessage(e));
    }
  }

  Future<void> updateEvent(String eventId, CreateEventPayload payload) async {
    final path = ApiPaths.eventById(eventId);
    final body = payload.toJson();
    if (kDebugMode) {
      debugPrint('[EventPOST] PATCH ${ApiConfig.baseUrl}$path');
      debugPrint('[EventPOST] body keys: ${body.keys.toList()}');
    }
    try {
      final response = await _api.dio.patch<dynamic>(
        path,
        data: body,
      );
      if (kDebugMode) {
        debugPrint(
          '[EventPOST] updateEvent OK status=${response.statusCode}',
        );
        debugPrint('[EventPOST] response: ${response.data}');
      }
    } on DioException catch (e) {
      _debugLogDio('updateEvent', e);
      throw PosterApiException(_dioMessage(e));
    }
  }

  static void _debugLogDio(String action, DioException e) {
    if (!kDebugMode) return;
    final req = e.requestOptions;
    debugPrint('[EventPOST] $action FAILED');
    debugPrint('[EventPOST]   ${e.type.name} ${e.message}');
    debugPrint('[EventPOST]   ${req.method} ${req.uri}');
    debugPrint('[EventPOST]   status: ${e.response?.statusCode}');
    debugPrint('[EventPOST]   response data: ${e.response?.data}');
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _api.dio.delete<dynamic>(ApiPaths.eventById(eventId));
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  /// Deletes a pending submission by application id (if your API uses `/event-applications/{id}`).
  Future<void> deleteEventApplication(String applicationId) async {
    try {
      await _api.dio.delete<dynamic>(ApiPaths.eventApplicationById(applicationId));
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  /// Loads one event for editing (poster dashboard; includes pending/published shapes).
  Future<EventListItem> getEvent(String eventId) async {
    try {
      final response = await _api.dio.get<dynamic>(ApiPaths.eventById(eventId));
      final data = response.data;
      if (data is! Map) {
        throw PosterApiException('Unexpected event response.');
      }
      final map = Map<String, dynamic>.from(data);
      if (map['event'] is Map) {
        return EventListItem.fromJson(
          Map<String, dynamic>.from(map['event'] as Map),
        );
      }
      if (map['data'] is Map) {
        return EventListItem.fromJson(
          Map<String, dynamic>.from(map['data'] as Map),
        );
      }
      return EventListItem.fromJson(map);
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  /// Multipart upload; returns the public media URL for `media_urls` on applications.
  Future<String> uploadEventMedia({
    required String filePath,
    String? filename,
  }) async {
    try {
      final name = filename ?? filePath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: name),
      });
      final response = await _api.dio.post<dynamic>(
        ApiPaths.uploadsEventMedia,
        data: formData,
      );
      final url = _urlFromUploadResponse(response.data);
      if (url == null || url.isEmpty) {
        throw PosterApiException('Upload did not return a URL.');
      }
      return url;
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  static String? _urlFromUploadResponse(dynamic data) {
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    for (final k in ['url', 'media_url', 'mediaURL', 'file_url', 'public_url']) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
    final nested = m['data'] ?? m['asset'] ?? m['file'];
    if (nested is Map) {
      return _urlFromUploadResponse(nested);
    }
    return null;
  }

  static List<Map<String, dynamic>> _mapsFromEnvelope(
    dynamic data, {
    required List<String> keys,
  }) {
    if (data is! Map) return [];
    for (final k in keys) {
      final raw = data[k];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return [];
  }

  static String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      final d = data['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty) {
        final first = d.first;
        if (first is Map && first['msg'] is String) {
          return first['msg'] as String;
        }
      }
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
    return e.message ?? 'Request failed.';
  }
}

class PosterApiException implements Exception {
  PosterApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
