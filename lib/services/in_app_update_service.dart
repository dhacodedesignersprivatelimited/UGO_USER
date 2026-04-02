import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service to manage Google Play In-App Updates for UGO_USER.
class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  bool _isUpdateCheckInProgress = false;
  static bool _androidPlayUpdateUnavailable = false;

  bool get _shouldSkipAndroidOta =>
      !kIsWeb && Platform.isAndroid && _androidPlayUpdateUnavailable;

  /// Check for updates via Google Play In-App Update API
  Future<void> checkForUpdate({bool forceImmediate = false}) async {
    if (kIsWeb) return;
    if (_shouldSkipAndroidOta) return;
    if (_isUpdateCheckInProgress) return;

    _isUpdateCheckInProgress = true;
    try {
      debugPrint('UGO_USER_OTA: Checking for Google Play updates...');
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (forceImmediate || info.immediateUpdateAllowed) {
          debugPrint('UGO_USER_OTA: Performing Immediate Update...');
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          debugPrint('UGO_USER_OTA: Performing Flexible Update...');
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else {
        debugPrint('UGO_USER_OTA: No update available via Play Store API');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('-10') || msg.contains('APP_NOT_OWNED')) {
        _androidPlayUpdateUnavailable = true;
      }
      debugPrint('UGO_USER_OTA_ERROR: Failed to check for in-app update: $e');
    } finally {
      _isUpdateCheckInProgress = false;
    }
  }

  /// Check and handle updates that were previously downloaded but not installed
  Future<void> checkRemainingUpdate() async {
    if (kIsWeb) return;
    if (_shouldSkipAndroidOta) return;
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.installStatus == InstallStatus.downloaded) {
        debugPrint('UGO_USER_OTA: Completing previously downloaded update...');
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('UGO_USER_OTA_ERROR: Failed to check remaining update: $e');
    }
  }
}
