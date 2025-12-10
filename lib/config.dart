  /// Prefer overriding at run time:
/// flutter run --dart-define=API_BASE_URL=https://mtvts-backend.onrender.com/api
const String _productionApiBaseUrl = 'https://mtvts-backend-3jjy.onrender.com/index.php/api';
const String _envApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

/// Use this getter everywhere (e.g., ApiClient(baseUrl: apiBaseUrl))
String get apiBaseUrl {
  // 1) If provided via --dart-define, always use it.
  if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;

  // 2) Default to the deployed backend so the app works online without LAN IPs.
  return _productionApiBaseUrl;
}
