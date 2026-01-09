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
import 'dart:math' show cos, sqrt, asin;
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
        // Pickup marker (Green)
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

        // Drop marker (Red)
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
          final legs = route['legs'][0];
          
          // Extract polyline points
          final points = _decodePolyline(
            route['overview_polyline']['points'],
          );

          setState(() {
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

          // Animate camera to show entire route
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
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }
// UPDATED _showQRResponseDialog with beautiful UI + dynamic locations
// COMPLETE FIXED _showQRResponseDialog with all helper widgets defined
// Place this entire code block in your _AvaliableOptionsWidgetState class

void _showQRResponseDialog(Map<String, dynamic> qrData) {
  // Get locations and estimated fare
  final pickupLocation = FFAppState().pickuplocation.isNotEmpty 
    ? FFAppState().pickuplocation 
    : 'Pickup Location';
  
  final dropLocation = FFAppState().droplocation.isNotEmpty 
    ? FFAppState().droplocation 
    : 'Drop Location';

  final tripFare = qrData['fare']?.toString() ?? '100.00';
  
  // Get estimated distance (use calculateDistance method)
  double distance = 0.0;
  if (FFAppState().pickupLatitude != null &&
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
                // Header Section with UGO TAXI branding
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

                // White Content Section
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver details title
                      Text(
                        'Driver details',
                        style: GoogleFonts.interTight(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Driver Information rows
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Driver Name
                          Text(
                            'Driver name: ${qrData['driver_name'] ?? 'N/A'}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Vehicle Number
                          Text(
                            'Vehicle number: ${qrData['vehicle_number'] ?? qrData['vehicle_id'] ?? 'N/A'}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Rating with Star
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

                          // Pickup Location
                          Text(
                            'Pickup location: $pickupLocation',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Drop Location
                          Text(
                            'Drop location: $dropLocation',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Drop Distance
                          Text(
                            'Drop distance: ${distance.toStringAsFixed(1)}km',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Trip Amount
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

                      // TIP AMOUNT Section
                      Text(
                        'TIP AMOUNT',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Tip Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
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
                                onTap: () {
                                  print('Tip: ₹10 selected');
                                },
                                child: Center(
                                  child: Text(
                                    '10',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFFE0A30B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
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
                                onTap: () {
                                  print('Tip: ₹20 selected');
                                },
                                child: Center(
                                  child: Text(
                                    '20',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFFE0A30B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
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
                                onTap: () {
                                  print('Tip: ₹30 selected');
                                },
                                child: Center(
                                  child: Text(
                                    '30',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFFE0A30B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Total Amount Box
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

                // Action Buttons
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
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

                      // Continue Button
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
                                      'driverId': qrData['driver_id'].toString(),
                                      'driverName': qrData['driver_name'] ?? 'Driver',
                                      'vehicleNumber': qrData['vehicle_number'] ?? 'N/A',
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

      // User cancelled scan
      if (scanResult == '-1') {
        setState(() => isScanning = false);
        return;
      }

      try {
        // Decode QR data
        final decodedData = jsonDecode(scanResult);
        _showQRResponseDialog(decodedData);
      } catch (e) {
        // If JSON parsing fails, show raw scan result
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
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  double sin(double value) {
    return value - (value * value * value) / 6 + (value * value * value * value * value) / 120;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    double estimatedDistance = 0.0;
    if (FFAppState().pickupLatitude != null &&
        FFAppState().pickupLongitude != null &&
        FFAppState().dropLatitude != null &&
        FFAppState().dropLongitude != null) {
      estimatedDistance = calculateDistance(
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
        backgroundColor: Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 60,
          leading: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFFF0F0F0),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 18,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Ride',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                '${estimatedDistance.toStringAsFixed(1)} km away',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              // Google Map with Route
              if (showMap)
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        mapController = controller;
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
                    ),
                  ),
                ),

              // Location Summary Card
              Padding(
                padding: EdgeInsets.all(16),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - _animationController.value)),
                      child: Opacity(
                        opacity: _animationController.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Pickup
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00D084),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pickup',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                  Text(
                                    FFAppState().pickuplocation.isNotEmpty
                                        ? FFAppState().pickuplocation
                                        : 'Location',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomPaint(
                                painter: DashedLinePainter(),
                                size: Size(double.infinity, 1),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Drop
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF7B10),
                              ),
                              child: Icon(
                                Icons.flag,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Drop off',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                  Text(
                                    FFAppState().droplocation.isNotEmpty
                                        ? FFAppState().droplocation
                                        : 'Location',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Icon(Icons.straighten,
                                      color: Color(0xFFFF7B10), size: 18),
                                  SizedBox(height: 4),
                                  Text(
                                    '${estimatedDistance.toStringAsFixed(1)} km',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Color(0xFFE0E0E0),
                              ),
                              Column(
                                children: [
                                  Icon(Icons.timer,
                                      color: Color(0xFF00D084), size: 18),
                                  SizedBox(height: 4),
                                  Text(
                                    '${(estimatedDistance * 2).toStringAsFixed(0)} min',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Available Rides Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available Rides',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              // Vehicle List
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<ApiCallResponse>(
                  future: GetVehicleDetailsCall.call(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox(
                        height: 400,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF7B10),
                          ),
                        ),
                      );
                    }

                    final jsonList =
                        (getJsonField(snapshot.data!.jsonBody, r'''$.data''')
                                as List)
                            .toList();

                    return Column(
                      children: List.generate(
                        jsonList.length,
                        (index) {
                          final dataItem = jsonList[index];
                          final vehicleType = getJsonField(
                            dataItem,
                            r'''$.vehicle_type''',
                          ).toString();
                          final pricePerKm = double.tryParse(
                                  getJsonField(dataItem,
                                          r'''$.kilometer_per_price''')
                                      .toString()) ??
                              0.0;
                          final estimatedFare =
                              estimatedDistance > 0
                                  ? estimatedDistance * pricePerKm
                                  : 0.0;
                          final isSelected = selectedVehicleType == vehicleType;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0,
                                      30 * (1 - _animationController.value)),
                                  child: Opacity(
                                    opacity: _animationController.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedVehicleType = vehicleType;
                                    FFAppState().vehicleselect =
                                        vehicleType;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Color(0xFFFFF3F0)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Color(0xFFFF7B10)
                                          : Color(0xFFE0E0E0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Color(0xFFFF7B10)
                                                  .withOpacity(0.1),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Image.network(
                                          'http://www.ugotaxi.com/${getJsonField(dataItem, r'''$.vehicle_image''')}',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.directions_car,
                                                size: 40,
                                                color: Color(0xFFCCCCCC),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      vehicleType,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      '₹${pricePerKm.toStringAsFixed(2)}/km',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Color(0xFF999999),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFFF7B10),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    '₹${estimatedFare.toStringAsFixed(0)}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 8),

                                            Row(
                                              children: [
                                                _buildFeature(
                                                  icon: Icons.person,
                                                  label:
                                                      '${getJsonField(dataItem, r'''$.seating_capacity''')} seats',
                                                ),
                                                SizedBox(width: 16),
                                                _buildFeature(
                                                  icon: Icons.luggage,
                                                  label:
                                                      '${getJsonField(dataItem, r'''$.luggage_capacity''')} bags',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (isSelected)
                                        Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFF7B10),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        )
                                      else
                                        SizedBox(width: 28),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // Bottom Action Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(
                              PaymentOptionsWidget.routeName);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.wallet,
                                    color: Color(0xFF00D084),
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Cash Payment',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF999999),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: isScanning ? null : _handleQRScan,
                            icon: Icon(isScanning ? Icons.hourglass_bottom : Icons.qr_code_2),
                            label: Text(isScanning ? 'Scanning...' : 'Scan'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: Color(0xFFFF7B10),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isLoadingRide ||
                                    selectedVehicleType == null
                                ? null
                                : () async {
                                    if (selectedVehicleType == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please select a vehicle'),
                                          backgroundColor: Color(0xFFFF7B10),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoadingRide = true);

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFFF7B10),
                                        ),
                                      ),
                                    );

                                    final response =
                                        await GetVehicleDetailsCall.call();
                                    final jsonList =
                                        (getJsonField(response.jsonBody,
                                                r'''$.data''') as List)
                                            .toList();

                                    double estimatedFare = 0.0;
                                    String vehicleImage = '';
                                    String seatingCapacity = '';
                                    String luggageCapacity = '';
                                    double pricePerKm = 0.0;

                                    for (var vehicle in jsonList) {
                                      if (getJsonField(vehicle,
                                              r'''$.vehicle_type''')
                                          .toString() ==
                                          selectedVehicleType) {
                                        pricePerKm = double.tryParse(
                                                getJsonField(vehicle,
                                                        r'''$.kilometer_per_price''')
                                                    .toString()) ??
                                            0.0;
                                        estimatedFare =
                                            estimatedDistance *
                                                pricePerKm;
                                        vehicleImage = getJsonField(vehicle,
                                                r'''$.vehicle_image''')
                                            .toString();
                                        seatingCapacity = getJsonField(vehicle,
                                                r'''$.seating_capacity''')
                                            .toString();
                                        luggageCapacity = getJsonField(vehicle,
                                                r'''$.luggage_capacity''')
                                            .toString();
                                        break;
                                      }
                                    }

                                    _model.apiResult85c =
                                        await CreateRideCall.call(
                                      token: FFAppState().accessToken,
                                      userId: FFAppState().userid,
                                      pickuplocation:
                                          FFAppState().pickuplocation,
                                      droplocation:
                                          FFAppState().droplocation,
                                      pickuplat:
                                          FFAppState().pickupLatitude!,
                                      pickuplon:
                                          FFAppState().pickupLongitude!,
                                      droplat: FFAppState().dropLatitude!,
                                      droplon: FFAppState().dropLongitude!,
                                      ridetype:
                                          FFAppState().vehicleselect,
                                    );

                                    Navigator.pop(context);

                                    if ((_model.apiResult85c?.succeeded ??
                                        false)) {
                                      final rideId = getJsonField(
                                        _model.apiResult85c?.jsonBody,
                                        r'''$.data.id''',
                                      ).toString();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Ride booked successfully!'),
                                          backgroundColor: Color(0xFF00D084),
                                        ),
                                      );

                                      context.pushNamed(
                                        AutoBookWidget.routeName,
                                        queryParameters: {
                                          'rideId': rideId,
                                          'vehicleType':
                                              FFAppState().vehicleselect,
                                          'pickupLocation':
                                              FFAppState().pickuplocation,
                                          'dropLocation':
                                              FFAppState().droplocation,
                                          'estimatedFare':
                                              estimatedFare.toString(),
                                          'estimatedDistance':
                                              estimatedDistance.toString(),
                                          'vehicleImage': vehicleImage,
                                          'seatingCapacity':
                                              seatingCapacity,
                                          'luggageCapacity':
                                              luggageCapacity,
                                          'pricePerKm': pricePerKm.toString(),
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            getJsonField(
                                              _model.apiResult85c?.jsonBody,
                                              r'''$.message''',
                                            ).toString(),
                                          ),
                                          backgroundColor: Color(0xFFFF7B10),
                                        ),
                                      );
                                    }

                                    setState(() => isLoadingRide = false);
                                  },
                            icon: Icon(
                              isLoadingRide ? Icons.hourglass_bottom : Icons.check_circle,
                              size: 18,
                            ),
                            label: Text(
                              isLoadingRide ? 'Booking...' : 'Confirm Ride',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF7B10),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: Color(0xFFFFCCCC),
                              disabledForegroundColor: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Color(0xFF999999), size: 16),
        SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
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
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => false;
}
