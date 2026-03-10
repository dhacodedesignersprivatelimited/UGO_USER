import '/backend/api_requests/api_calls.dart';
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_home_model.dart';
export 'add_home_model.dart';

class AddHomeWidget extends StatefulWidget {
  const AddHomeWidget({super.key});

  static String routeName = 'Add_home';
  static String routePath = '/addHome';

  @override
  State<AddHomeWidget> createState() => _AddHomeWidgetState();
}

class _AddHomeWidgetState extends State<AddHomeWidget> {
  late AddHomeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _addressLabelController = TextEditingController();
  final TextEditingController _addressTextController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isGeocoding = false;
  String? _errorMessage;
  String? _successMessage;

  List<dynamic> _savedAddresses = [];
  bool _isLoadingAddresses = true;
  LatLng? _currentUserLocation;
  String get _mapKey => AppConfig.googleMapsApiKey;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddHomeModel());
    _addressLabelController.text = 'Home';

    _initLocation();
    _fetchSavedAddresses();
  }

  Future<void> _initLocation() async {
    final loc = await getCurrentUserLocation(
      defaultLocation: const LatLng(17.385044, 78.486671),
      cached: true,
    );
    if (mounted) {
      setState(() {
        _currentUserLocation = loc;
        if (_model.googleMapsCenter == null) {
          _model.googleMapsCenter = loc;
          _latitude = loc.latitude;
          _longitude = loc.longitude;
          _addressTextController.text = 'Loading address...';
        }
      });
      _reverseGeocode(loc.latitude, loc.longitude);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _addressLabelController.dispose();
    _addressTextController.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedAddresses() async {
    setState(() => _isLoadingAddresses = true);
    try {
      final response = await GetSavedAddressesCall.call(
        userId: FFAppState().userid,
        token: FFAppState().accessToken,
      );
      if (response.succeeded) {
        setState(() {
          _savedAddresses = getJsonField(response.jsonBody, r'$.data') ?? [];
        });
      }
    } catch (e) {
      if (mounted) debugPrint('Error fetching addresses: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (_isGeocoding) return;
    setState(() => _isGeocoding = true);

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = [
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        if (mounted) {
          setState(() {
            _addressTextController.text = address.isNotEmpty ? address : 'Lat: $lat, Lng: $lng';
            _isGeocoding = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _addressTextController.text = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
            _isGeocoding = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressTextController.text = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
          _isGeocoding = false;
        });
      }
    }
  }

  void _onMapCameraIdle(LatLng center) {
    setState(() {
      _model.googleMapsCenter = center;
      _latitude = center.latitude;
      _longitude = center.longitude;
    });
    _reverseGeocode(center.latitude, center.longitude);
  }

  void _openSearch() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Search Location', style: _headerStyle()),
              const SizedBox(height: 16),
              FlutterFlowPlacePicker(
                iOSGoogleMapsApiKey: _mapKey,
                androidGoogleMapsApiKey: _mapKey,
                webGoogleMapsApiKey: _mapKey,
                onSelect: (place) {
                  Navigator.pop(ctx);
                  final loc = place.latLng;
                  _model.googleMapsController.future.then((ctrl) {
                    ctrl.animateCamera(CameraUpdate.newLatLng(loc.toGoogleMaps()));
                  });
                  setState(() {
                    _model.googleMapsCenter = loc;
                    _latitude = loc.latitude;
                    _longitude = loc.longitude;
                    _addressTextController.text = place.address;
                    _isGeocoding = false;
                  });
                },
                defaultText: 'Search for address',
                icon: Icon(Icons.search, color: Colors.grey, size: 20),
                buttonOptions: FFButtonOptions(
                  width: double.infinity,
                  height: 48,
                  color: Colors.grey.shade100,
                  textStyle: GoogleFonts.inter(),
                  elevation: 0,
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      final appState = FFAppState();
      if (_addressLabelController.text.trim().isEmpty) throw Exception('Enter label');
      if (_addressTextController.text.trim().isEmpty) throw Exception('Enter address');
      if (_latitude == null || _longitude == null) throw Exception('Select location on map');

      final response = await SaveAddressCall.call(
        userId: appState.userid,
        addressLabel: _addressLabelController.text.trim(),
        addressText: _addressTextController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        token: appState.accessToken,
      );

      if (response.succeeded) {
        setState(() {
          _successMessage = 'Saved successfully!';
          _addressLabelController.text = 'Home';
          _addressTextController.clear();
          _latitude = _currentUserLocation?.latitude;
          _longitude = _currentUserLocation?.longitude;
          if (_currentUserLocation != null) {
            _model.googleMapsCenter = _currentUserLocation;
            _reverseGeocode(_currentUserLocation!.latitude, _currentUserLocation!.longitude);
          }
        });
        _fetchSavedAddresses();
      } else {
        throw Exception(getJsonField(response.jsonBody, r'$.message') ?? 'Failed');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserLocation == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: Center(child: CircularProgressIndicator(color: const Color(0xFFFF7B10))),
      );
    }

    final initialLoc = _model.googleMapsCenter ?? _currentUserLocation!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10),
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30,
            buttonSize: 60,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
            onPressed: () => context.pop(),
          ),
          title: Text('Saved Places', style: GoogleFonts.interTight(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  FlutterFlowGoogleMap(
                    controller: _model.googleMapsController,
                    onCameraIdle: _onMapCameraIdle,
                    initialLocation: initialLoc,
                    markerColor: GoogleMarkerColor.orange,
                    mapType: MapType.normal,
                    style: GoogleMapStyle.uber,
                    initialZoom: 15,
                    allowInteraction: true,
                    allowZoom: true,
                    showZoomControls: false,
                    showLocation: true,
                    showCompass: false,
                    showMapToolbar: false,
                    showTraffic: false,
                    centerMapOnMarkerTap: false,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: TextField(
                        readOnly: true,
                        onTap: _openSearch,
                        decoration: InputDecoration(
                          hintText: 'Search address',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: IgnorePointer(
                      child: Icon(Icons.location_on, size: 48, color: const Color(0xFFFF7B10)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_successMessage != null) _buildBanner(_successMessage!, Colors.green),
                    if (_errorMessage != null) _buildBanner(_errorMessage!, Colors.red),
                    const SizedBox(height: 12),
                    Text('Add New Place', style: _headerStyle()),
                    const SizedBox(height: 12),
                    _buildTextField(_addressLabelController, 'Label (e.g., Home)', Icons.label_outline),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _addressTextController,
                      'Address',
                      Icons.place,
                      suffix: _isGeocoding
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : (_latitude != null ? const Icon(Icons.check_circle, color: Colors.green, size: 22) : null),
                    ),
                    const SizedBox(height: 8),
                    Text('Tap and drag the map to pick a location', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 20),
                    FFButtonWidget(
                      onPressed: (_isLoading || _isGeocoding) ? null : _saveAddress,
                      text: _isLoading ? 'Saving...' : 'Save Address',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 50,
                        color: const Color(0xFFFF7B10),
                        textStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                        borderRadius: BorderRadius.circular(8),
                        disabledColor: Colors.orange.shade200,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('Your Saved Places', style: _headerStyle()),
                    const SizedBox(height: 12),
                    _isLoadingAddresses
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10)))
                        : _savedAddresses.isEmpty
                            ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No saved places yet.')))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _savedAddresses.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final place = _savedAddresses[i];
                                  final label = (place['address_name'] ?? place['address_label'] ?? place['address_type'] ?? 'other').toString();
                                  final type = label.toLowerCase();
                                  final address = place['address_text']?.toString() ?? '';

                                  IconData icon;
                                  Color color;
                                  if (type.contains('home')) {
                                    icon = Icons.home_rounded;
                                    color = Colors.blue;
                                  } else if (type.contains('work') || type.contains('office')) {
                                    icon = Icons.work_rounded;
                                    color = Colors.orange;
                                  } else {
                                    icon = Icons.location_on_rounded;
                                    color = Colors.grey;
                                  }

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                                          child: Icon(icon, color: color, size: 24),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(label.isEmpty ? 'Other' : label[0].toUpperCase() + label.substring(1).toLowerCase(),
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                                              Text(address, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87);

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {Widget? suffix}) => TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFF7B10), width: 1.5)),
          filled: true,
          fillColor: Colors.white,
        ),
      );

  Widget _buildBanner(String msg, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
        child: Text(msg, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );
}
