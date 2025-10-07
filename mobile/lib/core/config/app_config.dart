/// Application Configuration
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://3.107.205.176:8080/api/v1',
  );
  
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false, // true=Enable Mock mode, false=Use real API data
  );
  
  // Network timeout configuration
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Pagination configuration
  static const int defaultPageSize = 20;
  
  // Search debounce configuration
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);
}
