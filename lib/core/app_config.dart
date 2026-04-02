/// Centralized app configuration singleton.
/// Holds API URLs, API keys, default locations - single source of truth.
class AppConfig {
  AppConfig._();

  static final AppConfig _instance = AppConfig._();
  static AppConfig get instance => _instance;

  /// Production default; override when pointing at another environment:
  /// `flutter run --dart-define=BASE_API_URL=https://your-host.example`
  static const String baseApiUrl = String.fromEnvironment(
    'BASE_API_URL',
    defaultValue: 'https://ugo-api.icacorp.org',
  );

  /// Absolute URL for relative upload paths (`uploads/...`).
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final t = path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = baseApiUrl.endsWith('/')
        ? baseApiUrl.substring(0, baseApiUrl.length - 1)
        : baseApiUrl;
    final rel = t.startsWith('/') ? t : '/$t';
    return '$base$rel';
  }

  // Google Maps
  static const String googleMapsApiKey =
      'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y';

  // Gemini AI Key
  static const String geminiApiKey = 'AIzaSyAwr7Gln5DxZKu7Ngxi0CE3Obaso1J8IxE';

  /// Default map center (Hyderabad)
  static const double defaultLat = 17.385044;
  static const double defaultLng = 78.486671;

  String get imageBaseUrl => '$baseApiUrl/';
  String get apiUrl => baseApiUrl;
}
