import 'dart:io' show Platform;

enum Environment { dev, production }

class AppConfig {
  // ─── Environment ───────────────────────────────────────────────────────────
  // Build with:  flutter build ipa --dart-define=ENV=production
  // Default:     dev (localhost for emulators/simulators)
  static const _envString = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const environment =
      _envString == 'production' ? Environment.production : Environment.dev;

  // ─── Production URL ────────────────────────────────────────────────────────
  // Replace with your actual production server URL.
  static const String _productionUrl = 'https://money.cameralkstore.com/api';

  // ─── Dev: real device LAN IP ───────────────────────────────────────────────
  static const bool _useRealDevice = false;
  static const String _realDeviceIp = '192.168.1.5';

  static String get baseUrl {
    if (environment == Environment.production) {
      return _productionUrl;
    }
    if (_useRealDevice) {
      return 'http://$_realDeviceIp:8000/api';
    }
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
