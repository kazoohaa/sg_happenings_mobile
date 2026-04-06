/// Current user from `GET /users/me` or `GET /auth/me` (shape varies by backend).
///
/// Event posters are identified by [role] matching **`Event Poster`** (Postgres `varchar`),
/// case-insensitive, normalized spaces. Other roles (`Admin`, `User`, …) are not posters.
class UserMe {
  const UserMe({
    required this.isEventPoster,
    this.username,
    this.email,
  });

  final bool isEventPoster;
  final String? username;
  final String? email;

  /// Normalizes a role string for comparison (trim, lowercase, single spaces).
  static String normalizeRole(String? raw) {
    if (raw == null) return '';
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// `true` only when [raw] is the **Event Poster** role (matches DB `Event Poster`).
  static bool matchesEventPosterRole(String? raw) {
    return normalizeRole(raw) == 'event poster';
  }

  /// Explicit poster flag from JSON only. Used for login/JWT hints.
  /// Returns null when the payload does not clearly state poster status.
  static bool? inferExplicitPosterFlag(Map<String, dynamic> json) {
    if (json['is_event_poster'] == true) return true;
    if (json['is_event_poster'] == false) return false;
    final roleStr = json['role']?.toString();
    if (roleStr != null && roleStr.trim().isNotEmpty) {
      if (matchesEventPosterRole(roleStr)) return true;
      if (_isKnownNonPosterRole(roleStr)) return false;
    }
    final user = json['user'];
    if (user is Map) {
      return inferExplicitPosterFlag(Map<String, dynamic>.from(user));
    }
    return null;
  }

  static bool _isKnownNonPosterRole(String raw) {
    final n = normalizeRole(raw);
    return n == 'admin' || n == 'user';
  }

  factory UserMe.fromJson(Map<String, dynamic> json) {
    bool poster = json['is_event_poster'] == true;
    if (!poster) {
      if (matchesEventPosterRole(json['role']?.toString())) {
        poster = true;
      }
    }
    if (!poster) {
      final roles = json['roles'];
      if (roles is List) {
        for (final r in roles) {
          if (matchesEventPosterRole(r.toString())) {
            poster = true;
            break;
          }
        }
      }
    }
    return UserMe(
      isEventPoster: poster,
      username: json['username'] as String? ?? json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}
