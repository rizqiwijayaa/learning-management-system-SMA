import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _defaultApiBaseUrl = 'http://192.168.100.104:3000/api';

  static String get baseUrl {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (apiBaseUrl.isNotEmpty) {
      return apiBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    return _defaultApiBaseUrl;
  }
}
