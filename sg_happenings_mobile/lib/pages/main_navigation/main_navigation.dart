import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/poster_role_resolver.dart';
import '../events/events_page.dart';
import '../home/home_page.dart';
import '../poster_dashboard/poster_dashboard_page.dart';
import '../profile/profile_page.dart';

/// Bottom shell: **Dashboard** tab only when `role` is **Event Poster** (see [UserMe]).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _roleLoaded = false;
  bool _isEventPoster = false;

  @override
  void initState() {
    super.initState();
    final cached = authTokenStore.isEventPosterCached;
    if (cached != null) {
      _isEventPoster = cached;
      _roleLoaded = true;
    }
    _loadRole();
  }

  Future<void> _loadRole() async {
    final poster = await resolveEventPosterRole();
    if (!mounted) return;
    setState(() {
      _isEventPoster = poster;
      _roleLoaded = true;
    });
  }

  List<Widget> get _pages {
    if (_isEventPoster) {
      return const [
        HomePage(),
        EventsPage(),
        PosterDashboardPage(),
        ProfilePage(),
      ];
    }
    return const [
      HomePage(),
      EventsPage(),
      ProfilePage(),
    ];
  }

  int get _profileIndex => _isEventPoster ? 3 : 2;

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = _pages;
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.event_rounded, 'Events', 1),
            if (_isEventPoster)
              _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 2),
            _buildNavItem(Icons.person_rounded, 'Profile', _profileIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? const Color(0xFFFF6B35) : Colors.brown;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            if (isSelected)
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
