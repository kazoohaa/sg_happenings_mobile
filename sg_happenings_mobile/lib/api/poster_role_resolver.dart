import 'app_api.dart';
import 'jwt_payload.dart';
import 'user_me.dart';

/// Whether the signed-in user is an event poster (profile, cache, then JWT).
Future<bool> resolveEventPosterRole() async {
  try {
    final me = await usersRepository.getMe();
    await authTokenStore.setEventPoster(me.isEventPoster);
    return me.isEventPoster;
  } catch (_) {
    if (authTokenStore.isEventPosterCached == true) {
      return true;
    }
    final token = authTokenStore.accessToken;
    final payload = token != null ? decodeJwtPayload(token) : null;
    if (payload != null) {
      final explicit = UserMe.inferExplicitPosterFlag(payload);
      if (explicit == true) {
        await authTokenStore.setEventPoster(true);
        return true;
      }
      if (explicit == false) {
        await authTokenStore.setEventPoster(false);
        return false;
      }
      final inferred = UserMe.fromJson(payload).isEventPoster;
      await authTokenStore.setEventPoster(inferred);
      return inferred;
    }
    return false;
  }
}
