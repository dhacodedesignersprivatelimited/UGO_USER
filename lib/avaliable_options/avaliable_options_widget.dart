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
import 'avaliable_options_model.dart';
export 'avaliable_options_model.dart';

const String GOOGLE_MAPS_API_KEY = 'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y';

class AvaliableOptionsWidget extends StatefulWidget {
  const AvaliableOptionsWidget({super.key});

  static String routeName = 'avaliable-options';
  static String routePath = '/avaliableOptions';

  @override
  State<AvaliableOptionsWidget> createState() =>
      _AvaliableOptionsWidgetState();
}

class _AvaliableOptionsWidgetState extends State<AvaliableOptionsWidget>
    with TickerProviderStateMixin {
  late AvaliableOptionsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  String? selectedVehicleType;
  bool isLoadingRide = false;
  bool isScanning = false;
  
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  bool showMap = true;
  
  double? googleDistanceKm;
  String? googleDuration;

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
  }

  Future<void> _initializeMap() async {
    await _addMarkers();
    await _getRoutePolyline();
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

  Future<void> _getRoutePolyline() async {
    if (FFAppState().pickupLatitude == null ||
        FFAppState().pickupLongitude == null ||
        FFAppState().dropLatitude == null ||
        FFAppState().dropLongitude == null) {
      return;
    }

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${FFAppState().pickupLatitude},${FFAppState().pickupLongitude}&destination=${FFAppState().dropLatitude},${FFAppState().dropLongitude}&key=$GOOGLE_MAPS_API_KEY';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['routes'].isNotEmpty) {
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
          });

          if (mapController != null) {
            _animateCameraToBounds(points);
          }
        }
      }
    } catch (e) {
      print('Error getting route: $e');
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

  void _showQRResponseDialog(Map<String, dynamic> qrData) {
    final pickupLocation = FFAppState().pickuplocation.isNotEmpty 
      ? FFAppState().pickuplocation 
      : 'Pickup Location';
    
    final dropLocation = FFAppState().droplocation.isNotEmpty 
      ? FFAppState().droplocation 
      : 'Drop Location';

    final tripFare = qrData['fare']?.toString() ?? '100.00';
    
    double distance = googleDistanceKm ?? 0.0;
    if (distance == 0.0 && FFAppState().pickupLatitude != null &&
        FFAppState().pickupLongitude != null &&
        FFAppState().dropLatitude != null &&
        FFAppState().dropLongitude != null) {
      distance = calculateDistance(
        FFAppState().pickupLatitude!,
        FFAppState().pickupLongitude!,
        FFAppState().dropLatitude!,
        FFAppState().dropLongitude!,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFFF7B10),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFF7B10),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'UGO TAXI',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.interTight(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFFFF7B10),
                            size: 45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver details',
                          style: GoogleFonts.interTight(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver name: ${qrData['driver_name'] ?? 'N/A'}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),

                            Text(
                              'Vehicle number: ${qrData['vehicle_number'] ?? qrData['vehicle_id'] ?? 'N/A'}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),

                            Row(
                              children: [
                                Text(
                                  'Rating: ',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.star,
                                  color: Color(0xFFFFDE14),
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${qrData['rating'] ?? '4.5'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            Text(
                              'Pickup location: $pickupLocation',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),

                            Text(
                              'Drop location: $dropLocation',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),

                            Text(
                              'Drop distance: ${distance.toStringAsFixed(1)}km',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),

                            Text(
                              'Trip amount: ₹$tripFare',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Text(
                          'TIP AMOUNT',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTipButton('10'),
                            _buildTipButton('20'),
                            _buildTipButton('30'),
                          ],
                        ),

                        SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          height: 60,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total amount',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF2D7E20),
                                ),
                              ),
                              Text(
                                '₹$tripFare',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF2D7E20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 110,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Color(0xFFF01C1C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(dialogContext),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.interTight(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(left: 16),
                            height: 56,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF7B10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  Navigator.pop(dialogContext);
                                  await Future.delayed(
                                    Duration(milliseconds: 300),
                                  );
                                  if (mounted) {
                                    context.pushNamed(
                                      AutoBookWidget.routeName,
                                      queryParameters: {
                                        'rideId': 'qr_${DateTime.now().millisecondsSinceEpoch}',
                                        'driverId': qrData['driver_id'].toString(),
                                        'driverName': qrData['driver_name'] ?? 'Driver',
                                        'license_plate': qrData['vehicle_number'] ?? 'N/A',
                                        'rating': (qrData['rating'] ?? '4.5').toString(),
                                        'pickupLocation': pickupLocation,
                                        'dropLocation': dropLocation,
                                        'tripFare': tripFare,
                                        'distance': distance.toString(),
                                      },
                                    );
                                  }
                                },
                                child: Center(
                                  child: Text(
                                    'Continue',
                                    style: GoogleFonts.interTight(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
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
        );
      },
    );
  }

  Widget _buildTipButton(String amount) {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFFE0E0E0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => print('Tip: ₹$amount selected'),
          child: Center(
            child: Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFFE0A30B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleQRScan() async {
    setState(() => isScanning = true);

    try {
      final scanResult = await FlutterBarcodeScanner.scanBarcode(
        '#FF7B10',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      if (scanResult == '-1') {
        setState(() => isScanning = false);
        return;
      }

      try {
        final decodedData = jsonDecode(scanResult);
        _showQRResponseDialog(decodedData);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Scanned: $scanResult'),
            backgroundColor: Color(0xFFFF7B10),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isScanning = false);
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    _animationController.dispose();
    _model.dispose();
    super.dispose();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    double dLon = (lon2 - lon1) * (3.141592653589793 / 180);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (3.141592653589793 / 180)) * 
        cos(lat2 * (3.141592653589793 / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    double currentDistance = googleDistanceKm ?? 0.0;
    if (currentDistance == 0.0 && FFAppState().pickupLatitude != null &&
        FFAppState().pickupLongitude != null &&
        FFAppState().dropLatitude != null &&
        FFAppState().dropLongitude != null) {
      currentDistance = calculateDistance(
        FFAppState().pickupLatitude!,
        FFAppState().pickupLongitude!,
        FFAppState().dropLatitude!,
        FFAppState().dropLongitude!,
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Map as background
            Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.45,
              child: GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                  if (markers.isNotEmpty) {
                    _initializeMap();
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    FFAppState().pickupLatitude ?? 17.3850,
                    FFAppState().pickupLongitude ?? 78.4867,
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
            ),

            // Back button
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
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.black, size: 24),
                ),
              ),
            ),

            // Bottom UI (Rapido Style)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
                ),
                child: Column(
                  children: [
                    // Pull Handle
                    Container(
                      margin: EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),

                    // Distance/Duration Badge
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Choose Your Ride',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Color(0xFFFFF3F0), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Icon(Icons.speed, color: Color(0xFFFF7B10), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  '${currentDistance.toStringAsFixed(1)} km • ${googleDuration ?? "Calculating..."}',
                                  style: GoogleFonts.inter(color: Color(0xFFFF7B10), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Vehicle List
                    Expanded(
                      child: FutureBuilder<ApiCallResponse>(
                        future: GetVehicleDetailsCall.call(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10)));
                          }

                          final jsonList = (getJsonField(snapshot.data!.jsonBody, r'''$.data''') as List).toList();

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: jsonList.length,
                            itemBuilder: (context, index) {
                              final dataItem = jsonList[index];
                              final vehicleType = getJsonField(dataItem, r'''$.vehicle_type''').toString();
                              final pricePerKm = double.tryParse(getJsonField(dataItem, r'''$.kilometer_per_price''').toString()) ?? 0.0;
                              final estimatedFare = currentDistance > 0 ? (currentDistance * pricePerKm).round() : 0;
                              final isSelected = selectedVehicleType == vehicleType;

                              return Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedVehicleType = vehicleType;
                                      FFAppState().vehicleselect = vehicleType;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Color(0xFFFDECD2).withOpacity(0.3) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isSelected ? Color(0xFFFF7B10) : Color(0xFFEEEEEE), width: isSelected ? 2 : 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.network(
                                          'https://ugotaxi.icacorp.org/${getJsonField(dataItem, r'''$.vehicle_image''')}',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(Icons.directions_car, size: 40, color: Colors.grey),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(vehicleType, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                                              Text('Get ride in 2 mins', style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF00D084), fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('₹$estimatedFare', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                                            if (isSelected) 
                                              Text('Best Price', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF7B10))),
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

                    // Bottom Bar
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Payment/Coupon Row
                          Row(
                            children: [
                              Icon(Icons.wallet, size: 18, color: Color(0xFF00D084)),
                              SizedBox(width: 8),
                              Text('Cash', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              Spacer(),
                              Text('Apply Coupon', style: GoogleFonts.inter(color: Color(0xFFFF7B10), fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Confirm Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoadingRide || selectedVehicleType == null ? null : _confirmBooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF7B10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: isLoadingRide 
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('CONFIRM BOOKING', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
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

  Future<void> _confirmBooking() async {
    setState(() => isLoadingRide = true);
    
    try {
      // Calculate current road distance and price
      double roadDistance = googleDistanceKm ?? 0.0;
      if (roadDistance == 0) roadDistance = calculateDistance(FFAppState().pickupLatitude!, FFAppState().pickupLongitude!, FFAppState().dropLatitude!, FFAppState().dropLongitude!);
      
      final response = await GetVehicleDetailsCall.call();
      final jsonList = (getJsonField(response.jsonBody, r'''$.data''') as List).toList();
      double pricePerKm = 0.0;
      for (var v in jsonList) {
        if (getJsonField(v, r'''$.vehicle_type''').toString() == selectedVehicleType) {
          pricePerKm = double.tryParse(getJsonField(v, r'''$.kilometer_per_price''').toString()) ?? 0.0;
          break;
        }
      }
      
      final estimatedFare = (roadDistance * pricePerKm).round();

      final createRideRes = await CreateRideCall.call(
        token: FFAppState().accessToken,
        userId: FFAppState().userid,
        pickuplocation: FFAppState().pickuplocation,
        droplocation: FFAppState().droplocation,
        pickuplat: FFAppState().pickupLatitude!,
        pickuplon: FFAppState().pickupLongitude!,
        droplat: FFAppState().dropLatitude!,
        droplon: FFAppState().dropLongitude!,
        ridetype: selectedVehicleType,
      );

      if (createRideRes.succeeded) {
        final rideId = getJsonField(createRideRes.jsonBody, r'''$.data.id''').toString();
        context.pushNamed(
          AutoBookWidget.routeName,
          queryParameters: {
            'rideId': rideId,
            'vehicleType': selectedVehicleType,
            'pickupLocation': FFAppState().pickuplocation,
            'dropLocation': FFAppState().droplocation,
            'estimatedFare': estimatedFare.toString(),
            'estimatedDistance': roadDistance.toStringAsFixed(2),
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getJsonField(createRideRes.jsonBody, r'''$.message''').toString())));
      }
    } finally {
      setState(() => isLoadingRide = false);
    }
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFE0E0E0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => false;
}
