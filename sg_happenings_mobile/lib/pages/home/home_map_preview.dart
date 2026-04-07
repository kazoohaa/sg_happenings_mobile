import 'dart:math' as math;

import 'package:flutter/foundation.dart' show Factory, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../api/event_list_item.dart';

/// Central Singapore when there are no pins yet.
const LatLng kSingaporeCenter = LatLng(1.3521, 103.8198);

/// Google Map: one marker per event using [EventListItem.latitude]/[longitude],
/// or [EventListItem.postalCode] geocoded to a point (Singapore).
///
/// Geocoding uses the platform [locationFromAddress] (e.g. `"Singapore 123456"`).
/// Works on Android and iOS after Maps API keys are set.
class HomeMapPreview extends StatefulWidget {
  const HomeMapPreview({
    super.key,
    required this.events,
    required this.loading,
    this.errorMessage,
    this.height = 160,
    this.allowExpand = true,
    this.fullscreen = false,
  });

  final List<EventListItem> events;
  final bool loading;
  final String? errorMessage;
  final double height;

  /// Shows an expand button that pushes a fullscreen map.
  final bool allowExpand;

  /// Fullscreen mode tweaks (controls, overlays).
  final bool fullscreen;

  @override
  State<HomeMapPreview> createState() => _HomeMapPreviewState();
}

class _HomeMapPreviewState extends State<HomeMapPreview> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  /// Cache: normalized postal digits → coordinates.
  final Map<String, LatLng> _postalResolved = {};

  bool _geocodingPostals = false;
  int _geocodeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _markers = _buildMarkers(widget.events);
    if (!kIsWeb && _needsPostalLookup(widget.events)) {
      _geocodingPostals = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolvePostalCodes(widget.events);
    });
  }

  @override
  void didUpdateWidget(HomeMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.events, widget.events)) {
      setState(() {
        _markers = _buildMarkers(widget.events);
        if (!kIsWeb && _needsPostalLookup(widget.events)) {
          _geocodingPostals = true;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitCamera();
        _resolvePostalCodes(widget.events);
      });
    }
  }

  bool _needsPostalLookup(List<EventListItem> events) {
    for (final e in events) {
      if (e.latitude != null && e.longitude != null) continue;
      final raw = e.postalCode?.trim();
      if (raw == null || raw.isEmpty) continue;
      final key = _postalKey(raw);
      if (key.isEmpty || _postalResolved.containsKey(key)) continue;
      return true;
    }
    return false;
  }

  /// Prefer last 6 digits for SG-style codes; otherwise trimmed string.
  static String _postalKey(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      return digits.substring(digits.length - 6);
    }
    return raw.trim();
  }

  static String _geocodeQuery(String postalKey) => 'Singapore $postalKey';

  LatLng? _positionForEvent(EventListItem e) {
    if (e.latitude != null && e.longitude != null) {
      return LatLng(e.latitude!, e.longitude!);
    }
    final raw = e.postalCode?.trim();
    if (raw == null || raw.isEmpty) return null;
    final key = _postalKey(raw);
    if (key.isEmpty) return null;
    return _postalResolved[key];
  }

  Set<Marker> _buildMarkers(List<EventListItem> events) {
    final out = <Marker>{};
    var i = 0;
    for (final e in events) {
      final pos = _positionForEvent(e);
      if (pos == null) continue;
      final id = e.eventId.isNotEmpty ? e.eventId : 'm_${i++}';
      out.add(
        Marker(
          markerId: MarkerId(id),
          position: pos,
          infoWindow: InfoWindow(
            title: e.title.isNotEmpty ? e.title : 'Event',
            snippet: e.location,
          ),
        ),
      );
    }
    return out;
  }

  Future<void> _resolvePostalCodes(List<EventListItem> events) async {
    if (kIsWeb) return;

    final needed = <String>{};
    for (final e in events) {
      if (e.latitude != null && e.longitude != null) continue;
      final raw = e.postalCode?.trim();
      if (raw == null || raw.isEmpty) continue;
      final key = _postalKey(raw);
      if (key.isEmpty || _postalResolved.containsKey(key)) continue;
      needed.add(key);
    }

    if (needed.isEmpty) {
      if (mounted) setState(() => _geocodingPostals = false);
      return;
    }

    final gen = ++_geocodeGeneration;
    if (mounted) setState(() => _geocodingPostals = true);

    for (final key in needed) {
      if (!mounted || gen != _geocodeGeneration) return;
      try {
        final locations = await locationFromAddress(_geocodeQuery(key));
        if (!mounted || gen != _geocodeGeneration) return;
        if (locations.isNotEmpty) {
          final loc = locations.first;
          _postalResolved[key] = LatLng(loc.latitude, loc.longitude);
        }
      } catch (_) {
        // Unknown or unroutable postal — skip marker
      }
    }

    if (!mounted || gen != _geocodeGeneration) return;
    setState(() {
      _geocodingPostals = false;
      _markers = _buildMarkers(widget.events);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  Future<void> _fitCamera() async {
    final c = _controller;
    if (c == null || !mounted) return;
    final positions = _markers.map((m) => m.position).toList();
    if (positions.isEmpty) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(kSingaporeCenter, 11));
      return;
    }
    if (positions.length == 1) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 14),
      );
      return;
    }
    var minLat = positions.first.latitude;
    var maxLat = minLat;
    var minLng = positions.first.longitude;
    var maxLng = minLng;
    for (final p in positions) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    if (minLat == maxLat && minLng == maxLng) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(positions.first, 14));
      return;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    try {
      await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    } catch (_) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(kSingaporeCenter, 11));
    }
  }

  bool _eventHasMappableInput(EventListItem e) {
    if (e.latitude != null && e.longitude != null) return true;
    final pc = e.postalCode?.trim();
    return pc != null && pc.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.events.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(child: CircularProgressIndicator(color: Colors.brown)),
      );
    }

    if (widget.errorMessage != null && widget.events.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
            ),
          ),
        ),
      );
    }

    if (kIsWeb) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Map preview runs on iOS and Android.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
      );
    }

    final hasMappableInput = widget.events.any(_eventHasMappableInput);
    final showNoDataHint = widget.events.isNotEmpty &&
        _markers.isEmpty &&
        !_geocodingPostals &&
        !hasMappableInput;
    final showResolveFailedHint = widget.events.isNotEmpty &&
        _markers.isEmpty &&
        !_geocodingPostals &&
        hasMappableInput;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: kSingaporeCenter,
                zoom: 11,
              ),
              markers: _markers,
              zoomControlsEnabled: widget.fullscreen,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _controller = controller;
                _fitCamera();
              },
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
            if (widget.allowExpand && !widget.fullscreen)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => _HomeMapFullscreenPage(
                            events: widget.events,
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.open_in_full_rounded, size: 18),
                    ),
                  ),
                ),
              ),
            if (_geocodingPostals && _markers.isEmpty)
              Material(
                color: Colors.white.withValues(alpha: 0.88),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Looking up postal codes…',
                        style: TextStyle(color: Colors.grey[800], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else if (!widget.fullscreen && showNoDataHint)
              Material(
                color: Colors.white.withValues(alpha: 0.88),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Add latitude/longitude or postal_code on each event to show pins.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ),
              )
            else if (!widget.fullscreen && showResolveFailedHint)
              Material(
                color: Colors.white.withValues(alpha: 0.88),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Could not place pins. Check postal codes (Singapore) or coordinates from the API.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeMapFullscreenPage extends StatelessWidget {
  const _HomeMapFullscreenPage({required this.events});

  final List<EventListItem> events;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Map'),
      ),
      body: SafeArea(
        child: HomeMapPreview(
          events: events,
          loading: false,
          height: MediaQuery.of(context).size.height,
          allowExpand: false,
          fullscreen: true,
        ),
      ),
    );
  }
}
