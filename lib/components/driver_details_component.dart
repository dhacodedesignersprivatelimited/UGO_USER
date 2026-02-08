import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import 'dart:math';

class DriverDetailsComponent extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? driverDetails;
  final String? rideOtp;
  final List<dynamic> ridesCache;
  final Function(String?) onCall;
  final VoidCallback onCancel;
  final String rideStatus;
  final double? currentRemainingDistance; // ✅ Real-time distance from parent

  static const Color primaryColor = Color(0xFFFF7B10);

  const DriverDetailsComponent({
    Key? key,
    required this.isLoading,
    required this.driverDetails,
    required this.rideOtp,
    required this.ridesCache,
    required this.onCall,
    required this.onCancel,
    required this.rideStatus,
    this.currentRemainingDistance,
  }) : super(key: key);

  // --- Utility Functions ---
  double _calculateDistanceKm(double startLat, double startLng, double endLat, double endLng) {
    const double earthRadius = 6371; // km
    double dLat = _degToRad(endLat - startLat);
    double dLng = _degToRad(endLng - startLng);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(startLat)) * cos(_degToRad(endLat)) * sin(dLng / 2) * sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  int _calculateEtaMinutes(double distanceKm) {
    const double avgSpeed = 30; // km/h (city average)
    double hours = distanceKm / avgSpeed;
    return (hours * 60).round();
  }

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    // Normalization: Ensure we check against lowercase standard statuses
    final status = rideStatus.toLowerCase().trim();

    // Status Groups
    final isArriving = status == 'arriving';
    final isAccepted = status == 'accepted' || status == 'driver_assigned';
    final isStarted = status == 'started' || status == 'picked_up' || status == 'in_progress';

    if (isLoading || driverDetails == null) {
      return Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    // Extract Data
    final driverName = GetDriverDetailsCall.name(driverDetails) ?? 'Captain';
    final driverRating = GetDriverDetailsCall.rating(driverDetails) ?? '4.8';
    final vehicleNumber = GetDriverDetailsCall.vehicleNumber(driverDetails) ?? 'AP28TA1234';
    final driverPhone = DriverIdfetchCall.mobileNumber(driverDetails);

    final pickupLat = FFAppState().pickupLatitude;
    final pickupLng = FFAppState().pickupLongitude;

    String? driverImage;
    try {
      driverImage = driverDetails?['profile_photo'] ??
          driverDetails?['profile_image'] ??
          driverDetails?['photo'] ??
          driverDetails?['image'];
    } catch (_) {}

    // ✅ OTP Logic: Only show if accepted or arriving. HIDE if ride already started.
    List<String> otpDigits = [];
    bool showOtp = (isAccepted || isArriving) && !isStarted;

    if (showOtp && rideOtp != null && rideOtp!.isNotEmpty) {
      otpDigits = rideOtp!.padRight(4, '-').split('').take(4).toList();
    }

    // ✅ Arriving Distance Logic
    double? driverLatDouble;
    double? driverLngDouble;
    double? arrivingDistance;
    int? arrivingEta;

    // Ride Cache Data
    String pickup = 'Pickup Location';
    String dropoff = 'Drop Location';
    String originalDistance = '--km';
    String amount = '₹--';

    if (ridesCache.isNotEmpty) {
      final ride = ridesCache[0];
      pickup = ride['pickup_location_address'] ?? pickup;
      dropoff = ride['drop_location_address'] ?? dropoff;
      amount = '₹${ride['estimated_fare'] ?? '--'}';
      originalDistance = '${ride['ride_distance_km'] ?? '--'}km';
      driverLatDouble = double.tryParse(ride['driver_latitude']?.toString() ?? '');
      driverLngDouble = double.tryParse(ride['driver_longitude']?.toString() ?? '');
    }

    // Calculate arrival distance if logic permits
    if (isArriving && driverLatDouble != null && driverLngDouble != null && pickupLat != null && pickupLng != null) {
      arrivingDistance = _calculateDistanceKm(driverLatDouble, driverLngDouble, pickupLat, pickupLng);
      arrivingEta = _calculateEtaMinutes(arrivingDistance);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // --- 1. Status Banners ---

          if (isArriving) ...[
            _buildStatusBanner(
              icon: Icons.car_rental,
              text: 'Driver is on the way',
              color: Colors.blue,
            ),
            if (arrivingDistance != null && arrivingEta != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row( // Changed to Row for cleaner look
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${arrivingDistance.toStringAsFixed(1)} km away',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.blue),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      height: 12, width: 1, color: Colors.blue,
                    ),
                    Text(
                      '~ $arrivingEta min',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          if (isStarted) ...[
            _buildStatusBanner(
              icon: Icons.navigation,
              text: 'Ride Started - En Route',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
          ],

          // --- 2. OTP Section ---
          if (otpDigits.isNotEmpty) ...[
            _buildOtpContainer(otpDigits),
            const SizedBox(height: 20),
          ],

          // --- 3. Driver Info Card ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: driverImage != null && driverImage.isNotEmpty
                          ? Image.network(
                        driverImage,
                        width: 60, height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                      )
                          : _buildPlaceholderAvatar(),
                    ),
                    const SizedBox(width: 12),

                    // Name & Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driverName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(
                                " $driverRating",
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 4, height: 4,
                                decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                              ),
                              Text(
                                vehicleNumber,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Call Button
                    InkWell(
                      onTap: () => onCall(driverPhone?.toString()),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),

                // Live Distance (Only when Started)
                if (isStarted && currentRemainingDistance != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.near_me, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Destination Distance:',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.green[800]),
                            ),
                          ],
                        ),
                        Text(
                          '${currentRemainingDistance!.toStringAsFixed(1)} km',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.green[900]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 4. Trip Details ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildLocationRow(Icons.radio_button_checked, Colors.green, pickup),
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(height: 16, child: VerticalDivider(width: 20, color: Colors.grey)),
                  ),
                ),
                _buildLocationRow(Icons.location_on, Colors.red, dropoff),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Distance', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                        Text(originalDistance, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Fare', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                        Text(amount, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 5. Cancel Button (Hide if started) ---
          if (!isStarted)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  'Cancel Ride',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Sub-Widgets ---

  Widget _buildStatusBanner({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.person, size: 30, color: Colors.grey),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multi-line text
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpContainer(List<String> otpDigits) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text("Share OTP with Driver", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: otpDigits.map((digit) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(
                digit,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
