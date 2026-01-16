import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/api_requests/api_calls.dart';
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

class _AutoBookWidgetState extends State<AutoBookWidget> with TickerProviderStateMixin {
  late AutoBookModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late IO.Socket socket;
  final String _baseUrl = "https://ugotaxi.icacorp.org";

  List<dynamic> ridesCache = [];
  Map<String, dynamic>? driverDetails;
  bool isLoadingDriver = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _searchTimer;
  int _searchSeconds = 0;

  String _rideStatus = 'searching'; // searching, accepted, arriving, picked_up, completed
  String _etaMinutes = '4';
  String _rideDistance = '900';

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
      if (mounted && _rideStatus == 'searching') {
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

      setState(() {
        ridesCache = [updatedRide];
        final status = updatedRide['status'] ?? updatedRide['ride_status'];
        
        // Accepted states
        if (['accepted', 'arriving', 'driver_assigned'].contains(status)) {
          _rideStatus = 'accepted';
          _searchTimer?.cancel();
        } else if (status == 'picked_up') {
          _rideStatus = 'picked_up';
        } else if (status == 'completed') {
          _rideStatus = 'completed';
        }
      });

      final driverId = updatedRide['driver_id'];
      if (driverId != null && driverDetails == null && !isLoadingDriver) {
        final status = updatedRide['status'] ?? updatedRide['ride_status'];
        if (['accepted', 'arriving', 'driver_assigned', 'picked_up'].contains(status)) {
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
            // Check if the response is nested under 'data' or similar
            var data = body['data'] ?? body;
            driverDetails = Map<String, dynamic>.from(data);
            isLoadingDriver = false;
            // Update UI status to show the driver card
            if (_rideStatus == 'accepted' || _rideStatus == 'searching') {
              _rideStatus = 'arriving';
            }
          });
        }
      } else {
        debugPrint("❌ Failed to fetch driver details. Status: ${response.statusCode} Body: ${response.bodyText}");
        if (mounted) {
          setState(() {
            isLoadingDriver = false;
          });
        }
      }
    } catch (e) {
      debugPrint("☠️ Exception fetching driver details: $e");
      if (mounted) {
        setState(() {
          isLoadingDriver = false;
        });
      }
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
            // Google Map (Full screen background)
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

            // Minimalist Header
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
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, 4))],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    if (_rideStatus != 'searching')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield, color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Safety',
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom UI (Uber-style)
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
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: (_rideStatus == 'searching') 
          ? _buildUberSearchingCard() 
          : _buildUberDriverDetailsCard(),
    );
  }

  Widget _buildUberSearchingCard() {
    return Container(
      key: const ValueKey('searching_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finding your ride',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This may take a moment...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Searching for ${_formatSearchTime(_searchSeconds)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _showCancelDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel Request',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.black),
            const SizedBox(height: 16),
            Text('Connecting to driver...', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
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
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _rideStatus == 'picked_up' ? 'Heading to destination' : 'Driver is arriving in $_etaMinutes mins',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          // Driver & Vehicle Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleNumber,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      vehicleModel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(
                                driverRating,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          driverName,
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
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      image: (driverImage != null && driverImage.toString().isNotEmpty)
                          ? DecorationImage(image: NetworkImage(driverImage), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (driverImage == null || driverImage.toString().isEmpty) 
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
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () => debugPrint('Open Chat'),
                    decoration: InputDecoration(
                      hintText: 'Any message for $driverName?',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.chat_bubble_outline, size: 18),
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
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => debugPrint('Call Driver'),
                  icon: const Icon(Icons.call, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Trip PIN or Share
          Row(
            children: [
              Expanded(
                child: _buildActionButton(Icons.share, 'Share Trip'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(Icons.close, 'Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatSearchTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')} min';
    }
    return '$seconds sec';
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel ride?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to cancel your ride request?', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: Text('Yes, Cancel', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
