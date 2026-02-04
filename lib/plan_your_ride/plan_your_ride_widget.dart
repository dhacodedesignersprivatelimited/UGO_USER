import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' hide LatLng;
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'plan_your_ride_model.dart';
export 'plan_your_ride_model.dart';

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
  LocationSelection activeSelection = LocationSelection.pickup;

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng? pickupLocation;
  LatLng? dropLocation;

  List<PlacePrediction> pickupPredictions = [];
  List<PlacePrediction> dropPredictions = [];
  bool showPickupDropdown = false;
  bool showDropDropdown = false;
  bool isSearching = false;

  static final LatLng hyderabadCenter = LatLng(17.3850, 78.4867);
  LatLng currentLocation = hyderabadCenter;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlanYourRideModel());
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        pickupLocation = currentLocation;
        _addPickupMarker(currentLocation);
      });

      _reverseGeocode(currentLocation, true);
    } catch (e) {
      print('Location error: $e');
      setState(() {
        pickupLocation = hyderabadCenter;
        _addPickupMarker(hyderabadCenter);
      });
    }
  }

  Future<void> _setCurrentLocationAsPickup() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng latLng = LatLng(position.latitude, position.longitude);
      _addPickupMarker(latLng);

      setState(() {
        pickupPredictions = [];
        showPickupDropdown = false;
      });

      await _reverseGeocode(latLng, true);

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 16),
        );
      }

      _showSnackBar('Current location set as pickup');
    } catch (e) {
      _showSnackBar('Unable to fetch current location', isError: true);
      print('Current location error: $e');
    }
  }

  void _addPickupMarker(LatLng location) {
    setState(() {
      markers.removeWhere((marker) => marker.markerId.value == 'pickup');
      markers.add(
        Marker(
          markerId: MarkerId('pickup'),
          position: location,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
          markerId: MarkerId('drop'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      dropLocation = location;
    });
  }

  Future<void> _reverseGeocode(LatLng location, bool isPickup) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$GOOGLE_MAPS_API_KEY';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['results'].isNotEmpty) {
          String address = json['results'][0]['formatted_address'];
          if (isPickup) {
            setState(() {
              _model.pickupController.text = address;
              FFAppState().pickuplocation = address;
              FFAppState().pickupLatitude = location.latitude;
              FFAppState().pickupLongitude = location.longitude;
            });
          } else {
            setState(() {
              _model.dropController.text = address;
              FFAppState().droplocation = address;
              FFAppState().dropLatitude = location.latitude;
              FFAppState().dropLongitude = location.longitude;
            });
          }
        }
      }
    } catch (e) {
      print('Reverse geocode error: $e');
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

    setState(() {
      isSearching = true;
    });

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$GOOGLE_MAPS_API_KEY&components=country:in&location=17.3850,78.4867&radius=50000';

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
    } catch (e) {
      print('Places search error: $e');
      setState(() {
        isSearching = false;
      });
    }
  }

  Future<void> _selectPlace(PlacePrediction prediction, bool isPickup) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&key=$GOOGLE_MAPS_API_KEY';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['result'] != null) {
          final result = json['result'];
          final lat = result['geometry']['location']['lat'];
          final lng = result['geometry']['location']['lng'];
          final address = result['formatted_address'];

          LatLng selectedLocation = LatLng(lat, lng);

          if (isPickup) {
            setState(() {
              _model.pickupController.text = address;
              pickupPredictions = [];
              showPickupDropdown = false;
              _addPickupMarker(selectedLocation);
              FFAppState().pickuplocation = address;
              FFAppState().pickupLatitude = lat;
              FFAppState().pickupLongitude = lng;
            });

            if (mapController != null) {
              mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(selectedLocation, 15),
              );
            }
          } else {
            setState(() {
              _model.dropController.text = address;
              dropPredictions = [];
              showDropDropdown = false;
              _addDropMarker(selectedLocation);
              FFAppState().droplocation = address;
              FFAppState().dropLatitude = lat;
              FFAppState().dropLongitude = lng;
            });

            if (mapController != null) {
              mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(selectedLocation, 15),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Place details error: $e');
    }
  }

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

  void _rebuildMarkers() {
    markers.clear();
    if (pickupLocation != null) {
      _addPickupMarker(pickupLocation!);
    }
    if (dropLocation != null) {
      _addDropMarker(dropLocation!);
    }
  }

  void _setAirportAsPickup() {
    final airportLocation = LatLng(17.2403, 78.4294);
    setState(() {
      _model.dropController.text = 'Rajiv Gandhi Airport, Shamshabad';
      FFAppState().droplocation = 'Rajiv Gandhi Airport, Shamshabad';
      FFAppState().dropLatitude = 17.2403;
      FFAppState().dropLongitude = 78.4294;
      _addDropMarker(airportLocation);
      dropPredictions = [];
      showDropDropdown = false;
    });

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(airportLocation, 15),
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _confirmRide() {
    if (FFAppState().pickuplocation.isEmpty ||
        FFAppState().droplocation.isEmpty) {
      _showSnackBar('Please select both pickup and drop locations',
          isError: true);
      return;
    }

    _showSnackBar('Locations confirmed! Finding rides...');

    Future.delayed(Duration(milliseconds: 800), () {
      context.pushNamed(AvaliableOptionsWidget.routeName);
    });
  }

  @override
  void dispose() {
    mapController?.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map Background
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            onTap: (position) {
              // Tap on map to set location
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
            mapToolbarEnabled: false,
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
                bottom: 5,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFFF7B10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color:  Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Plan Your Ride',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location Input Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black.withOpacity(0.15),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2DB854),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _model.pickupController,
                              onTap: () {
                                setState(() {
                                  activeSelection = LocationSelection.pickup;
                                  showDropDropdown = false;
                                });
                              },
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter pickup location',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                _searchPlaces(value, true);
                              },
                            ),
                          ),
                          if (_model.pickupController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear,
                                  size: 20, color: Colors.grey),
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
                            icon: Icon(
                              Icons.my_location,
                              size: 20,
                              color: Color(0xFF2DB854),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                          height: 1, thickness: 1, color: Colors.grey[200]),
                    ),

                    // Drop Input
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF5A5F),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _model.dropController,
                              onTap: () {
                                setState(() {
                                  activeSelection = LocationSelection.drop;
                                  showPickupDropdown = false;
                                });
                              },
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Where to?',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                _searchPlaces(value, false);
                              },
                            ),
                          ),
                          if (_model.dropController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear,
                                  size: 20, color: Colors.grey),
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
                            icon: Icon(
                              Icons.swap_vert_rounded,
                              color: Colors.grey[700],
                              size: 22,
                            ),
                            onPressed: _swapLocations,
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions
                    if (!showPickupDropdown && !showDropDropdown)
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey[200]),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                _buildQuickAction(
                                  icon: Icons.home_outlined,
                                  label: 'Home',
                                  onTap: () {
                                    // Add home location logic
                                    _showSnackBar(
                                        'Add home location in settings');
                                  },
                                ),
                                SizedBox(width: 12),
                                _buildQuickAction(
                                  icon: Icons.work_outline,
                                  label: 'Work',
                                  onTap: () {
                                    _showSnackBar(
                                        'Add work location in settings');
                                  },
                                ),
                                SizedBox(width: 12),
                                _buildQuickAction(
                                  icon: Icons.flight_outlined,
                                  label: 'Airport',
                                  onTap: _setAirportAsPickup,
                                ),
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

          // Autocomplete Suggestions
          if (showPickupDropdown && pickupPredictions.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 190,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: pickupPredictions.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final prediction = pickupPredictions[index];
                      return InkWell(
                        onTap: () {
                          _selectPlace(prediction, true);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prediction.mainText,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (prediction.secondaryText.isNotEmpty)
                                      Text(
                                        prediction.secondaryText,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
            ),

          if (showDropDropdown && dropPredictions.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 190,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: dropPredictions.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final prediction = dropPredictions[index];
                      return InkWell(
                        onTap: () {
                          _selectPlace(prediction, false);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prediction.mainText,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (prediction.secondaryText.isNotEmpty)
                                      Text(
                                        prediction.secondaryText,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
            ),

          // Confirm Button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7B10), Color(0xFFE65100)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF7B10).withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
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
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
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
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: Colors.grey[700]),
              SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
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
