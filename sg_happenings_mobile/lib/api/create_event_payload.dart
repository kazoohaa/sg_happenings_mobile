/// Body for `PATCH /events/:id` (field names align with [EventListItem] JSON).
///
/// Sends `category_ids` (non-empty). Also sends `category_id` as the first id for
/// older APIs that only read a single category.
class CreateEventPayload {
  const CreateEventPayload({
    required this.title,
    required this.description,
    required this.location,
    this.postalCode,
    required this.categoryIds,
    this.startTime,
    this.endTime,
    this.capacity,
    this.latitude,
    this.longitude,
    this.mediaUrls,
  });

  final String title;
  final String description;
  final String location;
  final String? postalCode;
  final List<String> categoryIds;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? capacity;
  final double? latitude;
  final double? longitude;
  final List<String>? mediaUrls;

  Map<String, dynamic> toJson() {
    final pc = postalCode?.trim();
    return {
      'title': title,
      'description': description,
      'location': location,
      if (pc != null && pc.isNotEmpty) 'postal_code': pc,
      'category_ids': categoryIds,
      if (categoryIds.isNotEmpty) 'category_id': categoryIds.first,
      if (startTime != null) 'start_time': startTime!.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toUtc().toIso8601String(),
      if (capacity != null) 'capacity': capacity,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (mediaUrls != null) 'media_urls': mediaUrls,
    };
  }
}
