/// Body for `POST /events` / `PATCH /events/:id` (field names align with [EventListItem] JSON).
class CreateEventPayload {
  const CreateEventPayload({
    required this.title,
    required this.description,
    required this.location,
    required this.categoryId,
    this.startTime,
    this.endTime,
    this.capacity,
  });

  final String title;
  final String description;
  final String location;
  final String categoryId;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? capacity;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'category_id': categoryId,
      if (startTime != null) 'start_time': startTime!.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toUtc().toIso8601String(),
      if (capacity != null) 'capacity': capacity,
    };
  }
}
