import '/backend/api_requests/api_calls.dart';
import '/components/ridecomplet_widget.dart';
import '/components/trip_summary_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/ride_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ridecomplete_model.dart';
export 'ridecomplete_model.dart';

class RidecompleteWidget extends StatefulWidget {
  const RidecompleteWidget({super.key, this.rideId, this.driverDetails});

  static String routeName = 'ridecomplete';
  static String routePath = '/ridecomplete';
  final int? rideId;
  final Map<String, dynamic>? driverDetails;

  @override
  State<RidecompleteWidget> createState() => _RidecompleteWidgetState();
}

class _RidecompleteWidgetState extends State<RidecompleteWidget> {
  late RidecompleteModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    print('DEBUG: [RidecompleteWidget] initState called');
    _model = createModel(context, () => RidecompleteModel());
    _fetchDriverIfMissing();
  }

  Future<void> _fetchDriverIfMissing() async {
    if (RideSession().driverData != null) return;
    final rawRide = RideSession().rideData ?? {};
    final rideData = rawRide['data'] is Map
        ? rawRide['data'] as Map
        : rawRide;
    final driverId = rideData['driver_id'];
    if (driverId == null) return;
    try {
      final res = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: FFAppState().accessToken,
      );
      if (res.succeeded && mounted) {
        RideSession().driverData = res.jsonBody;
        setState(() {});
      }
    } catch (e) {
      print('Ridecomplete: fetch driver failed: $e');
    }
  }

  static num? _parseFare(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
  }

  static String? _vehicleFromAdminVehicle(Map<String, dynamic>? d) {
    if (d == null) return null;
    final av = d['adminVehicle'];
    if (av is Map) return av['vehicle_name']?.toString();
    return null;
  }

  @override
  void dispose() {
    print('DEBUG: [RidecompleteWidget] dispose called');
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Unwrap ride data (API may return {data: {...}})
    final rawRide = RideSession().rideData ?? {};
    final rideData = rawRide['data'] is Map
        ? Map<String, dynamic>.from(rawRide['data'] as Map)
        : Map<String, dynamic>.from(rawRide);

    // Unwrap driver data (GetDriverDetailsCall returns {success, data: {...}})
    final rawDriver = RideSession().driverData;
    final driverData = rawDriver != null && rawDriver['data'] is Map
        ? Map<String, dynamic>.from(rawDriver['data'] as Map)
        : rawDriver != null
            ? Map<String, dynamic>.from(rawDriver)
            : null;

    final rideIdRaw = widget.rideId ?? FFAppState().currentRideId ??
        rideData['id'] ?? rideData['ride_id'];
    final rideId = rideIdRaw is int
        ? rideIdRaw
        : (rideIdRaw != null ? int.tryParse(rideIdRaw.toString()) : null);

    // Extract driver information with fallbacks
    final driverName = driverData != null
        ? ('${driverData['first_name'] ?? ''} ${driverData['last_name'] ?? ''}'
                .trim()
                .isNotEmpty
            ? '${driverData['first_name'] ?? ''} ${driverData['last_name'] ?? ''}'
                .trim()
            : (driverData['name'] ??
                driverData['driver_name'] ??
                'Driver not assigned'))
        : 'Driver not assigned';

    final vehicleNumber = driverData != null
        ? (driverData['vehicle_number'] ??
            driverData['vehicleNumber'] ??
            driverData['vehicle_no'] ??
            _vehicleFromAdminVehicle(driverData) ??
            'N/A')
        : 'N/A';

    final fare = rideData['estimated_fare'] != null
        ? '₹${rideData['estimated_fare']}'
        : rideData['fare'] != null
            ? '₹${rideData['fare']}'
            : null;

    print('🚗 Passing to RidecompletWidget:');
    print('   - driverName: $driverName');
    print('   - vehicleNumber: $vehicleNumber');
    print('   - fare: $fare');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          context.goNamed(HomeWidget.routeName);
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: _model.currentStep > 0
              ? FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 30.0,
                  borderWidth: 1.0,
                  buttonSize: 60.0,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 30.0,
                  ),
                  onPressed: () async {
                    print(
                        'DEBUG: [RidecompleteWidget] Back button pressed. Moving to step: ${_model.currentStep - 1}');
                    setState(() {
                      _model.currentStep--;
                    });
                  },
                )
              : null,
          title: Text(
            _model.currentStep == 0 ? 'Ride Complete' : 'Trip Summary',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (_model.currentStep == 0)
                Expanded(
                  child: RidecompletWidget(
                    rideId: rideId,
                    userId: FFAppState().userid,
                    paymentMethod: (rideData['payment_method'] ??
                            rideData['payment_type'] ??
                            FFAppState().selectedPaymentMethod)
                        ?.toString(),
                    fareAmount: _parseFare(rideData['estimated_fare'] ?? rideData['fare']),
                    pickupLocation: rideData['pickup_location_address'] ??
                        rideData['pickup_address'],
                    dropoffLocation: rideData['drop_location_address'] ??
                        rideData['drop_address'],
                    distance: rideData['ride_distance_km']?.toString() ??
                        rideData['distance']?.toString(),
                    duration: rideData['duration']?.toString(),
                    driverName: driverName,
                    vehicleNumber: vehicleNumber,
                    fare: fare,
                    driverDetails: driverData,
                    
                    onNext: () {
                      print(
                          'DEBUG: [RidecompleteWidget] Step 0 (Ride Complete) finished. Moving to Trip Summary');
                      setState(() {
                        _model.currentStep = 1;
                      });
                    },
                  ),
                ),
              if (_model.currentStep == 1)
                Expanded(
                  child: TripSummaryWidget(
                    pickupLocation: rideData['pickup_location_address'],
                    dropoffLocation: rideData['drop_location_address'],
                    distance: rideData['ride_distance_km']?.toString(),
                    duration: rideData['duration']?.toString(),
                    totalFare: rideData['estimated_fare'] != null
                        ? '₹${rideData['estimated_fare']}'
                        : null,
                    onNext: () {
                      print(
                          'DEBUG: [RidecompleteWidget] Step 1 (Trip Summary) finished. Navigating to Reviews');
                      context.pushNamed(ReviewWidget.routeName);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}