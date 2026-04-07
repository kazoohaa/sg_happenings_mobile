/// Body for `POST /event-applications` — matches FastAPI `EventApplicationCreate`.
///
/// Sends `category_ids` (non-empty). Also sends `category_id` as the first id for
/// older APIs that only read a single category.
class EventApplicationCreatePayload {
  const EventApplicationCreatePayload({
    required this.eventPosterId,
    required this.categoryIds,
    required this.title,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.startDatetime,
    required this.endDatetime,
    this.capacity,
    this.mediaUrls = const [],
  });

  final String eventPosterId;
  final List<String> categoryIds;
  final String title;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final int? capacity;
  final List<String> mediaUrls;

  Map<String, dynamic> toJson() {
    return {
      'event_poster_id': eventPosterId,
      'category_ids': categoryIds,
      if (categoryIds.isNotEmpty) 'category_id': categoryIds.first,
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'start_datetime': startDatetime.toUtc().toIso8601String(),
      'end_datetime': endDatetime.toUtc().toIso8601String(),
      if (capacity != null) 'capacity': capacity,
      'media_urls': mediaUrls,
    };
  }
}
