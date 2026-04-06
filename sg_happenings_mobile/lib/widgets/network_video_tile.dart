import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// In-gallery network video with Cupertino-style chrome; tap to play/pause.
///
/// If the native player cannot open the URL (codec, auth, corrupt file, or the
/// URL is actually an image), we fall back to [Image.network] with the same URL.
///
/// Use [httpHeaders] for protected video URLs (e.g. `Authorization: Bearer …`).
class NetworkVideoTile extends StatefulWidget {
  const NetworkVideoTile({
    super.key,
    required this.url,
    this.isActive = true,
    this.httpHeaders = const <String, String>{},
    this.videoFit = BoxFit.cover,
  });

  final String url;
  final bool isActive;
  final Map<String, String> httpHeaders;
  /// How the video frame is fitted inside the tile (e.g. [BoxFit.contain] for fullscreen).
  final BoxFit videoFit;

  @override
  State<NetworkVideoTile> createState() => _NetworkVideoTileState();
}

class _NetworkVideoTileState extends State<NetworkVideoTile> {
  VideoPlayerController? _controller;
  bool _ready = false;
  /// Video init failed — showing static image attempt instead.
  bool _imageFallback = false;

  @override
  void initState() {
    super.initState();
    // Defer native player setup until after the first frame. Creating the
    // Android TextureView too early can trigger:
    // PlatformException(channel-error, ... AndroidVideoPlayerApi.createForTextureView ...)
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupVideo());
  }

  void _setupVideo() {
    if (!mounted) return;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.httpHeaders,
    );
    _controller = c;
    c.addListener(_onTick);
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
    }).catchError((Object e, StackTrace st) {
      if (kDebugMode) {
        debugPrint('VideoPlayer init failed for ${widget.url}: $e');
      }
      c.removeListener(_onTick);
      c.dispose();
      if (!mounted) return;
      setState(() {
        _controller = null;
        _imageFallback = true;
        _ready = false;
      });
    });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(NetworkVideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _controller;
    if (c != null && !widget.isActive && c.value.isPlaying) {
      c.pause();
    }
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onTick);
      c.dispose();
    }
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_ready || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageFallback) {
      return SizedBox.expand(
        child: Image.network(
          widget.url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _unavailablePlaceholder(context),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return ColoredBox(
              color: CupertinoColors.tertiarySystemGroupedBackground
                  .resolveFrom(context),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 14),
              ),
            );
          },
        ),
      );
    }

    final c = _controller;
    if (c == null) {
      return _unavailablePlaceholder(context);
    }

    return ColoredBox(
      color: CupertinoColors.black,
      child: _ready && c.value.isInitialized
          ? CupertinoTheme(
              data: const CupertinoThemeData(brightness: Brightness.dark),
              child: SizedBox.expand(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlay,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FittedBox(
                        fit: widget.videoFit,
                        child: SizedBox(
                          width: c.value.size.width,
                          height: c.value.size.height,
                          child: VideoPlayer(c),
                        ),
                      ),
                      if (!c.value.isPlaying)
                        Center(
                          child: Icon(
                            CupertinoIcons.play_circle_fill,
                            size: 64,
                            color:
                                CupertinoColors.white.withValues(alpha: 0.95),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          : const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: CupertinoColors.white,
              ),
            ),
    );
  }

  Widget _unavailablePlaceholder(BuildContext context) {
    return ColoredBox(
      color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 48,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load this media.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'If this should be a video, check the file format (e.g. H.264 MP4) and that the server allows playback with your login.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
