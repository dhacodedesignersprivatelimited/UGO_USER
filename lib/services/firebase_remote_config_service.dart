import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service to manage Firebase Remote Config for UGO_USER.
/// Shared with Driver app for consistency.
class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfigService _instance =
      FirebaseRemoteConfigService._internal();
  factory FirebaseRemoteConfigService() => _instance;
  FirebaseRemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;
  late Future<void> _initializeFuture;

  /// Initialize Firebase Remote Config with default values
  Future<void> initialize() async {
    if (_initialized) return;
    _initializeFuture = _doInitialize();
    await _initializeFuture;
  }

  Future<void> _doInitialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default values (fallback if remote config fails).
      await _remoteConfig!.setDefaults(const {
        'razorpay_key_id': '',
        'razorpay_enabled': true,
        'google_maps_api_key': '',
        'play_store_url': 'https://play.google.com/store/apps/details?id=com.ugotaxi_rajkumar.user',
        'is_update_mandatory': false,
        'latest_app_version': '1.0.0',
        'min_required_version': '1.0.0',
      });

      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();

      _initialized = true;
      if (kDebugMode) {
        print('✅ Firebase Remote Config initialized successfully (User App)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Remote Config initialization error: $e');
      }
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _initializeFuture;
  }

  String getString(String key, {String defaultValue = ''}) {
    try {
      return _remoteConfig?.getString(key) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig?.getBool(key) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  String get latestAppVersion =>
      getString('latest_app_version', defaultValue: '1.0.0');

  String get minRequiredVersion =>
      getString('min_required_version', defaultValue: '1.0.0');

  String get playStoreUrl => getString('play_store_url', defaultValue: '');
}
