import 'api_config.dart';
import 'app_api.dart';

/// Headers for [VideoPlayerController] only. Same-origin as [ApiConfig.baseUrl]
/// gets `Authorization: Bearer …`; external hosts (e.g. S3) get none.
Map<String, String> playbackVideoHeadersForUrl(String absoluteUrl) {
  try {
    final media = Uri.parse(absoluteUrl);
    final api = Uri.parse(ApiConfig.baseUrl);
    if (media.host.isEmpty) return const {};
    final sameOrigin = media.scheme == api.scheme &&
        media.host == api.host &&
        media.port == api.port;
    if (!sameOrigin) {
      return const {};
    }
  } catch (_) {
    return const {};
  }
  final t = authTokenStore.accessToken;
  if (t == null || t.isEmpty) return const {};
  return {'Authorization': 'Bearer $t'};
}
