import 'package:dio/dio.dart';

import 'api_paths.dart';
import 'event_list_item.dart';
import 'sg_api_client.dart';

class EventsRepository {
  EventsRepository(this._api);

  final SgApiClient _api;

  Future<List<EventListItem>> listEvents() async {
    try {
      final response = await _api.dio.get<dynamic>(ApiPaths.events);
      final data = response.data;
      if (data is! Map) {
        throw EventsApiException('Unexpected response shape.');
      }
      final raw = data['events'];
      if (raw is! List) {
        return [];
      }
      return raw
          .map((e) => EventListItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.showsInBrowseList)
          .toList();
    } on DioException catch (e) {
      throw EventsApiException(_dioMessage(e));
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
    return e.message ?? 'Failed to load events.';
  }
}

class EventsApiException implements Exception {
  EventsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
