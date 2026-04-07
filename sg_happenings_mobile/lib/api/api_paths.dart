/// FastAPI route segments (relative to [ApiConfig.baseUrl]).
abstract final class ApiPaths {
  static const health = '/health';
  static const authLogin = '/auth/login';
  /// Current user profile (JWT). Used to detect event-poster role.
  static const usersMe = '/users/me';
  static const events = '/events';
  static const uploadsEventMedia = '/uploads/event-media';
  static const categories = '/categories';

  /// Authenticated event poster: approved / live events this user manages.
  static const eventPosterEvents = '/event-poster/events';
  /// Pending moderation queue for this poster.
  static const eventPosterPending = '/event-poster/submissions/pending';
  /// Past submissions (approved/rejected/published).
  static const eventPosterHistory = '/event-poster/submissions/history';

  /// New event submissions (moderation queue; starts as Pending).
  static const eventApplications = '/event-applications';

  static String eventById(String id) => '/events/$id';

  /// When pending rows use `submission_id` and deletes go through applications, not `/events`.
  static String eventApplicationById(String id) => '/event-applications/$id';
}
