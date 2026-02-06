import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/api_requests/api_calls.dart';

class DriverDetailsComponent extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? driverDetails;
  final String? rideOtp;
  final List<dynamic> ridesCache;
  final Function(String?) onCall;
  final VoidCallback onCancel;
  final String rideStatus;
  final double? currentRemainingDistance; // ✅ NEW: Real-time distance from parent

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
    this.currentRemainingDistance, // ✅ NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading || driverDetails == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    final driverName = GetDriverDetailsCall.name(driverDetails) ?? 'Captain';
    final driverRating = GetDriverDetailsCall.rating(driverDetails) ?? '4.8';
    final vehicleNumber =
        GetDriverDetailsCall.vehicleNumber(driverDetails) ?? 'AP28TA1234';
    final driverPhone = DriverIdfetchCall.mobileNumber(driverDetails);

    // Driver Image
    String? driverImage;
    try {
      driverImage = driverDetails?['profile_photo'] ??
          driverDetails?['profile_image'] ??
          driverDetails?['photo'] ??
          driverDetails?['image'];
    } catch (e) {
      driverImage = null;
    }

    // ✅ OTP - Only show if status is accepted or arriving
    List<String> otpDigits = [];
    bool showOtp = (rideStatus == 'accepted' || rideStatus == 'arrived');
    
    if (showOtp && rideOtp != null && rideOtp!.isNotEmpty) {
      otpDigits = rideOtp!
          .padRight(4, '-')
          .split('')
          .take(4)
          .toList();
    }

    // ✅ Ride Info
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
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -4),
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

          // ✅ STATUS BANNER (for arriving status)
          if (rideStatus == 'arrived') ...[
            _buildStatusBanner(
              icon: Icons.car_rental,
              text: 'Driver is on the way',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
          ],

          // ✅ STATUS BANNER (for picked_up status)
          if (rideStatus == 'started') ...[
            _buildStatusBanner(
              icon: Icons.navigation,
              text: 'Ride Started - En Route to Drop',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
          ],

          // ✅ OTP Section (ONLY show if status is accepted or arriving)
          if (otpDigits.isNotEmpty) ...[
            _buildOtpContainer(otpDigits),
            const SizedBox(height: 20),
          ],

          // Driver Card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Driver Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: driverImage != null && driverImage.isNotEmpty
                          ? Image.network(
                              driverImage,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderAvatar(),
                            )
                          : _buildPlaceholderAvatar(),
                    ),
                    const SizedBox(width: 10),

                    // Driver Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 2),
                              Text(
                                driverRating,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                ' • $vehicleNumber',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Call Button
                    InkWell(
                      onTap: () => onCall(driverPhone?.toString()),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.call, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
                
                // ✅ LIVE DISTANCE DISPLAY (when picked_up and distance available)
                if (rideStatus == 'started' && currentRemainingDistance != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation, 
                          size: 20, 
                          color: Colors.green[700]
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Distance to destination',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[600],
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '${currentRemainingDistance!.toStringAsFixed(2)} km',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Trip Details
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildLocationRow(
                    Icons.radio_button_checked, Colors.green, pickup),
                SizedBox(height: 12),
                _buildLocationRow(Icons.location_on, Colors.red, dropoff),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rideStatus == 'started' 
                            ? 'Original Distance' 
                            : 'Distance',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          originalDistance,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Fare',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          amount,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cancel Button (hide when picked_up)
          if (rideStatus != 'started')
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel Ride',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Status banner widget
  Widget _buildStatusBanner({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 14),
            maxLines: 1,
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
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'OTP: ',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          ...otpDigits.map(
            (digit) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor),
              ),
              child: Text(
                digit,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}