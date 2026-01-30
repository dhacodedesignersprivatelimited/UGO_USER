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

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';

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
  // 1. STATE VARIABLES & CONFIG
  // ============================================================================
  late AutoBookModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ✅ PRIMARY COLOR (UGO Orange)
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
  String _etaMinutes = '4';

  // Timer & Animation
  Timer? _searchTimer;
  int _searchSeconds = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Status Constants
  static const STATUS_SEARCHING = 'searching';
  static const STATUS_ACCEPTED = 'accepted';
  static const STATUS_ARRIVING = 'arriving';
  static const STATUS_PICKED_UP = 'picked_up';
  static const STATUS_COMPLETED = 'completed';
  static const STATUS_CANCELLED = 'cancelled';

  // ============================================================================
  // 2. INITIALIZATION
  // ============================================================================
  @override
  void initState() {
    super.initState();
    print('🚀 AutoBookWidget: initState - Ride ID: ${widget.rideId}');
    _model = createModel(context, () => AutoBookModel());

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startSearchTimer();
    _initializeSocket();
    _fetchInitialRideStatus();
  }

  void _startSearchTimer() {
    print('⏱️ AutoBookWidget: Starting search timer');
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _rideStatus == STATUS_SEARCHING) {
        setState(() => _searchSeconds++);
        if (_searchSeconds % 10 == 0) {
          print('⏱️ AutoBookWidget: Searching for $_searchSeconds seconds');
        }
      }
    });
  }

  // ============================================================================
  // 3. API & SOCKET LOGIC
  // ============================================================================

  Future<void> _fetchInitialRideStatus() async {
    print('📡 AutoBookWidget: Fetching initial ride status via API');
    try {
      final response = await GetRideDetailsCall.call(
        rideId: widget.rideId,
        token: FFAppState().accessToken,
      );
      if (response.succeeded) {
        final rideData = response.jsonBody['data'] ?? response.jsonBody;
        print('✅ AutoBookWidget: Initial API fetch successful');
        _processRideUpdate(rideData);
      } else {
        print('❌ AutoBookWidget: Initial API fetch failed: ${response.jsonBody}');
      }
    } catch (e) {
      print("❌ AutoBookWidget: Error fetching initial ride status: $e");
    }
  }

  void _initializeSocket() {
    final String token = FFAppState().accessToken;
    print('🔌 AutoBookWidget: Initializing socket connection');

    if (token.isEmpty) {
      print("❌ AutoBookWidget: Token is empty");
      return;
    }

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
        print("✅ AutoBookWidget: SOCKET CONNECTED");
        socket!.emit("watch_entity", {"type": "ride", "id": widget.rideId});
        print("📤 AutoBookWidget: Emitted watch_entity for ride ${widget.rideId}");
      });

      socket!.on("ride_updated", (data) {
        print("📡 AutoBookWidget: RIDE UPDATED via Socket: ${jsonEncode(data)}");
        if (data != null) _processRideUpdate(data);
      });

      socket!.onDisconnect((_) => print("⚠️ AutoBookWidget: SOCKET DISCONNECTED"));

      socket!.connect();
    } catch (e) {
      print("☠️ AutoBookWidget: SOCKET EXCEPTION: $e");
    }
  }

  void _processRideUpdate(dynamic data) {
    try {
      final updatedRide = Map<String, dynamic>.from(data);
      if (!mounted) return;

      final rawStatus = updatedRide['ride_status'] ?? updatedRide['status'];
      final status = rawStatus?.toString().toLowerCase().trim();
      print('🔄 AutoBookWidget: Processing status update: "$status"');

      bool navigateToComplete = false;

      setState(() {
        if (ridesCache.isNotEmpty) {
          ridesCache[0] = {...ridesCache[0], ...updatedRide};
        } else {
          ridesCache = [updatedRide];
        }

        // 🔑 Flexible OTP extraction
        final incomingOtp = updatedRide['otp'] ?? 
                           updatedRide['ride_otp'] ?? 
                           updatedRide['booking_otp'];
        
        if (incomingOtp != null) {
          _rideOtp = incomingOtp.toString();
          print('🔑 AutoBookWidget: Received OTP: $_rideOtp');
        } else {
          print('⚠️ AutoBookWidget: No OTP found in update data.');
        }

        if (status == 'cancelled') {
          print('🚫 AutoBookWidget: Ride cancelled');
          _rideStatus = STATUS_CANCELLED;
          _searchTimer?.cancel();
        } else if (['accepted', 'arriving', 'driver_assigned'].contains(status)) {
          print('🚕 AutoBookWidget: Captain assigned/accepted');
          _rideStatus = STATUS_ACCEPTED;
          _searchTimer?.cancel();
        } else if (status == 'started' || status == 'picked_up') {
          print('🚗 AutoBookWidget: Ride started/picked up');
          _rideStatus = STATUS_PICKED_UP;
        } else if (status == 'completed' || status == 'complete') {
          if (_rideStatus != STATUS_COMPLETED) {
            print('🏁 AutoBookWidget: Ride COMPLETED. Triggering navigation flow...');
            _rideStatus = STATUS_COMPLETED;
            _searchTimer?.cancel();
            navigateToComplete = true;
          }
        }
      });

      if (navigateToComplete) {
        print('🏁 AutoBookWidget: Navigating to RidecompleteWidget now');
        context.goNamed(RidecompleteWidget.routeName);
      }

      final driverId = updatedRide['driver_id'];
      if (driverId != null && driverDetails == null && !isLoadingDriver) {
        print('👨‍✈️ AutoBookWidget: Driver assigned ($driverId). Fetching details...');
        _fetchDriverDetails(driverId);
      }
    } catch (e) {
      print("❌ AutoBookWidget: ERROR processing ride update: $e");
    }
  }

  Future<void> _fetchDriverDetails(dynamic driverId) async {
    if (!mounted) return;
    setState(() => isLoadingDriver = true);
    print('📡 AutoBookWidget: Fetching driver details for ID: $driverId');

    try {
      final response = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: FFAppState().accessToken,
      );

      if (response.succeeded && mounted) {
        setState(() {
          driverDetails = response.jsonBody;
          isLoadingDriver = false;

          if (_rideStatus == STATUS_ACCEPTED || _rideStatus == STATUS_SEARCHING) {
            _rideStatus = STATUS_ARRIVING;
          }
        });
        print("👨‍✈️ AutoBookWidget: Driver details loaded: ${GetDriverDetailsCall.name(driverDetails)}");
      } else {
        print("❌ AutoBookWidget: Failed to load driver details");
        if (mounted) setState(() => isLoadingDriver = false);
      }
    } catch (e) {
      print("☠️ AutoBookWidget: Exception fetching driver: $e");
      if (mounted) setState(() => isLoadingDriver = false);
    }
  }

  Future<void> _cancelRide(String reason) async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    print('🚫 AutoBookWidget: Cancelling ride. Reason: $reason');

    try {
      final response = await CancelRide.call(
        rideId: widget.rideId,
        cancellationReason: reason,
        token: FFAppState().accessToken,
        cancelledBy: 'user',
      );

      if (mounted) {
        if (response.succeeded) {
          print('✅ AutoBookWidget: Cancellation API success');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(CancelRide.message(response.jsonBody) ?? 'Ride cancelled'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _rideStatus = STATUS_CANCELLED;
            _searchTimer?.cancel();
          });

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.pop();
          });
        } else {
          print('❌ AutoBookWidget: Cancellation API failed: ${response.jsonBody}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("☠️ AutoBookWidget: Cancel exception: $e");
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    print('📞 AutoBookWidget: Initiating call to: $phoneNumber');

    final raw = (phoneNumber ?? '').trim();
    if (raw.isEmpty || raw == 'null') {
      print('❌ AutoBookWidget: Phone number empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver phone number not available')),
        );
      }
      return;
    }

    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (!clean.startsWith('+') && RegExp(r'^\d{10}$').hasMatch(clean)) {
      clean = '+91$clean';
    }

    print('📞 AutoBookWidget: Cleaned phone: $clean');

    final Uri uri = Uri(scheme: 'tel', path: clean);

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        print('❌ AutoBookWidget: launchUrl returned false');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    } catch (e) {
      print('❌ AutoBookWidget: launchUrl exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    print('🗑️ AutoBookWidget: dispose called');
    _searchTimer?.cancel();
    _pulseController.dispose();

    try {
      socket?.disconnect();
      socket?.dispose();
    } catch (_) {}

    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: FlutterFlowGoogleMap(
                controller: _model.googleMapsController,
                onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
                initialLocation: _model.googleMapsCenter ??
                    const LatLng(17.385044, 78.486671),
                markerColor: GoogleMarkerColor.orange,
                mapType: MapType.normal,
                initialZoom: 14.0,
                allowInteraction: true,
                showLocation: true,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: PointerInterceptor(
                intercepting: isWeb,
                child: _buildUberBottomUI(),
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
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.5), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, 4))
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
              onPressed: () {
                print('🔙 AutoBookWidget: Back button pressed');
                context.pop();
              },
            ),
          ),
          if (_rideStatus != STATUS_SEARCHING)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Safety',
                    style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUberBottomUI() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: (_rideStatus == STATUS_SEARCHING)
          ? _buildSearchingCard()
          : (_rideStatus == STATUS_CANCELLED)
          ? _buildCancelledCard()
          : _buildUGODriverDetailsCard(),
    );
  }

  Widget _buildSearchingCard() {
    return Container(
      key: const ValueKey('searching_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search, color: primaryColor, size: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finding your Captain',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5)),
                    Text('Searching nearby drivers...',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                print('🚫 AutoBookWidget: Cancel button clicked');
                _showCancelDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Cancel Request',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUGODriverDetailsCard() {
    if (isLoadingDriver || driverDetails == null) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final driverName = GetDriverDetailsCall.name(driverDetails) ?? 'Bharath';
    final driverRating = GetDriverDetailsCall.rating(driverDetails) ?? '4.6';
    final vehicleNumber = GetDriverDetailsCall.vehicleNumber(driverDetails) ?? 'AP28TA';
    final driverPhone = DriverIdfetchCall.mobileNumber(driverDetails);
    
    // OTP display logic
    String displayOtp = _rideOtp ?? '----';
    List<String> otpDigits = displayOtp.split('');
    while (otpDigits.length < 4) {
      otpDigits.add('-');
    }

    // Distance and Location from ridesCache if available
    String pickup = 'Dilsukhnagar';
    String dropoff = 'Ameerpet';
    String distance = '15km';
    String amount = '₹76.00';

    if (ridesCache.isNotEmpty) {
      final ride = ridesCache[0];
      amount = '₹${ride['total_fare'] ?? '76.00'}';
      distance = '${ride['distance'] ?? '15'}km';
    }

    return Container(
      key: const ValueKey('UGO_driver_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. OTP Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Otp : ', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500)),
              ...otpDigits.map((digit) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                child: Text(digit, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              const Icon(Icons.motorcycle, size: 32),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Driver Info Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black87, width: 0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-4.0.3&auto=format&fit=crop&w=128&q=80',
                    width: 70, height: 70, fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(vehicleNumber, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          // Optional small tags
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFFFF3C4), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Top Rated', style: TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Name : $driverName', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Text('Rating : ', style: GoogleFonts.poppins(fontSize: 14)),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(driverRating, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _makeCall(driverPhone?.toString()),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.call, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Location & Amount Section
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radio_button_checked, size: 20),
                      const SizedBox(width: 8),
                      Text(': $pickup', style: GoogleFonts.poppins(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      Text(': $dropoff', style: GoogleFonts.poppins(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Distance : $distance', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              // Amount Bubble
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(color: Color(0xFF4E7D1A), shape: BoxShape.circle),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Amount', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                    Text(amount, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Cancel Button
          FFButtonWidget(
            onPressed: () {
              print('DEBUG: Cancel button clicked (assigned)');
              _showCancelDialog();
            },
            text: 'Cancel',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              color: primaryColor,
              textStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildCancelledCard() {
    return Container(
      key: const ValueKey('cancelled_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Ride Cancelled', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => context.pop(),
              child: Text('Back to Home')
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cancel Ride?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('No')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelRide('Customer requested cancellation');
              },
              child: Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }
}
