import 'package:flutter/material.dart';
import '../notifications/notifications_page.dart';
import '../event_poster_application/event_poster_application.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EEDC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: notifications and profile icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                    child: const Icon(Icons.notifications_none_rounded, color: Colors.brown),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE9C8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person, color: Colors.brown),
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
              // Search bar
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
              // Map promo card
              _MapCard(),

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

              // Filter chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Trending now', highlighted: true),
                    _chip('Music'),
                    _chip('Art'),
                    _chip('Food'),
                    _chip('More'),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Horizontal event cards
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _EventCard(title: 'Live Concert', subtitle: 'Today · 7:00 PM\nDowntown'),
                    SizedBox(width: 12),
                    _EventCard(title: 'Jazz Night', subtitle: 'Apr 20 · 8:00 PM\nJazz Club'),
                    SizedBox(width: 12),
                    _EventCard(title: 'Art Exhibition', subtitle: 'Apr 18 · 11:00 AM\nArt Gallery'),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Event posters promo tile
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
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
    );
  }
}

class _MapCard extends StatelessWidget {
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
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFCFE8E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Map preview', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _chip(String label, {bool highlighted = false}) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xFFFFE0C2) : Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: Colors.brown.shade700,
        fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
      ),
    ),
  );
}

class _EventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EventCard({required this.title, required this.subtitle});

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
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7A6F66)),
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



