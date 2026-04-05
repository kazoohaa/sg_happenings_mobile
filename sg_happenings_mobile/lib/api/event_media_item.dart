import 'api_config.dart';

/// One media file for an event (image or video).
class EventMediaItem {
  const EventMediaItem({
    required this.url,
    required this.isVideo,
  });

  final String url;
  final bool isVideo;

  /// Parse from API objects, e.g. `{ "mediaURL": "...", "media_type": "video/mp4" }`.
  factory EventMediaItem.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['mediaURL'] ?? json['media_url'] ?? json['url'];
    final url = rawUrl?.toString().trim() ?? '';
    final typeStr =
        '${json['media_type'] ?? json['mime_type'] ?? json['type'] ?? ''}'
            .toLowerCase();
    var isVideo = typeStr.contains('video');
    final isImage = typeStr.contains('image');
    if (!isVideo && !isImage && url.isNotEmpty) {
      isVideo = looksLikeVideoUrl(url);
    }
    return EventMediaItem(url: url, isVideo: isVideo);
  }

  /// Plain URL only (e.g. from `media_urls`); video inferred from extension / path.
  factory EventMediaItem.fromUrlString(String url) {
    final u = url.trim();
    return EventMediaItem(url: u, isVideo: looksLikeVideoUrl(u));
  }

  /// Reads `event_media` / `media` objects, or falls back to `media_urls` strings.
  static List<EventMediaItem> listFromApiEventJson(Map<String, dynamic> json) {
    final rich = json['event_media'] ?? json['media'];
    if (rich is List && rich.isNotEmpty) {
      final out = <EventMediaItem>[];
      for (final e in rich) {
        if (e is Map) {
          out.add(EventMediaItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      final nonEmpty = out.where((m) => m.url.isNotEmpty).toList();
      if (nonEmpty.isNotEmpty) {
        return nonEmpty;
      }
    }
    final urls = json['media_urls'];
    if (urls is! List) return [];
    return urls
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .map(EventMediaItem.fromUrlString)
        .toList();
  }

  static bool looksLikeVideoUrl(String url) {
    if (url.isEmpty) return false;
    final path = url.split('?').first.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.webm') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv');
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'is_video': isVideo,
      };

  static String resolveMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return Uri.parse(ApiConfig.baseUrl).resolve(url).toString();
  }

  String get resolvedUrl => resolveMediaUrl(url);
}
