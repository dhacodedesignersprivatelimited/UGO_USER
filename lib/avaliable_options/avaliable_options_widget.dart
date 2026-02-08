import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart' hide LatLng;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin, sin;
import 'dart:async';
import 'avaliable_options_model.dart';
export 'avaliable_options_model.dart';

// ⚠️ Ensure this API key has Directions API enabled
const String GOOGLE_MAPS_API_KEY = 'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y';

class AvaliableOptionsWidget extends StatefulWidget {
  const AvaliableOptionsWidget({super.key});

  static String routeName = 'avaliable-options';
  static String routePath = '/avaliableOptions';

  @override
  State<AvaliableOptionsWidget> createState() => _AvaliableOptionsWidgetState();
}

class _AvaliableOptionsWidgetState extends State<AvaliableOptionsWidget>
    with TickerProviderStateMixin {
  late AvaliableOptionsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // State
  String? selectedVehicleType;
  bool isLoadingRide = false;
  bool isCalculatingRoute = false;

  // Map
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // Route Data
  double? googleDistanceKm;
  String? googleDuration;

  // Data Caching
  Future<List<dynamic>>? _vehiclesFuture;
  bool showPaymentOptions = false;
  String selectedPaymentMethod = 'Cash'; // Default

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AvaliableOptionsModel());

    // 1. Setup Animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // 2. Start Processes
    _slideController.forward();
    _vehiclesFuture = _getVehicleData(); // Fetch once on init
    _initializeMap();
  }

  // ---------------------------------------------------------------------------
  // 🗺️ MAP LOGIC
  // ---------------------------------------------------------------------------

  Future<void> _initializeMap() async {
    await _addMarkers();
    await _getRoutePolyline();
  }

  Future<void> _addMarkers() async {
    final appState = FFAppState();
    if (appState.pickupLatitude != null && appState.dropLatitude != null) {
      setState(() {
        markers.clear();
        // Pickup Marker
        markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(appState.pickupLatitude!, appState.pickupLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
        // Drop Marker
        markers.add(Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(appState.dropLatitude!, appState.dropLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      });
    }
  }

  Future<void> _getRoutePolyline() async {
    final appState = FFAppState();
    if (appState.pickupLatitude == null || appState.dropLatitude == null) return;

    setState(() => isCalculatingRoute = true);

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${appState.pickupLatitude},${appState.pickupLongitude}'
          '&destination=${appState.dropLatitude},${appState.dropLongitude}'
          '&key=$GOOGLE_MAPS_API_KEY';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final leg = route['legs'][0];
          final points = _decodePolyline(route['overview_polyline']['points']);

          setState(() {
            googleDistanceKm = leg['distance']['value'] / 1000.0;
            googleDuration = leg['duration']['text'];

            polylines.clear();
            polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: Colors.orange,
              width: 4,
              geodesic: true,
            ));
            isCalculatingRoute = false;
          });

          if (mapController != null && points.isNotEmpty) {
            // Wait slightly for map to render before zooming
            await Future.delayed(const Duration(milliseconds: 300));
            _animateCameraToBounds(points);
          }
        }
      }
    } catch (e) {
      print('❌ Route Error: $e');
      _useFallbackDistance();
    }
  }

  void _useFallbackDistance() {
    final appState = FFAppState();
    if (appState.pickupLatitude != null && appState.dropLatitude != null) {
      setState(() {
        googleDistanceKm = calculateDistance(
          appState.pickupLatitude!, appState.pickupLongitude!,
          appState.dropLatitude!, appState.dropLongitude!,
        );
        googleDuration = 'Estimated';
        isCalculatingRoute = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 🧮 UTILITIES
  // ---------------------------------------------------------------------------

  double calculateTieredFare({
    required double distanceKm,
    required double baseKmStart,
    required double baseKmEnd,
    required double baseFare,
    required double pricePerKm,
  }) {
    if (distanceKm <= 0) return 0;
    if (distanceKm <= baseKmEnd) return baseFare;
    final extraKm = distanceKm - baseKmEnd;
    return baseFare + (extraKm * pricePerKm);
  }

  Future<List<dynamic>> _getVehicleData() async {
    try {
      final response = await GetVehicleDetailsCall.call();
      if (response.succeeded) {
        return (getJsonField(response.jsonBody, r'''$.data''') as List?)?.toList() ?? [];
      }
    } catch (e) {
      print('❌ Error fetching vehicles: $e');
    }
    return [];
  }

  // Haversine Fallback
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    double dLon = (lon2 - lon1) * (3.141592653589793 / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (3.141592653589793 / 180)) *
            cos(lat2 * (3.141592653589793 / 180)) *
            sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * asin(sqrt(a));
  }

  // Polyline Decoder
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _animateCameraToBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      80, // Padding
    ));
  }

  // ---------------------------------------------------------------------------
  // 🚀 BOOKING ACTION
  // ---------------------------------------------------------------------------

  Future<void> _confirmBooking() async {
    final appState = FFAppState();

    if (selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vehicle type')));
      return;
    }

    setState(() => isLoadingRide = true);

    try {
      double distance = googleDistanceKm ?? calculateDistance(
        appState.pickupLatitude!, appState.pickupLongitude!,
        appState.dropLatitude!, appState.dropLongitude!,
      );

      // Re-fetch logic to find pricing for selected ID would go here,
      // but we assume appState.selectedBaseFare was set during tap.

      // Calculate Final Fare again for safety
      final double rawFare = calculateTieredFare(
        distanceKm: distance,
        baseKmStart: 1, // Default, ideally fetched from vehicle data
        baseKmEnd: 5,
        baseFare: appState.selectedBaseFare ?? 0,
        pricePerKm: appState.selectedPricePerKm ?? 0,
      );

      final int finalFare = (rawFare - appState.discountAmount).round().clamp(0, 999999);

      final createRideRes = await CreateRideCall.call(
        token: appState.accessToken,
        userId: appState.userid,
        pickupLocationAddress: appState.pickuplocation,
        dropLocationAddress: appState.droplocation,
        pickupLatitude: appState.pickupLatitude,
        pickupLongitude: appState.pickupLongitude,
        dropLatitude: appState.dropLatitude,
        dropLongitude: appState.dropLongitude,
        adminVehicleId: int.tryParse(selectedVehicleType!) ?? 1,
        estimatedFare: finalFare.toString(),
        // paymentType: selectedPaymentMethod.toLowerCase(),
      );

      if (createRideRes.succeeded) {
        final rideId = getJsonField(createRideRes.jsonBody, r'''$.data.id''')?.toString();
        if (rideId != null) {
          appState.currentRideId = int.parse(rideId);
          appState.bookingInProgress = true; // Mark as active

          context.pushNamed(
            AutoBookWidget.routeName,
            queryParameters: {
              'rideId': rideId,
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(getJsonField(createRideRes.jsonBody, r'$.message') ?? 'Booking failed'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('Booking Error: $e');
    } finally {
      if (mounted) setState(() => isLoadingRide = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 🖥️ BUILD UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    double currentDistance = googleDistanceKm ?? 0.0;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Map Layer
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (c) {
                mapController = c;
                if (markers.isNotEmpty) _initializeMap();
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(appState.pickupLatitude ?? 17.3850, appState.pickupLongitude ?? 78.4867),
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              // IMPORTANT: Add padding to map so Google logo and route stay above bottom sheet
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.55),
            ),
          ),

          // 2. Top Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose a ride', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${currentDistance.toStringAsFixed(1)} km • ${googleDuration ?? "Calculating..."}',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Sheet (Vehicle List)
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),

                    // List
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _vehiclesFuture, // Uses cached future
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10)));
                          final vehicles = snapshot.data!;

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = vehicles[index];
                              return _buildVehicleCard(vehicle, currentDistance, appState);
                            },
                          );
                        },
                      ),
                    ),

                    // Bottom Actions (Payment & Confirm)
                    _buildBottomActions(appState),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(dynamic data, double distance, FFAppState appState) {
    final pricing = getJsonField(data, r'''$.pricing''');
    final String vehicleId = getJsonField(data, r'''$.pricing.vehicle_id''')?.toString() ?? '1';
    final String name = getJsonField(data, r'''$.vehicle_name''')?.toString() ?? 'Ride';

    // 1. IDENTIFY PRO RIDE
    bool isPro = name.toLowerCase().contains('pro') ||
        name.toLowerCase().contains('premium') ||
        name.toLowerCase().contains('prime');

    // Pricing Logic
    final baseKmStart = double.tryParse(getJsonField(pricing, r'''$.base_km_start''').toString()) ?? 1;
    final baseKmEnd = double.tryParse(getJsonField(pricing, r'''$.base_km_end''').toString()) ?? 5;
    final baseFare = double.tryParse(getJsonField(pricing, r'''$.base_fare''').toString()) ?? 0;
    final pricePerKm = double.tryParse(getJsonField(pricing, r'''$.price_per_km''').toString()) ?? 0;

    final calculatedFare = calculateTieredFare(
      distanceKm: distance, baseKmStart: baseKmStart, baseKmEnd: baseKmEnd,
      baseFare: baseFare, pricePerKm: pricePerKm,
    ).round();

    final isSelected = selectedVehicleType == vehicleId;
    final displayFare = (calculatedFare - appState.discountAmount).clamp(0, 999999).toInt();

    // Image Handling
    String? imgUrl = getJsonField(data, r'''$.vehicle_image''')?.toString();
    if (imgUrl != null && !imgUrl.startsWith('http')) imgUrl = 'https://ugo-api.icacorp.org/$imgUrl';

    // Styles
    Color backgroundColor = isSelected
        ? (isPro ? const Color(0xFFFFF9C4) : const Color(0xFFFFF8F0))
        : (isPro ? const Color(0xFFFAFAFA) : Colors.white);

    Color borderColor = isSelected
        ? (isPro ? const Color(0xFFFBC02D) : const Color(0xFFFF7B10))
        : (isPro ? const Color(0xFFFFD54F) : Colors.grey[200]!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedVehicleType = vehicleId;
            appState.vehicleselect = vehicleId;
            appState.selectedBaseFare = baseFare;
            appState.selectedPricePerKm = pricePerKm;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // Adjusted padding slightly to give the crown room at the top
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : (isPro ? 1.5 : 1),
            ),
            boxShadow: isPro
                ? [BoxShadow(color: Colors.amber.withOpacity(0.15), blurRadius: 8, offset: Offset(0, 4))]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // =========================
              // 3. IMAGE SECTION WITH CROWN STACK
              // =========================
              if (isPro)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // The Framed Image (Pushed down slightly)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Container(
                        width: 68, height: 68,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFBC02D), width: 2),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFBC02D).withOpacity(0.3), blurRadius: 4, offset: Offset(0,2))
                            ]
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imgUrl != null
                              ? Image.network(imgUrl, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.directions_car, color: Colors.amber))
                              : const Icon(Icons.directions_car, size: 36, color: Colors.amber),
                        ),
                      ),
                    ),
                    // The Crown Icon (Sitting on top center)
                    // The Crown Icon (Sitting on top center)
                    Positioned(
                      top: -12, // Moves the crown slightly higher to "float" on the edge
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFBC02D), width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                        // 👑 Renders the Emoji directly
                        child: const Text(
                          '👑',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                )
              else
              // --- NORMAL NO FRAME ---
                SizedBox(
                  width: 60, height: 60,
                  child: imgUrl != null
                      ? Image.network(imgUrl, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.directions_car, color: Colors.grey))
                      : const Icon(Icons.directions_car, size: 40, color: Colors.grey),
                ),
              // =========================
              // END IMAGE SECTION
              // =========================

              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        if (isPro)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                            child: Text('PRO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('2 mins away', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                    if (isPro)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Comfy • Top Drivers', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFF57F17))),
                      ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('₹$displayFare', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isPro ? Colors.black : Colors.black87)),
                  if (isPro) Icon(Icons.star, size: 16, color: Colors.amber[700])
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(FFAppState appState) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row with Payment & Coupon
          Row(
            children: [
              // PAYMENT SELECTION BUTTON
              InkWell(
                onTap: () async {
                  // Navigate to Payment Screen & Wait for Result
                  final result = await context.pushNamed(PaymentOptionsWidget.routeName);

                  if (result != null && result is String) {
                    setState(() {
                      selectedPaymentMethod = result;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          selectedPaymentMethod == 'Cash' ? Icons.money :
                          selectedPaymentMethod == 'Wallet' ? Icons.account_balance_wallet : Icons.qr_code,
                          size: 18,
                          color: const Color(0xFF1B5E20)
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedPaymentMethod,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // OFFERS BUTTON
              InkWell(
                onTap: () => context.pushNamed(VoucherWidget.routeName),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, size: 18, color: Color(0xFFFF7B10)),
                    const SizedBox(width: 4),
                    Text(
                        'Offers',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF7B10)
                        )
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CONFIRM BUTTON
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoadingRide || selectedVehicleType == null ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7B10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: isLoadingRide
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text(
                  'Confirm Booking',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
          ),
        ],
      ),
    );
  }

}