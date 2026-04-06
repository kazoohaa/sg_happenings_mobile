import 'package:flutter/material.dart';

import '../api/event_media_item.dart';
import '../api/playback_http_headers.dart';
import 'network_video_tile.dart';

/// Fullscreen swipeable gallery for event images and videos.
///
/// Close control is at the top; page count is at the bottom; chevrons on the
/// sides. Swipe horizontally to change media. Returns the last viewed index when popped.
class FullscreenEventMediaViewer extends StatefulWidget {
  const FullscreenEventMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  final List<EventMediaItem> items;
  final int initialIndex;

  @override
  State<FullscreenEventMediaViewer> createState() =>
      _FullscreenEventMediaViewerState();
}

class _FullscreenEventMediaViewerState extends State<FullscreenEventMediaViewer> {
  late final PageController _pageController;
  late int _index;

  static const _pageAnim = Duration(milliseconds: 280);
  static const _pageCurve = Curves.easeOutCubic;

  @override
  void initState() {
    super.initState();
    assert(widget.items.isNotEmpty);
    _index = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _popWithIndex() {
    Navigator.of(context).pop(_index);
  }

  void _goPrevious() {
    if (_index <= 0) return;
    _pageController.previousPage(duration: _pageAnim, curve: _pageCurve);
  }

  void _goNext() {
    if (_index >= widget.items.length - 1) return;
    _pageController.nextPage(duration: _pageAnim, curve: _pageCurve);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.items.isNotEmpty, 'FullscreenEventMediaViewer requires items');

    final multi = widget.items.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              final url = item.resolvedUrl;
              if (item.isVideo) {
                return NetworkVideoTile(
                  key: ValueKey<String>('fs-video-$url-$i'),
                  url: url,
                  isActive: i == _index,
                  httpHeaders: playbackVideoHeadersForUrl(url),
                  videoFit: BoxFit.contain,
                );
              }
              return _FullscreenZoomableImage(url: url);
            },
          ),
          if (multi)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 52,
              child: Center(
                child: _SideNavButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: _index > 0,
                  onPressed: _goPrevious,
                ),
              ),
            ),
          if (multi)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 52,
              child: Center(
                child: _SideNavButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: _index < widget.items.length - 1,
                  onPressed: _goNext,
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: _popWithIndex,
                ),
              ),
            ),
          ),
          if (multi)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  const _SideNavButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? Colors.black45 : Colors.black26,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white38,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _FullscreenZoomableImage extends StatelessWidget {
  const _FullscreenZoomableImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(160),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white38,
                  size: 64,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
