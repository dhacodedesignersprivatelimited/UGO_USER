/// Centralized app configuration singleton.
/// Holds API URLs, API keys, default locations - single source of truth.
class AppConfig {
  AppConfig._();

  static final AppConfig _instance = AppConfig._();
  static AppConfig get instance => _instance;

  // API
  static const String baseApiUrl = 'https://ugo-api.icacorp.org';
 //static const String baseApiUrl = 'https://ugotaxi.icacorp.org';
  // Google Maps
  static const String googleMapsApiKey =
      'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y';

  /// Default map center (Hyderabad)
  static const double defaultLat = 17.385044;
  static const double defaultLng = 78.486671;

  String get imageBaseUrl => '$baseApiUrl/';
  String get apiUrl => baseApiUrl;
}
