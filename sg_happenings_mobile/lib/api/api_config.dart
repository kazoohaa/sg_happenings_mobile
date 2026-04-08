import 'api_config_io.dart' if (dart.library.html) 'api_config_web.dart' as platform;

/// Resolves the FastAPI base URL for dev (Docker DB is only reached by the API, not the app).
///
/// Overrides (highest priority first):
/// - [API_BASE_URL] — full origin, e.g. `http://192.168.1.10:8000` or `https://api.example.com`
/// - [API_HOST] — host only; port from [API_PORT] (default `8000`)
///
/// Defaults when unset:
/// - Web: `http://localhost:8000`
/// - Android emulator: `http://10.0.2.2:8000`
/// - iOS simulator / desktop: `http://127.0.0.1:8000`
///
/// Physical phone: `flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000`
///
/// **LLM keys (OpenAI, Anthropic, …):** configure those only on your **FastAPI server**
/// (environment variables), not in this app. The app calls your `/chat` route; the server
/// calls the LLM with the secret key.
///
/// **Optional app key:** if your backend expects an extra header (e.g. `X-API-Key`) from
/// mobile clients, pass it at build/run time (still not ideal for highly sensitive secrets):
/// `flutter run --dart-define=SERVICE_API_KEY=your_key`
abstract final class ApiConfig {
  static const String _fromEnvFull = String.fromEnvironment('API_BASE_URL');
  static const String _fromEnvHost = String.fromEnvironment('API_HOST');
  static const String _fromEnvPort = String.fromEnvironment('API_PORT', defaultValue: '8000');

  /// Sent as `X-API-Key` on every request when non-empty (see class doc above).
  static const String serviceApiKey = String.fromEnvironment('SERVICE_API_KEY');

  static String get baseUrl {
    final full = _fromEnvFull.trim();
    if (full.isNotEmpty) {
      return full.replaceAll(RegExp(r'/+$'), '');
    }
    final hostOverride = _fromEnvHost.trim();
    final host = hostOverride.isNotEmpty ? hostOverride : platform.defaultApiHost();
    return 'http://$host:$_fromEnvPort';
  }
}
