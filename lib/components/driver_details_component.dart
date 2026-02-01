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

  static const Color primaryColor = Color(0xFFFF7B10);

  const DriverDetailsComponent({
    Key? key,
    required this.isLoading,
    required this.driverDetails,
    required this.rideOtp,
    required this.ridesCache,
    required this.onCall,
    required this.onCancel,
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
    final vehicleNumber = GetDriverDetailsCall.vehicleNumber(driverDetails) ?? 'AP28TA1234';
    final driverPhone = DriverIdfetchCall.mobileNumber(driverDetails);

    // ✅ FIXED: Direct dictionary access instead of non-existent method
    String? driverImage;
    try {
      driverImage = driverDetails?['profile_photo'] ??
          driverDetails?['profile_image'] ??
          driverDetails?['photo'] ??
          driverDetails?['image'];
    } catch (e) {
      driverImage = null;
    }

    // OTP
    String displayOtp = rideOtp ?? '----';
    List<String> otpDigits = displayOtp.padRight(4, '-').split('').take(4).toList();

    // Ride Info
    String pickup = 'Pickup Location';
    String dropoff = 'Drop Location';
    String distance = '--km';
    String amount = '₹--';

    if (ridesCache.isNotEmpty) {
      final ride = ridesCache[0];
      pickup = ride['pickup_location_address'] ?? pickup;
      dropoff = ride['drop_location_address'] ?? dropoff;
      amount = '₹${ride['total_fare'] ?? '--'}';
      distance = '${ride['distance'] ?? '--'}km';
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

          // OTP Section
          Container(
            padding: EdgeInsets.all(16),
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
                ...otpDigits.map((digit) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Driver Card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
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
                    errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                  )
                      : _buildPlaceholderAvatar(),
                ),
                const SizedBox(width: 16),

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
                          SizedBox(width: 4),
                          Text(
                            driverRating,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' • $vehicleNumber',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
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
                _buildLocationRow(Icons.radio_button_checked, Colors.green, pickup),
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
                          'Distance',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          distance,
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

          // Cancel Button
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
}
