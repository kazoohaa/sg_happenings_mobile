import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/user_me.dart';
import '../../api/users_repository.dart';
import '../edit_profile/edit_profile_page.dart';
import '../login/login_page.dart';

/// Profile hub. Use [showBackButton] when opened from another screen (e.g. home);
/// keep default when shown as the main shell tab.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserMe> _meFuture;

  @override
  void initState() {
    super.initState();
    _meFuture = usersRepository.getMe();
  }

  void _retryLoad() {
    setState(() {
      _meFuture = usersRepository.getMe();
    });
  }

  /// Shown when [getMe] fails — usually 401, missing `/users/me`, or network.
  String _loadErrorLine(Object error) {
    if (error is UsersApiException) return error.message;
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EEDC),
      appBar: widget.showBackButton
          ? AppBar(
              backgroundColor: const Color(0xFFF7EEDC),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.brown),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        top: !widget.showBackButton,
        child: ValueListenableBuilder<int>(
          valueListenable: authTokenStore.posterApplicationPendingRevision,
          builder: (context, _, __) {
            return FutureBuilder<UserMe>(
              future: _meFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.brown));
                }
                final me = snapshot.data;
                final error = snapshot.error;
                final displayName = me?.username?.trim().isNotEmpty == true
                    ? me!.username!
                    : (me?.email?.trim().isNotEmpty == true ? me!.email! : 'Profile');
                final subtitle = me?.email != null && me!.email!.trim().isNotEmpty
                    ? me.email
                    : (error != null ? _loadErrorLine(error) : null);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (!widget.showBackButton) const SizedBox(height: 24),
                      const SizedBox(height: 16),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE9C8),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(Icons.person, size: 50, color: Colors.brown),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: error != null ? Colors.red.shade700 : const Color(0xFF7A6F66),
                          ),
                        ),
                      ],
                      if (_showPendingPosterBanner(me)) ...[
                        const SizedBox(height: 16),
                        _pendingPosterStatusCard(),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _retryLoad,
                          icon: const Icon(Icons.refresh, color: Colors.brown),
                          label: const Text('Retry', style: TextStyle(color: Colors.brown)),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildProfileOption(context, Icons.person_outline, 'Edit Profile'),
                      _buildProfileOption(context, Icons.settings_outlined, 'Settings'),
                      _buildProfileOption(context, Icons.help_outline, 'Help & Support'),
                      _buildProfileOption(context, Icons.logout, 'Logout'),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _showPendingPosterBanner(UserMe? me) {
    if (!authTokenStore.hasPendingPosterApplicationSubmitted) return false;
    if (me?.isEventPoster == true) return false;
    return true;
  }

  Widget _pendingPosterStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0C2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade800, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event poster application',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.brown.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted — pending review. We will update you when it is processed.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          if (title == 'Edit Profile') {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const EditProfilePage(),
              ),
            );
          } else if (title == 'Logout') {
            authRepository.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (context) => const LoginPage(),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
