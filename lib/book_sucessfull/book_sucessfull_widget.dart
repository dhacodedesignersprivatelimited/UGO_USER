import 'dart:async';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'book_sucessfull_model.dart';
export 'book_sucessfull_model.dart';

class BookSucessfullWidget extends StatefulWidget {
  const BookSucessfullWidget({super.key, this.rideId});

  /// Optional; falls back to [FFAppState.currentRideId].
  final int? rideId;

  static String routeName = 'Book_sucessfull';
  static String routePath = '/bookSucessfull';

  @override
  State<BookSucessfullWidget> createState() => _BookSucessfullWidgetState();
}

class _BookSucessfullWidgetState extends State<BookSucessfullWidget> {
  late BookSucessfullModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _ride;
  Timer? _pollTimer;

  int? get _effectiveRideId => widget.rideId ?? FFAppState().currentRideId;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BookSucessfullModel());
    final app = FFAppState();
    final plat = app.pickupLatitude;
    final plng = app.pickupLongitude;
    if (plat != null && plng != null && plat != 0 && plng != 0) {
      _model.googleMapsCenter = LatLng(plat, plng);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRide();
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadRide(silent: true));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Future<void> _loadRide({bool silent = false}) async {
    final id = _effectiveRideId;
    if (id == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _ride = null;
          _error = null;
        });
      }
      return;
    }

    if (!silent && mounted) setState(() => _loading = true);

    try {
      final response = await GetRideDetailsCall.call(
        rideId: id,
        token: FFAppState().accessToken,
      );
      if (!mounted) return;

      if (response.succeeded) {
        final raw = getJsonField(response.jsonBody, r'$.data');
        Map<String, dynamic>? ride;
        if (raw is Map) {
          ride = Map<String, dynamic>.from(raw);
        }

        if (ride != null) {
          final plat = _asDouble(ride['pickup_latitude']);
          final plng = _asDouble(ride['pickup_longitude']);
          if (plat != null && plng != null) {
            _model.googleMapsCenter = LatLng(plat, plng);
          }
        }

        setState(() {
          _ride = ride;
          _error = null;
          _loading = false;
        });
      } else if (!silent) {
        setState(() {
          _error = response.bodyText.isNotEmpty ? response.bodyText : 'Could not load ride';
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _statusHeadline(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'SEARCHING':
      case 'PENDING':
        return 'Finding a driver';
      case 'ACCEPTED':
        return 'Driver is arriving';
      case 'STARTED':
      case 'ARRIVED':
        return 'Ride in progress';
      case 'COMPLETED':
        return 'Ride completed';
      case 'CANCELLED':
        return 'Ride cancelled';
      default:
        return 'Your ride';
    }
  }

  String _otpLine() {
    final fromApi = _ride?['otp']?.toString();
    if (fromApi != null && fromApi.isNotEmpty) return 'OTP: $fromApi';
    final cached = FFAppState().currentRideOtp;
    if (cached.isNotEmpty) return 'OTP: $cached';
    return 'OTP will appear when assigned';
  }

  String _driverName() {
    final d = _ride?['driver'];
    if (d is! Map) return 'Driver';
    final fn = d['first_name']?.toString() ?? '';
    final ln = d['last_name']?.toString() ?? '';
    final raw = ('$fn $ln').trim();
    if (raw.isEmpty) return 'Driver';
    return raw
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _plate() {
    final v = _ride?['vehicle'];
    if (v is! Map) return '—';
    final p = v['license_plate']?.toString();
    return (p != null && p.isNotEmpty) ? p : '—';
  }

  String _ratingLine() {
    final d = _ride?['driver'];
    if (d is! Map) return '';
    final r = _asDouble(d['driver_rating']);
    if (r == null) return '';
    return r.toStringAsFixed(1);
  }

  String _amountLine() {
    final finalF = _asDouble(_ride?['final_fare']);
    final est = _asDouble(_ride?['estimated_fare']);
    final v = finalF ?? est;
    if (v == null || v <= 0) return '—';
    return '₹${v.toStringAsFixed(2)}';
  }

  String _distanceLine() {
    final km = _asDouble(_ride?['ride_distance_km']);
    if (km == null || km <= 0) return '—';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  String? _driverPhotoUrl() {
    final d = _ride?['driver'];
    if (d is! Map) return null;
    final u = d['profile_image']?.toString();
    if (u == null || u.isEmpty) return null;
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return null;
  }

  String? _driverPhoneDigits() {
    final d = _ride?['driver'];
    if (d is! Map) return null;
    final raw = d['mobile_number']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  Future<void> _callDriver() async {
    final digits = _driverPhoneDigits();
    if (digits == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver number not available yet')),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool _isCarRide() {
    final v = _ride?['vehicle'];
    if (v is Map) {
      final name = '${v['vehicle_name'] ?? ''} ${v['vehicle_model'] ?? ''}'.toLowerCase();
      if (name.contains('car') || name.contains('sedan') || name.contains('suv')) return true;
    }
    final rt = _ride?['ride_type']?.toString().toLowerCase() ?? '';
    return rt.contains('car') || rt.contains('auto');
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final status = ride?['ride_status']?.toString();
    final mapCenter = _model.googleMapsCenter ?? const LatLng(13.106061, -59.613158);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterFlowGoogleMap(
                  controller: _model.googleMapsController,
                  onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
                  initialLocation: mapCenter,
                  markerColor: GoogleMarkerColor.violet,
                  mapType: MapType.normal,
                  style: GoogleMapStyle.uber,
                  initialZoom: 14.0,
                  allowInteraction: true,
                  allowZoom: true,
                  showZoomControls: true,
                  showLocation: true,
                  showCompass: false,
                  showMapToolbar: false,
                  showTraffic: false,
                  centerMapOnMarkerTap: true,
                  mapTakesGesturePreference: false,
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      if (_loading && ride == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        if (_error != null && ride == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_effectiveRideId == null && ride == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'No active ride. Book a ride to see live details.',
                              style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statusHeadline(status),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _otpLine(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF7B10),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isCarRide() ? Icons.directions_car : Icons.two_wheeler,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _driverPhotoUrl() != null
                                    ? CachedNetworkImage(
                                        imageUrl: _driverPhotoUrl()!,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Image.asset(
                                          'assets/images/dhsch3.png',
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/dhsch3.png',
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _driverName(),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _plate(),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_ratingLine().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                                          const SizedBox(width: 3),
                                          Text(
                                            _ratingLine(),
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _callDriver,
                                icon: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryItem(
                                Icons.payments_rounded,
                                'Amount',
                                _amountLine(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryItem(
                                Icons.route_rounded,
                                'Distance',
                                _distanceLine(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => context.pushNamed(CancelRideWidget.routeName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel Ride',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
