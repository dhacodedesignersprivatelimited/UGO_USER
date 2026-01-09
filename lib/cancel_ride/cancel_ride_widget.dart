import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' show cos, sqrt, asin;
import 'cancel_ride_model.dart';
export 'cancel_ride_model.dart';

class CancelRideWidget extends StatefulWidget {
  const CancelRideWidget({super.key});

  static String routeName = 'cancel_ride';
  static String routePath = '/cancelRide';

  @override
  State<CancelRideWidget> createState() => _CancelRideWidgetState();
}

class _CancelRideWidgetState extends State<CancelRideWidget> {
  late CancelRideModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  // Variables to store parsed data
  String? rideId;
  String? vehicleType;
  String? pickupLocation;
  String? dropLocation;
  double? estimatedFare;
  double? estimatedDistance;
  String? vehicleImage;
  String? seatingCapacity;
  String? luggageCapacity;
  double? pricePerKm;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CancelRideModel());
    
    _scrollController.addListener(() {
      setState(() {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.position.pixels;
          _scrollProgress = maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Parse query parameters
    final params = GoRouter.of(context).routeInformationProvider.value.uri.queryParameters;
    
    rideId = params['rideId'];
    vehicleType = params['vehicleType'];
    pickupLocation = params['pickupLocation'];
    dropLocation = params['dropLocation'];
    vehicleImage = params['vehicleImage'];
    seatingCapacity = params['seatingCapacity'];
    luggageCapacity = params['luggageCapacity'];
    
    // Parse numeric values
    if (params['estimatedFare'] != null) {
      estimatedFare = double.tryParse(params['estimatedFare']!);
    }
    if (params['estimatedDistance'] != null) {
      estimatedDistance = double.tryParse(params['estimatedDistance']!);
    }
    if (params['pricePerKm'] != null) {
      pricePerKm = double.tryParse(params['pricePerKm']!);
    }
    
    print('=== Parsed Parameters ===');
    print('Vehicle Type: $vehicleType');
    print('Estimated Fare: $estimatedFare');
    print('Vehicle Image: $vehicleImage');
    print('Seating: $seatingCapacity');
    print('Luggage: $luggageCapacity');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    // Use parsed parameters or fall back to FFAppState
    final displayVehicleType = vehicleType ?? FFAppState().vehicleselect;
    final displayPickupLocation = pickupLocation ?? FFAppState().pickuplocation;
    final displayDropLocation = dropLocation ?? FFAppState().droplocation;
    final displayEstimatedFare = estimatedFare;
    final displayVehicleImage = vehicleImage;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              // Map Background (Full Screen)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: Image.asset('assets/images/89ssz8.png').image,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Pickup Location Marker
                      Positioned(
                        left: 40,
                        top: 150,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.circle, color: Colors.green, size: 20),
                        ),
                      ),
                      // Drop Location Marker
                      Positioned(
                        right: 40,
                        bottom: 250,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.location_on, color: Colors.red, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sheet with Vehicle Details
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      Container(
                        margin: EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFFE1E1E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Scrollable Content
                      Expanded(
                        child: Row(
                          children: [
                            // Scroll Progress Bar
                            Container(
                              width: 4,
                              margin: EdgeInsets.only(left: 16, top: 16, bottom: 16),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE1E1E1),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: FractionallySizedBox(
                                          heightFactor: _scrollProgress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFF7B10),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Content
                            Expanded(
                              child: ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                children: [
                                  // Pickup Location Card (Compact)
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF8F8F8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Color(0xFFE1E1E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.circle, color: Colors.green, size: 10),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            displayPickupLocation.isNotEmpty ? displayPickupLocation : 'Pickup Location',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF756F6F)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 8),

                                  // Drop Location Card (Compact)
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF8F8F8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Color(0xFFE1E1E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.red, size: 12),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            displayDropLocation.isNotEmpty ? displayDropLocation : 'Drop Location',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF756F6F)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 16),

                                  // Vehicle Card
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Color(0xFFE1E1E1), width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        // Vehicle Image
                                        if (displayVehicleImage != null && displayVehicleImage.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              'http://www.ugotaxi.com/$displayVehicleImage',
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 70,
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFF5F5F5),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(Icons.directions_car, size: 35, color: Colors.grey),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF5F5F5),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.directions_car, size: 35, color: Colors.grey),
                                          ),
                                        
                                        SizedBox(width: 12),

                                        // Vehicle Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Vehicle Type and Price
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          displayVehicleType.isNotEmpty ? displayVehicleType : 'Vehicle',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        SizedBox(height: 2),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              'Pick up : ',
                                                              style: TextStyle(fontSize: 11, color: Color(0xFF756F6F)),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                displayPickupLocation.isNotEmpty 
                                                                    ? displayPickupLocation.split(',').first 
                                                                    : 'Dilsukhnagar',
                                                                style: TextStyle(fontSize: 11, color: Color(0xFF756F6F)),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              'Drop location : ',
                                                              style: TextStyle(fontSize: 11, color: Color(0xFF756F6F)),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                displayDropLocation.isNotEmpty 
                                                                    ? displayDropLocation.split(',').first 
                                                                    : 'Ameerpet',
                                                                style: TextStyle(fontSize: 11, color: Color(0xFF756F6F)),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  // Price Badge
                                                  if (displayEstimatedFare != null && displayEstimatedFare > 0)
                                                    Text(
                                                      '₹${displayEstimatedFare.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 16),

                                  // Cancel Button
                                  FFButtonWidget(
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => Center(child: CircularProgressIndicator()),
                                      );

                                      // TODO: Add your cancel ride API call here
                                      await Future.delayed(Duration(seconds: 1));
                                      Navigator.pop(context);

                                      // Show success dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          title: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green, size: 28),
                                              SizedBox(width: 8),
                                              Text('Ride Cancelled'),
                                            ],
                                          ),
                                          content: Text('Your ride has been cancelled successfully.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                context.pop();
                                                context.pop();
                                              },
                                              child: Text(
                                                'OK',
                                                style: TextStyle(
                                                  color: Color(0xFFFF7B10),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    text: 'Cancel',
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 56.0,
                                      color: Color(0xFFFF7B10),
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                      elevation: 0.0,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),

                                  SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Back Button (Positioned on Map)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FlutterFlowIconButton(
                    borderRadius: 30.0,
                    buttonSize: 50.0,
                    fillColor: Colors.white,
                    icon: Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFF7B10),
                      size: 24.0,
                    ),
                    onPressed: () async {
                      context.pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}