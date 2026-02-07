import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/index.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'auto_book_model.dart';
export 'auto_book_model.dart';

// Component imports
import '/components/searching_ride_component.dart';
import '/components/driver_details_component.dart';
import '/components/ride_cancelled_component.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';
import '/ride_session.dart';

class AutoBookWidget extends StatefulWidget {
  const AutoBookWidget({super.key, required this.rideId});
  final int rideId;

  static String routeName = 'auto-book';
  static String routePath = '/autoBook';

  @override
  State<AutoBookWidget> createState() => _AutoBookWidgetState();
}

class _AutoBookWidgetState extends State<AutoBookWidget>
    with TickerProviderStateMixin {
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================
  late AutoBookModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color primaryColor = Color(0xFFFF7B10);

  // Socket & API
  IO.Socket? socket;
  final String _baseUrl = "https://ugo-api.icacorp.org";

  // Data Storage
  List<dynamic> ridesCache = [];
  Map<String, dynamic>? driverDetails;

  // State Flags
  bool isLoadingDriver = false;
  bool _isCancelling = false;
  String? _rideOtp;

  // UI Status
  String _rideStatus = 'searching';

  // Timer
  Timer? _searchTimer;
  int _searchSeconds = 0;
  Timer? _distanceUpdateTimer;

  // Distance tracking
  double? _currentRemainingDistance;

  // Status Constants
  static const STATUS_SEARCHING = 'searching';
  static const STATUS_ACCEPTED = 'accepted';
  static const STATUS_ARRIVING = 'arriving';
  static const STATUS_PICKED_UP = 'picked_up';
  static const STATUS_COMPLETED = 'completed';
  static const STATUS_CANCELLED = 'cancelled';

  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  @override
  void initState() {
    super.initState();
    print('🚀 AutoBookWidget: initState - Ride ID: ${widget.rideId}');
    _model = createModel(context, () => AutoBookModel());

    _startSearchTimer();
    _initializeSocket();
    _fetchInitialRideStatus();
  }

  void _startSearchTimer() {
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _rideStatus == STATUS_SEARCHING) {
        setState(() => _searchSeconds++);
      }
    });
  }

  void _startDistanceUpdateTimer() {
    _distanceUpdateTimer?.cancel();
    _distanceUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _rideStatus == STATUS_PICKED_UP) {
        _updateRemainingDistance();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopDistanceUpdateTimer() {
    _distanceUpdateTimer?.cancel();
    _distanceUpdateTimer = null;
  }

  // ============================================================================
  // 🗺️ MAP LOGIC
  // ============================================================================

  List<FlutterFlowMarker> _getMarkers() {
    if (ridesCache.isEmpty) return [];

    final ride = ridesCache[0];
    final lat = double.tryParse(ride['driver_latitude']?.toString() ?? '');
    final lng = double.tryParse(ride['driver_longitude']?.toString() ?? '');

    // Only show driver marker if status is relevant (Accepted/Arriving/Picked Up)
    if (lat == null || lng == null || _rideStatus == STATUS_SEARCHING || _rideStatus == STATUS_CANCELLED) {
      return [];
    }

    return [
      FlutterFlowMarker(
        'driver_marker',
        LatLng(lat, lng),
        // You can add a custom icon here if available
      ),
    ];
  }

  // ============================================================================
  // API & SOCKET LOGIC
  // ============================================================================

  Future<void> _fetchInitialRideStatus() async {
    print('📡 Fetching initial ride status');
    try {
      final response = await GetRideDetailsCall.call(
        rideId: widget.rideId,
        token: FFAppState().accessToken,
      );
      if (response.succeeded) {
        final rideData = response.jsonBody['data'] ?? response.jsonBody;
        print("✅ Initial Ride Data: $rideData");
        _processRideUpdate(rideData);
      }
    } catch (e) {
      print("❌ Error fetching initial ride status: $e");
    }
  }

  void _initializeSocket() {
    final String token = FFAppState().accessToken;
    if (token.isEmpty) {
      print("⚠️ No Access Token for Socket!");
      return;
    }

    try {
      // 1. Initialize Socket
      socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .setAuth({'token': token})
            .setReconnectionAttempts(5) // Retry logic
            .build(),
      );

      // 2. Setup Listeners
      socket!.onConnect((_) {
        print("✅ Socket CONNECTED: ${socket?.id}");
        // Join the specific ride room
        socket!.emit("watch_entity", {
          "type": "ride",
          "id": widget.rideId, // Ensure this matches backend expectation (int vs string)
        });
      });

      socket!.onConnectError((data) => print("❌ Socket Connection Error: $data"));
      socket!.onError((data) => print("❌ Socket Error: $data"));
      socket!.onDisconnect((_) => print("⚠️ Socket Disconnected"));

      // 3. Listen for Updates
      socket!.on("ride_updated", (data) {
        print("📡 Socket Event Received: ${jsonEncode(data)}");
        if (data != null) {
          _processRideUpdate(data);
        }
      });

      // 4. Connect
      socket!.connect();
    } catch (e) {
      print("❌ Socket Initialization Exception: $e");
    }
  }

  void _processRideUpdate(dynamic data) {
    try {
      final updatedRide = Map<String, dynamic>.from(data);
      if (!mounted) return;

      // Update Global Session
      RideSession().rideData = updatedRide;

      final rawStatus = updatedRide['ride_status'] ?? updatedRide['status'];
      final status = rawStatus?.toString().toLowerCase().trim();

      print('🔄 Processing Status: "$status" | Driver Loc: ${updatedRide['driver_latitude']},${updatedRide['driver_longitude']}');

      bool navigateToComplete = false;
      String previousStatus = _rideStatus;

      setState(() {
        // 1. Update Cache (Trigger Map Rebuild)
        if (ridesCache.isNotEmpty) {
          ridesCache[0] = {...ridesCache[0], ...updatedRide};
        } else {
          ridesCache = [updatedRide];
        }

        // 2. OTP Extraction
        final incomingOtp = updatedRide['otp'] ??
            updatedRide['ride_otp'] ??
            updatedRide['booking_otp'];
        if (incomingOtp != null) {
          _rideOtp = incomingOtp.toString();
        }

        // 3. Status State Machine
        if (status == 'cancelled') {
          _rideStatus = STATUS_CANCELLED;
          _searchTimer?.cancel();
          _stopDistanceUpdateTimer();
        } else if (['accepted', 'driver_assigned'].contains(status)) {
          // If searching, move to accepted.
          // Note: If we are already in 'arriving', don't go back to 'accepted'
          if (_rideStatus == STATUS_SEARCHING) {
            _rideStatus = STATUS_ACCEPTED;
          }
          _searchTimer?.cancel();
        } else if (status == 'arriving') {
          _rideStatus = STATUS_ARRIVING;
          _stopDistanceUpdateTimer();
        } else if (status == 'started' || status == 'picked_up' || status == 'in_progress') {
          _rideStatus = STATUS_PICKED_UP;
          if (previousStatus != STATUS_PICKED_UP) {
            _updateRemainingDistance();
            _startDistanceUpdateTimer();
          }
        } else if (status == 'completed' || status == 'complete') {
          if (_rideStatus != STATUS_COMPLETED) {
            _rideStatus = STATUS_COMPLETED;
            _searchTimer?.cancel();
            _stopDistanceUpdateTimer();
            navigateToComplete = true;
          }
        }
      });

      // 4. Update Distance Calculation
      if (_rideStatus == STATUS_PICKED_UP) {
        _updateRemainingDistance();
      }

      // 5. Navigation Handling
      if (navigateToComplete) {
        _handleCompletedRideNavigation(updatedRide);
        return;
      }

      // 6. Fetch Driver Details if missing
      final driverId = updatedRide['driver_id'];
      if (driverId != null && driverDetails == null && !isLoadingDriver) {
        _fetchDriverDetails(driverId);
      }
    } catch (e, stackTrace) {
      print("❌ Error processing ride update: $e");
      print(stackTrace);
    }
  }

  // ... (Keep existing _updateRemainingDistance, _calculateDistance, _sin, _cos, etc.) ...
  void _updateRemainingDistance() {
    if (ridesCache.isEmpty) return;
    try {
      final ride = ridesCache[0];
      final driverLat = ride['driver_latitude'];
      final driverLng = ride['driver_longitude'];
      final dropLat = ride['drop_latitude'];
      final dropLng = ride['drop_longitude'];

      if (driverLat != null && driverLng != null && dropLat != null && dropLng != null) {
        double newDistance = _calculateDistance(
          double.parse(driverLat.toString()),
          double.parse(driverLng.toString()),
          double.parse(dropLat.toString()),
          double.parse(dropLng.toString()),
        );
        if (mounted) setState(() => _currentRemainingDistance = newDistance);
      }
    } catch (e) { print('Error updating distance: $e'); }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = (_sin(dLat / 2) * _sin(dLat / 2)) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
            (_sin(dLon / 2) * _sin(dLon / 2));
    double c = 2 * _asin(_sqrt(a));
    return earthRadius * c;
  }

  // Helper Math Functions
  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180.0);
  double _sin(double x) { double r = x; double t = x; for(int n=1;n<=10;n++){ t*=-x*x/((2*n)*(2*n+1)); r+=t; } return r; }
  double _cos(double x) { double r = 1; double t = 1; for(int n=1;n<=10;n++){ t*=-x*x/((2*n-1)*(2*n)); r+=t; } return r; }
  double _sqrt(double x) { if(x<0)return 0; double g=x/2; for(int i=0;i<10;i++) g=(g+x/g)/2; return g; }
  double _asin(double x) => x + (x*x*x)/6 + (3*x*x*x*x*x)/40;

  // ... (Keep existing _handleCompletedRideNavigation and Fetch Driver logic) ...
  Future<void> _handleCompletedRideNavigation(Map<String, dynamic> rideData) async {
    _stopDistanceUpdateTimer();
    socket?.off("ride_updated");

    RideSession().rideData = rideData;

    if (driverDetails != null) {
      RideSession().driverData = driverDetails;
    } else if (rideData['driver'] != null) {
      final nestedDriver = rideData['driver'];
      RideSession().driverData = nestedDriver is Map<String, dynamic>
          ? nestedDriver
          : Map<String, dynamic>.from(nestedDriver);
    } else if (rideData['driver_id'] != null) {
      await _fetchDriverDetailsSync(rideData['driver_id']);
    }

    if (mounted) {
      context.goNamed(RidecompleteWidget.routeName);
    }
  }

  Future<void> _fetchDriverDetailsSync(dynamic driverId) async {
    try {
      final response = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: FFAppState().accessToken,
      );
      if (response.succeeded && mounted) {
        RideSession().driverData = response.jsonBody;
      }
    } catch (e) {
      print('Sync driver fetch failed: $e');
    }
  }

  Future<void> _fetchDriverDetails(dynamic driverId) async {
    if (!mounted) return;
    setState(() => isLoadingDriver = true);
    try {
      final response = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: FFAppState().accessToken,
      );
      if (response.succeeded && mounted) {
        setState(() {
          driverDetails = response.jsonBody;
          isLoadingDriver = false;
          RideSession().driverData = driverDetails;

          // Auto-transition UI if we were just 'Accepted'
          if (_rideStatus == STATUS_ACCEPTED || _rideStatus == STATUS_SEARCHING) {
            _rideStatus = STATUS_ARRIVING;
          }
        });
      } else {
        if (mounted) setState(() => isLoadingDriver = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingDriver = false);
    }
  }

  // ... (Keep existing _cancelRide, _makeCall, _showCancelDialog, _onBackPressed) ...
  Future<void> _cancelRide(String reason) async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    try {
      final response = await CancelRide.call(
        rideId: widget.rideId,
        cancellationReason: reason,
        token: FFAppState().accessToken,
        cancelledBy: 'user',
      );
      if (mounted) {
        if (response.succeeded) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride cancelled successfully'), backgroundColor: Colors.green));
          setState(() {
            _rideStatus = STATUS_CANCELLED;
            _searchTimer?.cancel();
            _stopDistanceUpdateTimer();
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.pop();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel ride.'), backgroundColor: Colors.red));
        }
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    final raw = (phoneNumber ?? '').trim();
    if (raw.isEmpty || raw == 'null') return;
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (!clean.startsWith('+') && RegExp(r'^\d{10}$').hasMatch(clean)) clean = '+91$clean';
    try { await launchUrl(Uri(scheme: 'tel', path: clean), mode: LaunchMode.externalApplication); } catch (_) {}
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cancel Ride?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: const Text('Are you sure you want to cancel this ride?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
            TextButton(
              onPressed: () { Navigator.pop(context); _cancelRide('Customer requested cancellation'); },
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onBackPressed() async {
    if (_rideStatus == STATUS_CANCELLED || _rideStatus == STATUS_COMPLETED) return true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please continue the ride or cancel it first')));
    return false;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _stopDistanceUpdateTimer();
    try {
      socket?.off("ride_updated"); // Ensure listeners are removed
      socket?.disconnect();
      socket?.dispose();
    } catch (_) {}
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Map
            Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.45,
              child: FlutterFlowGoogleMap(
                controller: _model.googleMapsController,
                onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
                initialLocation: _model.googleMapsCenter ?? const LatLng(17.385044, 78.486671),
                markers: _getMarkers(), // ✅ Fixed: Markers now update via setState logic
                markerColor: GoogleMarkerColor.orange,
                mapType: MapType.normal,
                initialZoom: 14.0,
                allowInteraction: true,
                showLocation: true,
              ),
            ),

            // Header
            Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

            // Bottom Component
            Align(
              alignment: Alignment.bottomCenter,
              child: PointerInterceptor(
                intercepting: isWeb,
                child: _buildBottomComponent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 16, bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _rideStatus == STATUS_SEARCHING ? 'Finding your ride' : 'Your ride',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          if (_rideStatus != STATUS_SEARCHING)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: primaryColor),
                  const SizedBox(width: 4),
                  Text('Safety', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomComponent() {
    if (_rideStatus == STATUS_SEARCHING) {
      return SearchingRideComponent(searchSeconds: _searchSeconds, onCancel: _showCancelDialog);
    } else if (_rideStatus == STATUS_CANCELLED) {
      return RideCancelledComponent(onBackToHome: () => context.pop());
    } else {
      return DriverDetailsComponent(
        isLoading: isLoadingDriver,
        driverDetails: driverDetails,
        rideOtp: _rideOtp,
        ridesCache: ridesCache,
        onCall: _makeCall,
        onCancel: _showCancelDialog,
        rideStatus: _rideStatus,
        currentRemainingDistance: _currentRemainingDistance,
      );
    }
  }
}