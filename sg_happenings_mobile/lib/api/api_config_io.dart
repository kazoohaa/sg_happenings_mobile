import 'dart:io';

/// Hostname for the FastAPI server when no `API_BASE_URL` / `API_HOST` override is set.
String defaultApiHost() {
  if (Platform.isAndroid) {
    // Android emulator: forwards to the host machine's loopback.
    // Physical device: use --dart-define=API_BASE_URL= or API_HOST= with your PC's LAN IP.
    return '10.0.2.2';
  }
  return '127.0.0.1';
}
