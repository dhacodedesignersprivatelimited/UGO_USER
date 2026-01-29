import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/api_requests/api_calls.dart';
import '/ridecomplete/ridecomplete_widget.dart';
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

  static String routeName = 'rapido-auto-book';
  static String routePath = '/rapidoAutoBook';

  @override
  State<AutoBookWidget> createState() => _AutoBookWidgetState();
}

class _AutoBookWidgetState extends State<AutoBookWidget>
    with TickerProviderStateMixin {
  late AutoBookModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color primaryColor = Color(0xFFF7C844);

  IO.Socket? socket;
  final String _baseUrl = "https://ugotaxi.icacorp.org";

  List<dynamic> ridesCache = [];
  Map<String, dynamic>? driverDetails;

  bool isLoadingDriver = false;
  bool _isCancelling = false;
  String? _rideOtp;

  String _rideStatus = 'searching';
  String _etaMinutes = '4';

  Timer? _searchTimer;
  int _searchSeconds = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const STATUS_SEARCHING = 'searching';
  static const STATUS_ACCEPTED = 'accepted';
  static const STATUS_ARRIVING = 'arriving';
  static const STATUS_PICKED_UP = 'picked_up';
  static const STATUS_COMPLETED = 'completed';
  static const STATUS_CANCELLED = 'cancelled';

  @override
  void initState() {
    super.initState();
    print('DEBUG: [AutoBookWidget] initState called');
    print('DEBUG: [AutoBookWidget] Ride ID: ${widget.rideId}');
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
    print('DEBUG: [AutoBookWidget] Starting searching timer...');
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _rideStatus == STATUS_SEARCHING) {
        setState(() => _searchSeconds++);
        if (_searchSeconds % 10 == 0) {
          print('DEBUG: [AutoBookWidget] Still searching... Time elapsed: $_searchSeconds seconds');
        }
      }
    });
  }

  Future<void> _fetchInitialRideStatus() async {
    print('DEBUG: [AutoBookWidget] Fetching initial ride status via REST API');
    try {
      final response = await GetRideDetailsCall.call(
        rideId: widget.rideId,
        token: FFAppState().accessToken,
      );
      if (response.succeeded) {
        final rideData = response.jsonBody['data'] ?? response.jsonBody;
        print('DEBUG: [AutoBookWidget] Initial API Fetch Success: ${jsonEncode(rideData)}');
        _processRideUpdate(rideData);
      } else {
        print('DEBUG: [AutoBookWidget] Initial API Fetch Failed: ${response.statusCode} - ${response.jsonBody}');
      }
    } catch (e) {
      print("DEBUG: [AutoBookWidget] Exception in _fetchInitialRideStatus: $e");
    }
  }

  void _initializeSocket() {
    final String token = FFAppState().accessToken;
    print('DEBUG: [AutoBookWidget] Initializing Socket.IO connection to $_baseUrl');

    if (token.isEmpty) {
      print("DEBUG: [AutoBookWidget] ERROR: Access token is empty. Socket won't connect.");
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
        print("DEBUG: [AutoBookWidget] SOCKET CONNECTED SUCCESSFULLY");
        socket!.emit("watch_entity", {"type": "ride", "id": widget.rideId});
        print("DEBUG: [AutoBookWidget] SOCKET EMITTED: watch_entity for ride ${widget.rideId}");
      });

      socket!.on("ride_updated", (data) {
        print("DEBUG: [AutoBookWidget] SOCKET EVENT: ride_updated received");
        print("DEBUG: [AutoBookWidget] DATA: ${jsonEncode(data)}");
        if (data != null) _processRideUpdate(data);
      });

      socket!.onDisconnect((_) => print("DEBUG: [AutoBookWidget] SOCKET DISCONNECTED"));
      socket!.onConnectError((err) => print("DEBUG: [AutoBookWidget] SOCKET CONNECTION ERROR: $err"));

      socket!.connect();
    } catch (e) {
      print("DEBUG: [AutoBookWidget] SOCKET EXCEPTION: $e");
    }
  }

  void _processRideUpdate(dynamic data) {
    try {
      final updatedRide = Map<String, dynamic>.from(data);
      if (!mounted) return;

      final rawStatus = updatedRide['ride_status'] ?? updatedRide['status'];
      final status = rawStatus?.toString().toLowerCase();
      print('DEBUG: [AutoBookWidget] Incoming Status Update: "$status"');

      setState(() {
        if (ridesCache.isNotEmpty) {
          ridesCache[0] = {...ridesCache[0], ...updatedRide};
        } else {
          ridesCache = [updatedRide];
        }

        if (updatedRide['otp'] != null) {
          _rideOtp = updatedRide['otp'].toString();
          print('DEBUG: [AutoBookWidget] Ride OTP Received: $_rideOtp');
        }

        if (status == 'cancelled') {
          print('DEBUG: [AutoBookWidget] Flow: Status changed to CANCELLED');
          _rideStatus = STATUS_CANCELLED;
          _searchTimer?.cancel();
        } else if (['accepted', 'arriving', 'driver_assigned'].contains(status)) {
          print('DEBUG: [AutoBookWidget] Flow: Status changed to ACCEPTED/ARRIVING');
          _rideStatus = STATUS_ACCEPTED;
          _searchTimer?.cancel();
        } else if (status == 'started' || status == 'picked_up') {
          print('DEBUG: [AutoBookWidget] Flow: Status changed to PICKED_UP (In Progress)');
          _rideStatus = STATUS_PICKED_UP;
        } else if (status == 'completed') {
          print('DEBUG: [AutoBookWidget] FLOW REACHED: COMPLETED');
          print('DEBUG: [AutoBookWidget] Navigating to RidecompleteWidget flow...');
          _rideStatus = STATUS_COMPLETED;
          _searchTimer?.cancel();
          context.pushNamed(RidecompleteWidget.routeName);
        }
      });

      final driverId = updatedRide['driver_id'];
      if (driverId != null && driverDetails == null && !isLoadingDriver) {
        print('DEBUG: [AutoBookWidget] Driver ID identified: $driverId. Fetching details...');
        _fetchDriverDetails(driverId);
      }
    } catch (e) {
      print("DEBUG: [AutoBookWidget] ERROR in _processRideUpdate: $e");
    }
  }

  Future<void> _fetchDriverDetails(dynamic driverId) async {
    if (!mounted) return;
    setState(() => isLoadingDriver = true);
    print('DEBUG: [AutoBookWidget] Calling GetDriverDetails API for ID: $driverId');

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
        print("DEBUG: [AutoBookWidget] Driver details loaded for: ${GetDriverDetailsCall.name(driverDetails)}");
      } else {
        print("DEBUG: [AutoBookWidget] Failed to load driver details: ${response.jsonBody}");
        if (mounted) setState(() => isLoadingDriver = false);
      }
    } catch (e) {
      print("DEBUG: [AutoBookWidget] Exception in _fetchDriverDetails: $e");
      if (mounted) setState(() => isLoadingDriver = false);
    }
  }

  Future<void> _cancelRide(String reason) async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    print('DEBUG: [AutoBookWidget] User requested cancellation. Reason: $reason');

    try {
      final response = await CancelRide.call(
        rideId: widget.rideId,
        cancellationReason: reason,
        token: FFAppState().accessToken,
        cancelledBy: 'user',
      );

      if (mounted) {
        if (response.succeeded) {
          print('DEBUG: [AutoBookWidget] Ride cancellation successful');
          setState(() {
            _rideStatus = STATUS_CANCELLED;
            _searchTimer?.cancel();
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.pop();
          });
        } else {
          print('DEBUG: [AutoBookWidget] Ride cancellation failed: ${response.jsonBody}');
        }
      }
    } catch (e) {
      print("DEBUG: [AutoBookWidget] Cancel exception: $e");
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    print('DEBUG: [AutoBookWidget] Attempting to call: $phoneNumber');
    final raw = (phoneNumber ?? '').trim();
    if (raw.isEmpty || raw == 'null') {
      print('DEBUG: [AutoBookWidget] ERROR: Phone number is missing');
      return;
    }
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (!clean.startsWith('+') && RegExp(r'^\d{10}$').hasMatch(clean)) {
      clean = '+91$clean';
    }
    final Uri uri = Uri(scheme: 'tel', path: clean);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      print('DEBUG: [AutoBookWidget] Call launched successfully');
    } catch (e) {
      print('DEBUG: [AutoBookWidget] ERROR: Could not launch call: $e');
    }
  }

  @override
  void dispose() {
    print('DEBUG: [AutoBookWidget] dispose called. Cleaning up...');
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
                child: _buildRapidoBottomUI(),
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
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
              onPressed: () {
                print('DEBUG: [AutoBookWidget] Back button pressed');
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapidoBottomUI() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
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
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Text('Finding your Rapido Captain', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                print('DEBUG: [AutoBookWidget] User clicked Cancel Request');
                _showCancelDialog();
              },
              child: Text('Cancel Rapido Request'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapidoDriverDetailsCard() {
    if (isLoadingDriver || driverDetails == null) {
      return Container(
          height: 300, 
          decoration: BoxDecoration(color: Colors.white),
          child: Center(child: CircularProgressIndicator())
      );
    }
    return Container(
      key: const ValueKey('rapido_driver_card'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Captain Assigned', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: Icon(Icons.call, color: Colors.green), 
                    onPressed: () => _makeCall(DriverIdfetchCall.mobileNumber(driverDetails)?.toString())
                ),
                IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red), 
                    onPressed: () {
                      print('DEBUG: [AutoBookWidget] User clicked Cancel Ride (assigned)');
                      _showCancelDialog();
                    }
                ),
              ],
            )
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
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cancelled', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () {
                print('DEBUG: [AutoBookWidget] User returning to home from cancelled screen');
                context.pop();
              }, 
              child: Text('Back to Home')
          )
        ],
      ),
    );
  }

  void _showCancelDialog() {
    print('DEBUG: [AutoBookWidget] Showing cancellation confirmation dialog');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cancel Ride?'),
          actions: [
            TextButton(
                onPressed: () {
                  print('DEBUG: [AutoBookWidget] User dismissed cancellation dialog (Clicked No)');
                  Navigator.pop(context);
                }, 
                child: Text('No')
            ),
            TextButton(
              onPressed: () {
                print('DEBUG: [AutoBookWidget] User confirmed cancellation (Clicked Yes)');
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
