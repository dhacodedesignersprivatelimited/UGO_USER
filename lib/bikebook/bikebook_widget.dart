import 'dart:math' as math;

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bikebook_model.dart';
export 'bikebook_model.dart';

/// Enhanced Uber-Style Ride Booking Screen
class BikebookWidget extends StatefulWidget {
  const BikebookWidget({super.key, this.rideId});

  /// Optional; falls back to [FFAppState.currentRideId] for live fare / driver phone.
  final int? rideId;

  static String routeName = 'bikebook';
  static String routePath = '/bikebook';

  @override
  State<BikebookWidget> createState() => _BikebookWidgetState();
}

class _BikebookWidgetState extends State<BikebookWidget>
    with SingleTickerProviderStateMixin {
  late BikebookModel _model;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _ride;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BikebookModel());
    final app = FFAppState();
    final plat = app.pickupLatitude;
    final plng = app.pickupLongitude;
    if (plat != null && plng != null && plat != 0 && plng != 0) {
      _model.googleMapsCenter = LatLng(plat, plng);
    }

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRideDetails());
  }

  int? get _effectiveRideId => widget.rideId ?? FFAppState().currentRideId;

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  double? _tripKmFromState() {
    final app = FFAppState();
    final lat1 = app.pickupLatitude;
    final lng1 = app.pickupLongitude;
    final lat2 = app.dropLatitude;
    final lng2 = app.dropLongitude;
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null)
      return null;
    if (lat1 == 0 && lng1 == 0) return null;
    return _haversineKm(lat1, lng1, lat2, lng2);
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const p = math.pi / 180;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _fetchRideDetails() async {
    final id = _effectiveRideId;
    if (id == null) return;
    try {
      final res = await GetRideDetailsCall.call(
        rideId: id,
        token: FFAppState().accessToken,
      );
      if (!mounted || !res.succeeded) return;
      final raw = getJsonField(res.jsonBody, r'$.data');
      if (raw == null) return;
      final ride = raw is Map<String, dynamic>
          ? Map<String, dynamic>.from(raw)
          : Map<String, dynamic>.from(raw as Map);
      setState(() => _ride = ride);
    } catch (_) {}
  }

  String _vehicleTitle() {
    final v = _ride?['vehicle'];
    if (v is Map) {
      final n = v['vehicle_name']?.toString().trim();
      if (n != null && n.isNotEmpty) return n.toUpperCase();
    }
    final vs = FFAppState().vehicleselect.trim();
    return vs.isNotEmpty ? vs.toUpperCase() : 'UGO RIDE';
  }

  String _vehicleSubtitle() {
    final v = _ride?['vehicle'];
    if (v is Map) {
      final m = v['vehicle_model']?.toString().trim();
      if (m != null && m.isNotEmpty) return m;
    }
    return FFAppState().vehicleselect.trim().isNotEmpty
        ? FFAppState().vehicleselect
        : 'Ride';
  }

  String _fareDisplay() {
    final est = _asDouble(_ride?['estimated_fare']);
    final fin = _asDouble(_ride?['final_fare']);
    final fromRide = fin ?? est;
    if (fromRide != null && fromRide > 0)
      return '₹${fromRide.toStringAsFixed(2)}';
    final f = FFAppState().selectedBaseFare;
    if (f > 0) return '₹${f.toStringAsFixed(2)}';
    return '—';
  }

  String _distanceSubtitle() {
    final apiKm = _asDouble(_ride?['ride_distance_km']);
    final km = apiKm ?? _tripKmFromState();
    if (km == null || km <= 0) return '—';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  String? _etaSubtitle() {
    final dLat = _asDouble(_ride?['driver_latitude']);
    final dLng = _asDouble(_ride?['driver_longitude']);
    final pLat =
        _asDouble(_ride?['pickup_latitude']) ?? FFAppState().pickupLatitude;
    final pLng =
        _asDouble(_ride?['pickup_longitude']) ?? FFAppState().pickupLongitude;
    if (dLat == null || dLng == null || pLat == null || pLng == null)
      return null;
    final km = _haversineKm(dLat, dLng, pLat, pLng);
    if (km <= 0) return null;
    const avgKmh = 22.0;
    final mins = (km / avgKmh * 60).round().clamp(1, 999);
    return '~$mins min away';
  }

  String _pickupAddress() {
    final r = _ride;
    final fromApi = r?['pickup_location_address']?.toString().trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    final a = FFAppState().pickuplocation.trim();
    return a.isNotEmpty ? a : 'Pickup';
  }

  String _dropAddress() {
    final r = _ride;
    final fromApi = r?['drop_location_address']?.toString().trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    final a = FFAppState().droplocation.trim();
    return a.isNotEmpty ? a : 'Drop-off';
  }

  String? _driverPhoneDigits() {
    final d = _ride?['driver'];
    if (d is! Map) return null;
    final raw = d['mobile_number']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _contactDriver() async {
    final digits = _driverPhoneDigits();
    if (digits == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver number not available yet')),
        );
      }
      return;
    }
    await _makeCall(digits);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FFAppState(),
      builder: (context, _) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            resizeToAvoidBottomInset: false,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Map Background
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                    ),
                    child: FlutterFlowGoogleMap(
                      controller: _model.googleMapsController,
                      onCameraIdle: (latLng) =>
                          _model.googleMapsCenter = latLng,
                      initialLocation: _model.googleMapsCenter ??=
                          LatLng(13.106061, -59.613158),
                      markerColor: GoogleMarkerColor.violet,
                      mapType: MapType.normal,
                      style: GoogleMapStyle.uber,
                      initialZoom: 14.0,
                      allowInteraction: true,
                      allowZoom: true,
                      showZoomControls: false,
                      showLocation: true,
                      showCompass: false,
                      showMapToolbar: false,
                      showTraffic: false,
                      centerMapOnMarkerTap: true,
                      mapTakesGesturePreference: false,
                    ),
                  ),

                  // Custom Top Bar with Glassmorphism
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        bottom: 12,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => context.pop(),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _vehicleTitle(),
                              style: GoogleFonts.interTight(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3D8033),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.menu, color: Colors.black),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Animated Route Line
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35,
                    left: MediaQuery.of(context).size.width * 0.2,
                    right: MediaQuery.of(context).size.width * 0.2,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3D8033),
                            Color(0xFF5CB847),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF3D8033).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pickup Location Marker
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.32,
                    left: MediaQuery.of(context).size.width * 0.15,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.circle,
                        color: Color(0xFF3D8033),
                        size: 16,
                      ),
                    ),
                  ),

                  // Drop Location Marker
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.32,
                    right: MediaQuery.of(context).size.width * 0.15,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF3D8033),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF3D8033).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Bike Icon (moving along route)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.31,
                    left: MediaQuery.of(context).size.width * 0.45,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF7B10),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF7B10).withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.two_wheeler,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Bottom Sheet with Booking Details
                  AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Transform.translate(
                          offset: Offset(
                              0,
                              MediaQuery.of(context).size.height *
                                  0.5 *
                                  _slideAnimation.value),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle
                          Container(
                            margin: EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // Status Header
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF3D8033)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF3D8033),
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ride Confirmed',
                                        style: GoogleFonts.interTight(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Your rider is on the way',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Divider
                          Divider(height: 1, color: Color(0xFFE0E0E0)),

                          // Ride Details Card
                          Container(
                            margin: EdgeInsets.all(16),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF3D8033).withValues(alpha: 0.05),
                                  Color(0xFF5CB847).withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(0xFF3D8033).withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Vehicle Type & Price
                                Row(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          'assets/images/Group_2967.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _vehicleSubtitle(),
                                                style: GoogleFonts.interTight(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF3D8033),
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF3D8033),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFF3D8033)
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  _fareDisplay(),
                                                  style: GoogleFonts.interTight(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (_etaSubtitle() != null) ...[
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Color(0xFF757575),
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  _etaSubtitle()!,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: Color(0xFF757575),
                                                  ),
                                                ),
                                                SizedBox(width: 16),
                                              ],
                                              Icon(
                                                Icons.route,
                                                size: 16,
                                                color: Color(0xFF757575),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                _distanceSubtitle(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: Color(0xFF757575),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 20),

                                // Route Details
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF3D8033),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pickup',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: Color(0xFF9E9E9E),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  _pickupAddress(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            left: 3, top: 4, bottom: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 2,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFE0E0E0),
                                                borderRadius:
                                                    BorderRadius.circular(1),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Color(0xFFFF7B10),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Drop-off',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: Color(0xFF9E9E9E),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  _dropAddress(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w600,
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
                              ],
                            ),
                          ),

                          // Action Buttons
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Column(
                              children: [
                                // Contact Driver Button
                                Container(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _contactDriver,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Color(0xFF3D8033),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Color(0xFF3D8033),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.phone, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Contact Driver',
                                          style: GoogleFonts.interTight(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 12),

                                // Cancel Ride Button
                                Container(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: () => context
                                        .pushNamed(CancelRideWidget.routeName),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFF7B10),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: Color(0xFFFF7B10)
                                          .withValues(alpha: 0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel Ride',
                                      style: GoogleFonts.interTight(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
          ),
        );
      },
    );
  }
}
