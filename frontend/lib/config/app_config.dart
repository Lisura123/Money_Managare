import 'dart:io' show Platform;

class AppConfig {
  // ─── Base URL ──────────────────────────────────────────────────────────────
  // For emulators/simulators, the host machine's localhost is resolved via
  // platform-specific aliases. For real devices, set _realDeviceIp to your
  // computer's LAN IP (e.g. '192.168.1.5') and run the backend with:
  //   php artisan serve --host=0.0.0.0 --port=8000
  // Then switch _useRealDevice to true.
  static const bool _useRealDevice = false;
  static const String _realDeviceIp = '192.168.1.5'; // ← update this

  static String get baseUrl {
    if (_useRealDevice) {
      return 'http://$_realDeviceIp:8000/api';
    }
    // Android emulator uses 10.0.2.2 to reach host machine localhost.
    // iOS simulator uses localhost directly.
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 15;
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  static const String appName = 'Money Manager';
  static const String appVersion = '1.0.0';
  static const String currencyPrefix = 'Rs.';
}
