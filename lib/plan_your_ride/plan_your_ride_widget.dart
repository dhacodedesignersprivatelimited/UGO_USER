import '/flutter_flow/flutter_flow_util.dart' hide LatLng;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'plan_your_ride_model.dart';
export 'plan_your_ride_model.dart';

// NOTE: Ideally, move this to a secure config or AppState
const String GOOGLE_MAPS_API_KEY = 'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y';

enum LocationSelection {
  pickup,
  drop,
}

class PlanYourRideWidget extends StatefulWidget {
  const PlanYourRideWidget({super.key});

  static String routeName = 'plan_your_ride';
  static String routePath = '/planYourRide';

  @override
  State<PlanYourRideWidget> createState() => _PlanYourRideWidgetState();
}

class _PlanYourRideWidgetState extends State<PlanYourRideWidget> {
  late PlanYourRideModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Selection State
  LocationSelection activeSelection = LocationSelection.pickup;

  // Map State
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng? pickupLocation;
  LatLng? dropLocation;

  // Search & Autocomplete State
  List<PlacePrediction> pickupPredictions = [];
  List<PlacePrediction> dropPredictions = [];
  bool showPickupDropdown = false;
  bool showDropDropdown = false;
  bool isSearching = false;

  // Default Location (Hyderabad)
  static final LatLng hyderabadCenter = LatLng(17.3850, 78.4867);
  LatLng currentLocation = hyderabadCenter;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlanYourRideModel());
    _initializeLocation();
  }

  @override
  void dispose() {
    mapController?.dispose();
    _model.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 📍 LOCATION LOGIC
  // ---------------------------------------------------------------------------

  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // FIXED: Using LocationSettings instead of desiredAccuracy
        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );

        Position position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );

        if (mounted) {
          setState(() {
            currentLocation = LatLng(position.latitude, position.longitude);
            pickupLocation = currentLocation;
            _addPickupMarker(currentLocation);
          });
          _reverseGeocode(currentLocation, true);

          mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation, 16),
          );
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() {
          pickupLocation = hyderabadCenter;
          _addPickupMarker(hyderabadCenter);
        });
      }
    }
  }

  Future<void> _setCurrentLocationAsPickup() async {
    try {
      // FIXED: Using LocationSettings instead of desiredAccuracy
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      LatLng latLng = LatLng(position.latitude, position.longitude);
      _addPickupMarker(latLng);

      if (mounted) {
        setState(() {
          pickupPredictions = [];
          showPickupDropdown = false;
        });
      }

      await _reverseGeocode(latLng, true);

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );

      _showSnackBar('Current location set as pickup');
    } catch (e) {
      _showSnackBar('Unable to fetch current location', isError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // 🗺️ MAP MARKERS
  // ---------------------------------------------------------------------------

  void _addPickupMarker(LatLng location) {
    setState(() {
      markers.removeWhere((marker) => marker.markerId.value == 'pickup');
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: "Pickup Location"),
        ),
      );
      pickupLocation = location;
    });
  }

  void _addDropMarker(LatLng location) {
    setState(() {
      markers.removeWhere((marker) => marker.markerId.value == 'drop');
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Drop Location"),
        ),
      );
      dropLocation = location;
    });
  }

  void _rebuildMarkers() {
    markers.clear();
    if (pickupLocation != null) _addPickupMarker(pickupLocation!);
    if (dropLocation != null) _addDropMarker(dropLocation!);
  }

  // ---------------------------------------------------------------------------
  // 🌐 GOOGLE MAPS API CALLS
  // ---------------------------------------------------------------------------

  Future<void> _reverseGeocode(LatLng location, bool isPickup) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$GOOGLE_MAPS_API_KEY';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['results'].isNotEmpty) {
          String address = json['results'][0]['formatted_address'];
          if (mounted) {
            setState(() {
              if (isPickup) {
                _model.pickupController.text = address;
                FFAppState().pickuplocation = address;
                FFAppState().pickupLatitude = location.latitude;
                FFAppState().pickupLongitude = location.longitude;
              } else {
                _model.dropController.text = address;
                FFAppState().droplocation = address;
                FFAppState().dropLatitude = location.latitude;
                FFAppState().dropLongitude = location.longitude;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
  }

  Future<void> _searchPlaces(String input, bool isPickup) async {
    if (input.isEmpty) {
      setState(() {
        if (isPickup) {
          pickupPredictions = [];
          showPickupDropdown = false;
        } else {
          dropPredictions = [];
          showDropDropdown = false;
        }
        isSearching = false;
      });
      return;
    }

    setState(() => isSearching = true);

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$GOOGLE_MAPS_API_KEY&components=country:in&radius=50000';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List<PlacePrediction> predictions = [];

        if (json['predictions'] != null) {
          for (var p in json['predictions']) {
            predictions.add(PlacePrediction(
              placeId: p['place_id'],
              mainText: p['structured_formatting']['main_text'] ?? '',
              secondaryText: p['structured_formatting']['secondary_text'] ?? '',
              fullDescription: p['description'] ?? '',
            ));
          }
        }

        if (mounted) {
          setState(() {
            if (isPickup) {
              pickupPredictions = predictions;
              showPickupDropdown = predictions.isNotEmpty;
            } else {
              dropPredictions = predictions;
              showDropDropdown = predictions.isNotEmpty;
            }
            isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isSearching = false);
    }
  }

  Future<void> _selectPlace(PlacePrediction prediction, bool isPickup) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&key=$GOOGLE_MAPS_API_KEY';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['result'] != null) {
          final result = json['result'];
          final lat = result['geometry']['location']['lat'];
          final lng = result['geometry']['location']['lng'];
          final address = result['formatted_address'];

          LatLng selectedLocation = LatLng(lat, lng);

          if (mounted) {
            setState(() {
              if (isPickup) {
                _model.pickupController.text = address;
                pickupPredictions = [];
                showPickupDropdown = false;
                _addPickupMarker(selectedLocation);

                FFAppState().pickuplocation = address;
                FFAppState().pickupLatitude = lat;
                FFAppState().pickupLongitude = lng;
              } else {
                _model.dropController.text = address;
                dropPredictions = [];
                showDropDropdown = false;
                _addDropMarker(selectedLocation);

                FFAppState().droplocation = address;
                FFAppState().dropLatitude = lat;
                FFAppState().dropLongitude = lng;
              }
            });

            mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(selectedLocation, 15),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Place details error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 🔄 UI ACTIONS
  // ---------------------------------------------------------------------------

  void _swapLocations() {
    setState(() {
      String tempText = _model.pickupController.text;
      _model.pickupController.text = _model.dropController.text;
      _model.dropController.text = tempText;

      String tempLoc = FFAppState().pickuplocation;
      FFAppState().pickuplocation = FFAppState().droplocation;
      FFAppState().droplocation = tempLoc;

      double? tempLat = FFAppState().pickupLatitude;
      FFAppState().pickupLatitude = FFAppState().dropLatitude;
      FFAppState().dropLatitude = tempLat;

      double? tempLng = FFAppState().pickupLongitude;
      FFAppState().pickupLongitude = FFAppState().dropLongitude;
      FFAppState().dropLongitude = tempLng;

      LatLng? tempPickup = pickupLocation;
      pickupLocation = dropLocation;
      dropLocation = tempPickup;

      _rebuildMarkers();
    });
  }

  void _setAirportAsPickup() {
    final airportLocation = const LatLng(17.2403, 78.4294);
    setState(() {
      _model.dropController.text = 'Rajiv Gandhi Airport, Shamshabad';
      FFAppState().droplocation = 'Rajiv Gandhi Airport, Shamshabad';
      FFAppState().dropLatitude = 17.2403;
      FFAppState().dropLongitude = 78.4294;
      _addDropMarker(airportLocation);
      dropPredictions = [];
      showDropDropdown = false;
    });

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(airportLocation, 15),
    );
  }

  void _confirmRide() {
    if (FFAppState().pickuplocation.isEmpty || FFAppState().droplocation.isEmpty) {
      _showSnackBar('Please select both pickup and drop locations', isError: true);
      return;
    }

    _showSnackBar('Locations confirmed! Finding rides...');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.pushNamed(AvaliableOptionsWidget.routeName);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🖥️ BUILD UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            onTap: (position) {
              if (activeSelection == LocationSelection.pickup) {
                _addPickupMarker(position);
                _reverseGeocode(position, true);
              } else {
                _addDropMarker(position);
                _reverseGeocode(position, false);
              }
            },
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 15,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),

          // Top Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7B10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Plan Your Ride',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location Input Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black.withValues(alpha:0.15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pickup Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2DB854)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _model.pickupController,
                              onTap: () {
                                setState(() {
                                  activeSelection = LocationSelection.pickup;
                                  showDropDropdown = false;
                                });
                              },
                              style: GoogleFonts.inter(color: Colors.black, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Enter pickup location',
                                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) => _searchPlaces(value, true),
                            ),
                          ),
                          if (_model.pickupController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _model.pickupController.clear();
                                  pickupPredictions = [];
                                  showPickupDropdown = false;
                                  FFAppState().pickuplocation = '';
                                });
                              },
                            ),
                          IconButton(
                            onPressed: _setCurrentLocationAsPickup,
                            icon: const Icon(Icons.my_location, size: 22, color: Color(0xFF2DB854)),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                    // Drop Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF5A5F)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _model.dropController,
                              onTap: () {
                                setState(() {
                                  activeSelection = LocationSelection.drop;
                                  showPickupDropdown = false;
                                });
                              },
                              style: GoogleFonts.inter(color: Colors.black, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Where to?',
                                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) => _searchPlaces(value, false),
                            ),
                          ),
                          if (_model.dropController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _model.dropController.clear();
                                  dropPredictions = [];
                                  showDropDropdown = false;
                                  FFAppState().droplocation = '';
                                });
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.swap_vert_rounded, color: Colors.grey[700], size: 24),
                            onPressed: _swapLocations,
                          ),
                        ],
                      ),
                    ),

                    if (!showPickupDropdown && !showDropDropdown)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildQuickAction(icon: Icons.home_outlined, label: 'Home', onTap: () => _showSnackBar('Add home location in settings')),
                                const SizedBox(width: 12),
                                _buildQuickAction(icon: Icons.work_outline, label: 'Work', onTap: () => _showSnackBar('Add work location in settings')),
                                const SizedBox(width: 12),
                                _buildQuickAction(icon: Icons.flight_outlined, label: 'Airport', onTap: _setAirportAsPickup),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (showPickupDropdown && pickupPredictions.isNotEmpty)
            _buildSuggestionsList(predictions: pickupPredictions, onSelect: (p) => _selectPlace(p, true)),

          if (showDropDropdown && dropPredictions.isNotEmpty)
            _buildSuggestionsList(predictions: dropPredictions, onSelect: (p) => _selectPlace(p, false)),

          // Confirm Button
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF7B10), Color(0xFFE65100)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF7B10).withValues(alpha:0.4), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _confirmRide,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Text(
                      'Confirm Locations',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🧩 HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildSuggestionsList({
    required List<PlacePrediction> predictions,
    required Function(PlacePrediction) onSelect,
  }) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 200,
      left: 16, right: 16, bottom: 100,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: predictions.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final prediction = predictions[index];
              return InkWell(
                onTap: () => onSelect(prediction),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prediction.mainText, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                            if (prediction.secondaryText.isNotEmpty)
                              Text(prediction.secondaryText, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: Colors.grey[700]),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullDescription;

  PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullDescription,
  });
}