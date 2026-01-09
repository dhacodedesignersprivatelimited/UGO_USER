import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/api_requests/api_calls.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart'; // Add this package to pubspec.yaml
import 'add_home_model.dart';
export 'add_home_model.dart';

/// Location Management Interface with Auto Geocoding
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
  
  // Controllers for input fields
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressLabelController = TextEditingController();
  final TextEditingController _addressTextController = TextEditingController();
  
  // Store coordinates internally (not in text fields)
  double? _latitude;
  double? _longitude;
  
  bool _isLoading = false;
  bool _isGeocoding = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddHomeModel());
    
    // Listen to address changes and geocode automatically
    _addressTextController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    _addressLabelController.dispose();
    _addressTextController.dispose();
    super.dispose();
  }

  // Automatically geocode when address changes
  void _onAddressChanged() {
    // Debounce: wait for user to stop typing
    Future.delayed(Duration(milliseconds: 800), () {
      if (_addressTextController.text.isNotEmpty && 
          _addressTextController.text.length > 3) {
        _geocodeAddress(_addressTextController.text);
      }
    });
  }

  // Geocode address to get lat/long
  Future<void> _geocodeAddress(String address) async {
    if (_isGeocoding) return; // Prevent multiple simultaneous requests
    
    setState(() {
      _isGeocoding = true;
      _errorMessage = null;
    });

    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        setState(() {
          _latitude = locations.first.latitude;
          _longitude = locations.first.longitude;
          _isGeocoding = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Could not find location for this address';
          _latitude = null;
          _longitude = null;
          _isGeocoding = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Please enter a more specific address';
        _latitude = null;
        _longitude = null;
        _isGeocoding = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final appState = FFAppState();
      
      // Validation
      if (_addressLabelController.text.isEmpty) {
        throw Exception('Please enter an address label (e.g., Home, Work)');
      }
      if (_addressTextController.text.isEmpty) {
        throw Exception('Please enter the address');
      }
      if (_latitude == null || _longitude == null) {
        throw Exception('Please wait for location to be detected or enter a valid address');
      }

      // Make API call using your custom API structure
      final response = await SaveAddressCall.call(
        userId: appState.userid,
        addressLabel: _addressLabelController.text,
        addressText: _addressTextController.text,
        latitude: _latitude!,
        longitude: _longitude!,
        token: appState.accessToken,
      );

      if (response.succeeded) {
        setState(() {
          _successMessage = 'Address saved successfully!';
        });

        // Clear form after 2 seconds and go back
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          context.pop();
        }
      } else {
        throw Exception(response.jsonBody['message'] ?? 'Failed to save address');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'unxbdrt3' /* Add Saved Place */,
            ),
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w500,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 24.0, 16.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success/Error Messages
                if (_successMessage != null)
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(color: Colors.green.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 24),
                
                // Address Label Input
                Text(
                  'Label',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _addressLabelController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Home, Work, Friend\'s Place',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).accent1,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).accent1,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 2.0,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Address Text Input with Auto Geocoding
                Text(
                  'Address',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _addressTextController,
                  decoration: InputDecoration(
                    hintText: 'e.g., BTM Layout, Bengaluru, Karnataka',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).accent1,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).accent1,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 2.0,
                      ),
                    ),
                    suffixIcon: _isGeocoding 
                      ? Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                          ),
                        )
                      : (_latitude != null && _longitude != null)
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                  ),
                  maxLines: 2,
                ),
                
                SizedBox(height: 12),
                
                // Display detected coordinates
                if (_latitude != null && _longitude != null)
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location Detected',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.0,
                                ),
                              ),
                              Text(
                                'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_isGeocoding)
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Detecting location...',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 12.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                SizedBox(height: 32),
                
                // Save Button
                FFButtonWidget(
                  onPressed: (_isLoading || _isGeocoding || _latitude == null) 
                      ? null 
                      : _saveAddress,
                  text: _isLoading 
                      ? 'Saving...' 
                      : (_latitude == null 
                          ? 'Enter address first' 
                          : 'Save Address'),
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 50.0,
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    iconPadding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          color: Colors.white,
                          fontSize: 16.0,
                          letterSpacing: 0.0,
                        ),
                    elevation: 2.0,
                    borderSide: BorderSide(
                      color: Colors.transparent,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    disabledColor: Colors.grey.shade400,
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Quick Options Section
                Divider(),
                SizedBox(height: 16),
                
                Text(
                  'Quick Options',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                    font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Search in different city
                InkWell(
                  onTap: () {
                    _showSearchDialog();
                  },
                  child: _buildQuickOption(
                    icon: Icons.search,
                    title: 'Search in different city',
                    iconColor: FlutterFlowTheme.of(context).primary,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Saved places
                InkWell(
                  onTap: () {
                    // Navigate to saved places screen
                    // context.pushNamed('SavedPlacesWidget');
                  },
                  child: _buildQuickOption(
                    icon: Icons.star,
                    title: 'View saved places',
                    iconColor: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Location'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Enter city or location name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _addressTextController.text = value;
            _geocodeAddress(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FFButtonWidget(
            onPressed: () {
              Navigator.pop(context);
              _addressTextController.text = _searchController.text;
              _geocodeAddress(_searchController.text);
            },
            text: 'Search',
            options: FFButtonOptions(
              height: 40.0,
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              color: FlutterFlowTheme.of(context).primary,
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.inter(),
                    color: Colors.white,
                  ),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOption({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).accent1,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.0,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                  ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: FlutterFlowTheme.of(context).accent1,
            size: 16.0,
          ),
        ],
      ),
    );
  }
}