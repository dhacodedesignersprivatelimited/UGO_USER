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

const String GOOGLE_MAPS_API_KEY =
    'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y'; // Replace with your API key
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

  // Hyderabad coordinates
  static final LatLng hyderabadCenter = LatLng(17.3850, 78.4867);
  LatLng currentLocation = hyderabadCenter;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlanYourRideModel());
    _initializeLocation();
  }

  Future<void> _setCurrentLocationAsPickup() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng latLng = LatLng(position.latitude, position.longitude);

      // Add marker
      _addPickupMarker(latLng);
      setState(() {
        pickupPredictions = [];
        showPickupDropdown = false;
      });

      // Reverse geocode to get address + update state
      await _reverseGeocode(latLng, true);

      // Move camera
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

  Future<void> _initializeLocation() async {
    try {
      // Get current device location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        _addPickupMarker(currentLocation);
        setState(() {
          pickupPredictions = [];
          showPickupDropdown = false;
        });
      });
    } catch (e) {
      print('Location error: $e');
      // Default to Hyderabad if location fails
      _addPickupMarker(hyderabadCenter);
    }
  }

  void _addPickupMarker(LatLng location) {
    setState(() {
      markers.removeWhere((marker) => marker.markerId.value == 'pickup');
      markers.add(
        Marker(
          markerId: MarkerId('pickup'),
          position: location,
          infoWindow: InfoWindow(title: 'Pickup Location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          draggable: true,
          onDragEnd: (newLocation) {
            setState(() {
              pickupLocation = newLocation;
              _reverseGeocode(newLocation, true);
            });
          },
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
          infoWindow: InfoWindow(title: 'Drop Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          draggable: true,
          onDragEnd: (newLocation) {
            setState(() {
              dropLocation = newLocation;
              _reverseGeocode(newLocation, false);
            });
          },
        ),
      );
      dropLocation = location;
    });
  }
  Future<void> _updateLocationFromMap(LatLng position) async {
  if (activeSelection == LocationSelection.pickup) {
    _addPickupMarker(position);
    await _reverseGeocode(position, true);
  } else {
    _addDropMarker(position);
    await _reverseGeocode(position, false);
  }
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
        } else {
          dropPredictions = [];
        }
      });
      return;
    }

    try {
      // Get predictions from Google Places API
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
            showPickupDropdown = true;
          } else {
            dropPredictions = predictions;
            showDropDropdown = true;
          }
        });
      }
    } catch (e) {
      print('Places search error: $e');
    }
  }

  Future<void> _selectPlace(PlacePrediction prediction, bool isPickup) async {
    try {
      // Get place details (lat/lng)
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

            // Center map on pickup
            if (mapController != null) {
              mapController!.animateCamera(
                CameraUpdate.newLatLng(selectedLocation),
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

            // Center map on drop
            if (mapController != null) {
              mapController!.animateCamera(
                CameraUpdate.newLatLng(selectedLocation),
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
      // Swap text fields
      String tempText = _model.pickupController.text;
      _model.pickupController.text = _model.dropController.text;
      _model.dropController.text = tempText;

      // Swap AppState
      String tempLoc = FFAppState().pickuplocation;
      FFAppState().pickuplocation = FFAppState().droplocation;
      FFAppState().droplocation = tempLoc;

      double? tempLat = FFAppState().pickupLatitude;
      FFAppState().pickupLatitude = FFAppState().dropLatitude;
      FFAppState().dropLatitude = tempLat;

      double? tempLng = FFAppState().pickupLongitude;
      FFAppState().pickupLongitude = FFAppState().dropLongitude;
      FFAppState().dropLongitude = tempLng;

      // Swap markers
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
      _model.pickupController.text = 'Rajiv Gandhi Airport, Shamshabad';
      FFAppState().pickuplocation = 'Rajiv Gandhi Airport, Shamshabad';
      FFAppState().pickupLatitude = 17.2403;
      FFAppState().pickupLongitude = 78.4294;
      _addPickupMarker(airportLocation);
      pickupPredictions = [];
      showPickupDropdown = false;
    });

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(airportLocation),
      );
    }
    _showSnackBar('Airport set as pickup');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(milliseconds: 2000),
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
      context.pushNamed(
          AvaliableOptionsWidget.routeName); // Replace with your route
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
      body: Stack(
        children: [
          // Google Map Background
          GoogleMap(
  onMapCreated: (controller) {
    mapController = controller;
  },

  onCameraIdle: () async {
    if (mapController == null) return;

    final bounds = await mapController!.getVisibleRegion();
    final LatLng center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    _updateLocationFromMap(center);
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
)
,
          // Location Input Cards (Top Overlay)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pickup Input
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2DB854),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                              controller: _model.pickupController,
                              onTap: () {
                                activeSelection = LocationSelection.pickup;
                              },
                              style: TextStyle(
                              color: Colors.black,        // ⭐ IMPORTANT
                              fontSize: 14,
                            ),
                              decoration: InputDecoration(
                                hintText: 'Pickup Location',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                _searchPlaces(value, true);
                              },
                            ),

                              if (pickupPredictions.isNotEmpty &&
                                  showPickupDropdown)
                                Container(
                                  margin: EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: pickupPredictions.length,
                                    itemBuilder: (context, index) {
                                      final prediction =
                                          pickupPredictions[index];
                                      return InkWell(
                                        onTap: () {
                                          _selectPlace(prediction, true);
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prediction.mainText,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (prediction
                                                  .secondaryText.isNotEmpty)
                                                Text(
                                                  prediction.secondaryText,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              if (index <
                                                  pickupPredictions.length - 1)
                                                Divider(height: 8),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_model.pickupController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _model.pickupController.clear();
                                pickupPredictions = [];
                                showPickupDropdown = false;
                              });
                            },
                          ),
                        IconButton(
                          onPressed: _setCurrentLocationAsPickup,
                          icon: Icon(
                            Icons.my_location,
                            size: 18,
                            color: Color(0xFF2DB854),
                          ),
                        ),
                      ],
                    ),

                    Divider(height: 12, thickness: 1),

                    // Drop Input
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF5A5F),
                          ),
                          child: Icon(
                            Icons.flag,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                  controller: _model.dropController,
                                  onTap: () {
                                    activeSelection = LocationSelection.drop;
                                  },
                                  style: TextStyle(
                                      color: Colors.black,        // ⭐ IMPORTANT
                                      fontSize: 14,
                                    ),
                                  decoration: InputDecoration(
                                    hintText: 'Drop Location',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    _searchPlaces(value, false);
                                  },
                                ),

                              if (dropPredictions.isNotEmpty &&
                                  showDropDropdown)
                                Container(
                                  margin: EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: dropPredictions.length,
                                    itemBuilder: (context, index) {
                                      final prediction = dropPredictions[index];
                                      return InkWell(
                                        onTap: () {
                                          _selectPlace(prediction, false);
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prediction.mainText,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (prediction
                                                  .secondaryText.isNotEmpty)
                                                Text(
                                                  prediction.secondaryText,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              if (index <
                                                  dropPredictions.length - 1)
                                                Divider(height: 8),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_model.dropController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _model.dropController.clear();
                                dropPredictions = [];
                                showDropDropdown = false;
                              });
                            },
                          ),
                      ],
                    ),

                    // Swap Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          Icons.swap_vert_rounded,
                          color: Color(0xFF000000),
                        ),
                        onPressed: _swapLocations,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          
          // // Confirm Button (Bottom)
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: FFButtonWidget(
              onPressed: _confirmRide,
              text: 'Confirm Ride',
              options: FFButtonOptions(
                width: double.infinity,
                height: 56,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 0.0,
                ),
                iconPadding: EdgeInsets.all(0.0),
                color: Color(0xFFFF7B10),
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                      font: GoogleFonts.inter(),
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                elevation: 3.0,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ],
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
