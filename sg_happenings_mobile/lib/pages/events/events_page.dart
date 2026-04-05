import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/event_list_item.dart';
import '../../api/events_repository.dart';
import '../events_details/events_details_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<EventListItem>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = eventsRepository.listEvents();
  }

  Future<void> _refresh() async {
    final next = eventsRepository.listEvents();
    setState(() => _eventsFuture = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.tune,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<EventListItem>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is EventsApiException
                        ? (snapshot.error as EventsApiException).message
                        : 'Something went wrong.';
                    return _EventsErrorBody(
                      message: message,
                      onRetry: () {
                        setState(() {
                          _eventsFuture = eventsRepository.listEvents();
                        });
                      },
                    );
                  }
                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return _EventsEmptyBody(onRetry: () {
                      setState(() {
                        _eventsFuture = eventsRepository.listEvents();
                      });
                    });
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return _EventListCard(event: events[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventListCard extends StatelessWidget {
  const _EventListCard({required this.event});

  final EventListItem event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventsDetailsPage(
              event: event.toDetailMap(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDE8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _EventLeadingImage(event: event),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.formattedStart,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventLeadingImage extends StatelessWidget {
  const _EventLeadingImage({required this.event});

  final EventListItem event;

  @override
  Widget build(BuildContext context) {
    if (event.media.isEmpty) {
      return _categoryPlaceholder(event.categoryName);
    }
    final first = event.media.first;
    if (first.isVideo) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.play_circle_filled,
          color: Colors.white70,
          size: 44,
        ),
      );
    }
    final url = event.primaryImageUrl;
    if (url != null) {
      return Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _categoryPlaceholder(event.categoryName),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 80,
            height: 80,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
            ),
          );
        },
      );
    }
    return _categoryPlaceholder(event.categoryName);
  }
}

Widget _categoryPlaceholder(String categoryName) {
  final style = _categoryStyle(categoryName);
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: style.color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      style.icon,
      color: Colors.white,
      size: 40,
    ),
  );
}

({Color color, IconData icon}) _categoryStyle(String name) {
  final n = name.toLowerCase();
  if (n.contains('music') ||
      n.contains('concert') ||
      n.contains('live')) {
    return (color: const Color(0xFFFF6B35), icon: Icons.mic);
  }
  if (n.contains('art') ||
      n.contains('gallery') ||
      n.contains('exhibition')) {
    return (color: const Color(0xFFFFA726), icon: Icons.palette);
  }
  if (n.contains('food') ||
      n.contains('cook') ||
      n.contains('dining') ||
      n.contains('workshop')) {
    return (color: const Color(0xFF8D6E63), icon: Icons.restaurant);
  }
  return (color: const Color(0xFF78909C), icon: Icons.event);
}

class _EventsErrorBody extends StatelessWidget {
  const _EventsErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.35,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventsEmptyBody extends StatelessWidget {
  const _EventsEmptyBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.35),
        Center(
          child: Text(
            'No events yet.',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Refresh'),
          ),
        ),
      ],
    );
  }
}
