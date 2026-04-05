import 'package:intl/intl.dart';

import 'api_config.dart';

/// One row from `GET /events` → `{ "events": [ ... ] }`.
class EventListItem {
  EventListItem({
    required this.eventId,
    required this.eventPosterId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    this.startTime,
    this.endTime,
    this.capacity,
    required this.status,
    required this.eventPosterName,
    required this.categoryName,
    required this.mediaUrls,
  });

  final String eventId;
  final String eventPosterId;
  final String categoryId;
  final String title;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? capacity;
  final String status;
  final String eventPosterName;
  final String categoryName;
  final List<String> mediaUrls;

  static final RegExp _completedWord = RegExp(r'\bcompleted\b', caseSensitive: false);
  static final RegExp _cancelWord =
      RegExp(r'\bcancel(?:led|ed)?\b', caseSensitive: false);

  /// Whether this event should appear on the public browse list (e.g. Events tab).
  /// Hides when [status] indicates completed or cancelled/canceled.
  bool get showsInBrowseList {
    if (status.isEmpty) return true;
    if (_completedWord.hasMatch(status)) return false;
    if (_cancelWord.hasMatch(status)) return false;
    return true;
  }

  factory EventListItem.fromJson(Map<String, dynamic> json) {
    return EventListItem(
      eventId: json['event_id']?.toString() ?? '',
      eventPosterId: json['event_poster_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      startTime: _parseDate(json['start_time']),
      endTime: _parseDate(json['end_time']),
      capacity: _toInt(json['capacity']),
      status: json['status'] as String? ?? '',
      eventPosterName: json['event_poster_name'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      mediaUrls: _stringList(json['media_urls']),
    );
  }

  /// e.g. "Fri, Apr 12 • 7:00 PM" in local time.
  String get formattedStart {
    final t = startTime;
    if (t == null) return 'Date TBD';
    final local = t.toLocal();
    return DateFormat('EEE, MMM d • h:mm a').format(local);
  }

  /// First image URL resolved against [ApiConfig.baseUrl] if relative.
  String? get primaryImageUrl {
    if (mediaUrls.isEmpty) return null;
    return _resolveUrl(mediaUrls.first);
  }

  Map<String, dynamic> toDetailMap() {
    return {
      'title': title,
      'date': formattedStart,
      'location': location,
      'event_id': eventId,
      'description': description,
      'status': status,
      'category_name': categoryName,
      'event_poster_name': eventPosterName,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'capacity': capacity,
      'latitude': latitude,
      'longitude': longitude,
      'media_urls': mediaUrls,
    };
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null || v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = Uri.parse(ApiConfig.baseUrl);
    return base.resolve(url).toString();
  }
}
