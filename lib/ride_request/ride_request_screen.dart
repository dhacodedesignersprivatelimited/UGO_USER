import 'package:flutter/material.dart';

import '/auto_book/auto_book_widget.dart';

/// Canonical screen for Rapido-style ride request: searching, driver match, and trip tracking.
///
/// Delegates to [AutoBookWidget]. Prefer [routeName] / [routePath] for navigation so all
/// entry points (booking, FCM, resume) stay aligned; legacy `/autoBook` remains registered.
class RideRequestScreen extends StatelessWidget {
  const RideRequestScreen({
    super.key,
    required this.rideId,
    this.initialRideStatus,
    this.totalDistanceKm,
    this.totalDuration,
  });

  final int rideId;
  final String? initialRideStatus;
  final double? totalDistanceKm;
  final String? totalDuration;

  static const String routeName = 'ride-request';
  static const String routePath = '/rideRequest';

  @override
  Widget build(BuildContext context) {
    return AutoBookWidget(
      rideId: rideId,
      initialRideStatus: initialRideStatus,
      totalDistanceKm: totalDistanceKm,
      totalDuration: totalDuration,
    );
  }
}
