/// FastAPI route segments (relative to [ApiConfig.baseUrl]).
abstract final class ApiPaths {
  static const health = '/health';
  static const authLogin = '/auth/login';
  static const events = '/events';
  static const uploadsEventMedia = '/uploads/event-media';
}
