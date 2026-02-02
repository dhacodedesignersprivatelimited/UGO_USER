import 'dart:math';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'driver_details_model.dart';
export 'driver_details_model.dart';

class DriverDetailsWidget extends StatefulWidget {
  const DriverDetailsWidget({
    super.key,
    required this.driverId,
    required this.vehicleType,
    this.dropLocation,
    this.dropDistance,
    this.tripAmount,
  });

  final dynamic driverId;
  final String? vehicleType;
  final String? dropLocation;
  final String? dropDistance;
  final double? tripAmount;

  static String routeName = 'Driver_details';
  static String routePath = '/driverDetails';

  @override
  State<DriverDetailsWidget> createState() => _DriverDetailsWidgetState();
}

class _DriverDetailsWidgetState extends State<DriverDetailsWidget> {
  late DriverDetailsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
    bool isLoadingRide = false;
  bool _isLoading = true;
  dynamic _driverData;
  int _selectedTip = 0;
double? googleDistanceKm;

  List<dynamic>? _cachedVehicleData;
  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverDetailsModel());
    _fetchDriverDetails();
  }
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    double dLon = (lon2 - lon1) * (3.141592653589793 / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (3.141592653589793 / 180)) *
            cos(lat2 * (3.141592653589793 / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }
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
void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }
  Future<List<dynamic>> _getVehicleData({bool forceRefresh = false}) async {
    if (_cachedVehicleData != null && !forceRefresh) {
      return _cachedVehicleData!;
    }

    try {
      final response = await GetVehicleDetailsCall.call();
      if (response.succeeded) {
        final jsonList = (getJsonField(
              response.jsonBody,
              r'''$.data''',
            ) as List?)
                ?.toList() ??
            [];
        _cachedVehicleData = jsonList;
        return jsonList;
      }
    } catch (e) {
      print('❌ Error fetching vehicles: $e');
    }
    return [];
  }
    double calculateTieredFare({
    required double distanceKm,
    required double baseKmStart,
    required double baseKmEnd,
    required double baseFare,
    required double pricePerKm,
  }) {
    if (distanceKm <= 0) return 0;
    if (distanceKm <= baseKmEnd) {
      return baseFare;
    }
    final extraKm = distanceKm - baseKmEnd;
    final extraFare = extraKm * pricePerKm;
    return baseFare + extraFare;
  }

Future<void> _confirmBooking() async {
    final appState = FFAppState();

    if (widget.vehicleType == null) {
      _showError('Please select a vehicle type');
      return;
    }

    if (appState.pickupLatitude == null ||
        appState.pickupLongitude == null ||
        appState.dropLatitude == null ||
        appState.dropLongitude == null) {
      _showError('Invalid location data');
      return;
    }

    if (appState.accessToken.isEmpty) {
      _showError('Session expired. Please login again');
      context.pushNamed(LoginWidget.routeName);
      return;
    }

    setState(() => isLoadingRide = true);

    try {
      double roadDistance = googleDistanceKm ?? 0.0;
      if (roadDistance == 0) {
        roadDistance = calculateDistance(
          appState.pickupLatitude!,
          appState.pickupLongitude!,
          appState.dropLatitude!,
          appState.dropLongitude!,
        );
      }

      final vehicleData = await _getVehicleData();
      double baseKmStart = 1;
      double baseKmEnd = 5;
      double baseFare = 0;
      double pricePerKm = 0;

      int finalVehicleId = int.tryParse(widget.vehicleType ?? '0') ?? 0;

      for (var vehicle in vehicleData) {
        String? vId =
            getJsonField(vehicle, r'''$.pricing.vehicle_id''')?.toString();
        vId ??= getJsonField(vehicle, r'''$.vehicle_name''')?.toString();

        if (vId == widget.vehicleType) {
          final pricing = getJsonField(vehicle, r'''$.pricing''');
          baseKmStart = double.tryParse(
                  getJsonField(pricing, r'''$.base_km_start''').toString()) ??
              1;
          baseKmEnd = double.tryParse(
                  getJsonField(pricing, r'''$.base_km_end''').toString()) ??
              5;
          baseFare = double.tryParse(
                  getJsonField(pricing, r'''$.base_fare''').toString()) ??
              0;
          pricePerKm = double.tryParse(
                  getJsonField(pricing, r'''$.price_per_km''').toString()) ??
              0;
          break;
        }
      }

      final int finalBaseFare = calculateTieredFare(
        distanceKm: roadDistance,
        baseKmStart: baseKmStart,
        baseKmEnd: baseKmEnd,
        baseFare: baseFare,
        pricePerKm: pricePerKm,
      ).round();

      final int finalFare = (finalBaseFare - appState.discountAmount.round())
          .clamp(0, 999999)
          .toInt();

      print(
          '🚀 Creating Ride | Vehicle ID: $finalVehicleId | Fare: ₹$finalFare');

      final createRideRes = await CreateRideCall.call(
        token: appState.accessToken,
        userId: appState.userid,
        pickupLocationAddress: appState.pickuplocation,
        dropLocationAddress: appState.droplocation,
        pickupLatitude: appState.pickupLatitude!,
        pickupLongitude: appState.pickupLongitude!,
        dropLatitude: appState.dropLatitude!,
        dropLongitude: appState.dropLongitude!,
        adminVehicleId: finalVehicleId,
        estimatedFare: finalFare.toString(),
        rideStatus: 'started',
      );

      if (createRideRes.succeeded) {
        final rideId = CreateRideCall.rideId(createRideRes.jsonBody)
                ?.toString() ??
            getJsonField(createRideRes.jsonBody, r'''$.data.id''')?.toString();

        if (rideId == null) throw Exception('No ride ID returned');

        print('✅ Ride Created: $rideId');

        await context.pushNamed(
          AutoBookWidget.routeName,
          queryParameters: {
            'rideId': rideId,
            'vehicleType': widget.vehicleType ?? '',
            'pickupLocation': appState.pickuplocation ?? '',
            'dropLocation': appState.droplocation ?? '',
            'estimatedFare': finalFare.toString(),
            'estimatedDistance': roadDistance.toStringAsFixed(2),
            'ride_status': 'started',
          },
        );
      } else {
        final errorMsg =
            CreateRideCall.getResponseMessage(createRideRes.jsonBody) ??
                'Failed to create ride';
        _showError(errorMsg);
      }
    } catch (e) {
      print('❌ Booking Exception: $e');
      _showError('Booking failed: $e');
    } finally {
      if (mounted) setState(() => isLoadingRide = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10))));
    }

    final driverName = GetDriverDetailsCall.name(_driverData) ?? 'Sharath';
    final vehicleNum = GetDriverDetailsCall.vehicleNumber(_driverData) ?? '1287737738';
    final rating = GetDriverDetailsCall.rating(_driverData) ?? '4.7';
    final profileImg = GetDriverDetailsCall.profileImage(_driverData);
    
    final dropLoc = widget.dropLocation ?? FFAppState().droplocation ?? 'Ameerpet';
    final dropDist = widget.dropDistance ?? '15km';
    final baseAmount = widget.tripAmount ?? 100.0;
    final totalAmount = baseAmount + _selectedTip;

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
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7B10),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
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
                                  'T  A  X  I',
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
                          // Driver Image
                          Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: profileImg != null 
                                  ? Image.network(profileImg, fit: BoxFit.cover)
                                  : Image.asset('assets/images/0l6yw6.png', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Driver details',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow('Driver name', driverName),
                          _buildDetailRow('vehicle number', vehicleNum),
                          Row(
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
                          const SizedBox(height: 8),
                          _buildDetailRow('Drop location', dropLoc),
                          _buildDetailRow('Drop distance', dropDist),
                          const SizedBox(height: 16),
                          _buildDetailRow('Trip amount', '₹${baseAmount.toStringAsFixed(2)}'),
                          const SizedBox(height: 20),
                          Text(
                            'TIP AMOUNT',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTipButton(10),
                              _buildTipButton(20),
                              _buildTipButton(30),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total amount',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xFF2D7E20),
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: FFButtonWidget(
                        onPressed: () => Navigator.pop(context),
                        text: 'Cancel',
                        options: FFButtonOptions(
                          height: 56,
                          color: const Color(0xFFF01C1C),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FFButtonWidget(
                        onPressed: () async {
                          _confirmBooking();
                        
                        },
                        text: 'Continue',
                        options: FFButtonOptions(
                          height: 56,
                          color: const Color(0xFFFF7B10),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white, width: 1),
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
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
          children: [
            TextSpan(text: '$label : '),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipButton(int amount) {
    final isSelected = _selectedTip == amount;
    return InkWell(
      onTap: () => setState(() => _selectedTip = isSelected ? 0 : amount),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.23,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1E6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Center(
          child: Text(
            amount.toString(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFFFF7B10) : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}