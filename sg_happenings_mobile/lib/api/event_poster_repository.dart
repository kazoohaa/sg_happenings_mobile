import 'package:dio/dio.dart';

import 'api_paths.dart';
import 'category_option.dart';
import 'create_event_payload.dart';
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

  Future<void> createEvent(CreateEventPayload payload) async {
    try {
      await _api.dio.post<dynamic>(ApiPaths.events, data: payload.toJson());
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  Future<void> updateEvent(String eventId, CreateEventPayload payload) async {
    try {
      await _api.dio.patch<dynamic>(
        ApiPaths.eventById(eventId),
        data: payload.toJson(),
      );
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _api.dio.delete<dynamic>(ApiPaths.eventById(eventId));
    } on DioException catch (e) {
      throw PosterApiException(_dioMessage(e));
    }
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
