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
import 'choose_destination_model.dart';
export 'choose_destination_model.dart';

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
  bool _isPickupSelected = false; // true if editing pickup, false if destination

  // Using the API key found in AvaliableOptionsWidget
  final String _googleMapsApiKey = 'AIzaSyDO0iVw0vItsg45hIDHV3oAu8RB-zcra2Y';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChooseDestinationModel());

    _model.pickupLocationController ??= TextEditingController(
      text: FFAppState().pickuplocation,
    );
    _model.pickupLocationFocusNode ??= FocusNode();

    _model.destinationLocationController ??= TextEditingController();
    _model.destinationLocationFocusNode ??= FocusNode();

    // Listeners for focus to know which field is being edited
    _model.pickupLocationFocusNode?.addListener(() {
      if (_model.pickupLocationFocusNode?.hasFocus ?? false) {
        setState(() => _isPickupSelected = true);
      }
    });

    _model.destinationLocationFocusNode?.addListener(() {
      if (_model.destinationLocationFocusNode?.hasFocus ?? false) {
        setState(() => _isPickupSelected = false);
      }
    });

    // Auto focus destination if pickup is already set
    if (FFAppState().pickuplocation.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _model.destinationLocationFocusNode?.requestFocus();
      });
    } else {
      _getCurrentLocation();
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

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        String address = "${place.name}, ${place.subLocality}, ${place.locality}";

        setState(() {
          _model.pickupLocationController?.text = address;
          FFAppState().pickuplocation = address;
          FFAppState().pickupLatitude = position.latitude;
          FFAppState().pickupLongitude = position.longitude;
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

        if (_isPickupSelected) {
          setState(() {
            _model.pickupLocationController?.text = description;
            FFAppState().pickuplocation = description;
            FFAppState().pickupLatitude = lat;
            FFAppState().pickupLongitude = lng;
            _predictions = [];
            _model.destinationLocationFocusNode?.requestFocus();
          });
        } else {
          setState(() {
            _model.destinationLocationController?.text = description;
            FFAppState().droplocation = description;
            FFAppState().dropLatitude = lat;
            FFAppState().dropLongitude = lng;
            _predictions = [];
          });
          // Navigation logic to ride options
          context.pushNamed(HomeWidget.routeName);
        }
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  @override
  void dispose() {
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
          child: Column(
            children: [
              // Header & Inputs (Primary Orange Background)
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
                        Text(
                          'Plan your ride',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Left Visual (Uber dots/lines)
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
                        // TextFields
                        Expanded(
                          child: Column(
                            children: [
                              // Pickup field
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _model.pickupLocationController,
                                  focusNode: _model.pickupLocationFocusNode,
                                  decoration: InputDecoration(
                                    hintText: 'Pickup Location',
                                    hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    suffixIcon: _model.pickupLocationController!.text.isNotEmpty
                                        ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                      onPressed: () {
                                        _model.pickupLocationController?.clear();
                                        setState(() {});
                                      },
                                    )
                                        : null,
                                  ),
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                                  onChanged: (val) => _getPlacePredictions(val),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Destination field
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
                                    hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    suffixIcon: _model.destinationLocationController!.text.isNotEmpty
                                        ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                      onPressed: () {
                                        _model.destinationLocationController?.clear();
                                        setState(() {});
                                      },
                                    )
                                        : null,
                                  ),
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                                  onChanged: (val) => _getPlacePredictions(val),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.my_location, color: Colors.white, size: 24),
                          onPressed: _getCurrentLocation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Results List (Secondary White Background)
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _predictions.isNotEmpty
                      ? ListView.builder(
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: Color(0xFFFF7B10)),
                        title: Text(
                          prediction['structured_formatting']['main_text'],
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black),
                        ),
                        subtitle: Text(
                          prediction['structured_formatting']['secondary_text'] ?? '',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _getPlaceDetails(
                          prediction['place_id'],
                          prediction['description'],
                        ),
                      );
                    },
                  )
                      : _isSearching
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10)))
                      : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Set on Map Option
                      InkWell(
                        onTap: () {
                          context.pushNamed(SetLocationWidget.routeName);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7B10).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.map_rounded, color: Color(0xFFFF7B10), size: 20),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Set location on map',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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