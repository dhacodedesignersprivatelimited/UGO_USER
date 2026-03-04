import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Payment configuration handler
class PaymentConfig {
  static final PaymentConfig _instance = PaymentConfig._internal();

  factory PaymentConfig() {
    return _instance;
  }

  PaymentConfig._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Initialize Firebase Remote Config
  Future<void> initialize() async {
    if (_initialized) return;

    _remoteConfig = FirebaseRemoteConfig.instance;

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Set default values (fallback)
    await _remoteConfig.setDefaults({
      'razorpay_key': 'rzp_test_SAvHgTPEoPnNo7', // Fallback test key
    });

    try {
      // Fetch and activate remote config
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error fetching remote config: $e');
    }

    _initialized = true;
  }

  /// Get Razorpay key from Firebase Remote Config
  String getRazorpayKey() {
    try {
      return _remoteConfig.getString('razorpay_key');
    } catch (e) {
      print('Error getting Razorpay key: $e');
      return 'rzp_test_SAvHgTPEoPnNo7'; // Fallback
    }
  }
}
