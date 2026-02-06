import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'choose_destination_model.dart';
export 'choose_destination_model.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class ChooseDestinationWidget extends StatefulWidget {
  const ChooseDestinationWidget({super.key});

  static String routeName = 'choose_destination';
  static String routePath = '/chooseDestination';

  @override
  State<ChooseDestinationWidget> createState() =>
      _ChooseDestinationWidgetState();
}

class _ChooseDestinationWidgetState extends State<ChooseDestinationWidget> {
  late ChooseDestinationModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> _predictions = [];
  bool _isSearching = false;
  bool _isLoadingAddress = false;

  // Map controller and location
  gmaps.GoogleMapController? _mapController;
  gmaps.LatLng? _currentMapCenter;
  bool _isMapReady = false;

  // Using the API key found in AvaliableOptionsWidget
  final String _googleMapsApiKey = 'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChooseDestinationModel());

    // Controllers
    _model.pickupLocationController ??= TextEditingController();
    _model.pickupLocationFocusNode ??= FocusNode();
    _model.destinationLocationController ??= TextEditingController();
    _model.destinationLocationFocusNode ??= FocusNode();

    // Restore saved addresses to controllers
    final appState = FFAppState();
    if (appState.pickuplocation.isNotEmpty) {
      _model.pickupLocationController?.text = appState.pickuplocation;
    }
    if (appState.droplocation.isNotEmpty) {
      _model.destinationLocationController?.text = appState.droplocation;
      // Set initial map center to drop location if available
      if (appState.dropLatitude != null && appState.dropLongitude != null) {
        _currentMapCenter = gmaps.LatLng(appState.dropLatitude!, appState.dropLongitude!);
      }
    }

    // Initialize with current location for pickup (non-editable)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (appState.pickupLatitude != null &&
          appState.pickupLongitude != null &&
          appState.pickupLatitude != 0.0 &&
          appState.pickupLongitude != 0.0) {
        if (appState.pickuplocation.isEmpty) {
          try {
            final placemarks = await geo.placemarkFromCoordinates(
              appState.pickupLatitude!,
              appState.pickupLongitude!,
            );
            if (placemarks.isNotEmpty && mounted) {
              final place = placemarks.first;
              final address =
                  "${place.name}, ${place.subLocality}, ${place.locality}";
              setState(() {
                _model.pickupLocationController?.text = address;
                FFAppState().pickuplocation = address;
              });
            }
          } catch (e) {
            debugPrint("Reverse geocode failed: $e");
            _getCurrentLocation();
          }
        }
      } else {
        _getCurrentLocation();
      }

      // Set default map center if no drop location
      if (_currentMapCenter == null && appState.pickupLatitude != null) {
        setState(() {
          _currentMapCenter = gmaps.LatLng(
            appState.pickupLatitude!,
            appState.pickupLongitude!,
          );
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();

      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        String address =
            "${place.name}, ${place.subLocality}, ${place.locality}";

        setState(() {
          _model.pickupLocationController?.text = address;
          FFAppState().pickuplocation = address;
          FFAppState().pickupLatitude = position.latitude;
          FFAppState().pickupLongitude = position.longitude;
          
          // Set map center if not already set
          if (_currentMapCenter == null) {
            _currentMapCenter = gmaps.LatLng(position.latitude, position.longitude);
          }
        });
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> _getPlacePredictions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleMapsApiKey&components=country:in',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _predictions = data['predictions'];
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching predictions: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _getPlaceDetails(String placeId, String description) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleMapsApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = data['result']['geometry']['location']['lat'];
        final lng = data['result']['geometry']['location']['lng'];

        setState(() {
          _model.destinationLocationController?.text = description;
          FFAppState().droplocation = description;
          FFAppState().dropLatitude = lat;
          FFAppState().dropLongitude = lng;
          _predictions = []; // Clear predictions
          _currentMapCenter = gmaps.LatLng(lat, lng);
        });
        
        // Unfocus text field to dismiss keyboard
        FocusScope.of(context).unfocus();

        // Move map to selected location
        _mapController?.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(_currentMapCenter!, 15),
        );
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  // Update destination based on map center (draggable pin)
  Future<void> _updateDestinationFromMap(gmaps.LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
      _currentMapCenter = position;
      FFAppState().dropLatitude = position.latitude;
      FFAppState().dropLongitude = position.longitude;
    });

    try {
      final placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = "${place.name}, ${place.subLocality}, ${place.locality}";
        
        setState(() {
          _model.destinationLocationController?.text = address;
          FFAppState().droplocation = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocode failed: $e");
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _model.dispose();
    super.dispose();
  }

 Future<void> _openScanner() async {
  try {
    final scanResult = await FlutterBarcodeScanner.scanBarcode(
      '#FF7B10',
      'Cancel',
      true,
      ScanMode.BARCODE,
    );

    if (!mounted || scanResult == '-1') return;

    int? driverId;
    int? vehicleType;
    double? baseFare;
    double? pricePerKm;
    double? baseKmStart;
    double? baseKmEnd;

    try {
      if (scanResult.trim().startsWith('{')) {
        final decodedData = jsonDecode(scanResult);

        driverId =
            int.tryParse(decodedData['driver_id']?.toString() ?? '');
        vehicleType =
            int.tryParse(decodedData['vehicle_type_id']?.toString() ?? '');

        baseFare = double.tryParse(
            decodedData['pricing']['base_fare']?.toString() ?? '0');
        pricePerKm = double.tryParse(
            decodedData['pricing']['price_per_km']?.toString() ?? '0');
        baseKmStart = double.tryParse(
            decodedData['pricing']['base_km_start']?.toString() ?? '1');
        baseKmEnd = double.tryParse(
            decodedData['pricing']['base_km_end']?.toString() ?? '5');
      } else {
        driverId = int.tryParse(scanResult);
      }
    } catch (e) {
      debugPrint('QR decode error: $e');
      driverId = int.tryParse(scanResult);
    }

    if (driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR Code')),
      );
      return;
    }

    // 🚀 SAME DESTINATION AS HOME SCREEN
    context.pushNamed(
      DriverDetailsWidget.routeName,
      queryParameters: {
        'driverId': driverId.toString(),
        'vehicleType': vehicleType?.toString() ?? '',
        'baseFare': baseFare?.toString() ?? '0',
        'pricePerKm': pricePerKm?.toString() ?? '0',
        'baseKmStart': baseKmStart?.toString() ?? '1',
        'baseKmEnd': baseKmEnd?.toString() ?? '5',
      },
    );
  } catch (e) {
    debugPrint('QR Scan failed: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Map Background
              if (_currentMapCenter != null)
                gmaps.GoogleMap(
                  initialCameraPosition: gmaps.CameraPosition(
                    target: _currentMapCenter!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    setState(() => _isMapReady = true);
                  },
                  onCameraMove: (position) {
                    // Update center as user drags map
                    _currentMapCenter = position.target;
                  },
                  // onCameraIdle: () {
                  //   // Update address when user stops dragging
                  //   if (_currentMapCenter != null) {
                  //     _updateDestinationFromMap(_currentMapCenter!);
                  //   }
                  // },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

              // Center Pin (fixed in center of map)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 48,
                      color: Color(0xFFFF7B10),
                    ),
                    const SizedBox(height: 48), // Offset for pin bottom
                  ],
                ),
              ),

              // Top Header with Input Fields
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7B10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => context.safePop(),
                            ),
                            Expanded(
                              child: Text(
                                'Plan your ride',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            // IconButton(
                            //   icon: const Icon(Icons.qr_code_scanner,
                            //       color: Colors.white),
                            //   onPressed: _openScanner,
                            // ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Left Visual (Uber dots/lines)
                            Column(
                              children: [
                                const Icon(Icons.circle,
                                    size: 12, color: Colors.white),
                                Container(
                                  width: 1,
                                  height: 35,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                const Icon(Icons.square,
                                    size: 12, color: Colors.white),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // TextFields
                            Expanded(
                              child: Column(
                                children: [
                                  // Pickup field (DISABLED)
                                  Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller:
                                          _model.pickupLocationController,
                                      enabled: false, // ✅ DISABLED
                                      decoration: InputDecoration(
                                        hintText: 'Pickup Location',
                                        hintStyle: GoogleFonts.inter(
                                            color: Colors.grey[600],
                                            fontSize: 14),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                        prefixIcon: const Icon(
                                          Icons.location_on,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Destination field
                                  Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: _model.destinationLocationFocusNode
                                                  ?.hasFocus ??
                                              false
                                          ? Border.all(
                                              color: Colors.black, width: 1.5)
                                          : null,
                                    ),
                                    child: TextField(
                                      controller:
                                          _model.destinationLocationController,
                                      focusNode:
                                          _model.destinationLocationFocusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Where to?',
                                        hintStyle: GoogleFonts.inter(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                        suffixIcon: _isLoadingAddress
                                            ? const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Color(0xFFFF7B10),
                                                  ),
                                                ),
                                              )
                                            : (_model
                                                    .destinationLocationController!
                                                    .text
                                                    .isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                        Icons.clear,
                                                        size: 18,
                                                        color: Colors.grey),
                                                    onPressed: () async {
                                                      _model
                                                          .destinationLocationController
                                                          ?.clear();
                                                      FFAppState().droplocation =
                                                          '';
                                                      final prefs =
                                                          FFAppState().prefs;
                                                      await prefs.remove(
                                                          'ff_droplocation');
                                                      setState(() {});
                                                    },
                                                  )
                                                : null),
                                      ),
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black),
                                      onChanged: (val) =>
                                          _getPlacePredictions(val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.my_location,
                                  color: Colors.white, size: 24),
                              onPressed: _getCurrentLocation,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Autocomplete Results Overlay
                  if (_predictions.isNotEmpty)
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: ListView.builder(
                          itemCount: _predictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _predictions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined,
                                  color: Color(0xFFFF7B10)),
                              title: Text(
                                prediction['structured_formatting']
                                    ['main_text'],
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black),
                              ),
                              subtitle: Text(
                                prediction['structured_formatting']
                                        ['secondary_text'] ??
                                    '',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _getPlaceDetails(
                                prediction['place_id'],
                                prediction['description'],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),

              // Bottom Scanner Button
              // ✅ Bottom action buttons (IMAGE STYLE)
          if (_predictions.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔶 Scan to go button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openScanner,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: Text(
                        'Scan to go',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7B10),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🔹 Back to Home button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.goNamed(HomeWidget.routeName),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                  ],
          ),
        ),
      ),
    );
  }
}