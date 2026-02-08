import '/backend/api_requests/api_calls.dart'; // ✅ Your fixed CancelRide API
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'cancel_ride_model.dart';
export 'cancel_ride_model.dart';

class CancelRideWidget extends StatefulWidget {
  const CancelRideWidget({super.key});

  static String routeName = 'cancel_ride';
  static String routePath = '/cancelRide';

  @override
  State<CancelRideWidget> createState() => _CancelRideWidgetState();
}

class _CancelRideWidgetState extends State<CancelRideWidget> {
  late CancelRideModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  bool _isCancelling = false; // ✅ Loading state

  // Variables to store parsed data
  String? rideId;
  String? vehicleType;
  String? pickupLocation;
  String? dropLocation;
  double? estimatedFare;
  double? estimatedDistance;
  String? vehicleImage;
  String? seatingCapacity;
  String? luggageCapacity;
  double? pricePerKm;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CancelRideModel());

    _scrollController.addListener(() {
      setState(() {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.position.pixels;
          // Update scroll progress for UI
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Parse query parameters
    final params = GoRouter.of(context).routeInformationProvider.value.uri.queryParameters;

    rideId = params['rideId'];
    vehicleType = params['vehicleType'];
    pickupLocation = params['pickupLocation'];
    dropLocation = params['dropLocation'];
    vehicleImage = params['vehicleImage'];
    seatingCapacity = params['seatingCapacity'];
    luggageCapacity = params['luggageCapacity'];

    // Parse numeric values
    estimatedFare = double.tryParse(params['estimatedFare'] ?? '0');
    estimatedDistance = double.tryParse(params['estimatedDistance'] ?? '0');
    pricePerKm = double.tryParse(params['pricePerKm'] ?? '0');

    print('=== CancelRide Parsed Parameters ===');
    print('Ride ID: $rideId');
    print('Vehicle Type: $vehicleType');
    print('Fare: ₹$estimatedFare');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  // ✅ FIXED: Real CancelRide API Integration
  Future<void> _cancelRide() async {
    if (_isCancelling || rideId == null) return;

    setState(() => _isCancelling = true);

    try {
      final token = FFAppState().accessToken; // ✅ Get from FFAppState

      print('🚫 Cancelling ride $rideId with token: ${token.substring(0, 20)}...');

      final response = await CancelRide.call(
        rideId: int.parse(rideId!), // ✅ Parse string to int
        cancellationReason: 'Customer cancelled before driver arrived',
        token: token,
        cancelledBy: 'user',
      );

      print('✅ CancelRide Response: ${response.succeeded}');

      if (mounted) {
        if (response.succeeded) {
          // ✅ Success - Navigate back 2 screens (home)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(CancelRide.message(response) ?? 'Ride cancelled successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Pop twice to go back to home
          Future.delayed(Duration(milliseconds: 1500), () {
            if (mounted) {
              context.pop(); // Cancel screen
              context.pop(); // AutoBook screen
            }
          });
        } else {
          // ✅ Error handling
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel ride. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ CancelRide Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    // Use parsed parameters or fallbacks
    final displayVehicleType = vehicleType ?? FFAppState().vehicleselect ?? 'Auto';
    final displayPickupLocation = pickupLocation ?? FFAppState().pickuplocation ?? 'Pickup';
    final displayDropLocation = dropLocation ?? FFAppState().droplocation ?? 'Drop';
    final displayEstimatedFare = estimatedFare ?? 0.0;
    final displayVehicleImage = vehicleImage;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ✅ Map Background (Full Screen)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/images/map_background.png'), // ✅ Update path
                  ),
                ),
                child: Stack(
                  children: [
                    // Pickup Marker (Green)
                    Positioned(
                      left: 40,
                      top: 150,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.circle, color: Colors.green, size: 20),
                      ),
                    ),
                    // Drop Marker (Red)
                    Positioned(
                      right: 40,
                      bottom: 250,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.red, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ UGO-STYLE Bottom Sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        children: [
                          // Pickup Location (UGO Compact Style)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFE9ECEF)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.circle, color: Colors.white, size: 12),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pickup',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        displayPickupLocation.split(',').first,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Drop Location
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFE9ECEF)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on, color: Colors.white, size: 12),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Drop',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        displayDropLocation.split(',').first,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ✅ Vehicle Card (UGO Style)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Color(0xFFE9ECEF), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Vehicle Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: displayVehicleImage != null && displayVehicleImage.isNotEmpty
                                        ? Image.network(
                                      'https://ugo-api.icacorp.org/$displayVehicleImage',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.directions_car, size: 40, color: Colors.grey),
                                    )
                                        : Icon(Icons.directions_car, size: 40, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Vehicle Details + Price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayVehicleType,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${pricePerKm?.toStringAsFixed(0) ?? '0'} / km',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (estimatedFare != null && estimatedFare! > 0) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFFD700), // UGO Yellow
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '₹${estimatedFare!.toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ✅ Cancel Button (UGO Orange)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isCancelling ? null : _cancelRide, // ✅ Real API Call
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isCancelling
                                    ? Colors.grey[300]
                                    : const Color(0xFFFF7B10), // UGO Orange
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isCancelling
                                  ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : Text(
                                'Cancel Ride',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Back Button (Floating on Map)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: FlutterFlowIconButton(
                  borderRadius: 30,
                  buttonSize: 56,
                  icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF7B10), size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
