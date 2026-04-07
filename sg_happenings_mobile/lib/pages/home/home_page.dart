import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/category_option.dart';
import '../../api/event_list_item.dart';
import '../../api/events_repository.dart';
import '../event_poster_application/event_poster_application.dart';
import '../events_details/events_details_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import 'home_map_preview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<EventListItem> _events = [];
  bool _loadingEvents = true;
  String? _eventsError;
  bool _showPosterApplication = true;
  List<CategoryOption> _categories = [];
  String? _selectedCategoryKey;

  List<EventListItem> get _filteredEvents {
    final key = _selectedCategoryKey?.trim().toLowerCase();
    if (key == null || key.isEmpty) return _events;
    return _events.where((e) {
      if (e.categoryId.trim().toLowerCase() == key) return true;
      if (e.categoryName.trim().toLowerCase() == key) return true;
      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _showPosterApplication = authTokenStore.isEventPosterCached != true;
    _loadRoleFlags();
    _loadCategories();
    _loadEvents();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await eventPosterRepository.listCategories();
      if (!mounted) return;
      setState(() => _categories = list);
    } catch (_) {
      // Keep the UI working even if categories fail to load.
    }
  }

  Future<void> _loadRoleFlags() async {
    try {
      final me = await usersRepository.getMe();
      if (!mounted) return;
      setState(() {
        _showPosterApplication = !(me.isEventPoster || me.isAdmin);
      });
    } catch (_) {
      // If role lookup fails, keep current behavior (default is to show for non-poster).
    }
  }

  /// [silent] is used for pull-to-refresh: keep the list/map visible instead of
  /// toggling the blocking loading state (which can confuse [RefreshIndicator]).
  Future<void> _loadEvents({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingEvents = true;
        _eventsError = null;
      });
    } else {
      setState(() => _eventsError = null);
    }
    try {
      final list = await eventsRepository.listEvents();
      if (!mounted) return;
      setState(() {
        _events = list;
        _loadingEvents = false;
      });
    } on EventsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _eventsError = e.message;
        _loadingEvents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eventsError = 'Could not load events.';
        _loadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EEDC),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.brown,
          onRefresh: () => _loadEvents(silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                      },
                      child: const Icon(Icons.notifications_none_rounded, color: Colors.brown),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const ProfilePage(showBackButton: true),
                          ),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE9C8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.person, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 44,
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.brown),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search',
                          style: TextStyle(color: Color(0xFF7A6F66)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _MapCard(
                  events: _events,
                  loading: _loadingEvents,
                  errorMessage: _eventsError,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nearby events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(
                        label: 'Trending now',
                        selected: _selectedCategoryKey == null,
                        onTap: () => setState(() => _selectedCategoryKey = null),
                      ),
                      ..._categories
                          .where((c) => c.name.trim().isNotEmpty)
                          .take(4)
                          .map(
                            (c) => _filterChip(
                              label: c.name,
                              selected: _selectedCategoryKey == (c.id.isNotEmpty ? c.id : c.name),
                              onTap: () => setState(
                                () => _selectedCategoryKey = c.id.isNotEmpty ? c.id : c.name,
                              ),
                            ),
                          ),
                      _filterChip(
                        label: 'More',
                        selected: false,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('More categories coming soon.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: _buildEventStrip(_filteredEvents),
                ),
                const SizedBox(height: 16),
                if (_showPosterApplication)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const EventPosterApplicationPage(),
                        ),
                      );
                    },
                    child: _PosterTile(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventStrip(List<EventListItem> events) {
    if (_loadingEvents && events.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.brown));
    }
    if (_eventsError != null && events.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadEvents,
          icon: const Icon(Icons.refresh, color: Colors.brown),
          label: const Text('Retry loading events', style: TextStyle(color: Colors.brown)),
        ),
      );
    }
    if (events.isEmpty) {
      if (_selectedCategoryKey != null && _events.isNotEmpty) {
        return Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _selectedCategoryKey = null),
            icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.brown),
            label: const Text('No events in this category', style: TextStyle(color: Colors.brown)),
          ),
        );
      }
      return ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _PlaceholderEventCard(
            title: 'Live Concert',
            subtitle: 'Today · 7:00 PM\nDowntown',
          ),
          SizedBox(width: 12),
          _PlaceholderEventCard(
            title: 'Jazz Night',
            subtitle: 'Apr 20 · 8:00 PM\nJazz Club',
          ),
          SizedBox(width: 12),
          _PlaceholderEventCard(
            title: 'Art Exhibition',
            subtitle: 'Apr 18 · 11:00 AM\nArt Gallery',
          ),
        ],
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) => _HomeEventStripCard(event: events[i]),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.events,
    required this.loading,
    this.errorMessage,
  });

  final List<EventListItem> events;
  final bool loading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDEAD7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SG Happenings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 8),
          HomeMapPreview(
            events: events,
            loading: loading,
            errorMessage: errorMessage,
          ),
        ],
      ),
    );
  }
}

Widget _filterChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFE0C2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFFFF6B35) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.brown.shade700,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    ),
  );
}

class _HomeEventStripCard extends StatelessWidget {
  const _HomeEventStripCard({required this.event});

  final EventListItem event;

  @override
  Widget build(BuildContext context) {
    final url = event.primaryImageUrl;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => EventsDetailsPage(
              event: event.toDetailMap(),
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: url != null
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _purplePlaceholder(),
                      )
                    : _purplePlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                '${event.formattedStart}\n${event.location}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A6F66)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purplePlaceholder() {
    return Container(
      color: const Color(0xFF9D7CD4),
    );
  }
}

class _PlaceholderEventCard extends StatelessWidget {
  const _PlaceholderEventCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF9D7CD4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A6F66)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFCF8C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event posters',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
                ),
                SizedBox(height: 4),
                Text(
                  'Want to become an event poster?\nSubmit your application here',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A6F66)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
