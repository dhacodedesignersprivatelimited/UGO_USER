import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/api_requests/api_calls.dart';
import '/index.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
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
  final String _baseUrl = "https://ugotaxi.icacorp.org";

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
        _processRideUpdate(rideData);
      }
    } catch (e) {
      print("❌ Error fetching initial ride status: $e");
    }
  }

  void _initializeSocket() {
    final String token = FFAppState().accessToken;
    if (token.isEmpty) return;

    try {
      socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .setAuth({'token': token})
            .build(),
      );

      socket!.onConnect((_) {
        print("✅ Socket connected");
        socket!.emit("watch_entity", {"type": "ride", "id": widget.rideId});
      });

      socket!.on("ride_updated", (data) {
        print("📡 Ride updated: ${jsonEncode(data)}");
        if (data != null) _processRideUpdate(data);
      });

      socket!.onDisconnect((_) => print("⚠️ Socket disconnected"));
      socket!.connect();
    } catch (e) {
      print("❌ Socket error: $e");
    }
  }

  void _processRideUpdate(dynamic data) {
    try {
      final updatedRide = Map<String, dynamic>.from(data);
      if (!mounted) return;

      print('═══════════════════════════════════════════');
      print('🔄 PROCESSING RIDE UPDATE');
      print('   Ride data keys: ${updatedRide.keys.toList()}');
      print('═══════════════════════════════════════════');

      // ✅ CRITICAL: Store ride data IMMEDIATELY
      RideSession().rideData = updatedRide;
      print('✅ Stored ride data in RideSession');

      final rawStatus = updatedRide['ride_status'] ?? updatedRide['status'];
      final status = rawStatus?.toString().toLowerCase().trim();
      print('🔄 Processing status: "$status"');

      bool navigateToComplete = false;

      setState(() {
        if (ridesCache.isNotEmpty) {
          ridesCache[0] = {...ridesCache[0], ...updatedRide};
        } else {
          ridesCache = [updatedRide];
        }

        final incomingOtp = updatedRide['otp'] ??
            updatedRide['ride_otp'] ??
            updatedRide['booking_otp'];

        if (incomingOtp != null) {
          _rideOtp = incomingOtp.toString();
          print('🔑 Received OTP: $_rideOtp');
        }

        if (status == 'cancelled') {
          _rideStatus = STATUS_CANCELLED;
          _searchTimer?.cancel();
        } else if (['accepted', 'arriving', 'driver_assigned']
            .contains(status)) {
          _rideStatus = STATUS_ACCEPTED;
          _searchTimer?.cancel();
        } else if (status == 'STARTED' || status == 'picked_up') {
          _rideStatus = STATUS_PICKED_UP;
        } else if (status == 'completed' || status == 'complete') {
          if (_rideStatus != STATUS_COMPLETED) {
            _rideStatus = STATUS_COMPLETED;
            _searchTimer?.cancel();
            navigateToComplete = true;
          }
        }
      });

      // ✅ CRITICAL: Handle navigation with driver data
      if (navigateToComplete) {
        print('\n🏁 RIDE COMPLETED - PREPARING NAVIGATION');
        print('═══════════════════════════════════════════');
        _handleCompletedRideNavigation(updatedRide);
        return; // Don't continue processing
      }

      // ✅ Fetch driver details if needed (for earlier stages)
      final driverId = updatedRide['driver_id'];
      if (driverId != null && driverDetails == null && !isLoadingDriver) {
        print('📡 Triggering driver fetch for driver_id: $driverId');
        _fetchDriverDetails(driverId);
      }
    } catch (e, stackTrace) {
      print("❌ Error processing ride update: $e");
      print("Stack trace: $stackTrace");
    }
  }

  // ✅ NEW METHOD: Handle completed ride navigation with driver data
  Future<void> _handleCompletedRideNavigation(Map<String, dynamic> rideData) async {
    print('📋 Checking driver data sources...');
    
    // Source 1: Local state (already fetched)
    if (driverDetails != null) {
      print('✅ Using driver data from LOCAL state');
      RideSession().driverData = driverDetails;
      print('   Driver: ${driverDetails?['name'] ?? driverDetails?['first_name']}');
      print('   Vehicle: ${driverDetails?['vehicle_number']}');
      _navigateToComplete();
      return;
    }

    // Source 2: Nested in ride data
    if (rideData['driver'] != null) {
      print('✅ Using driver data from RIDE response');
      final nestedDriver = rideData['driver'];
      final driverMap = nestedDriver is Map<String, dynamic> 
          ? nestedDriver 
          : Map<String, dynamic>.from(nestedDriver);
      
      RideSession().driverData = driverMap;
      driverDetails = driverMap; // Store locally too
      print('   Driver: ${driverMap['name'] ?? driverMap['first_name']}');
      print('   Vehicle: ${driverMap['vehicle_number']}');
      _navigateToComplete();
      return;
    }

    // Source 3: Driver ID exists, need to fetch
    if (rideData['driver_id'] != null) {
      print('⚠️  Driver ID found, fetching driver details: ${rideData['driver_id']}');
      await _fetchDriverDetailsSync(rideData['driver_id']);
      // Navigation will happen after fetch completes
      return;
    }

    // Source 4: Driver info directly in ride data (flat structure)
    if (rideData['driver_name'] != null || rideData['driver_phone'] != null) {
      print('✅ Using FLAT driver data from ride response');
      final flatDriver = {
        'name': rideData['driver_name'],
        'first_name': rideData['driver_name'],
        'phone': rideData['driver_phone'],
        'mobile_number': rideData['driver_phone'],
        'vehicle_number': rideData['driver_vehicle'] ?? rideData['vehicle_number'],
        'rating': rideData['driver_rating'],
      };
      
      RideSession().driverData = flatDriver;
      driverDetails = flatDriver;
      print('   Driver: ${flatDriver['name']}');
      print('   Vehicle: ${flatDriver['vehicle_number']}');
      _navigateToComplete();
      return;
    }

    // No driver data available
    print('❌ WARNING: No driver data found in any source!');
    print('   Available ride keys: ${rideData.keys.toList()}');
    print('   Navigating anyway...');
    _navigateToComplete();
  }

  void _navigateToComplete() {
    print('\n🎯 FINAL CHECK BEFORE NAVIGATION:');
    print('   RideSession.rideData: ${RideSession().rideData != null ? "SET ✅" : "NULL ❌"}');
    print('   RideSession.driverData: ${RideSession().driverData != null ? "SET ✅" : "NULL ❌"}');
    
    if (RideSession().driverData != null) {
      print('   Driver Name: ${RideSession().driverData?['name'] ?? RideSession().driverData?['first_name']}');
      print('   Vehicle: ${RideSession().driverData?['vehicle_number']}');
    }
    
    print('═══════════════════════════════════════════\n');
    print('🚀 Navigating to RidecompleteWidget');
    
    if (mounted) {
      context.goNamed(RidecompleteWidget.routeName);
    }
  }

  // ✅ SYNCHRONOUS driver fetch (waits for result before navigation)
  Future<void> _fetchDriverDetailsSync(dynamic driverId) async {
    if (!mounted) return;
    print('📡 SYNCHRONOUS driver fetch for: $driverId');

    try {
      final response = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: FFAppState().accessToken,
      );

      if (response.succeeded) {
        final fetchedDriver = response.jsonBody;
        
        if (mounted) {
          setState(() {
            driverDetails = fetchedDriver;
            RideSession().driverData = fetchedDriver;
          });
          
          print('✅ Driver details fetched successfully');
          print('   Driver: ${fetchedDriver['name'] ?? fetchedDriver['first_name']}');
          print('   Vehicle: ${fetchedDriver['vehicle_number']}');
        }
      } else {
        print('❌ Driver fetch failed, status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception during driver fetch: $e');
    } finally {
      // Navigate regardless of fetch result
      _navigateToComplete();
    }
  }

  // ✅ ASYNCHRONOUS driver fetch (for earlier ride stages)
  Future<void> _fetchDriverDetails(dynamic driverId) async {
    if (!mounted) return;
    setState(() => isLoadingDriver = true);
    print('📡 Fetching driver details for: $driverId');

    try {
      final response = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: FFAppState().accessToken,
      );

      if (response.succeeded && mounted) {
        setState(() {
          driverDetails = response.jsonBody;
          isLoadingDriver = false;

          // ✅ Store in RideSession immediately
          RideSession().driverData = driverDetails;
          print('✅ Driver details loaded and stored');
          print('   Driver: ${driverDetails?['name'] ?? driverDetails?['first_name']}');
          print('   Vehicle: ${driverDetails?['vehicle_number']}');

          if (_rideStatus == STATUS_ACCEPTED ||
              _rideStatus == STATUS_SEARCHING) {
            _rideStatus = STATUS_ARRIVING;
          }
        });
      } else {
        if (mounted) setState(() => isLoadingDriver = false);
      }
    } catch (e) {
      print("❌ Error fetching driver: $e");
      if (mounted) setState(() => isLoadingDriver = false);
    }
  }

  Future<void> _cancelRide(String reason) async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    print('🚫 Cancelling ride. Reason: $reason');

    try {
      final response = await CancelRide.call(
        rideId: widget.rideId,
        cancellationReason: reason,
        token: FFAppState().accessToken,
        cancelledBy: 'user',
      );

      if (mounted) {
        if (response.succeeded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ride cancelled successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );

          setState(() {
            _rideStatus = STATUS_CANCELLED;
            _searchTimer?.cancel();
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.pop();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Cancel exception: $e");
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    final raw = (phoneNumber ?? '').trim();
    if (raw.isEmpty || raw == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number not available')),
      );
      return;
    }

    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (!clean.startsWith('+') && RegExp(r'^\d{10}$').hasMatch(clean)) {
      clean = '+91$clean';
    }

    final Uri uri = Uri(scheme: 'tel', path: clean);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('❌ Call failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: $e')),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Cancel Ride?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to cancel this ride?',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelRide('Customer requested cancellation');
              },
              child: Text(
                'Yes, Cancel',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    print('🗑️ Disposing AutoBookWidget');
    _searchTimer?.cancel();

    try {
      socket?.disconnect();
      socket?.dispose();
    } catch (_) {}

    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              initialLocation:
                  _model.googleMapsCenter ?? const LatLng(17.385044, 78.486671),
              markerColor: GoogleMarkerColor.orange,
              mapType: MapType.normal,
              initialZoom: 14.0,
              allowInteraction: true,
              showLocation: true,
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),

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
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Row(
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
            child: Text(
              _rideStatus == STATUS_SEARCHING
                  ? 'Finding your ride'
                  : 'Your ride',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_rideStatus != STATUS_SEARCHING)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: primaryColor),
                  SizedBox(width: 4),
                  Text(
                    'Safety',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomComponent() {
    if (_rideStatus == STATUS_SEARCHING) {
      return SearchingRideComponent(
        searchSeconds: _searchSeconds,
        onCancel: _showCancelDialog,
      );
    } else if (_rideStatus == STATUS_CANCELLED) {
      return RideCancelledComponent(
        onBackToHome: () => context.pop(),
      );
    } else {
      return DriverDetailsComponent(
        isLoading: isLoadingDriver,
        driverDetails: driverDetails,
        rideOtp: _rideOtp,
        ridesCache: ridesCache,
        onCall: _makeCall,
        onCancel: _showCancelDialog,
      );
    }
  }
}