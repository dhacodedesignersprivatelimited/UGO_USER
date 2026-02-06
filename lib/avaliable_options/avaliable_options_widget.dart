import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' hide LatLng;
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, sin;
import 'dart:async';
import 'dart:io';
import 'avaliable_options_model.dart';
export 'avaliable_options_model.dart';

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
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String? selectedVehicleType;
  bool isLoadingRide = false;
  bool isCalculatingRoute = false;

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  double? googleDistanceKm;
  String? googleDuration;

  List<dynamic>? _cachedVehicleData;
   bool showPaymentOptions = false;
  //  String selectedPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AvaliableOptionsModel());

    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _addMarkers();
    await _getRoutePolyline();
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

  Future<void> _addMarkers() async {
    final appState = FFAppState();
    if (appState.pickupLatitude != null &&
        appState.pickupLongitude != null &&
        appState.dropLatitude != null &&
        appState.dropLongitude != null) {
      setState(() {
        markers.clear();
        markers.add(
          Marker(
            markerId: MarkerId('pickup'),
            position: LatLng(
              appState.pickupLatitude!,
              appState.pickupLongitude!,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );

        markers.add(
          Marker(
            markerId: MarkerId('drop'),
            position: LatLng(
              appState.dropLatitude!,
              appState.dropLongitude!,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      });
    }
  }

  Future<void> _getRoutePolyline() async {
    final appState = FFAppState();
    if (appState.pickupLatitude == null ||
        appState.pickupLongitude == null ||
        appState.dropLatitude == null ||
        appState.dropLongitude == null) {
      return;
    }

    setState(() => isCalculatingRoute = true);

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${appState.pickupLatitude},${appState.pickupLongitude}'
          '&destination=${appState.dropLatitude},${appState.dropLongitude}'
          '&key=$GOOGLE_MAPS_API_KEY';

      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Route calculation timed out'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final leg = route['legs'][0];

          final distanceInMeters = leg['distance']['value'];
          final durationText = leg['duration']['text'];

          final points = _decodePolyline(
            route['overview_polyline']['points'],
          );

          setState(() {
            googleDistanceKm = distanceInMeters / 1000.0;
            googleDuration = durationText;
            polylines.clear();
            polylines.add(
              Polyline(
                polylineId: PolylineId('route'),
                points: points,
                color: Color(0xFF000000),
                width: 4,
                geodesic: true,
              ),
            );
            isCalculatingRoute = false;
          });

          if (mapController != null && points.isNotEmpty) {
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
    if (appState.pickupLatitude != null &&
        appState.pickupLongitude != null &&
        appState.dropLatitude != null &&
        appState.dropLongitude != null) {
      setState(() {
        googleDistanceKm = calculateDistance(
          appState.pickupLatitude!,
          appState.pickupLongitude!,
          appState.dropLatitude!,
          appState.dropLongitude!,
        );
        googleDuration = 'Estimated';
        isCalculatingRoute = false;
      });
    } else {
      setState(() => isCalculatingRoute = false);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return poly;
  }

  void _animateCameraToBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    _slideController.dispose();
    _model.dispose();
    markers.clear();
    polylines.clear();
    _cachedVehicleData = null;
    super.dispose();
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
        ) as List?)?.toList() ?? [];
        _cachedVehicleData = jsonList;
        return jsonList;
      }
    } catch (e) {
      print('❌ Error fetching vehicles: $e');
    }
    return [];
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
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();

    double currentDistance = googleDistanceKm ?? 0.0;
    if (currentDistance == 0.0 &&
        appState.pickupLatitude != null &&
        appState.pickupLongitude != null &&
        appState.dropLatitude != null &&
        appState.dropLongitude != null) {
      currentDistance = calculateDistance(
        appState.pickupLatitude!,
        appState.pickupLongitude!,
        appState.dropLatitude!,
        appState.dropLongitude!,
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map Section
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.5,
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
                if (markers.isNotEmpty) {
                  _initializeMap();
                }
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  appState.pickupLatitude ?? 17.3850,
                  appState.pickupLongitude ?? 78.4867,
                ),
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: false,
            ),
          ),

          // Top Bar with Back Button & Trip Info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose a ride',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '${currentDistance.toStringAsFixed(1)} km • ${googleDuration ?? "Calculating..."}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
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
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.58,
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
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Vehicle List
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _getVehicleData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF7B10),
                                strokeWidth: 3,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Failed to load vehicles'),
                                ],
                              ),
                            );
                          }

                          final jsonList = snapshot.data ?? [];
                          if (jsonList.isEmpty) {
                            return Center(
                              child: Text(
                                'No vehicles available',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: jsonList.length,
                            itemBuilder: (context, index) {
                              final dataItem = jsonList[index];
                              final int rideCategory =
                              int.tryParse(getJsonField(dataItem, r'''$.ride_category''')?.toString() ?? '0') ?? 0;

                          final bool isProRide = rideCategory == 1;


                              String? vehicleType = getJsonField(dataItem, r'''$.pricing.vehicle_id''')?.toString();
                              String? vehicleName = getJsonField(dataItem, r'''$.vehicle_name''')?.toString();
                              vehicleType ??= getJsonField(dataItem, r'''$.vehicle_name''')?.toString();

                              if (vehicleType == null || vehicleType == 'null' || vehicleType.isEmpty) {
                                vehicleType = '1';
                              }

                              final pricing = getJsonField(dataItem, r'''$.pricing''');
                              final baseKmStart = double.tryParse(getJsonField(pricing, r'''$.base_km_start''').toString()) ?? 1;
                              final baseKmEnd = double.tryParse(getJsonField(pricing, r'''$.base_km_end''').toString()) ?? 5;
                              final baseFare = double.tryParse(getJsonField(pricing, r'''$.base_fare''').toString()) ?? 0;
                              final pricePerKm = double.tryParse(getJsonField(pricing, r'''$.price_per_km''').toString()) ?? 0;

                              final calculatedFare = calculateTieredFare(
                                distanceKm: currentDistance,
                                baseKmStart: baseKmStart,
                                baseKmEnd: baseKmEnd,
                                baseFare: baseFare,
                                pricePerKm: pricePerKm,
                              ).round();

                              final isSelected = selectedVehicleType == vehicleType;
                              int displayFare = calculatedFare;
                              if (isSelected && appState.discountAmount > 0) {
                                displayFare = (calculatedFare - appState.discountAmount).round().clamp(0, 999999);
                              }

                              String? vehicleImagePath = getJsonField(dataItem, r'''$.vehicle_image''')?.toString();
                              String? vehicleImageUrl;
                              if (vehicleImagePath != null && vehicleImagePath != 'null' && vehicleImagePath.isNotEmpty) {
                                vehicleImageUrl = vehicleImagePath.startsWith('http')
                                    ? vehicleImagePath
                                    : 'https://ugotaxi.icacorp.org/$vehicleImagePath';
                              }

                              final seatingCapacity = getJsonField(dataItem, r'''$.seating_capacity''')?.toString() ?? '';

                              return Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (displayFare > 0) {
                                        setState(() {
                                          selectedVehicleType = vehicleType;
                                          appState.vehicleselect = vehicleType!;
                                          // ✅ STORE IN APP STATE
                                        appState.selectedBaseFare = baseFare;
                                        appState.selectedPricePerKm = pricePerKm;
                                        });
                                      } else {
                                        _showError('This vehicle is not available');
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Color(0xFFFFF8F0) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? Color(0xFFFF7B10) : Colors.grey[200]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                          BoxShadow(
                                            color: Color(0xFFFF7B10).withOpacity(0.15),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ]
                                            : [],
                                      ),
                                      child: Row(
                                        children: [
                                          // Vehicle Image
                                          Container(
                                            width: 70,
                                            height: 70,
                                            child: vehicleImageUrl != null
                                                ? Image.network(
                                              vehicleImageUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.directions_car,
                                                size: 40,
                                                color: Colors.grey[400],
                                              ),
                                            )
                                                : Icon(
                                              Icons.directions_car,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          SizedBox(width: 4),

                                          // Vehicle Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Text(
                                                //   vehicleName ?? 'UGO',
                                                //   style: GoogleFonts.inter(
                                                //     fontSize: 16,
                                                //     fontWeight: FontWeight.w700,
                                                //     color: Colors.black,
                                                //   ),
                                                // ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      vehicleName ?? 'UGO',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.black,
                                                      ),
                                                    ),

                                                    if (isProRide) ...[
                                                      SizedBox(width: 0),
                                                      Text(
                                                        '👑', // you can use 👑 ⚡ 🚀 ⭐
                                                        style: TextStyle(fontSize: 16),
                                                      ),
                                                    ],
                                                  ],
                                                ),

                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    SizedBox(width: 0),
                                                    Text(
                                                      '2 mins away',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (seatingCapacity.isNotEmpty) ...[
                                                      Text(' • ', style: TextStyle(color: Colors.grey[400])),
                                                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                                      Text(
                                                        ' $seatingCapacity',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Price
                                          // Column(
                                          //   crossAxisAlignment: CrossAxisAlignment.end,
                                          //   children: [
                                          //     if (isSelected && appState.discountAmount > 0 && calculatedFare > 0) ...[
                                          //       Text(
                                          //         '₹$calculatedFare',
                                          //         style: GoogleFonts.inter(
                                          //           fontSize: 13,
                                          //           decoration: TextDecoration.lineThrough,
                                          //           color: Colors.grey[500],
                                          //           fontWeight: FontWeight.w500,
                                          //         ),
                                          //       ),
                                          //       SizedBox(height: 2),
                                          //     ],
                                          //     Text(
                                          //       displayFare > 0 ? '₹$displayFare' : '₹--',
                                          //       style: GoogleFonts.inter(
                                          //         fontSize: 22,
                                          //         fontWeight: FontWeight.w900,
                                          //         color: displayFare > 0 ? Colors.black : Colors.grey[400],
                                          //       ),
                                          //     ),
                                          //   ],
                                          // ),
                                          Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isSelected && appState.discountAmount > 0 && calculatedFare > 0) ...[
                                        Text(
                                          '₹$calculatedFare',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                      ],

                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: displayFare > 0
                                              ? (isSelected
                                                  ? Color(0xFFFF7B10)
                                                  : isProRide
                                                      ? Color(0xFFFFF2E8)
                                                      : Color(0xFFF5F5F5))
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected
                                                ? Color(0xFFFF7B10)
                                                : isProRide
                                                    ? Color(0xFFFF7B10).withOpacity(0.4)
                                                    : Colors.transparent,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          displayFare > 0 ? '₹$displayFare' : '₹--',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: displayFare > 0
                                                ? (isSelected ? Colors.white : Colors.black)
                                                : Colors.grey[500],
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
                            },
                          );
                        },
                      ),
                    ),

                    // Bottom Action Section
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Payment & Coupon Row
                          Row(
  children: [
    // PAYMENT OPTIONS BUTTON
    InkWell(
      onTap: () {
        setState(() {
          showPaymentOptions = !showPaymentOptions;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.payment, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Payment Options',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),

            // ⬇️ CAP / DROPDOWN ICON
            Icon(
              showPaymentOptions
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 20,
            ),
          ],
        ),
        
      ),
    ),

    const Spacer(),

    // OFFERS BUTTON
    InkWell(
      onTap: () => context.pushNamed(VoucherWidget.routeName),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            Icon(Icons.local_offer_outlined, size: 16),
            SizedBox(width: 6),
            Text(
              'Offers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
if (showPaymentOptions) ...[
  const SizedBox(height: 12),

  InkWell(
    onTap: () {
      setState(() => showPaymentOptions = false);
      // context.pushNamed(CashPaymentWidget.routeName);
    },
    child: _simpleOptionTile(
      'Cash',
      Icons.money,
    ),
  ),

  const SizedBox(height: 8),

  InkWell(
    onTap: () {
      setState(() => showPaymentOptions = false);
      context.pushNamed(WalletWidget.routeName);
    },
    child: _simpleOptionTile(
      'Wallet',
      Icons.account_balance_wallet,
    ),
  ),
],


                          SizedBox(height: 16),

                          // Confirm Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoadingRide || selectedVehicleType == null
                                  ? null
                                  : _confirmBooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF7B10),
                                disabledBackgroundColor: Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isLoadingRide
                                  ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : Text(
                                'Confirm ${selectedVehicleType != null ? _getVehicleName(selectedVehicleType!) : "Ride"}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
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
        ],
      ),
    );
  }

  String _getVehicleName(String vehicleId) {
    if (_cachedVehicleData == null) return 'Ride';

    for (var vehicle in _cachedVehicleData!) {
      String? vId = getJsonField(vehicle, r'''$.pricing.vehicle_id''')?.toString();
      if (vId == vehicleId) {
        return getJsonField(vehicle, r'''$.vehicle_name''')?.toString() ?? 'Ride';
      }
    }
    return 'Ride';
  }

  Future<void> _confirmBooking() async {
    final appState = FFAppState();

    if (selectedVehicleType == null) {
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

      int finalVehicleId = int.tryParse(selectedVehicleType ?? '0') ?? 0;

      for (var vehicle in vehicleData) {
        String? vId = getJsonField(vehicle, r'''$.pricing.vehicle_id''')?.toString();
        vId ??= getJsonField(vehicle, r'''$.vehicle_name''')?.toString();

        if (vId == selectedVehicleType) {
          final pricing = getJsonField(vehicle, r'''$.pricing''');
          baseKmStart = double.tryParse(getJsonField(pricing, r'''$.base_km_start''').toString()) ?? 1;
          baseKmEnd = double.tryParse(getJsonField(pricing, r'''$.base_km_end''').toString()) ?? 5;
          baseFare = double.tryParse(getJsonField(pricing, r'''$.base_fare''').toString()) ?? 0;
          pricePerKm = double.tryParse(getJsonField(pricing, r'''$.price_per_km''').toString()) ?? 0;
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

      final int finalFare = (finalBaseFare - appState.discountAmount.round()).clamp(0, 999999).toInt();

      print('🚀 Creating Ride | Vehicle ID: $finalVehicleId | Fare: ₹$finalFare');

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
      );

      if (createRideRes.succeeded) {
        final rideId = CreateRideCall.rideId(createRideRes.jsonBody)?.toString() ??
            getJsonField(createRideRes.jsonBody, r'''$.data.id''')?.toString();

        if (rideId == null) throw Exception('No ride ID returned');

        print('✅ Ride Created: $rideId');
        // ✅ STORE RIDE ID GLOBALLY
       appState.currentRideId = int.parse(rideId);


        await context.pushNamed(
          AutoBookWidget.routeName,
          queryParameters: {
            'rideId': rideId,
            'vehicleType': selectedVehicleType!,
            'pickupLocation': appState.pickuplocation ?? '',
            'dropLocation': appState.droplocation ?? '',
            'estimatedFare': finalFare.toString(),
            'estimatedDistance': roadDistance.toStringAsFixed(2),
            'baseFare': baseFare.toString(),
            'pricePerKm': pricePerKm.toString(),
          },
        );
      } else {
        final errorMsg = CreateRideCall.getResponseMessage(createRideRes.jsonBody) ??
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
 Widget _simpleOptionTile(String text, IconData icon) {
  return Container(
    width: 160,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.black),
        SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Spacer(),
        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ],
    ),
  );
}


}
