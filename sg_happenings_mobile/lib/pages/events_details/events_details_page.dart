import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/event_media_item.dart';
import '../../api/playback_http_headers.dart';
import '../../widgets/fullscreen_event_media_viewer.dart';
import '../../widgets/network_video_tile.dart';

class EventsDetailsPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventsDetailsPage({super.key, required this.event});

  @override
  State<EventsDetailsPage> createState() => _EventsDetailsPageState();
}

class _EventsDetailsPageState extends State<EventsDetailsPage> {
  bool _isBookmarked = false;
  final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  String get _title => widget.event['title']?.toString() ?? 'Event';

  String get _location => widget.event['location']?.toString() ?? '';

  String get _description {
    final d = widget.event['description']?.toString().trim();
    if (d == null || d.isEmpty) {
      return 'No description provided.';
    }
    return d;
  }

  String get _organizer =>
      widget.event['event_poster_name']?.toString().trim().isNotEmpty == true
          ? widget.event['event_poster_name'].toString()
          : 'Organizer';

  List<EventMediaItem> get _mediaItems {
    final raw = Map<String, dynamic>.from(widget.event);
    return EventMediaItem.listFromApiEventJson(raw);
  }

  double? get _lat => _toDouble(widget.event['latitude']);

  double? get _lng => _toDouble(widget.event['longitude']);

  String _formattedDateLine() {
    final start = _parseDate(widget.event['start_time']);
    final end = _parseDate(widget.event['end_time']);
    if (start == null) {
      return widget.event['date']?.toString() ?? 'Date TBD';
    }
    final ls = start.toLocal();
    final le = end?.toLocal();
    final datePart = DateFormat('EEEE, MMMM d').format(ls);
    final startPart = DateFormat('h:mm a').format(ls);
    if (le == null) {
      return '$datePart · $startPart';
    }
    final sameDay = ls.year == le.year && ls.month == le.month && ls.day == le.day;
    if (sameDay) {
      return '$datePart · $startPart – ${DateFormat('h:mm a').format(le)}';
    }
    return '${DateFormat('EEE, MMM d, h:mm a').format(ls)} – ${DateFormat('EEE, MMM d, h:mm a').format(le)}';
  }

  List<String> _categoryTags() {
    final raw = widget.event['category_name']?.toString().trim();
    if (raw == null || raw.isEmpty) return [];
    for (final sep in [',', '|', '/']) {
      if (raw.contains(sep)) {
        return raw
            .split(sep)
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    return [raw];
  }

  Future<void> _openMaps() async {
    final loc = _location;
    Uri uri;
    final lat = _lat;
    final lng = _lng;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${lat.toString()},${lng.toString()}',
      );
    } else if (loc.isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search?q=${Uri.encodeComponent(loc)}',
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location available for maps.')),
        );
      }
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = _categoryTags();
    final mediaItems = _mediaItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildGallery(
                          mediaItems,
                          onImageTap: () => _openFullscreenMedia(mediaItems),
                        ),
                        if (mediaItems.isNotEmpty)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => _openFullscreenMedia(mediaItems),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.fullscreen_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (mediaItems.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      mediaItems.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _galleryIndex
                              ? const Color(0xFFFF6B35)
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _formattedDateLine(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isBookmarked = !_isBookmarked;
                            });
                          },
                          child: Icon(
                            _isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: _isBookmarked
                                ? const Color(0xFFFF6B35)
                                : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    if (widget.event['status']?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.event['status'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildSection(
                      'Location',
                      [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _location.isEmpty ? 'TBA' : _location,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: _openMaps,
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 60,
                                  height: 40,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          Icons.map,
                                          color: Colors.grey[600],
                                          size: 22,
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF6B35),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Description',
                      [
                        Text(
                          _description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map(_buildTag).toList(),
                          ),
                        ],
                      ],
                    ),
                    if (widget.event['capacity'] != null) ...[
                      const SizedBox(height: 24),
                      _buildSection(
                        'Capacity',
                        [
                          Text(
                            '${widget.event['capacity']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildSection(
                      'Organizer',
                      [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4C4B0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _organizer,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFullscreenMedia(List<EventMediaItem> items) async {
    if (items.isEmpty || !mounted) return;
    final idx = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        fullscreenDialog: true,
        builder: (context) => FullscreenEventMediaViewer(
          items: items,
          initialIndex: _galleryIndex,
        ),
      ),
    );
    if (!mounted) return;
    if (idx != null && idx >= 0 && idx < items.length) {
      setState(() => _galleryIndex = idx);
      if (_galleryController.hasClients) {
        _galleryController.jumpToPage(idx);
      }
    }
  }

  Widget _buildGallery(
    List<EventMediaItem> items, {
    VoidCallback? onImageTap,
  }) {
    if (items.isEmpty) {
      return Container(
        color: const Color(0xFFD4C4B0),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 56,
            color: Colors.grey[500],
          ),
        ),
      );
    }
    return PageView.builder(
      controller: _galleryController,
      itemCount: items.length,
      onPageChanged: (i) => setState(() => _galleryIndex = i),
      itemBuilder: (context, index) {
        final item = items[index];
        final url = item.resolvedUrl;
        if (item.isVideo) {
          return NetworkVideoTile(
            key: ValueKey<String>(url),
            url: url,
            isActive: index == _galleryIndex,
            httpHeaders: playbackVideoHeadersForUrl(url),
          );
        }
        return GestureDetector(
          onTap: onImageTap,
          behavior: HitTestBehavior.opaque,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFD4C4B0),
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.grey[500],
              ),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFFE8E0D8),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v);
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

