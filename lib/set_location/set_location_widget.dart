import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:geocoding/geocoding.dart';
import 'set_location_model.dart';
export 'set_location_model.dart';

class SetLocationWidget extends StatefulWidget {
  const SetLocationWidget({super.key});

  static String routeName = 'Set_Location';
  static String routePath = '/setLocation';

  @override
  State<SetLocationWidget> createState() => _SetLocationWidgetState();
}

class _SetLocationWidgetState extends State<SetLocationWidget> {
  late SetLocationModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;
  String pickupAddress = '';
  String dropAddress = '';
  bool isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetLocationModel());

    // Load existing locations from AppState
    pickupAddress = FFAppState().pickuplocation;
    dropAddress = FFAppState().droplocation;

    getCurrentUserLocation(defaultLocation: LatLng(0.0, 0.0), cached: true)
        .then((loc) {
      safeSetState(() => currentUserLocationValue = loc);
      
      // Only update current location if no location is selected
      if (pickupAddress.isEmpty && dropAddress.isEmpty) {
        _updateAddressFromLocation(loc);
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _updateAddressFromLocation(LatLng location) async {
    setState(() {
      isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.name,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        setState(() {
          // Update based on which location is being set
          if (FFAppState().selectedlocation) {
            pickupAddress = address;
          } else {
            dropAddress = address;
          }
          isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        String coords = 'Location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        if (FFAppState().selectedlocation) {
          pickupAddress = coords;
        } else {
          dropAddress = coords;
        }
        isLoadingAddress = false;
      });
    }
  }

  void _showSearchDialog(bool isPickup) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPickup ? 'Search Pickup Location' : 'Search Drop Location',
                      style: FlutterFlowTheme.of(context).headlineSmall,
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                FlutterFlowPlacePicker(
                  iOSGoogleMapsApiKey: 'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y',
                  androidGoogleMapsApiKey: 'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y',
                  webGoogleMapsApiKey: 'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y',
                  onSelect: (place) async {
                    Navigator.pop(dialogContext);
                    
                    final selectedLatLng = place.latLng;
                    
                    // Move map to selected location
                    _model.googleMapsController.future.then((controller) {
                      controller.animateCamera(
                        CameraUpdate.newLatLng(selectedLatLng.toGoogleMaps()),
                      );
                    });
                    
                    setState(() {
                      _model.googleMapsCenter = selectedLatLng;
                      if (isPickup) {
                        pickupAddress = place.address;
                      } else {
                        dropAddress = place.address;
                      }
                    });
                  },
                  defaultText: 'Search for a location',
                  icon: Icon(
                    Icons.search,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 16.0,
                  ),
                  buttonOptions: FFButtonOptions(
                    width: double.infinity,
                    height: 50.0,
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(),
                      letterSpacing: 0.0,
                    ),
                    elevation: 0.0,
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onPickupFieldTap() {
    // Set selectedlocation to true (pickup mode)
    FFAppState().selectedlocation = true;
    print('🔵 Switched to PICKUP mode');
    setState(() {});
  }

  void _onDropFieldTap() {
    // Set selectedlocation to false (drop mode)
    FFAppState().selectedlocation = false;
    print('🔴 Switched to DROP mode');
    setState(() {});
  }

  void _confirmLocation() {
    if (_model.googleMapsCenter == null) return;

    final selectedLocation = _model.googleMapsCenter!;
    
    if (FFAppState().selectedlocation) {
      // Save pickup location
      FFAppState().pickuplocation = pickupAddress;
      FFAppState().pickupLatitude = selectedLocation.latitude;
      FFAppState().pickupLongitude = selectedLocation.longitude;
      
      print('✅ Pickup confirmed: $pickupAddress');
      _showSnackBar('Pickup location confirmed!');
    } else {
      // Save drop location
      FFAppState().droplocation = dropAddress;
      FFAppState().dropLatitude = selectedLocation.latitude;
      FFAppState().dropLongitude = selectedLocation.longitude;
      
      print('✅ Drop confirmed: $dropAddress');
      _showSnackBar('Drop location confirmed!');
    }

    // Check if both locations are now filled
    if (FFAppState().pickuplocation.isNotEmpty && 
        FFAppState().droplocation.isNotEmpty) {
      
      print('🚀 Both locations filled - Auto navigating to Available Options');
      
      // Navigate to Available Options screen
      Future.delayed(Duration(milliseconds: 800), () {
        context.pushNamed(AvaliableOptionsWidget.routeName);
      });
    } else {
      // Just go back to plan screen
      Future.delayed(Duration(milliseconds: 500), () {
        context.pop();
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: 2000),
        backgroundColor: FlutterFlowTheme.of(context).success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserLocationValue == null) {
      return Container(
        color: FlutterFlowTheme.of(context).primaryBackground,
        child: Center(
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            decoration: BoxDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Container(
                      width: double.infinity,
                      height: 400.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                      ),
                      child: Stack(
                        children: [
                          FlutterFlowGoogleMap(
                            controller: _model.googleMapsController,
                            onCameraIdle: (latLng) {
                              _model.googleMapsCenter = latLng;
                              _updateAddressFromLocation(latLng);
                            },
                            initialLocation: _model.googleMapsCenter ?? currentUserLocationValue!,
                            markerColor: GoogleMarkerColor.orange,
                            mapType: MapType.normal,
                            style: GoogleMapStyle.standard,
                            initialZoom: 14.0,
                            allowInteraction: true,
                            allowZoom: true,
                            showZoomControls: false,
                            showLocation: true,
                            showCompass: false,
                            showMapToolbar: false,
                            showTraffic: false,
                            centerMapOnMarkerTap: true,
                          ),
                          
                          // Back Button
                          Align(
                            alignment: AlignmentDirectional(-1.0, -1.0),
                            child: PointerInterceptor(
                              intercepting: isWeb,
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                                child: FlutterFlowIconButton(
                                  borderRadius: 20.0,
                                  buttonSize: 40.0,
                                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: FlutterFlowTheme.of(context).primaryText,
                                    size: 24.0,
                                  ),
                                  onPressed: () {
                                    context.pop();
                                  },
                                ),
                              ),
                            ),
                          ),
                          
                          // Center Pin
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: PointerInterceptor(
                              intercepting: isWeb,
                              child: Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: FFAppState().selectedlocation 
                                      ? Colors.green 
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 24.0,
                                ),
                              ),
                            ),
                          ),
                          
                          // Current Location Button
                          Align(
                            alignment: AlignmentDirectional(1.0, 1.0),
                            child: PointerInterceptor(
                              intercepting: isWeb,
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                                child: FlutterFlowIconButton(
                                  borderRadius: 20.0,
                                  buttonSize: 40.0,
                                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                  icon: Icon(
                                    Icons.my_location,
                                    color: FlutterFlowTheme.of(context).primaryText,
                                    size: 24.0,
                                  ),
                                  onPressed: () async {
                                    final location = await getCurrentUserLocation(
                                      defaultLocation: LatLng(0.0, 0.0),
                                    );
                                    setState(() {
                                      currentUserLocationValue = location;
                                    });
                                    _model.googleMapsController.future.then((controller) {
                                      controller.animateCamera(
                                        CameraUpdate.newLatLng(location.toGoogleMaps()),
                                      );
                                    });
                                    _updateAddressFromLocation(location);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: SingleChildScrollView(
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              FFAppState().selectedlocation 
                                  ? 'Set your pickup spot' 
                                  : 'Set your drop spot',
                              style: FlutterFlowTheme.of(context).headlineSmall.override(
                                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              FFLocalizations.of(context).getText('oyq430f9' /* Drag map to move pin */),
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.inter(),
                                color: FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ].divide(SizedBox(height: 8.0)),
                        ),
                        
                        // Pickup Location Field (Clickable)
                        InkWell(
                          onTap: () {
                            _onPickupFieldTap();
                            _showSearchDialog(true);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 50.0,
                            decoration: BoxDecoration(
                              color: FFAppState().selectedlocation 
                                  ? FlutterFlowTheme.of(context).primaryBackground
                                  : FlutterFlowTheme.of(context).secondaryBackground,
                              border: Border.all(
                                color: FFAppState().selectedlocation 
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context).alternate,
                                width: FFAppState().selectedlocation ? 2.0 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: FFAppState().selectedlocation 
                                        ? Colors.green 
                                        : FlutterFlowTheme.of(context).secondaryText,
                                    size: 20.0,
                                  ),
                                  Expanded(
                                    child: Text(
                                      pickupAddress.isEmpty 
                                          ? 'Pickup Location' 
                                          : pickupAddress,
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        font: GoogleFonts.inter(),
                                        color: pickupAddress.isEmpty
                                            ? FlutterFlowTheme.of(context).secondaryText
                                            : FlutterFlowTheme.of(context).primaryText,
                                        letterSpacing: 0.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.search,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                    size: 20.0,
                                  ),
                                ].divide(SizedBox(width: 12.0)),
                              ),
                            ),
                          ),
                        ),
                        
                        // Drop Location Field (Clickable)
                        InkWell(
                          onTap: () {
                            _onDropFieldTap();
                            _showSearchDialog(false);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 50.0,
                            decoration: BoxDecoration(
                              color: !FFAppState().selectedlocation 
                                  ? FlutterFlowTheme.of(context).primaryBackground
                                  : FlutterFlowTheme.of(context).secondaryBackground,
                              border: Border.all(
                                color: !FFAppState().selectedlocation 
                                    ? FlutterFlowTheme.of(context).error
                                    : FlutterFlowTheme.of(context).alternate,
                                width: !FFAppState().selectedlocation ? 2.0 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: !FFAppState().selectedlocation 
                                        ? Colors.red 
                                        : FlutterFlowTheme.of(context).secondaryText,
                                    size: 20.0,
                                  ),
                                  Expanded(
                                    child: Text(
                                      dropAddress.isEmpty 
                                          ? 'Drop Location' 
                                          : dropAddress,
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        font: GoogleFonts.inter(),
                                        color: dropAddress.isEmpty
                                            ? FlutterFlowTheme.of(context).secondaryText
                                            : FlutterFlowTheme.of(context).primaryText,
                                        letterSpacing: 0.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.search,
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                    size: 20.0,
                                  ),
                                ].divide(SizedBox(width: 12.0)),
                              ),
                            ),
                          ),
                        ),
                        
                        FFButtonWidget(
                          onPressed: _confirmLocation,
                          text: FFAppState().selectedlocation 
                              ? 'Confirm Pickup' 
                              : 'Confirm Drop',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 50.0,
                            padding: EdgeInsets.all(8.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                            color: FFAppState().selectedlocation 
                                ? Colors.green 
                                : Colors.red,
                            textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                              font: GoogleFonts.interTight(),
                              color: Colors.white,
                              letterSpacing: 0.0,
                            ),
                            elevation: 0.0,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                  ),
                ),
              ].divide(SizedBox(height: 16.0)),
            ),
          ),
        ),
      ),
    );
  }
}