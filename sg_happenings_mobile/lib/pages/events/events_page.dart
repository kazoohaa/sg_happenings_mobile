import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/category_option.dart';
import '../../api/event_list_item.dart';
import '../../api/event_search_filters.dart';
import '../../api/events_repository.dart';
import '../events_details/events_details_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  /// Loaded events (updated on first load and on pull-to-refresh).
  List<EventListItem> _events = [];

  /// Only the first load shows a blocking spinner; refresh keeps the list.
  bool _initialLoading = true;

  Object? _loadError;

  final TextEditingController _searchController = TextEditingController();
  String? _categoryFilterKey;
  List<CategoryOption> _categories = [];

  List<EventListItem> get _visibleEvents {
    Iterable<EventListItem> list = _events;
    list = list.where((e) => eventMatchesCategoryKey(e, _categoryFilterKey));
    final q = _searchController.text;
    return list.where((e) => eventMatchesSearchQuery(e, q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadInitial();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await eventPosterRepository.listCategories();
      if (!mounted) return;
      setState(() => _categories = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadError = null;
      _initialLoading = true;
    });
    try {
      final list = await eventsRepository.listEvents();
      if (!mounted) return;
      setState(() {
        _events = list;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final list = await eventsRepository.listEvents();
      if (!mounted) return;
      setState(() => _events = list);
    } catch (e) {
      if (!mounted) return;
      final message = e is EventsApiException ? e.message : 'Could not refresh.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Search events…',
                            hintStyle: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 16,
                            ),
                          ),
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          tooltip: 'Clear',
                        ),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: _categoryFilterKey != null,
                          smallSize: 8,
                          child: Icon(
                            Icons.tune,
                            color: Colors.grey[600],
                            size: 22,
                          ),
                        ),
                        onPressed: () => _openCategoryFilterSheet(context),
                        tooltip: 'Category filter',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategoryFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              RadioListTile<String?>(
                title: const Text('All categories'),
                value: null,
                groupValue: _categoryFilterKey,
                onChanged: (v) {
                  setState(() => _categoryFilterKey = v);
                  Navigator.pop(ctx);
                },
              ),
              ..._categories.where((c) => c.name.trim().isNotEmpty).map(
                    (c) {
                      final key = c.id.isNotEmpty ? c.id : c.name;
                      return RadioListTile<String?>(
                        title: Text(c.name),
                        value: key,
                        groupValue: _categoryFilterKey,
                        onChanged: (v) {
                          setState(() => _categoryFilterKey = v);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      final message = _loadError is EventsApiException
          ? (_loadError! as EventsApiException).message
          : 'Something went wrong.';
      return _EventsErrorBody(
        message: message,
        onRetry: _loadInitial,
      );
    }
    return RefreshIndicator(
      color: Colors.brown,
      onRefresh: _refresh,
      child: _events.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.45,
                  child: _EventsEmptyBody(onRetry: _loadInitial),
                ),
              ],
            )
          : _visibleEvents.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.35,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No events match your search or filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[700], fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _categoryFilterKey = null);
                              },
                              child: const Text('Clear search & category'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _visibleEvents.length,
                  itemBuilder: (context, index) {
                    return _EventListCard(event: _visibleEvents[index]);
                  },
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No events yet.',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
