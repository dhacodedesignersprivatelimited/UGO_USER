import 'dart:math';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'driver_details_model.dart';
import 'package:geolocator/geolocator.dart'; // Ensure this package is available for getCurrentPosition
export 'driver_details_model.dart';

class DriverDetailsWidget extends StatefulWidget {
  const DriverDetailsWidget({
    super.key,
    required this.driverId,
    required this.vehicleType,
    this.dropLocation,
    this.dropDistance,
    this.tripAmount,
    this.baseKmStart,
    this.baseKmEnd,
    this.baseFare,
    this.pricePerKm,
  });

  final int? driverId;
  final int? vehicleType;
  final String? dropLocation;
  final String? dropDistance;
  final double? tripAmount;
  final double? baseKmStart;
  final double? baseKmEnd;
  final double? baseFare;
  final double? pricePerKm;
  static String routeName = 'Driver_details';
  static String routePath = '/driverDetails';

  @override
  State<DriverDetailsWidget> createState() => _DriverDetailsWidgetState();
}

class _DriverDetailsWidgetState extends State<DriverDetailsWidget> {
  late DriverDetailsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  bool isLoadingRide = false;
  bool _isLoading = true;
  dynamic _driverData;
  int _selectedTip = 0;
  double _calculatedDistanceKm = 0;
  double _calculatedFare = 0;
  int? _rideId;


  // Computed total
  double get totalAmount => _calculatedFare + _selectedTip;
  final appState = FFAppState();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverDetailsModel());
    _fetchDriverDetails();

    // Calculate fare immediately after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDistanceAndFare();
       _createRide();
       print('🧪 Updating ride');
        print('rideId = $_rideId');
        print('token = ${FFAppState().accessToken}');

    });
                 
      
  }
//   Future<void> _createRide() async {
//   try {
//     final createRideRes = await CreateRideCall.call(
//       token: appState.accessToken,
//       userId: appState.userid,
//       pickupLocationAddress: appState.pickuplocation.isNotEmpty
//           ? appState.pickuplocation
//           : "Current Location",
//       dropLocationAddress: appState.droplocation.isNotEmpty
//           ? appState.droplocation
//           : "Drop Location",
//       pickupLatitude: appState.pickupLatitude!,
//       pickupLongitude: appState.pickupLongitude!,
//       dropLatitude: appState.dropLatitude!,
//       dropLongitude: appState.dropLongitude!,
//       adminVehicleId: widget.vehicleType ?? 1,
//       estimatedFare: totalAmount.toStringAsFixed(2),
//       rideStatus: 'qr_scan',
//       // driverId: widget.driverId,
//       // paymentMethod: selectedPaymentMethod.toLowerCase(),
//     );

//     // 🔍 Debug full response
//     print('🟢 CreateRide response: ${createRideRes.jsonBody}');

//     if (createRideRes.succeeded) {
//       final bool status =
//           getJsonField(createRideRes.jsonBody, r'$.status') ?? false;

//       if (status) {
//         final rideId =
//             getJsonField(createRideRes.jsonBody, r'$.data.id');

//         print('✅ Ride created successfully. Ride ID: $rideId');

//         // Optional: save rideId
//         appState.currentRideId = int.parse(rideId.toString());
//       } else {
//         final message =
//             getJsonField(createRideRes.jsonBody, r'$.message') ??
//                 'Ride creation failed';

//         print('❌ Backend error: $message');
//       }
//     } else {
//       print('❌ API call failed (network/server)');
//     }
//   } catch (e) {
//     print('🔥 Exception while creating ride: $e');
//   }
// }
Future<void> _createRide() async {
  try {
    print('🚕 Creating ride...');

    final response = await CreateRideCall.call(
      token: FFAppState().accessToken, // USER token is correct for create ride
      userId: FFAppState().userid,
      pickupLocationAddress: FFAppState().pickuplocation.isNotEmpty
          ? FFAppState().pickuplocation
          : "Current Location",
      dropLocationAddress: FFAppState().droplocation.isNotEmpty
          ? FFAppState().droplocation
          : "Drop Location",
      pickupLatitude: FFAppState().pickupLatitude!,
      pickupLongitude: FFAppState().pickupLongitude!,
      dropLatitude: FFAppState().dropLatitude!,
      dropLongitude: FFAppState().dropLongitude!,
      adminVehicleId: widget.vehicleType ?? 1,
      estimatedFare: totalAmount.toStringAsFixed(2),
      rideStatus: 'qr_scan', // IMPORTANT
      driverId: widget.driverId,
    );

    print('🟢 CreateRide response: ${response.jsonBody}');

    if (response.succeeded == true) {
      final bool success =
          getJsonField(response.jsonBody, r'$.success') ?? false;

      if (success) {
        final int rideId =
            int.parse(getJsonField(response.jsonBody, r'$.data.id').toString());

        // ✅ SAVE RIDE ID PROPERLY
        _rideId = rideId;
        // FFAppState().currentRideId = rideId;

        print('✅ Ride created successfully');
        print('🆔 rideId = $_rideId');

        setState(() {});
      } else {
        final message =
            getJsonField(response.jsonBody, r'$.message') ?? 'Ride creation failed';
        print('❌ Backend error: $message');
      }
    } else {
      print('❌ CreateRide API failed');
    }
  } catch (e) {
    print('🔥 Exception in _createRide(): $e');
  }
}


  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // --- 1. Load Data & Calculate Fare ---

  Future<void> _fetchDriverDetails() async {
    try {
      final response = await GetDriverDetailsCall.call(
        driverId: widget.driverId,
        token: FFAppState().accessToken,
      );
      if (mounted) {
        setState(() {
          if (response.succeeded) {
            _driverData = response.jsonBody;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDistanceAndFare() async {
    final appState = FFAppState();

    // 1. Validation: Ensure Pickup is set (Red Pin logic)
    if (appState.pickupLatitude == null || appState.pickupLatitude == 0.0) {
      debugPrint('⚠️ Pickup coordinates missing. Attempting to fetch current location...');
      await _refreshCurrentLocation();
    }

    final lat1 = appState.pickupLatitude;
    final lon1 = appState.pickupLongitude;
    final lat2 = appState.dropLatitude;
    final lon2 = appState.dropLongitude;

    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      debugPrint('❌ Still missing coordinates for calculation.');
      return;
    }

    // 2. Calculate Distance (Haversine)
    final distance = calculateDistance(lat1, lon1, lat2, lon2);

    // 3. Pricing Logic (Robust Fallback)
    // Prioritize widget params passed from QR scan, fallback to defaults
    final baseKmStart = widget.baseKmStart ?? 1.0;
    final baseKmEnd = widget.baseKmEnd ?? 5.0;
    final baseFare = widget.baseFare ?? 50.0; // Default base fare if null
    final pricePerKm = widget.pricePerKm ?? 15.0; // Default price/km if null

    // 4. Calculate Fare
    final fare = _calculateTierFare(
      distanceKm: distance,
      baseKmStart: baseKmStart,
      baseKmEnd: baseKmEnd,
      baseFare: baseFare,
      pricePerKm: pricePerKm,
    );

    if (mounted) {
      setState(() {
        _calculatedDistanceKm = distance;
        _calculatedFare = fare;
      });
      debugPrint('✅ Distance: ${distance.toStringAsFixed(2)} km, Fare: ₹${fare.toStringAsFixed(2)}');
    }
  }

  // --- Helper: Fetch Location if missing ---
  Future<void> _refreshCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        FFAppState().pickupLatitude = position.latitude;
        FFAppState().pickupLongitude = position.longitude;
      });
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }

  // --- Helper: Distance Math ---
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of earth in km
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  // --- Helper: Fare Math ---
  double _calculateTierFare({
    required double distanceKm,
    required double baseKmStart,
    required double baseKmEnd,
    required double baseFare,
    required double pricePerKm,
  }) {
    if (distanceKm <= 0) return 0;

    // Flat rate for initial KMs
    if (distanceKm <= baseKmEnd) {
      return baseFare;
    }

    // Additional fare for extra KMs
    final extraKm = distanceKm - baseKmEnd;
    return baseFare + (extraKm * pricePerKm);
  }

  // --- 2. Confirm Booking (Direct Start) ---

  // Future<void> _confirmBooking() async {
  //   if (isLoadingRide) return;

  //   final appState = FFAppState();

  //   // Safety check for location before API call
  //   if (appState.pickupLatitude == null || appState.dropLatitude == null) {
  //     _showError("Locations not set. Please restart booking.");
  //     return;
  //   }

  //   setState(() => isLoadingRide = true);

  //   try {
  //     print('🚀 Starting Ride Directly (No OTP)...');

      // Call Create Ride API with status 'started'
      // final createRideRes = await CreateRideCall.call(
      //   token: appState.accessToken,
      //   userId: appState.userid,
      //   pickupLocationAddress: appState.pickuplocation.isNotEmpty
      //       ? appState.pickuplocation
      //       : "Current Location", // Fallback name
      //   dropLocationAddress: appState.droplocation.isNotEmpty
      //       ? appState.droplocation
      //       : "Drop Location",   // Fallback name
      //   pickupLatitude: appState.pickupLatitude!,
      //   pickupLongitude: appState.pickupLongitude!,
      //   dropLatitude: appState.dropLatitude!,
      //   dropLongitude: appState.dropLongitude!,
      //   adminVehicleId: widget.vehicleType,
      //   estimatedFare: totalAmount.toStringAsFixed(2),
      //   rideStatus: 'started', // <--- KEY: Bypass OTP/Pending state
      //   driverId: widget.driverId,
      // );

      // if (createRideRes.succeeded) {
      //   // Extract Ride ID safely
      //   final rideId = CreateRideCall.rideId(createRideRes.jsonBody)?.toString() ??
      //       getJsonField(createRideRes.jsonBody, r'''$.data.id''')?.toString();

        // if (rideId != null) {
        //   appState.currentRideId = int.parse(rideId);
        //   appState.bookingInProgress = true; // Mark session active
        //   print('✅ Ride Started Successfully. ID: $rideId');

        //   // Navigate to Active Ride Screen
        //   if (mounted) {
        //     await context.pushNamed(
        //       AutoBookWidget.routeName,
        //       queryParameters: {
        //         'rideId': rideId,
        //         // Add these if AutoBookWidget needs them to initialize UI faster
        //         'status': 'started',
        //       },
        //     );
        //   }
        // } else {
        //   _showError("Ride created but ID missing.");
        // }
      // } else {
      //   final errorMsg = CreateRideCall.getResponseMessage(createRideRes.jsonBody) ??
      //       'Failed to start ride.';
      //   _showError(errorMsg);
      // }
//       onPressed: () async {
//   final response = await UpdateRideStatusCall.call(
//     rideId: FFAppState().currentRideId,
//     status: 'started',
//     token: FFAppState().accessToken,
//   );

//   if (UpdateRideStatusCall.success(response.jsonBody) == true) {
//     FFAppState().currentRideStatus = 'started';
//     print('🚀 Ride started');
//   }
// }

//     } catch (e) {
//       print('❌ Booking Exception: $e');
//       _showError('Connection error. Please try again.');
//     } finally {
//       if (mounted) setState(() => isLoadingRide = false);
//     }
//   }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  Future<void> _confirmBooking() async {
  if (isLoadingRide) return;

  setState(() => isLoadingRide = true);

  try {
    print('🚀 START RIDE pressed');

    final response = await UpdateRideStatusCall.call(
      rideId:  _rideId,
      status: 'started',
      token: FFAppState().accessToken,
    );

    print('🟢 UpdateRideStatus response: ${response.jsonBody}');

    if (UpdateRideStatusCall.success(response.jsonBody) == true) {
      // FFAppState().currentRideStatus = 'started';
      print('✅ Ride status changed to STARTED');

      // OPTIONAL: navigate to next screen
      if (mounted) {
        await context.pushNamed(
          AutoBookWidget.routeName,
          queryParameters: {
            'rideId': _rideId?.toString(),
            'status': 'started',
          },
        );
      }
    } else {
      _showError('Failed to start ride');
      print('🟢 response: ${response.jsonBody}');
    }
  } catch (e) {
    print('❌ Start ride error: $e');
    _showError('Something went wrong');
  } finally {
    if (mounted) setState(() => isLoadingRide = false);
  }
}


  // --- UI Construction ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10))),
      );
    }

    // Extract Driver Details
    final driverName = GetDriverDetailsCall.name(_driverData) ?? 'Driver';
    final vehicleNum = GetDriverDetailsCall.vehicleNumber(_driverData) ?? 'Unknown';
    final rating = GetDriverDetailsCall.rating(_driverData) ?? '4.5';
    final profileImg = GetDriverDetailsCall.profileImage(_driverData);

    final dropLoc = widget.dropLocation ?? FFAppState().droplocation;
    final displayDropLoc = (dropLoc.isNotEmpty) ? dropLoc : 'Selected Destination';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Main Info Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7B10),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Logo
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'UGO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'T A X I',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Driver Profile Image
                          Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(70), // Circle
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(70),
                                child: profileImg != null && profileImg.isNotEmpty
                                    ? Image.network(profileImg, fit: BoxFit.cover)
                                    : Image.asset('assets/images/0l6yw6.png', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Driver Details Title
                          Center(
                            child: Text(
                              'Verified Driver',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Details List
                          _buildDetailRow('Driver Name', driverName),
                          _buildDetailRow('Vehicle No', vehicleNum),

                          // Rating Row
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  'Rating : ',
                                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                                ),
                                const Icon(Icons.star, color: Color(0xFFFFDE14), size: 20),
                                Text(
                                  ' $rating',
                                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          ),

                          const Divider(color: Colors.white30, height: 20),

                          // Trip Details
                          _buildDetailRow('Destination', displayDropLoc),
                          _buildDetailRow('Distance', '${_calculatedDistanceKm.toStringAsFixed(2)} km'),
                          _buildDetailRow('Est. Fare', '₹${_calculatedFare.toStringAsFixed(0)}'),

                          const SizedBox(height: 20),

                          // Tipping Section
                          Text(
                            'ADD A TIP (Optional)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTipButton(10),
                              _buildTipButton(20),
                              _buildTipButton(50),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Total Amount Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Payable',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D7E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => context.safePop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF01C1C), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF01C1C),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Continue Button
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoadingRide ? null : _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7B10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: isLoadingRide
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : Text(
                            'START RIDE',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipButton(int amount) {
    final isSelected = _selectedTip == amount;
    return InkWell(
      onTap: () => setState(() => _selectedTip = isSelected ? 0 : amount),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: MediaQuery.of(context).size.width * 0.23,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? const Color(0xFFFF7B10) : Colors.white70,
              width: 1.5
          ),
        ),
        child: Center(
          child: Text(
            '+ ₹$amount',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFFFF7B10) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}