import 'auth_repository.dart';
import 'auth_token_store.dart';
import 'events_repository.dart';
import 'sg_api_client.dart';

final AuthTokenStore authTokenStore = AuthTokenStore();

final SgApiClient sgApiClient = SgApiClient(tokenStore: authTokenStore);

final AuthRepository authRepository = AuthRepository(sgApiClient, authTokenStore);

final EventsRepository eventsRepository = EventsRepository(sgApiClient);
