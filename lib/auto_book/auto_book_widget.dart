import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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

class _AutoBookWidgetState extends State<AutoBookWidget> {
  late AutoBookModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late IO.Socket socket;
  final String _baseUrl = "https://ugotaxi.icacorp.org";

  List<dynamic> ridesCache = [];
  Map<String, dynamic>? driverDetails;
  bool isLoadingDriver = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AutoBookModel());

    final String token = FFAppState().accessToken;
    final int rideId = widget.rideId;

    debugPrint("-----------------------------------");
    debugPrint("🚀 STARTING SOCKET CONNECTION...");
    debugPrint("🔑 TOKEN: ${token.isNotEmpty ? 'Present' : 'MISSING!'}");
    debugPrint("🆔 RIDE ID: $rideId");
    debugPrint("-----------------------------------");

    if (token.isEmpty) {
      debugPrint("❌ ABORTING: Token is empty. Check FFAppState.");
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
        debugPrint("✅ SOCKET CONNECTED (ID: ${socket.id})");
        debugPrint("📡 Emitting watch_entity for Ride #$rideId...");
        socket.emit("watch_entity", {"type": "ride", "id": rideId});
      });

      socket.onConnectError((data) => debugPrint("❌ Connect Error: $data"));
      socket.onError((data) => debugPrint("❌ General Error: $data"));
      socket.onDisconnect((_) => debugPrint("⚠️ Disconnected"));

      socket.on("ride_updated", (data) {
        debugPrint("📩 RAW DATA RECEIVED: $data");
        debugPrint("📩 DATA TYPE: ${data.runtimeType}");

        if (data != null) {
          try {
            final updatedRide = Map<String, dynamic>.from(data);
            debugPrint("📦 PARSED RIDE DATA: $updatedRide");

            if (mounted) {
              setState(() {
                ridesCache = [updatedRide];
              });

              // Fetch driver details when ride is accepted
              if ((updatedRide['status'] == 'accepted' ||
                  updatedRide['ride_status'] == 'accepted') &&
                  updatedRide['driver_id'] != null) {
                _fetchDriverDetails(updatedRide['driver_id']);
              }
            }
          } catch (e) {
            debugPrint("❌ ERROR PARSING RIDE DATA: $e");
          }
        }
      });

      socket.connect();
    } catch (e) {
      debugPrint("☠️ CRITICAL EXCEPTION: $e");
    }
  }

  Future<void> _fetchDriverDetails(dynamic driverId) async {
    if (!mounted) return;

    setState(() {
      isLoadingDriver = true;
    });

    try {
      final token = FFAppState().accessToken;
      final response = await http.get(
        Uri.parse('$_baseUrl/api/drivers/$driverId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final driver = jsonDecode(response.body);
        debugPrint("✅ DRIVER DETAILS FETCHED: $driver");

        if (mounted) {
          setState(() {
            driverDetails = driver is Map ? driver : driver['data'];
            isLoadingDriver = false;
          });
        }
      } else {
        debugPrint("❌ FAILED TO FETCH DRIVER: ${response.statusCode}");
        if (mounted) {
          setState(() {
            isLoadingDriver = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ ERROR FETCHING DRIVER: $e");
      if (mounted) {
        setState(() {
          isLoadingDriver = false;
        });
      }
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText('077w129n'),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              font: GoogleFonts.interTight(),
              color: Colors.white,
              fontSize: 22.0,
            ),
          ),
          centerTitle: true,
          elevation: 2.0,
        ),
        body: Stack(
          children: [
            FlutterFlowGoogleMap(
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
            Align(
              alignment: const AlignmentDirectional(0.0, 1.0),
              child: PointerInterceptor(
                intercepting: isWeb,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  offset: ridesCache.isEmpty
                      ? const Offset(0, 0.2)
                      : Offset.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ridesCache.isEmpty
                        ? _waitingCard()
                        : (driverDetails != null
                        ? _driverAcceptedCard(ridesCache.first)
                        : _loadingDriverCard(ridesCache.first)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Finding driver nearby...',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ride ID: ${widget.rideId}',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingDriverCard(dynamic ride) {
    final rideId = ride['id']?.toString() ?? widget.rideId.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ride #$rideId',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _statusChip('ACCEPTED'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _driverAcceptedCard(dynamic ride) {
    final rideId = ride['id']?.toString() ?? widget.rideId.toString();
    final pickupLocation = ride['pickup_location']?.toString() ?? '-';
    final dropoffLocation = ride['dropoff_location']?.toString() ?? '-';

    final driverName = driverDetails?['name'] ?? 'Driver';
    final driverRating = driverDetails?['rating'] ?? 4.8;
    final driverPhone = driverDetails?['phone'] ?? '';
    final vehicleNumber = driverDetails?['vehicle']?['number'] ?? 'N/A';
    final vehicleModel = driverDetails?['vehicle']?['model'] ?? 'Unknown';
    final vehicleColor = driverDetails?['vehicle']?['color'] ?? 'White';
    final driverImage = driverDetails?['profile_image'];
    final totalRides = driverDetails?['total_rides'] ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Ride ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ride #$rideId',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    _statusChip('ACCEPTED'),
                  ],
                ),
                const SizedBox(height: 16),

                // Driver Profile Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      // Driver Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                          image: driverImage != null
                              ? DecorationImage(
                            image: NetworkImage(driverImage),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: driverImage == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Driver Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$driverRating • $totalRides rides',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Call & Chat Icons
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              debugPrint('📞 Calling driver: $driverPhone');
                              // Add call functionality here
                              // Example: url_launcher to make call
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Icon(
                                Icons.call,
                                size: 18,
                                color: FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              debugPrint('💬 Opening chat with driver');
                              // Add chat functionality here
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Icon(
                                Icons.chat_outlined,
                                size: 18,
                                color: FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 32,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicleModel,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$vehicleColor • $vehicleNumber',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Trip Details
                if (pickupLocation != '-' || dropoffLocation != '-') ...[
                  Text(
                    'Trip Details',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pickupLocation != '-')
                    _tripDetailRow(
                      Icons.location_on_outlined,
                      'Pickup',
                      pickupLocation,
                    ),
                  if (pickupLocation != '-' && dropoffLocation != '-')
                    const SizedBox(height: 8),
                  if (dropoffLocation != '-')
                    _tripDetailRow(
                      Icons.flag_outlined,
                      'Dropoff',
                      dropoffLocation,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color chipColor;
    Color chipBgColor;
    switch (status.toLowerCase()) {
      case 'accepted':
        chipColor = Colors.green;
        chipBgColor = Colors.green.withOpacity(0.1);
        break;
      case 'pending':
        chipColor = Colors.orange;
        chipBgColor = Colors.orange.withOpacity(0.1);
        break;
      case 'completed':
        chipColor = Colors.blue;
        chipBgColor = Colors.blue.withOpacity(0.1);
        break;
      default:
        chipColor = Colors.grey;
        chipBgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}