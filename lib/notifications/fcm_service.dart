// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/auto_book/auto_book_widget.dart';
import '/flutter_flow/nav/nav.dart';
import '/ridecomplete/ridecomplete_widget.dart';

/// Background message handler - MUST be top-level function.
/// Runs when app is in background/terminated and a data message is received.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('🔔 [FCM Background] ${message.messageId}: ${message.data}');
  }
  // No navigation possible here - runs in separate isolate.
  // User tap will trigger onMessageOpenedApp or getInitialMessage.
}

/// FCM payload keys (backend may use different conventions).
const _kRideId = 'ride_id';
const _kRideIdAlt = 'rideId';
const _kRideIdAlt2 = 'rideID';
const _kType = 'type';
const _kTypeAlt = 'event';
const _kTypeAlt2 = 'action';

/// Ride-related notification types that should open AutoBook.
const _kRideEventTypes = {
  'driver_assigned',
  'accepted',
  'arriving',
  'arrived',
  'started',
  'picked_up',
  'in_progress',
  'ontrip',
};

/// Completion types that should open Ride Complete.
const _kCompletedTypes = {'completed', 'complete'};

/// Extracts ride ID from FCM data payload.
int? _getRideId(Map<String, dynamic> data) {
  final raw = data[_kRideId] ?? data[_kRideIdAlt] ?? data[_kRideIdAlt2];
  if (raw == null) return null;
  if (raw is int) return raw;
  return int.tryParse(raw.toString());
}

/// Extracts event/type from FCM data payload.
String? _getEventType(Map<String, dynamic> data) {
  final raw = data[_kType] ?? data[_kTypeAlt] ?? data[_kTypeAlt2];
  if (raw == null) return null;
  return raw.toString().toLowerCase().trim();
}

/// Handles navigation for ride-related push notifications.
void _handleRideNotification(
  GoRouter router,
  int rideId,
  String? eventType,
) {
  if (_kCompletedTypes.contains(eventType)) {
    router.goNamed(
      RidecompleteWidget.routeName,
      queryParameters: {'rideId': rideId.toString()},
    );
    return;
  }
  if (_kRideEventTypes.contains(eventType) || eventType == null) {
    router.pushNamed(
      AutoBookWidget.routeName,
      queryParameters: {'rideId': rideId.toString()},
    );
  }
}

/// Sets up Firebase Cloud Messaging handlers.
/// Call from [MyApp.initState] after router is created.
void setupFirebaseMessaging(GoRouter router) {
  final messaging = FirebaseMessaging.instance;

  // 0. Get and store FCM token for backend
  messaging.getToken().then((token) {
    if (token != null && token.isNotEmpty) {
      FFAppState().fcmToken = token;
      if (kDebugMode) {
        print('🔔 FCM Token: ${token.substring(0, 20)}...');
      }
    }
  });
  messaging.onTokenRefresh.listen((token) {
    FFAppState().fcmToken = token;
    if (kDebugMode) {
      print('🔔 FCM Token refreshed');
    }
  });

  // 1. Request permission (iOS, Android 13+)
  if (!kIsWeb) {
    messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    ).then((s) {
      if (kDebugMode) {
        print('🔔 FCM Permission: $s');
      }
    });
  }

  // 2. Foreground messages - show in-app or rely on existing socket
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 [FCM Foreground] ${message.notification?.title ?? message.messageId}');
    }
    final data = message.data;
    if (data.isEmpty) return;

    final rideId = _getRideId(data);
    final eventType = _getEventType(data);

    if (rideId != null) {
      // Update booking state so Home knows we have an active ride
      FFAppState().currentRideId = rideId;
      FFAppState().bookingInProgress = true;

      final currentLocation = router.getCurrentLocation();
      final alreadyOnRide = currentLocation.contains('autoBook') || currentLocation.contains('auto-book');
      final alreadyOnComplete = currentLocation.contains('ridecomplete');

      if (!alreadyOnRide && !alreadyOnComplete) {
        _handleRideNotification(router, rideId, eventType);
      }
    }
  });

  // 3. User tapped notification (app was in background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 [FCM OpenedApp] ${message.data}');
    }
    final data = message.data;
    if (data.isEmpty) return;

    final rideId = _getRideId(data);
    final eventType = _getEventType(data);

    if (rideId != null && FFAppState().userid != 0) {
      FFAppState().currentRideId = rideId;
      FFAppState().bookingInProgress = true;
      _handleRideNotification(router, rideId, eventType);
    }
  });

  // 4. App launched from terminated state via notification tap
  messaging.getInitialMessage().then((RemoteMessage? message) {
    if (message == null) return;
    if (kDebugMode) {
      print('🔔 [FCM Initial] ${message.data}');
    }
    final data = message.data;
    if (data.isEmpty) return;

    final rideId = _getRideId(data);
    final eventType = _getEventType(data);

    if (rideId != null && FFAppState().userid != 0) {
      FFAppState().currentRideId = rideId;
      FFAppState().bookingInProgress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRideNotification(router, rideId, eventType);
      });
    }
  });
}
