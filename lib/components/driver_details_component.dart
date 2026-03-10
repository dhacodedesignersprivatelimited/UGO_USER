import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_config.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import 'dart:math';

class DriverDetailsComponent extends StatefulWidget {
  final bool isLoading;
  final Map<String, dynamic>? driverDetails;
  final dynamic driverId;
  final String? rideOtp;
  final List<dynamic> ridesCache;
  final Function(String?) onCall;
  final VoidCallback onCancel;
  final String rideStatus;
  final double? currentRemainingDistance;
  final String? liveEtaText;
  final VoidCallback? onShare;
  final double? totalRoadDistanceKm;
  final ScrollController? scrollController;

  static const Color primaryColor = Color(0xFFFF7B10);

  const DriverDetailsComponent({
    Key? key,
    required this.isLoading,
    this.driverDetails,
    required this.driverId,
    required this.rideOtp,
    required this.ridesCache,
    required this.onCall,
    required this.onCancel,
    required this.rideStatus,
    this.currentRemainingDistance,
    this.liveEtaText,
    this.onShare,
    this.totalRoadDistanceKm,
    this.scrollController,
  }) : super(key: key);

  @override
  State<DriverDetailsComponent> createState() => _DriverDetailsComponentState();
}

class _DriverDetailsComponentState extends State<DriverDetailsComponent> {
  bool _isInternalLoading = false;
  Map<String, dynamic>? _fetchedDriverData;
  Map<String, dynamic>? _fetchedVehicleData;

  @override
  void initState() {
    super.initState();
    _fetchDynamicData();
  }

  @override
  void didUpdateWidget(DriverDetailsComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driverId != oldWidget.driverId) {
      _fetchDynamicData();
    }
  }

  Future<void> _fetchDynamicData() async {
    final dIdRaw = widget.driverId;
    if (dIdRaw == null) return;

    final dId = dIdRaw is int ? dIdRaw : int.tryParse(dIdRaw.toString());
    if (dId == null) return;

    if (mounted) setState(() => _isInternalLoading = true);

    try {
      final token = FFAppState().accessToken;

      // Fetch both in parallel
      final results = await Future.wait([
        DriverIdfetchCall.call(id: dId, token: token),
        GetVehicleInfoByDriverCall.call(driverId: dId, token: token),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].succeeded) {
            _fetchedDriverData = results[0].jsonBody;
          }
          if (results[1].succeeded) {
            _fetchedVehicleData = results[1].jsonBody;
          }
          _isInternalLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching driver/vehicle details: $e');
      if (mounted) setState(() => _isInternalLoading = false);
    }
  }

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

  static String _formatDistance(double? km) {
    if (km == null) return '--';
    return km < 1 ? '${(km * 1000).round()}m' : '${km.toStringAsFixed(1)}Km';
  }

  int _calculateEtaMinutes(double distanceKm) {
    const double avgSpeed = 30; // km/h (city average)
    double hours = distanceKm / avgSpeed;
    return (hours * 60).round();
  }

  @override
  Widget build(BuildContext context) {
    final flowTheme = FlutterFlowTheme.of(context);
    final status = widget.rideStatus.toLowerCase().trim();

    // Status Groups
    final isArriving = status == 'arriving' || status == 'arrived';
    final isAccepted = status == 'accepted' || status == 'driver_assigned';
    final isStarted = status == 'started' || status == 'picked_up' || status == 'in_progress' || status == 'ontrip';

    final showLoading = widget.isLoading || (_isInternalLoading && _fetchedDriverData == null);

    if (showLoading) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.3),
          decoration: BoxDecoration(
            color: flowTheme.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(color: DriverDetailsComponent.primaryColor),
            ),
          ),
        ),
      );
    }

    // Resolve data sources
    final driverData = _fetchedDriverData ?? widget.driverDetails;

    // Extract Data
    final driverName = GetDriverDetailsCall.name(driverData) ?? 'Captain';
    final driverRating = GetDriverDetailsCall.rating(driverData) ?? '4.8';
    final totalRides = DriverIdfetchCall.totalRidesCompleted(driverData) ?? 0;
    
    // Vehicle Info
    String vehicleInfo = 'AP27TA1234'; // Default fallback
    String? vehicleImageUrl;

    if (_fetchedVehicleData != null) {
      final model = GetVehicleInfoByDriverCall.vehicleModel(_fetchedVehicleData) ?? '';
      final name = GetVehicleInfoByDriverCall.vehicleName(_fetchedVehicleData) ?? '';
      final color = GetVehicleInfoByDriverCall.vehicleColor(_fetchedVehicleData) ?? '';
      final plate = GetVehicleInfoByDriverCall.licensePlate(_fetchedVehicleData) ?? '';
      
      // We can also try to get vehicle image from this dynamic call if available, 
      // but DriverIdfetchCall has a dedicated helper for it.
      
      List<String> parts = [];
      if (model.isNotEmpty) parts.add(model);
      if (name.isNotEmpty) parts.add(name);
      if (color.isNotEmpty) parts.add(color);
      
      if (parts.isNotEmpty && plate.isNotEmpty) {
        vehicleInfo = '${parts.join(' ')} • $plate';
      } else if (plate.isNotEmpty) {
        vehicleInfo = plate;
      } else if (parts.isNotEmpty) {
        vehicleInfo = parts.join(' ');
      }
    } else {
      vehicleInfo = GetDriverDetailsCall.vehicleNumber(driverData) ?? vehicleInfo;
    }

    vehicleImageUrl = DriverIdfetchCall.vehicleImage(driverData);

    final driverPhone = DriverIdfetchCall.mobileNumber(driverData);
    final driverImage = GetDriverDetailsCall.profileImage(driverData);

    final pickupLat = FFAppState().pickupLatitude;
    final pickupLng = FFAppState().pickupLongitude;

    // Fallback for nested/ride-embedded driver (profile_image in data)
    String? resolvedImage = driverImage;
    if (resolvedImage == null) {
      try {
        final d = driverData?['data'] ?? driverData;
        if (d is Map) {
          resolvedImage = (d['profile_photo'] ?? d['profile_image'] ?? d['photo'] ?? d['image'])?.toString();
          if (resolvedImage != null && !resolvedImage.startsWith('http')) {
            resolvedImage = '${AppConfig.baseApiUrl}/$resolvedImage';
          }
        }
      } catch (_) {}
    }

    // ✅ OTP Logic: Only show if accepted or arriving. HIDE if ride already started.
    List<String> otpDigits = [];
    bool showOtp = (isAccepted || isArriving) && !isStarted;

    if (showOtp && widget.rideOtp != null && widget.rideOtp!.isNotEmpty) {
      otpDigits = widget.rideOtp!.padRight(4, '-').split('').take(4).toList();
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

    if (widget.ridesCache.isNotEmpty) {
      final ride = widget.ridesCache[0];
      pickup = ride['pickup_location_address'] ?? pickup;
      dropoff = ride['drop_location_address'] ?? dropoff;
      amount = '₹${ride['estimated_fare'] ?? '--'}';
      originalDistance = '${ride['ride_distance_km'] ?? '--'}km';
      driverLatDouble = double.tryParse(ride['driver_latitude']?.toString() ?? '');
      driverLngDouble = double.tryParse(ride['driver_longitude']?.toString() ?? '');
    }

    // Calculate arrival distance logic
    if (isArriving) {
      if (widget.currentRemainingDistance != null) {
        arrivingDistance = widget.currentRemainingDistance;
      } else if (driverLatDouble != null && driverLngDouble != null && pickupLat != null && pickupLng != null) {
        arrivingDistance = _calculateDistanceKm(driverLatDouble, driverLngDouble, pickupLat, pickupLng);
      }

      if (arrivingDistance != null) {
        arrivingEta = _calculateEtaMinutes(arrivingDistance);
      }
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: widget.scrollController != null ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle (Visual only now)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: flowTheme.alternate,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // --- 1. Status Banners ---
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
              color: flowTheme.alternate.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: flowTheme.alternate),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: resolvedImage != null && resolvedImage.isNotEmpty
                              ? Image.network(
                            resolvedImage,
                            width: 60, height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                          )
                              : _buildPlaceholderAvatar(),
                        ),
                        Container(
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Name & Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(driverName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                              if (totalRides > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.withValues(alpha:0.3)),
                                  ),
                                  child: Text(
                                    "$totalRides+ Rides",
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                                  ),
                                ),
                            ],
                          ),
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
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.directions_car_filled, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        vehicleInfo.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Share Trip (PRD: Trip sharing)
                    if (widget.onShare != null)
                      InkWell(
                        onTap: widget.onShare,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.share_outlined, color: Colors.grey[800], size: 22),
                        ),
                      ),
                    if (widget.onShare != null) const SizedBox(width: 10),
                    // Call Button
                    InkWell(
                      onTap: () => widget.onCall(driverPhone?.toString()),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: DriverDetailsComponent.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),

                // Vehicle Image Section
                if (vehicleImageUrl != null && vehicleImageUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      vehicleImageUrl.startsWith('http') ? vehicleImageUrl : '${AppConfig.baseApiUrl}/$vehicleImageUrl',
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],

                // Live Distance (Only when Started)
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 4. Trip Details ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: flowTheme.alternate.withValues(alpha: 0.5),
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
                        Text(_formatDistance(widget.totalRoadDistanceKm ?? double.tryParse(originalDistance.replaceAll('km', ''))), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Fare', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                        Text(amount, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: DriverDetailsComponent.primaryColor)),
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
                onPressed: widget.onCancel,
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
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
        color: DriverDetailsComponent.primaryColor.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverDetailsComponent.primaryColor.withValues(alpha:0.2)),
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
                border: Border.all(color: DriverDetailsComponent.primaryColor),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(
                digit,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: DriverDetailsComponent.primaryColor),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
