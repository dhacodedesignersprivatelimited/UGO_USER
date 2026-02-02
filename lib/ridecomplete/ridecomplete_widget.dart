import '/components/ridecomplet_widget.dart';
import '/components/trip_summary_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/review/review_widget.dart';
import '/ride_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ridecomplete_model.dart';
export 'ridecomplete_model.dart';

class RidecompleteWidget extends StatefulWidget {
  const RidecompleteWidget({super.key, this.driverDetails});

  static String routeName = 'ridecomplete';
  static String routePath = '/ridecomplete';
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
    // Optionally clear session after use
    // RideSession().clear();
  }

  @override
  void dispose() {
    print('DEBUG: [RidecompleteWidget] dispose called');
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideData = RideSession().rideData ?? {};
   final driverData = RideSession().driverData;

     print('DEBUG: Ridecomplete.driverData => $driverData');
     print('🟢 Driver in RideComplete: ${RideSession().driverData}');

      
  

    return GestureDetector(
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
                        'DEBUG: [RidecompleteWidget] Back button pressed. Moving to step: \\${_model.currentStep - 1}');
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
                    pickupLocation: rideData['pickup_location_address'],
                    dropoffLocation: rideData['drop_location_address'],
                    distance: rideData['ride_distance_km']?.toString(),
                    duration: rideData['duration']?.toString(),
                    driverName: driverData != null
                                     ? (driverData['name'] ??
                      driverData['first_name'] ??
                      'Driver not assigned')
                  : 'Driver not assigned',

                    vehicleNumber: driverData != null
                  ? (driverData['vehicle_number'] ?? 'N/A')
                  : 'N/A',
                    fare: rideData['estimated_fare'] != null
                        ? '₹${rideData['estimated_fare']}'
                        : null,
                         driverDetails: driverData,
                          // driverName: driverData['name'] ?? driverData['first_name'],
                          // vehicleNumber: driverData['vehicle_number'],
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
    );
  }
}
