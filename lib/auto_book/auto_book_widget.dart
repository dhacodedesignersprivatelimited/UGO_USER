import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/api_requests/api_calls.dart';
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

  // ✅ PRIMARY COLOR (Rapido Orange)
  static const Color primaryColor = Color(0xFFFF7B10);

  // Socket & API
  IO.Socket? socket; // changed from late to nullable (safe dispose)
  final String _baseUrl = "https://ugotaxi.icacorp.org";

  // Data Storage
  List<dynamic> ridesCache = [];
  Map<String, dynamic>? driverDetails; // Stores full API response

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
    _model = createModel(context, () => AutoBookModel());

    // Animation for searching pulse
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
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _rideStatus == STATUS_SEARCHING) {
        setState(() => _searchSeconds++);
      }
    });
  }

  // ============================================================================
  // 3. API & SOCKET LOGIC
  // ============================================================================

  Future<void> _fetchInitialRideStatus() async {
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
      debugPrint("❌ Error fetching initial ride status: $e");
    }
  }

  void _initializeSocket() {
    final String token = FFAppState().accessToken;

    if (token.isEmpty) {
      debugPrint("❌ Token is empty");
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
        debugPrint("✅ SOCKET CONNECTED");
        socket!.emit("watch_entity", {"type": "ride", "id": widget.rideId});
      });

      socket!.on("ride_updated", (data) {
        debugPrint("📡 RIDE UPDATED via Socket: $data");
        if (data != null) _processRideUpdate(data);
      });

      socket!.onDisconnect((_) => debugPrint("⚠️ SOCKET DISCONNECTED"));

      socket!.connect();
    } catch (e) {
      debugPrint("☠️ SOCKET EXCEPTION: $e");
    }
  }

  void _processRideUpdate(dynamic data) {
    try {
      final updatedRide = Map<String, dynamic>.from(data);
      if (!mounted) return;

      setState(() {
        // Update local cache
        if (ridesCache.isNotEmpty) {
          ridesCache[0] = {...ridesCache[0], ...updatedRide};
        } else {
          ridesCache = [updatedRide];
        }

        // Extract OTP
        if (updatedRide['otp'] != null) {
          _rideOtp = updatedRide['otp'].toString();
        }

        // Determine Status
        final rawStatus = updatedRide['ride_status'] ?? updatedRide['status'];
        final status = rawStatus?.toString().toLowerCase();

        if (status == 'cancelled') {
          _rideStatus = STATUS_CANCELLED;
          _searchTimer?.cancel();
        } else if (['accepted', 'arriving', 'driver_assigned'].contains(status)) {
          _rideStatus = STATUS_ACCEPTED;
          _searchTimer?.cancel();
        } else if (status == 'started' || status == 'picked_up') {
          _rideStatus = STATUS_PICKED_UP;
        } else if (status == 'completed') {
          _rideStatus = STATUS_COMPLETED;
        }
      });

      // Fetch driver details if assigned and we don't have them yet
      final driverId = updatedRide['driver_id'];
      if (driverId != null && driverDetails == null && !isLoadingDriver) {
        _fetchDriverDetails(driverId);
      }
    } catch (e) {
      debugPrint("❌ ERROR processing ride update: $e");
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
          // Store FULL response for helper methods
          driverDetails = response.jsonBody;
          isLoadingDriver = false;

          // If currently waiting, move to arriving status
          if (_rideStatus == STATUS_ACCEPTED || _rideStatus == STATUS_SEARCHING) {
            _rideStatus = STATUS_ARRIVING;
          }
        });

        // DEBUG LOGS (important for phone issue)
        debugPrint("👨‍✈️ Driver Loaded: ${GetDriverDetailsCall.name(driverDetails)}");
        debugPrint("🔍 FULL driverDetails JSON: ${jsonEncode(driverDetails)}");
        debugPrint(
            '🔍 driverPhone from helper: "${DriverIdfetchCall.mobileNumber(driverDetails)}"');
      } else {
        if (mounted) setState(() => isLoadingDriver = false);
      }
    } catch (e) {
      debugPrint("☠️ Exception fetching driver: $e");
      if (mounted) setState(() => isLoadingDriver = false);
    }
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(CancelRide.message(response.jsonBody) ?? 'Ride cancelled'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("☠️ Exception: $e");
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  // ✅ UPDATED Helper to make a phone call (with logs + cleaning + safer launch)
  Future<void> _makeCall(String? phoneNumber) async {
    debugPrint('📞 CALL BUTTON PRESSED | Raw phoneNumber: "$phoneNumber"');

    final raw = (phoneNumber ?? '').trim();
    if (raw.isEmpty || raw == 'null') {
      debugPrint('❌ PHONE NULL/EMPTY');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver phone number not available')),
        );
      }
      return;
    }

    // Clean number: keep digits and leading +
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    // Optional India normalization: if 10 digits, prefix +91
    if (!clean.startsWith('+') && RegExp(r'^\d{10}$').hasMatch(clean)) {
      clean = '+91$clean';
    }

    debugPrint('📞 Cleaned number: "$clean"');

    final Uri uri = Uri(scheme: 'tel', path: clean);

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('📞 launchUrl result: $ok');

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    } catch (e, st) {
      debugPrint('❌ launchUrl EXCEPTION: $e');
      debugPrint('Stack: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _pulseController.dispose();

    try {
      socket?.disconnect();
      socket?.dispose();
    } catch (_) {}

    _model.dispose();
    super.dispose();
  }

  // ============================================================================
  // 4. MAIN BUILD METHOD
  // ============================================================================
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

  // ============================================================================
  // 5. UI COMPONENTS
  // ============================================================================

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
                BoxShadow(
                    blurRadius: 10, color: Colors.black12, offset: Offset(0, 4))
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
              onPressed: () => context.pop(),
            ),
          ),
          if (_rideStatus != STATUS_SEARCHING)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 10, color: Colors.black12, offset: Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: primaryColor, size: 20),
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
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      child: (_rideStatus == STATUS_SEARCHING)
          ? _buildSearchingCard()
          : (_rideStatus == STATUS_CANCELLED)
          ? _buildCancelledCard()
          : _buildRapidoDriverDetailsCard(),
    );
  }

  Widget _buildSearchingCard() {
    return Container(
      key: const ValueKey('searching_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))
        ],
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
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isCancelling ? null : _showCancelDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _isCancelling ? Colors.grey[300] : Colors.grey[100],
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: _isCancelling
                  ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey[600]!)))
                  : Text('Cancel Request',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapidoDriverDetailsCard() {
    // 1. Loading State
    if (isLoadingDriver || driverDetails == null) {
      return Container(
        key: const ValueKey('loading_driver_card'),
        height: 300,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
            const SizedBox(height: 20),
            Text('Connecting to Captain...',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.grey[700])),
          ],
        ),
      );
    }

    // 2. Extract Data using API Helpers
    final driverName = GetDriverDetailsCall.name(driverDetails) ?? 'Captain';
    final driverRating = GetDriverDetailsCall.rating(driverDetails) ?? '4.8';
    final totalRides = GetDriverDetailsCall.totalRides(driverDetails) ?? 0;
    final vehicleModel = GetDriverDetailsCall.vehicleModel(driverDetails) ?? 'Auto';
    final vehicleNumber =
        GetDriverDetailsCall.vehicleNumber(driverDetails) ?? 'XX-00';

    final driverPhone = DriverIdfetchCall.mobileNumber(driverDetails);
    debugPrint('📞 UI driverPhone value: "$driverPhone"');

    // Image URL Logic
    String? profilePath = GetDriverDetailsCall.profileImage(driverDetails);
    final profileImageUrl = (profilePath != null && profilePath.isNotEmpty)
        ? (profilePath.startsWith('http') ? profilePath : '$_baseUrl/$profilePath')
        : null;

    // 3. Main Card UI
    return Container(
      key: const ValueKey('rapido_driver_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _rideStatus == STATUS_PICKED_UP
                    ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                    : [primaryColor, const Color(0xFFFF8C28)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (_rideStatus == STATUS_PICKED_UP
                      ? Colors.green
                      : primaryColor)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _rideStatus == STATUS_PICKED_UP
                      ? Icons.trip_origin_rounded
                      : Icons.access_time_filled_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _rideStatus == STATUS_PICKED_UP
                        ? '🚗 Ride in Progress'
                        : '⏱️ Captain arriving in $_etaMinutes min',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_rideOtp != null && _rideStatus != STATUS_PICKED_UP)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share OTP with Captain',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Required to start the ride',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_rideOtp!,
                        style: GoogleFonts.robotoMono(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 5)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                        image: profileImageUrl != null
                            ? DecorationImage(
                            image: NetworkImage(profileImageUrl),
                            fit: BoxFit.cover)
                            : null,
                      ),
                      child: profileImageUrl == null
                          ? Icon(Icons.person,
                          size: 40, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(driverRating,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverName,
                          style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87)),
                      const SizedBox(height: 3),
                      Text('$totalRides rides completed',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                          Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Text('$vehicleModel • $vehicleNumber',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor)),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildRapidoCircleButton(
                      Icons.call_rounded,
                      const Color(0xFF4CAF50),
                          () => _makeCall(driverPhone?.toString()),
                    ),
                    const SizedBox(height: 10),
                    _buildRapidoCircleButton(Icons.chat_bubble_rounded,
                        const Color(0xFF2196F3), () => debugPrint('Chat')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildRapidoActionButton(
                      icon: Icons.share_location_rounded,
                      label: 'Share Trip',
                      onTap: () => debugPrint('Share'),
                      isPrimary: false),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildRapidoActionButton(
                      icon: Icons.close_rounded,
                      label: 'Cancel',
                      onTap: _showCancelDialog,
                      isDestructive: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapidoCircleButton(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildRapidoActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red.shade600 : Colors.grey[700];
    final bgColor = isDestructive ? Colors.red.shade50 : Colors.grey[100];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isDestructive
              ? Border.all(color: Colors.red.shade200)
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
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
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration:
            BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.cancel_rounded,
                size: 64, color: Colors.red.shade400),
          ),
          const SizedBox(height: 24),
          Text('Ride Cancelled',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Your ride request has been cancelled',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Back to Home',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isCancelling,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cancel Ride?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Text('Are you sure you want to cancel this ride?',
              style: GoogleFonts.poppins(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: _isCancelling ? null : () => Navigator.pop(context),
              child: Text('No',
                  style: GoogleFonts.poppins(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: _isCancelling
                  ? null
                  : () {
                Navigator.pop(context);
                _cancelRide('Customer requested cancellation');
              },
              child: _isCancelling
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.red)))
                  : Text('Yes, Cancel',
                  style: GoogleFonts.poppins(
                      color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}
