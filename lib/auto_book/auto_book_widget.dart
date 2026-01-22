import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/api_requests/api_calls.dart'; // ✅ Ensure this path is correct
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'auto_book_model.dart';
export 'auto_book_model.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AutoBookWidget extends StatefulWidget {
  const AutoBookWidget({
    super.key,
    required this.rideId,
  });

  final int rideId;

  static String routeName = 'auto-book';
  static String routePath = '/autoBook';

  @override
  State<AutoBookWidget> createState() => _AutoBookWidgetState();
}

class _AutoBookWidgetState extends State<AutoBookWidget>
    with TickerProviderStateMixin {
      String? _rideOtp;

  late AutoBookModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late IO.Socket socket;
  final String _baseUrl = "https://ugotaxi.icacorp.org";

  List<dynamic> ridesCache = [];
  Map<String, dynamic>? driverDetails;
  bool isLoadingDriver = false;
  bool _isCancelling = false; // ✅ Track cancellation state

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  

  Timer? _searchTimer;
  
  int _searchSeconds = 0;

  String _rideStatus =
      'searching'; // searching, accepted, arriving, picked_up, completed, cancelled
  String _etaMinutes = '4';

  // ✅ Ride Status Constants
  static const STATUS_SEARCHING = 'searching';
  static const STATUS_ACCEPTED = 'accepted';
  static const STATUS_ARRIVING = 'arriving';
  static const STATUS_PICKED_UP = 'picked_up';
  static const STATUS_COMPLETED = 'completed';
  static const STATUS_CANCELLED = 'cancelled';

  @override
  void initState() {
    super.initState();
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
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _rideStatus == STATUS_SEARCHING) {
        setState(() {
          _searchSeconds++;
        });
      }
    });
  }

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
      debugPrint("Error fetching initial ride status: $e");
    }
  }

  void _initializeSocket() {
    final String token = FFAppState().accessToken;
    final int rideId = widget.rideId;

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

      socket.onConnect((_) {
        debugPrint("✅ SOCKET CONNECTED");

        socket.emit("watch_entity", {"type": "ride", "id": rideId});
      });

      socket.on("ride_updated", (data) {
        debugPrint("📡 RIDE UPDATED via Socket: $data");
        if (data != null) {
          _processRideUpdate(data);
        }
      });

      socket.connect();
    } catch (e) {
      debugPrint("☠️ SOCKET EXCEPTION: $e");
    }
  }

  void _processRideUpdate(dynamic data) {
    
    try {
      final updatedRide = Map<String, dynamic>.from(data);
      if (!mounted) return;
      print("🔄 Processing ride update socket: ${updatedRide}");

      setState(() {
  if (ridesCache.isNotEmpty) {
    ridesCache[0] = {
      ...ridesCache[0],   // keep API data
      ...updatedRide,     // overwrite changed fields only
    };
  } else {
    ridesCache = [updatedRide];
  }

  final rawStatus = updatedRide['ride_status'] ?? updatedRide['status'];
  final status = rawStatus?.toString().toLowerCase();

  if (updatedRide['otp'] != null) {
    _rideOtp = updatedRide['otp'].toString();
  }

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

      final driverId = updatedRide['driver_id'];
      if (driverId != null && driverDetails == null && !isLoadingDriver) {
        final status = updatedRide['status'] ?? updatedRide['ride_status'];
        if ([
          STATUS_ACCEPTED,
          STATUS_ARRIVING,
          'driver_assigned',
          STATUS_PICKED_UP
        ].contains(status)) {
          _fetchDriverDetails(driverId);
        }
      }
    } catch (e) {
      debugPrint("❌ ERROR processing ride update: $e");
    }
  }

  Future<void> _fetchDriverDetails(dynamic driverId) async {
    if (!mounted) return;

    setState(() {
      isLoadingDriver = true;
    });

    try {
      final token = FFAppState().accessToken;
      debugPrint("🔍 Fetching details for driver: $driverId");

      final response = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: token,
      );

      if (response.succeeded) {
        final body = response.jsonBody;
        debugPrint("✅ Driver details received: $body");

        if (mounted) {
          setState(() {
            var data = body['data'] ?? body;
            driverDetails = Map<String, dynamic>.from(data);
            isLoadingDriver = false;
            if (_rideStatus == STATUS_ACCEPTED ||
                _rideStatus == STATUS_SEARCHING) {
              _rideStatus = STATUS_ARRIVING;
            }
          });
        }
      } else {
        debugPrint("❌ Failed to fetch driver details.");
        if (mounted) setState(() => isLoadingDriver = false);
      }
    } catch (e) {
      debugPrint("☠️ Exception fetching driver details: $e");
      if (mounted) setState(() => isLoadingDriver = false);
    }
  }

  // ✅ CANCEL RIDE FUNCTION (API CALL)
  Future<void> _cancelRide(String reason) async {
    if (_isCancelling) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final token = FFAppState().accessToken;

      debugPrint("🚫 Cancelling ride ${widget.rideId} with reason: $reason");

      final response = await CancelRide.call(
        rideId: widget.rideId,
        cancellationReason: reason,
        token: token,
        cancelledBy: 'user',
      );

      if (mounted) {
        if (response.succeeded) {
          final message = CancelRide.message(response);
          debugPrint("✅ Ride cancelled successfully: $message");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Ride cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _rideStatus = STATUS_CANCELLED;
            _searchTimer?.cancel();
          });

          // Navigate back after delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.pop();
          });
        } else {
          debugPrint("❌ Failed to cancel ride. Status: ${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel ride. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("☠️ Exception cancelling ride: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _pulseController.dispose();
    socket.disconnect();
    socket.dispose();
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
            // Google Map
            Positioned.fill(
              child: FlutterFlowGoogleMap(
                controller: _model.googleMapsController,
                onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
                initialLocation: _model.googleMapsCenter ??=
                    const LatLng(13.106061, -59.613158),
                markerColor: GoogleMarkerColor.violet,
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
              child: Container(
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
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
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
                              blurRadius: 10,
                              color: Colors.black12,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.black, size: 24),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    if (_rideStatus != STATUS_SEARCHING)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 10,
                                color: Colors.black12,
                                offset: Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield,
                                color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Safety',
                              style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom UI
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

  Widget _buildUberBottomUI() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(animation),
          child: child,
        );
      },
      child: (_rideStatus == STATUS_SEARCHING)
          ? _buildUberSearchingCard()
          : (_rideStatus == STATUS_CANCELLED)
              ? _buildCancelledCard()
              : _buildUberDriverDetailsCard(),
    );
  }

  // ✅ CANCELLED RIDE CARD
  Widget _buildCancelledCard() {
    return Container(
      key: const ValueKey('cancelled_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 32),
          const Icon(Icons.cancel, size: 64, color: Colors.red),
          const SizedBox(height: 24),
          Text('Ride Cancelled',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black)),
          const SizedBox(height: 8),
          Text('Your ride request has been cancelled',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Back to Home',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUberSearchingCard() {
    return Container(
      key: const ValueKey('searching_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finding your ride',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('This may take a moment...',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                      color: Colors.black, shape: BoxShape.circle),
                  child: const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Searching for ${_formatSearchTime(_searchSeconds)}',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isCancelling ? null : () => _showCancelDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isCancelling ? Colors.grey[300] : Colors.grey[100],
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCancelling
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey[600]!)))
                  : Text('Cancel Request',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUberDriverDetailsCard() {
    if (isLoadingDriver || (ridesCache.isEmpty && driverDetails == null)) {
      return Container(
        key: const ValueKey('loading_driver_card'),
        height: 250,
        width: double.infinity,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.black),
            const SizedBox(height: 16),
            Text('Connecting to driver...',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    final driverName = driverDetails?['name'] ?? 'Driver';
    final vehicleModel = driverDetails?['vehicle']?['model'] ?? 'Vehicle';
    final vehicleNumber = driverDetails?['vehicle']?['number'] ?? 'PLATE';
    final driverRating = driverDetails?['rating']?.toString() ?? '4.8';
    final driverImage = driverDetails?['profile_image'];

    return Container(
      key: const ValueKey('driver_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Column(
    children: [
      Text(
        _rideStatus == STATUS_PICKED_UP
            ? 'Heading to destination'
            : 'Driver is arriving in $_etaMinutes mins',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),

      // ✅ OTP CARD (Uber Style)
      if (_rideOtp != null &&
          _rideStatus != STATUS_PICKED_UP) ...[
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Column(
            children: [
              Text(
                'OTP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _rideOtp!,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share this OTP with the driver',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  ),
),

          const Divider(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicleNumber,
                        style: GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    Text(vehicleModel,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 14, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(driverRating,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(driverName,
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      image: (driverImage != null &&
                              driverImage.toString().isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(driverImage),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child:
                        (driverImage == null || driverImage.toString().isEmpty)
                            ? const Icon(Icons.person, size: 32)
                            : null,
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(26)),
                  child: TextField(
                    readOnly: true,
                    onTap: () => debugPrint('Open Chat'),
                    decoration: InputDecoration(
                      hintText: 'Any message for $driverName?',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14, color: Colors.grey[600]),
                      prefixIcon:
                          const Icon(Icons.chat_bubble_outline, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: Colors.grey[100], shape: BoxShape.circle),
                child: IconButton(
                    onPressed: () => debugPrint('Call Driver'),
                    icon: const Icon(Icons.call, size: 22)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildActionButton(Icons.share, 'Share Trip')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionButton(Icons.close, 'Cancel',
                      isCancel: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label,
      {bool isCancel = false}) {
    return GestureDetector(
      onTap: isCancel
          ? () => _showCancelDialog()
          : () => debugPrint('$label tapped'),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            border:
                Border.all(color: isCancel ? Colors.red : Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isCancel ? Colors.red : Colors.black),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isCancel ? Colors.red : Colors.black)),
          ],
        ),
      ),
    );
  }

  String _formatSearchTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0)
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')} min';
    return '$seconds sec';
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isCancelling,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel ride?',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to cancel your ride request?',
              style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: _isCancelling ? null : () => Navigator.pop(context),
              child: Text('No', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: _isCancelling
                  ? null
                  : () {
                      Navigator.pop(context);
                      _cancelRide('Customer cancelled');
                    },
              child: _isCancelling
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.red)))
                  : Text('Yes, Cancel',
                      style: GoogleFonts.inter(
                          color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
