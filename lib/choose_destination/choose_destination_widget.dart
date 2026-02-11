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

  // Google Maps API Key
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

    // Set initial map center logic
    if (appState.dropLatitude != null && appState.dropLongitude != null && appState.dropLatitude != 0.0) {
      // If previous drop location exists, center on that
      _currentMapCenter = gmaps.LatLng(appState.dropLatitude!, appState.dropLongitude!);
      if (appState.droplocation.isNotEmpty) {
        _model.destinationLocationController?.text = appState.droplocation;
      }
    } else if (appState.pickupLatitude != null && appState.pickupLongitude != null && appState.pickupLatitude != 0.0) {
      // Fallback to pickup location
      _currentMapCenter = gmaps.LatLng(appState.pickupLatitude!, appState.pickupLongitude!);
    }

    // Post-frame callback to handle initial location setup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeLocations();
    });
  }

  Future<void> _initializeLocations() async {
    final appState = FFAppState();

    // 1. Ensure Pickup is Set
    if (appState.pickupLatitude == 0.0 || appState.pickupLatitude == null) {
      await _getCurrentLocation();
    } else if (appState.pickuplocation.isEmpty) {
      // Reverse geocode if coordinates exist but address is empty
      try {
        final placemarks = await geo.placemarkFromCoordinates(
          appState.pickupLatitude!,
          appState.pickupLongitude!,
        );
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          final address = "${place.name}, ${place.subLocality}, ${place.locality}";
          setState(() {
            _model.pickupLocationController?.text = address;
            FFAppState().pickuplocation = address;
          });
        }
      } catch (e) {
        debugPrint("Reverse geocode failed: $e");
      }
    }

    // 2. Initialize Map Center if still null
    if (_currentMapCenter == null && mounted) {
      if (appState.pickupLatitude != null && appState.pickupLatitude != 0.0) {
        setState(() {
          _currentMapCenter = gmaps.LatLng(appState.pickupLatitude!, appState.pickupLongitude!);
        });
      } else {
        // Fallback to a default location (e.g., city center) if absolutely nothing is available
        // For now, let's wait for _getCurrentLocation to finish
      }
    }
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

      if (placemarks.isNotEmpty && mounted) {
        geo.Placemark place = placemarks[0];
        String address = "${place.name}, ${place.subLocality}, ${place.locality}";

        setState(() {
          _model.pickupLocationController?.text = address;
          FFAppState().pickuplocation = address;
          FFAppState().pickupLatitude = position.latitude;
          FFAppState().pickupLongitude = position.longitude;

          if (_currentMapCenter == null) {
            _currentMapCenter = gmaps.LatLng(position.latitude, position.longitude);
            _moveCameraToCenter();
          }
        });
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  void _moveCameraToCenter() {
    if (_mapController != null && _currentMapCenter != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(_currentMapCenter!, 15),
      );
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
          _predictions = []; // Clear predictions to show map
          _currentMapCenter = gmaps.LatLng(lat, lng);
        });

        // Unfocus text field to dismiss keyboard
        FocusScope.of(context).unfocus();

        // Move map to selected location
        _moveCameraToCenter();
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  Future<void> _openScanner() async {
    // Basic validation
    if (FFAppState().droplocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination first.')),
      );
      return;
    }

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

          driverId = int.tryParse(decodedData['driver_id']?.toString() ?? '');
          vehicleType = int.tryParse(decodedData['vehicle_type_id']?.toString() ?? '');

          final pricing = decodedData['pricing'] ?? {};
          baseFare = double.tryParse(pricing['base_fare']?.toString() ?? '0');
          pricePerKm = double.tryParse(pricing['price_per_km']?.toString() ?? '0');
          baseKmStart = double.tryParse(pricing['base_km_start']?.toString() ?? '1');
          baseKmEnd = double.tryParse(pricing['base_km_end']?.toString() ?? '5');
        } else {
          driverId = int.tryParse(scanResult);
        }
      } catch (e) {
        debugPrint('QR decode error: $e');
        driverId = int.tryParse(scanResult);
      }

      if (driverId != null) {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR Code')),
        );
      }
    } catch (e) {
      debugPrint('QR Scan failed: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _model.dispose();
    super.dispose();
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
              // 1. Google Map Background
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
                    // Just track the center, don't update state yet
                    _currentMapCenter = position.target;
                  },
                  // Optional: Enable this if you want the pin to update address on drag end
                  onCameraIdle: () {
                     if (_currentMapCenter != null && !_isSearching) {
                       _updateDestinationFromMap(_currentMapCenter!);
                     }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

              // 2. Center Pin (Fixed)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 48,
                      color: Color(0xFFFF7B10),
                    ),
                    const SizedBox(height: 48), // Offset so pin point is center
                  ],
                ),
              ),

              // 3. Top Search Panel
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
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Visual Path Line
                            Column(
                              children: [
                                const Icon(Icons.circle, size: 12, color: Colors.white),
                                Container(
                                  width: 1,
                                  height: 35,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                const Icon(Icons.square, size: 12, color: Colors.white),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Input Fields
                            Expanded(
                              child: Column(
                                children: [
                                  // Pickup (ReadOnly)
                                  Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      controller: _model.pickupLocationController,
                                      enabled: false,
                                      decoration: InputDecoration(
                                        hintText: 'Pickup Location',
                                        hintStyle: GoogleFonts.inter(
                                            color: Colors.grey[600], fontSize: 14),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        prefixIcon: const Icon(Icons.location_on,
                                            size: 18, color: Colors.grey),
                                      ),
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Destination Input
                                  Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: _model.destinationLocationFocusNode?.hasFocus ?? false
                                          ? Border.all(color: Colors.black, width: 1.5)
                                          : null,
                                    ),
                                    child: TextField(
                                      controller: _model.destinationLocationController,
                                      focusNode: _model.destinationLocationFocusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Where to?',
                                        hintStyle: GoogleFonts.inter(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        suffixIcon: _model.destinationLocationController!.text.isNotEmpty
                                            ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              size: 18, color: Colors.grey),
                                          onPressed: () {
                                            _model.destinationLocationController?.clear();
                                            FFAppState().droplocation = '';
                                            setState(() {
                                              _predictions = [];
                                            });
                                          },
                                        )
                                            : null,
                                      ),
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black),
                                      onChanged: (val) => _getPlacePredictions(val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Current Location Button
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

                  // 4. Search Predictions List (Overlay)
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
                                prediction['structured_formatting']['main_text'],
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black),
                              ),
                              subtitle: Text(
                                prediction['structured_formatting']['secondary_text'] ?? '',
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

              // 5. Bottom Action Buttons (Visible only when not searching)
              if (_predictions.isEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Scan to Go Button
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
                      // Back Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => context.goNamed(HomeWidget.routeName),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
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
  Future<void> _updateDestinationFromMap(gmaps.LatLng latLng) async {
  try {
    setState(() {
      _isLoadingAddress = true;
    });

    final placemarks = await geo.placemarkFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );

    if (placemarks.isNotEmpty && mounted) {
      final place = placemarks.first;

      final address =
          "${place.name ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}";

      setState(() {
        _model.destinationLocationController?.text = address;
        FFAppState().droplocation = address;
        FFAppState().dropLatitude = latLng.latitude;
        FFAppState().dropLongitude = latLng.longitude;
        _isLoadingAddress = false;
      });
    }
  } catch (e) {
    debugPrint("Reverse geocode error: $e");
    setState(() {
      _isLoadingAddress = false;
    });
  }
}

}