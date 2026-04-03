import 'package:flutter/foundation.dart';

import '/ride_request/ride_request_screen.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/login/login_widget.dart';

/// Fetches the user's active ride from the backend and opens [RideRequestScreen] when needed.
/// Used on cold start (Home) and when the app returns to foreground so riders don't stay on Home
/// during an ongoing trip.
class ActiveRideNavigation {
  ActiveRideNavigation._();

  static DateTime? _lastRun;
  static bool _inFlight = false;

  /// Returns the pending-rides API response when a call was made (for Home model / UI).
  static Future<ApiCallResponse?> tryOpenActiveRideFromApi(
      GoRouter router) async {
    if (_inFlight) return null;
    final now = DateTime.now();
    if (_lastRun != null &&
        now.difference(_lastRun!) < const Duration(milliseconds: 800)) {
      return null;
    }
    _lastRun = now;
    _inFlight = true;

    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty || FFAppState().userid == 0) return null;

      final loc = router.getCurrentLocation();
      if (loc.contains('autoBook') ||
          loc.contains('auto-book') ||
          loc.contains('rideRequest') ||
          loc.contains('ride-request') ||
          loc.contains('ridecomplete') ||
          loc.contains('ride-complete')) {
        return null;
      }

      final response = await GetRideStatus.call(
        userId: FFAppState().userid,
        token: token,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        FFAppState().clearAuthSession();
        router.goNamed(LoginWidget.routeName);
        return response;
      }

      if (!response.succeeded) return response;

      final rideList = getJsonField(response.jsonBody, r'''$.data.rides''');
      if (rideList == null || rideList is! List || rideList.isEmpty) {
        FFAppState().bookingInProgress = false;
        return response;
      }

      final activeRide = rideList.first;
      if (activeRide is! Map) return response;

      final rideId = activeRide['id'] ?? activeRide['ride_id'];
      final statusRaw = activeRide['ride_status'] ?? activeRide['status'];
      final status = statusRaw?.toString().toLowerCase();

      const terminal = {
        'completed',
        'complete',
        'cancelled',
        'canceled',
        'cancelled_by_user',
      };
      if (status != null && terminal.contains(status)) {
        FFAppState().bookingInProgress = false;
        return response;
      }

      const activeStatuses = {
        'searching',
        'driver_assigned',
        'accepted',
        'arriving',
        'arrived',
        'picked_up',
        'started',
        'in_progress',
        'ontrip',
        'on_trip',
        'qr_scanned',
        'qr-scanned',
        'qr scanned',
      };

      final isActive = status == null || activeStatuses.contains(status);
      if (rideId == null || !isActive) {
        FFAppState().bookingInProgress = false;
        return response;
      }

      final id = rideId is int ? rideId : int.tryParse(rideId.toString());
      if (id == null || id <= 0) return response;

      FFAppState().bookingInProgress = true;
      FFAppState().currentRideId = id;

      router.pushNamed(
        RideRequestScreen.routeName,
        queryParameters: {'rideId': id.toString()},
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ActiveRideNavigation.tryOpenActiveRideFromApi: $e');
      }
      return null;
    } finally {
      _inFlight = false;
    }
  }
}
