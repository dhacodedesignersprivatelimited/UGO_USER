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
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, sin;
import 'dart:async';
import 'dart:io';
import 'avaliable_options_model.dart';
export 'avaliable_options_model.dart';

// ✅ SECURITY: Move to environment variable or backend proxy
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
  late AnimationController _animationController;

  // ✅ State variables
  String? selectedVehicleType;
  bool isLoadingRide = false;
  bool isScanning = false;
  bool isCalculatingRoute = false;

  // ✅ Map state
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  bool showMap = true;

  // ✅ Route data
  double? googleDistanceKm;
  String? googleDuration;

  // ✅ Cached vehicle data for performance
  List<dynamic>? _cachedVehicleData;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AvaliableOptionsModel());
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
    _initializeMap();

    // ✅ DEBUG: Remove in production
    _debugVehicleAPI();
  }

  // ✅ DEBUG: Check vehicle API response
  Future<void> _debugVehicleAPI() async {
    try {
      final response = await GetVehicleDetailsCall.call();
      print('🚗 Vehicle API Full Response:');
      print(jsonEncode(response.jsonBody));
      print('\n🚗 Parsed Data:');
      final data = getJsonField(response.jsonBody, r'''$.data''');
      print(jsonEncode(data));
    } catch (e) {
      print('❌ Vehicle API Error: $e');
    }
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
    if (FFAppState().pickupLatitude != null &&
        FFAppState().pickupLongitude != null &&
        FFAppState().dropLatitude != null &&
        FFAppState().dropLongitude != null) {
      setState(() {
        markers.clear();
        markers.add(
          Marker(
            markerId: MarkerId('pickup'),
            position: LatLng(
              FFAppState().pickupLatitude!,
              FFAppState().pickupLongitude!,
            ),
            infoWindow: InfoWindow(
              title: 'Pickup Location',
              snippet: FFAppState().pickuplocation,
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
              FFAppState().dropLatitude!,
              FFAppState().dropLongitude!,
            ),
            infoWindow: InfoWindow(
              title: 'Drop Location',
              snippet: FFAppState().droplocation,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      });
    }
  }

  // ✅ IMPROVED: Better error handling for route calculation
  Future<void> _getRoutePolyline() async {
    if (FFAppState().pickupLatitude == null ||
        FFAppState().pickupLongitude == null ||
        FFAppState().dropLatitude == null ||
        FFAppState().dropLongitude == null) {
      _showError('Invalid location coordinates');
      return;
    }

    setState(() => isCalculatingRoute = true);

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${FFAppState().pickupLatitude},${FFAppState().pickupLongitude}'
          '&destination=${FFAppState().dropLatitude},${FFAppState().dropLongitude}'
          '&key=$GOOGLE_MAPS_API_KEY';

      final response = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Route calculation timed out'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // ✅ Check API response status
        if (json['status'] != 'OK') {
          throw Exception('Google Maps API error: ${json['status']}');
        }

        if (json['routes'].isEmpty) {
          throw Exception('No route found between locations');
        }

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
              color: Color(0xFFFF7B10),
              width: 5,
              geodesic: true,
            ),
          );
          isCalculatingRoute = false;
        });

        if (mapController != null && points.isNotEmpty) {
          _animateCameraToBounds(points);
        }
      } else {
        throw HttpException(
          'Failed to fetch route: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout: $e');
      _useFallbackDistance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route calculation timed out. Using estimated distance.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      _useFallbackDistance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No internet connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error getting route: $e');
      _useFallbackDistance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not calculate route. Using estimated distance.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ✅ Fallback to Haversine distance calculation
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
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    _animationController.dispose();
    _model.dispose();

    // ✅ Clear data to free memory
    markers.clear();
    polylines.clear();
    _cachedVehicleData = null;

    super.dispose();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
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

  // ✅ Cache vehicle data for performance and retry mechanism
  Future<List<dynamic>> _getVehicleData({bool forceRefresh = false}) async {
    if (_cachedVehicleData != null && !forceRefresh) {
      return _cachedVehicleData!;
    }

    ApiCallResponse response;
    try {
      response = await GetVehicleDetailsCall.call();
    } catch (e) {
      print('❌ Error calling GetVehicleDetailsCall: $e');
      _showError('Failed to fetch vehicle details. Please retry.');
      return [];
    }

    if (response.succeeded) {
      final jsonList = (getJsonField(
        response.jsonBody,
        r'''$.data''',
      ) as List?)?.toList() ?? [];
      _cachedVehicleData = jsonList;
      return jsonList;
    } else {
      final errorMsg = getJsonField(
        response.jsonBody,
        r'''$.message''',
      )?.toString() ?? 'Failed to load vehicles from API.';
      print('❌ GetVehicleDetailsCall failed: ${response.statusCode} - $errorMsg');
      _showError(errorMsg);
      return [];
    }
  }

  // ✅ Show error snackbar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();

    // ✅ Use single source of truth for distance
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ✅ Map Section
            Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.45,
              child: Stack(
                children: [
                  GoogleMap(
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
                  ),

                  // ✅ Loading overlay for route calculation
                  if (isCalculatingRoute)
                    Container(
                      color: Colors.black26,
                      child: Center(
                        child: Card(
                          margin: EdgeInsets.all(32),
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFFFF7B10),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Calculating best route...',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ✅ Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: InkWell(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8)
                    ],
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.black, size: 24),
                ),
              ),
            ),

            // ✅ Bottom Sheet with Vehicle Options
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // ✅ Handle bar
                    Container(
                      margin: EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // ✅ Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Choose Your Ride',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF3F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.speed,
                                  color: Color(0xFFFF7B10),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${currentDistance.toStringAsFixed(1)} km • ${googleDuration ?? "Calculating..."}',
                                  style: GoogleFonts.inter(
                                    color: Color(0xFFFF7B10),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // ✅ IMPROVED: Vehicle List
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _getVehicleData(), // Uses cache on rebuild
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF7B10),
                              ),
                            );
                          }

                          // ✅ Error handling
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load vehicles',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _cachedVehicleData = null;
                                        // Trigger a re-fetch of vehicle data
                                        _getVehicleData(forceRefresh: true);
                                      });
                                    },
                                    child: Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final jsonList = snapshot.data ?? [];

                          if (jsonList.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No vehicles available',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Please try again later',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: jsonList.length,
                            itemBuilder: (context, index) {
                              final dataItem = jsonList[index];

                              // ✅ FIXED: Try multiple field names for vehicle type
                              String? vehicleType = getJsonField(
                                dataItem,
                                r'''$.pricing.vehicle_id''',
                              )?.toString();
                                  String? vehicleName = getJsonField(
                                dataItem,
                                r'''$.vehicle_name''',
                              )?.toString();
                              vehicleType ??= getJsonField(
                                dataItem,
                                r'''$.vehicle_name''',
                              )?.toString();
                              vehicleType ??= 'Unknown Vehicle';

                              // Remove 'null' string if API returns it
                              if (vehicleType == 'null' || vehicleType.isEmpty) {
                                vehicleType = 'Vehicle ${index + 1}';
                              }

                              // ✅ FIXED: Better price parsing with validation
                             final pricing =
                                  getJsonField(dataItem, r'''$.pricing''');

                              final baseKmStart = double.tryParse(
                                    getJsonField(
                                            pricing, r'''$.base_km_start''')
                                        .toString(),
                                  ) ??
                                  1;

                              final baseKmEnd = double.tryParse(
                                    getJsonField(pricing, r'''$.base_km_end''')
                                        .toString(),
                                  ) ??
                                  5;

                              final baseFare = double.tryParse(
                                    getJsonField(pricing, r'''$.base_fare''')
                                        .toString(),
                                  ) ??
                                  0;

                              final pricePerKm = double.tryParse(
                                    getJsonField(pricing, r'''$.price_per_km''')
                                        .toString(),
                                  ) ??
                                  0;

                 

                              // ✅ Debug print for each vehicle
                              print('🚗 Vehicle $index: $vehicleType, Price/km: ₹$pricePerKm');

                              // ✅ Calculate fare with validation
                           final calculatedFare = calculateTieredFare(
                                distanceKm: currentDistance,
                                baseKmStart: baseKmStart,
                                baseKmEnd: baseKmEnd,
                                baseFare: baseFare,
                                pricePerKm: pricePerKm,
                              ).round();


                              final isSelected = selectedVehicleType == vehicleType;

                              // Apply discount if selected
                              int displayFare = calculatedFare;
                              if (isSelected && appState.discountAmount > 0) {
                                displayFare = (calculatedFare - appState.discountAmount)
                                    .round()
                                    .clamp(0, 999999);
                              }

                              // ✅ Get vehicle image with fallback
                              String? vehicleImagePath = getJsonField(
                                dataItem,
                                r'''$.vehicle_image''',
                              )?.toString();
                              String? vehicleImageUrl;

                              if (vehicleImagePath != null &&
                                  vehicleImagePath != 'null' &&
                                  vehicleImagePath.isNotEmpty) {
                                vehicleImageUrl = vehicleImagePath.startsWith('http')
                                    ? vehicleImagePath
                                    : 'https://ugotaxi.icacorp.org/$vehicleImagePath';
                              }

                              // ✅ Get seating capacity
                              final seatingCapacity = getJsonField(
                                dataItem,
                                r'''$.seating_capacity''',
                              )?.toString() ?? '';

                              return Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    if (displayFare > 0) {
                                      setState(() {
                                        selectedVehicleType = vehicleType;
                                        appState.vehicleselect = vehicleType!;
                                      });
                                    } else {
                                      _showError('This vehicle is not available right now');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(0xFFFDECD2).withOpacity(0.3)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Color(0xFFFF7B10)
                                            : Color(0xFFEEEEEE),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // ✅ Vehicle image with better error handling
                                        vehicleImageUrl != null
                                            ? Image.network(
                                          vehicleImageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return SizedBox(
                                              width: 60,
                                              height: 60,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2,
                                                  color: Color(0xFFFF7B10),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.directions_car,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        )
                                            : Icon(
                                          Icons.directions_car,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                vehicleName!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Get ride in 2 mins',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: Color(0xFF00D084),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (seatingCapacity.isNotEmpty) ...[
                                                    Text(
                                                      ' • ',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.person,
                                                      size: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    Text(
                                                      ' $seatingCapacity',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              // ✅ Show price per km for transparency
                                              if (pricePerKm > 0)
                                                Text(
                                                  '₹${baseFare.toStringAsFixed(0)} (1–${baseKmEnd.toInt()}km) + ₹${pricePerKm.toStringAsFixed(0)}/km after',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            if (isSelected && appState.discountAmount > 0 && baseFare > 0) ...[
                                              Text(
                                                '₹$baseFare',
                                                style: TextStyle(
                                                  decoration: TextDecoration.lineThrough,
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                            ],
                                            Text(
                                              displayFare > 0 ? '₹$displayFare' : '₹--',
                                              style: GoogleFonts.inter(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: displayFare > 0
                                                    ? Colors.black
                                                    : Colors.grey,
                                              ),
                                            ),
                                            if (isSelected && displayFare > 0)
                                              Text(
                                                'Best Price',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFF7B10),
                                                ),
                                              ),
                                            // ✅ Show warning if fare is 0
                                            if (displayFare == 0)
                                              Text(
                                                'Unavailable',
                                                style: GoogleFonts.inter(
                                                  fontSize: 9,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // ✅ Bottom Action Bar
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        MediaQuery.of(context).padding.bottom + 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => context.pushNamed(WalletWidget.routeName),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.wallet,
                                      size: 18,
                                      color: Color(0xFF00D084),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cash',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Spacer(),
                              InkWell(
                                onTap: () => context.pushNamed(VoucherWidget.routeName),
                                child: Row(
                                  children: [
                                    Icon(
                                      appState.appliedCouponCode.isEmpty
                                          ? Icons.local_offer_outlined
                                          : Icons.check_circle,
                                      size: 16,
                                      color: Color(0xFFFF7B10),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      appState.appliedCouponCode.isEmpty
                                          ? 'Apply Coupon'
                                          : 'Coupon Applied: ${appState.appliedCouponCode}',
                                      style: GoogleFonts.inter(
                                        color: Color(0xFFFF7B10),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
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
                                'CONFIRM BOOKING',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
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
          ],
        ),
      ),
    );
  }

  // ✅ IMPROVED: Complete validation and error handling
  Future<void> _confirmBooking() async {
    final appState = FFAppState();

    // ✅ Validate all required data
    if (selectedVehicleType == null) {
      _showError('Please select a vehicle type');
      return;
    }

    if (appState.pickupLatitude == null ||
        appState.pickupLongitude == null ||
        appState.dropLatitude == null ||
        appState.dropLongitude == null) {
      _showError('Invalid location data. Please go back and select locations again.');
      return;
    }

    if (appState.accessToken.isEmpty) {
      _showError('Authentication error. Please login again.');
      context.pushNamed(LoginWidget.routeName);
      return;
    }

    setState(() => isLoadingRide = true);

    try {
      // ✅ Calculate road distance
      double roadDistance = googleDistanceKm ?? 0.0;
      if (roadDistance == 0) {
        roadDistance = calculateDistance(
          appState.pickupLatitude!,
          appState.pickupLongitude!,
          appState.dropLatitude!,
          appState.dropLongitude!,
        );
      }

      // Validate distance
      if (roadDistance <= 0) {
        throw Exception('Invalid distance calculation');
      }

      // ✅ Get vehicle details with caching
      final vehicleData = await _getVehicleData();
      // -------------------------------
// GET PRICING FOR SELECTED VEHICLE
// -------------------------------
      double baseKmStart = 1;
      double baseKmEnd = 5;
      double baseFare = 0;
      double pricePerKm = 0;

      for (var vehicle in vehicleData) {
        String? vType =
            getJsonField(vehicle, r'''$.vehicle_type''')?.toString();
        vType ??= getJsonField(vehicle, r'''$.vehicle_name''')?.toString();

        if (vType == selectedVehicleType) {
          final pricing = getJsonField(vehicle, r'''$.pricing''');

          baseKmStart = double.tryParse(
                getJsonField(pricing, r'''$.base_km_start''').toString(),
              ) ??
              1;

          baseKmEnd = double.tryParse(
                getJsonField(pricing, r'''$.base_km_end''').toString(),
              ) ??
              5;

          baseFare = double.tryParse(
                getJsonField(pricing, r'''$.base_fare''').toString(),
              ) ??
              0;

          pricePerKm = double.tryParse(
                getJsonField(pricing, r'''$.price_per_km''').toString(),
              ) ??
              0;

          break;
        }
      }

      if (baseFare == 0 || pricePerKm == 0) {
        throw Exception('Invalid pricing data for selected vehicle');
      }

// -------------------------------
// FINAL FARE CALCULATION
// -------------------------------
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


      if (pricePerKm == 0) {
        throw Exception('Unable to calculate fare for selected vehicle');
      }

    

      print('💰 Fare Calculation:');
      print('   Distance: ${roadDistance.toStringAsFixed(2)} km');
      print('   Price/km: ₹$pricePerKm');
      print('   Base Fare: ₹$baseFare');
      print('   Discount: ₹${appState.discountAmount}');
      print('   Final Fare: ₹$finalFare');

      // ✅ Create ride with proper parameters
      final createRideRes = await CreateRideCall.call(
        token: appState.accessToken,
        userId: appState.userid,
        pickupLocationAddress: appState.pickuplocation,
        dropLocationAddress: appState.droplocation,
        pickupLatitude: appState.pickupLatitude!,
        pickupLongitude: appState.pickupLongitude!,
        dropLatitude: appState.dropLatitude!,
        dropLongitude: appState.dropLongitude!,
        rideType: selectedVehicleType,
      );

      if (createRideRes.succeeded) {
        final rideIdField = getJsonField(
          createRideRes.jsonBody,
          r'''$.data.id''',
        );

        if (rideIdField == null) {
          throw Exception('Invalid ride ID in response');
        }

        final rideId = rideIdField.toString();

        print('✅ Ride created successfully: $rideId');

        // ✅ Navigate to booking screen
        await context.pushNamed(
          AutoBookWidget.routeName,
          queryParameters: {
            'rideId': rideId,
            'vehicleType': selectedVehicleType!,
            'pickupLocation': appState.pickuplocation ?? '',
            'dropLocation': appState.droplocation ?? '',
            'estimatedFare': finalFare.toString(),
            'estimatedDistance': roadDistance.toStringAsFixed(2),
          },
        );
      } else {
        final errorMsg = getJsonField(
          createRideRes.jsonBody,
          r'''$.message''',
        )?.toString() ?? 'Failed to create ride. Please try again.';

        print('❌ Ride creation failed: $errorMsg');
        _showError(errorMsg);
      }
    } on SocketException {
      _showError('No internet connection. Please check your network.');
    } on TimeoutException {
      _showError('Request timed out. Please try again.');
    } on FormatException catch (e) {
      _showError('Invalid data format: ${e.message}');
    } catch (e) {
      print('❌ Booking error: $e');
      _showError('Failed to create booking: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoadingRide = false);
      }
    }
  }
}
