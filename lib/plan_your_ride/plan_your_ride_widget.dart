import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_google_map.dart' show GoogleMapStyle, googleMapStyleStrings;
import '/flutter_flow/flutter_flow_util.dart' hide LatLng;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'plan_your_ride_model.dart';
export 'plan_your_ride_model.dart';

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
  Timer? _searchDebounce;

  // Default Location (from AppConfig)
  LatLng get _defaultCenter =>
      LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  late LatLng currentLocation;
  bool isMapSelected = false;

  List<Map<String, dynamic>> dynamicRecentSearchList = [];
  bool isLoadingSavedAddresses = false;

  @override
  void initState() {
    super.initState();
    // ✅ Clear previous session data to ensure a fresh ride planning flow
    FFAppState().pickuplocation = '';
    FFAppState().pickupLatitude = null;
    FFAppState().pickupLongitude = null;
    FFAppState().droplocation = '';
    FFAppState().dropLatitude = null;
    FFAppState().dropLongitude = null;
    
    currentLocation = _defaultCenter;
    _model = createModel(context, () => PlanYourRideModel());
    _initializeLocation();
    _fetchDynamicRecentData();
  }

  Future<void> _fetchDynamicRecentData() async {
    setState(() => isLoadingSavedAddresses = true);
    
    List<Map<String, dynamic>> combined = [];
    
    // 1. Fetch Saved Addresses (Home/Work)
    try {
      final response = await GetSavedAddressesCall.call(
        userId: FFAppState().userid,
        token: FFAppState().accessToken,
      );
      if (response.succeeded) {
        final List<dynamic> data = getJsonField(response.jsonBody, r'''$.data''', true) as List<dynamic>;
        for (var item in data) {
          combined.add({
            'name': item['address_name'] ?? (item['address_type'] == 'home' ? 'Home' : 'Work'),
            'address': item['address_text'],
            'lat': double.tryParse(item['latitude'].toString()) ?? 0.0,
            'lng': double.tryParse(item['longitude'].toString()) ?? 0.0,
            'icon': item['address_type'] == 'home' ? Icons.home_outlined : (item['address_type'] == 'work' ? Icons.work_outline : Icons.bookmark_outline),
            'isSaved': true,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching saved addresses: $e');
    }

    // 2. Add Persisted Recent Searches from AppState
    for (var encoded in FFAppState().recentSearches) {
      try {
        final decoded = jsonDecode(encoded);
        combined.add({
          'name': decoded['name'] ?? 'Recent',
          'address': decoded['address'],
          'lat': decoded['lat'],
          'lng': decoded['lng'],
          'icon': Icons.history,
          'isSaved': false,
        });
      } catch (_) {}
    }

    setState(() {
      dynamicRecentSearchList = combined;
      isLoadingSavedAddresses = false;
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
          pickupLocation = _defaultCenter;
          _addPickupMarker(_defaultCenter);
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
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=${AppConfig.googleMapsApiKey}';
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (input.isEmpty) {
        if (mounted) {
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
        }
        return;
      }

      if (mounted) setState(() => isSearching = true);

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=${AppConfig.googleMapsApiKey}&components=country:in&radius=50000';
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
    });
  }

  Future<void> _selectPlace(PlacePrediction prediction, bool isPickup) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&key=${AppConfig.googleMapsApiKey}';
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

            // Save to dynamic recent searches
            FFAppState().addToRecentSearches({
              'name': prediction.mainText,
              'address': address,
              'lat': lat,
              'lng': lng,
              'icon_name': 'history',
            });
            _fetchDynamicRecentData(); // Refresh the list in the UI

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

  // ignore: unused_element
  Future<void> _setSavedLocationByLabel(String label) async {
    try {
      final res = await GetSavedAddressesCall.call(
        userId: FFAppState().userid,
        token: FFAppState().accessToken,
      );
      if (!res.succeeded || !mounted) return;

      final data = getJsonField(res.jsonBody, r'$.data');
      final list = data is List ? data : <dynamic>[];

      Map<String, dynamic>? match;
      final search = label.toLowerCase();
      for (final a in list) {
        final l = (a['address_name'] ?? a['address_label'] ?? a['address_type'] ?? '').toString().toLowerCase();
        if (l.contains(search)) {
          match = a is Map<String, dynamic> ? a : Map<String, dynamic>.from(a);
          break;
        }
      }

      if (match == null) {
        _showSnackBar('No saved $label location. Add it in Saved Places.');
        return;
      }

      final lat = (match['latitude'] is num)
          ? (match['latitude'] as num).toDouble()
          : double.tryParse(match['latitude']?.toString() ?? '');
      final lng = (match['longitude'] is num)
          ? (match['longitude'] as num).toDouble()
          : double.tryParse(match['longitude']?.toString() ?? '');
      final address = match['address_text']?.toString() ?? '';

      if (lat == null || lng == null) {
        _showSnackBar('Invalid $label location saved.');
        return;
      }

      final location = LatLng(lat, lng);

      if (mounted) {
        setState(() {
          if (activeSelection == LocationSelection.pickup) {
            _model.pickupController.text = address;
            pickupPredictions = [];
            showPickupDropdown = false;
            _addPickupMarker(location);
            FFAppState().pickuplocation = address;
            FFAppState().pickupLatitude = lat;
            FFAppState().pickupLongitude = lng;
          } else {
            _model.dropController.text = address;
            dropPredictions = [];
            showDropDropdown = false;
            _addDropMarker(location);
            FFAppState().droplocation = address;
            FFAppState().dropLatitude = lat;
            FFAppState().dropLongitude = lng;
          }
        });
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15),
        );
        _showSnackBar('$label location set');
      }
    } catch (e) {
      _showSnackBar('Could not load $label location', isError: true);
    }
  }


  void _confirmRide() {
    final app = FFAppState();
    if (app.pickuplocation.isEmpty || app.droplocation.isEmpty) {
      _showSnackBar('Please select both pickup and drop locations', isError: true);
      return;
    }

    // ✅ SHIELD: Prevent same pickup and drop
    bool isSameAddress = app.pickuplocation.trim().toLowerCase() == 
                         app.droplocation.trim().toLowerCase();
    bool isSameCoords = app.pickupLatitude == app.dropLatitude && 
                         app.pickupLongitude == app.dropLongitude;

    if (isSameAddress || isSameCoords) {
      _showSnackBar('Pickup and drop locations cannot be the same', isError: true);
      return;
    }

    _showSnackBar('Locations confirmed! Finding rides...');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.pushNamed(AvaliableOptionsWidget.routeName);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false, bool isInfo = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white)),
        backgroundColor: isError ? Colors.red : (isInfo ? const Color(0xFFFF7B10) : Colors.green),
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
          // Background Map (visible during precise selection)
          Positioned.fill(
            child: GoogleMap(
              style: googleMapStyleStrings[GoogleMapStyle.uber],
              onMapCreated: (controller) => mapController = controller,
              onTap: (position) {
                if (!isMapSelected) return;
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
          ),

          // Main Search/List Content (List-First View)
          if (!isMapSelected)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 270),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Search Results or Recent Locations
                        if (activeSelection == LocationSelection.pickup && pickupPredictions.isNotEmpty)
                          ...pickupPredictions.map((p) => _buildListEntry(
                                icon: Icons.location_on_outlined,
                                title: p.mainText,
                                subtitle: p.secondaryText,
                                onTap: () => _selectPlace(p, true),
                              ))
                        else if (activeSelection == LocationSelection.drop && dropPredictions.isNotEmpty)
                          ...dropPredictions.map((p) => _buildListEntry(
                                icon: Icons.location_on_outlined,
                                title: p.mainText,
                                subtitle: p.secondaryText,
                                onTap: () => _selectPlace(p, false),
                              ))
                        else ...[
                        // Recent Locations Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Row(
                            children: [
                              Text(
                                'RECENT & SAVED LOCATIONS',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[500],
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (isLoadingSavedAddresses)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                            ],
                          ),
                        ),
                        if (dynamicRecentSearchList.isEmpty && !isLoadingSavedAddresses)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Text(
                              'No recent searches yet.',
                              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                            ),
                          ),
                        ...dynamicRecentSearchList.map((loc) => _buildListEntry(
                              icon: (loc['icon'] is IconData) ? (loc['icon'] as IconData) : Icons.history,
                              title: loc['name'].toString(),
                              subtitle: loc['address'].toString(),
                              onTap: () {
                                final latLng = LatLng(loc['lat'] as double, loc['lng'] as double);
                                if (activeSelection == LocationSelection.pickup) {
                                  setState(() {
                                    _model.pickupController.text = loc['address'].toString();
                                    _addPickupMarker(latLng);
                                    FFAppState().pickuplocation = loc['address'].toString();
                                    FFAppState().pickupLatitude = latLng.latitude;
                                    FFAppState().pickupLongitude = latLng.longitude;
                                    pickupPredictions = [];
                                  });
                                } else {
                                  setState(() {
                                    _model.dropController.text = loc['address'].toString();
                                    _addDropMarker(latLng);
                                    FFAppState().droplocation = loc['address'].toString();
                                    FFAppState().dropLatitude = latLng.latitude;
                                    FFAppState().dropLongitude = latLng.longitude;
                                    dropPredictions = [];
                                  });
                                }
                                mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
                              },
                            )),
                      ],
                        const SizedBox(height: 100), // Bottom padding for confirm button
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Header & Input Area (UGO Branding)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 16, bottom: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7B10), // UGO Orange
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                      Text(
                        'Plan Your Ride',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      if (isMapSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton.icon(
                            onPressed: () => setState(() => isMapSelected = false),
                            icon: const Icon(Icons.search, size: 16, color: Colors.white),
                            label: Text(
                              'Search',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visual Connector (Premium)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Column(
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF2DB854), width: 3),
                              ),
                            ),
                            Container(
                              width: 2, height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white, Colors.white.withValues(alpha: 0.5)],
                                ),
                              ),
                            ),
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFFF5A5F), width: 3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Inputs Redesign
                      Expanded(
                        child: Column(
                          children: [
                            _buildPremiumTextField(
                              controller: _model.pickupController,
                              hintText: 'Pickup from?',
                              iconColor: const Color(0xFF2DB854),
                              onTap: () => setState(() {
                                activeSelection = LocationSelection.pickup;
                                isMapSelected = false;
                              }),
                              onChanged: (v) => _searchPlaces(v, true),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location, size: 18, color: Colors.green),
                                onPressed: _setCurrentLocationAsPickup,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPremiumTextField(
                              controller: _model.dropController,
                              hintText: 'Where to?',
                              iconColor: const Color(0xFFFF5A5F),
                              onTap: () => setState(() {
                                activeSelection = LocationSelection.drop;
                                isMapSelected = false;
                              }),
                              onChanged: (v) => _searchPlaces(v, false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 38),
                        child: IconButton(
                          onPressed: _swapLocations,
                          icon: const Icon(Icons.swap_vert_circle, color: Colors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Bar (Select from map / Add stops)
                  Row(
                    children: [
                      _buildHeaderActionButton(
                        icon: Icons.location_on,
                        label: 'Select from map',
                        onTap: () => setState(() => isMapSelected = true),
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'Add stops',
                        onTap: () => _showSnackBar('Add stops coming soon!', isInfo: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Confirmation Button
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
                      'Confirm',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
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

  Widget _buildListEntry({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    String? distance,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (iconColor ?? const Color(0xFFFF7B10)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: iconColor ?? const Color(0xFFFF7B10)),
                ),
                if (distance != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    distance,
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w400),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.favorite_border, size: 20, color: Colors.grey[300]),
              onPressed: () {}, // Future: Add to favorites logic
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String hintText,
    required Color iconColor,
    required VoidCallback onTap,
    required Function(String) onChanged,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background for black text
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
        cursorColor: Colors.black,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.circle, size: 10, color: iconColor),
          filled: false,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: Colors.red[400]),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
              if (suffixIcon != null)
                IconTheme(
                  data: IconThemeData(color: Colors.grey[400]),
                  child: suffixIcon,
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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