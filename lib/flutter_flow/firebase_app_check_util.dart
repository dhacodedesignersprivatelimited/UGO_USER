import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

Future initializeFirebaseAppCheck() async {
  try {
    if (kDebugMode) {
      // Debug mode: Use the debug provider so App Check tokens are valid.
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      debugPrint(
        '✅ Debug App Check activated (register the debug token in Firebase)',
      );
    } else {
      // Production: Enable real validation providers
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
      debugPrint('✅ Production App Check activated with Play Integrity');
    }
  } catch (e) {
    debugPrint('⚠️ App Check initialization error: $e (proceeding anyway)');
  }
}
