import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
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

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressLabelController = TextEditingController();
  final TextEditingController _addressTextController = TextEditingController();

  // State Variables
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isGeocoding = false;
  String? _errorMessage;
  String? _successMessage;

  // ✅ Saved Addresses State
  List<dynamic> _savedAddresses = [];
  bool _isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddHomeModel());
    _addressTextController.addListener(_onAddressChanged);

    // ✅ Fetch addresses on load
    _fetchSavedAddresses();
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    _addressLabelController.dispose();
    _addressTextController.dispose();
    super.dispose();
  }

  // ✅ Fetch Saved Addresses API
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
      print('Error fetching addresses: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  void _onAddressChanged() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_addressTextController.text.isNotEmpty &&
          _addressTextController.text.length > 3) {
        _geocodeAddress(_addressTextController.text);
      }
    });
  }

  Future<void> _geocodeAddress(String address) async {
    if (_isGeocoding) return;
    setState(() { _isGeocoding = true; _errorMessage = null; });

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
          _errorMessage = 'Could not find location';
          _latitude = null; _longitude = null; _isGeocoding = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Please enter a valid address';
        _latitude = null; _longitude = null; _isGeocoding = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      final appState = FFAppState();

      if (_addressLabelController.text.isEmpty) throw Exception('Enter label');
      if (_addressTextController.text.isEmpty) throw Exception('Enter address');
      if (_latitude == null) throw Exception('Wait for location detection');

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
          _successMessage = 'Saved successfully!';
          _addressLabelController.clear();
          _addressTextController.clear();
          _latitude = null;
          _longitude = null;
        });

        // ✅ Refresh list instead of popping immediately
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10), // Primary Orange
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            buttonSize: 60.0,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30.0),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Saved Places',
            style: FlutterFlowTheme.of(context).titleLarge.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Messages
                if (_successMessage != null)
                  _buildMessageBanner(_successMessage!, Colors.green),
                if (_errorMessage != null)
                  _buildMessageBanner(_errorMessage!, Colors.red),

                const SizedBox(height: 16),

                // --- ADD NEW ADDRESS FORM ---
                Text('Add New Place', style: _headerStyle()),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _addressLabelController,
                  hint: 'Label (e.g., Home, Office)',
                  icon: Icons.label_outline,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _addressTextController,
                  hint: 'Address (e.g., BTM Layout)',
                  icon: Icons.map_outlined,
                  suffix: _isGeocoding
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : (_latitude != null ? const Icon(Icons.check_circle, color: Colors.green) : null),
                ),

                const SizedBox(height: 20),

                FFButtonWidget(
                  onPressed: (_isLoading || _isGeocoding) ? null : _saveAddress,
                  text: _isLoading ? 'Saving...' : 'Save Address',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 50.0,
                    color: const Color(0xFFFF7B10),
                    textStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                    borderRadius: BorderRadius.circular(8.0),
                    disabledColor: Colors.orange.shade200,
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(thickness: 1),
                const SizedBox(height: 16),

                // --- SAVED PLACES LIST ---
                Text('Your Saved Places', style: _headerStyle()),
                const SizedBox(height: 12),

                _isLoadingAddresses
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10)))
                    : _savedAddresses.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No saved places yet.'),
                  ),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedAddresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final place = _savedAddresses[index];
                    final type = place['address_label']?.toString().toLowerCase() ?? 'other';
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place['address_label'] ?? 'Unknown',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  address,
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
      ),
    );
  }

  // --- HELPERS ---

  TextStyle _headerStyle() => GoogleFonts.interTight(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black87
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFFFF7B10), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildMessageBanner(String msg, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(msg, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}