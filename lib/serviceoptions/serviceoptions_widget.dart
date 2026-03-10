import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/api_requests/api_calls.dart';
import 'serviceoptions_model.dart';
export 'serviceoptions_model.dart';

/// 🚀 Modern Responsive Service Options
class ServiceoptionsWidget extends StatefulWidget {
  const ServiceoptionsWidget({super.key});

  static String routeName = 'serviceoptions';
  static String routePath = '/serviceoptions';

  @override
  State<ServiceoptionsWidget> createState() => _ServiceoptionsWidgetState();
}

class _ServiceoptionsWidgetState extends State<ServiceoptionsWidget> {
  late ServiceoptionsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Our Services - vehicle types from API
  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _vehicleTypesLoading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ServiceoptionsModel());
    _fetchVehicleTypes();
  }

  Future<void> _fetchVehicleTypes() async {
    try {
      final res = await GetVehicleTypesCall.call();
      if (mounted && res.succeeded) {
        final list = GetVehicleTypesCall.vehicles(res.jsonBody);
        setState(() {
          _vehicleTypes = (list ?? [])
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();
          _vehicleTypesLoading = false;
        });
      } else {
        if (mounted) setState(() => _vehicleTypesLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch vehicle types error: $e');
      if (mounted) setState(() => _vehicleTypesLoading = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false prevents the system from popping the route automatically,
      // which allows us to handle the navigation manually in onPopInvokedWithResult.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        context.goNamed(HomeWidget.routeName);
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFF7B10),
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                borderWidth: 1.0,
                buttonSize: 44.0,
                // Note: withValues(alpha:) is available in very recent Flutter versions.
                // If you face issues, use .withOpacity(0.2) instead.
                fillColor: Colors.white.withValues(alpha: 0.2),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24.0,
                ),
                onPressed: () async {
                  context.goNamed(HomeWidget.routeName);
                },
              ),
            ),
            title: Text(
              FFLocalizations.of(context).getText('rnwdwckb' /* Services */),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: const [],
            centerTitle: true,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isNarrow = screenWidth < 360;
                final padding = isNarrow ? 20.0 : 28.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 40),
                  child: Column(
                    children: [
                      // 0. Map preview (Uber-style orange roads)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: FlutterFlowGoogleMap(
                            controller: _model.googleMapsController,
                            onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
                            initialLocation: _model.googleMapsCenter ??
                                const LatLng(17.3850, 78.4867),
                            markers: const [],
                            markerColor: GoogleMarkerColor.orange,
                            mapType: MapType.normal,
                            style: GoogleMapStyle.uber,
                            initialZoom: 13.0,
                            allowInteraction: true,
                            allowZoom: true,
                            showZoomControls: false,
                            showLocation: false,
                            showCompass: false,
                            showMapToolbar: false,
                            showTraffic: false,
                          ),
                        ),
                      ),
                      SizedBox(height: isNarrow ? 24 : 28),

                      // 1. Hero Header
                      _buildHeroHeader(isNarrow),

                      SizedBox(height: isNarrow ? 40 : 56),

                      // 2. Service Cards Grid
                      _buildOurServicesSection(isNarrow),

                      SizedBox(height: isNarrow ? 100 : 140),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHeroHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   FFLocalizations.of(context).getText('xlfqyvqa' /* Comfortable Rides, Anytime */),
        //   style: GoogleFonts.poppins(
        //     fontSize: isNarrow ? 26 : 32,
        //     fontWeight: FontWeight.w700,
        //     color: Colors.black87,
        //     height: 1.2,
        //   ),
        // ),
        Text(
          'Comfortable Rides Anytime',
          style: GoogleFonts.inter(
            fontSize: isNarrow ? 20 : 22,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Choose your ride type below',
          style: GoogleFonts.inter(
            fontSize: isNarrow ? 16 : 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOurServicesSection(bool isNarrow) {
    if (_vehicleTypesLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
            3,
            (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: isNarrow ? 90 : 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFFF7B10)),
                      ),
                    ),
                  ),
                )),
      );
    }
    final vehicles = _vehicleTypes.isEmpty
        ? [
            {'id': 2, 'name': 'bike', 'image': null},
            {'id': 1, 'name': 'auto', 'image': null},
            {'id': 3, 'name': 'car', 'image': null},
          ]
        : _vehicleTypes;

    List<Widget> displayItems = [];
    for (final v in vehicles) {
      displayItems.add(_buildVehicleCard(v, context, isNarrow));
    }

    const rowSpacing = 16.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < displayItems.length; i += 3) ...[
          if (i > 0) const SizedBox(height: rowSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (int j = 0; j < 3; j++)
                (i + j) < displayItems.length
                    ? displayItems[i + j]
                    : Expanded(child: const SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildComingSoonCard(BuildContext context, bool isNarrow) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        height: isNarrow ? 90 : 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vehicle coming soon!')),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  color: Colors.grey[500], size: isNarrow ? 28 : 32),
              const SizedBox(height: 4),
              Text(
                'Coming soon',
                style: GoogleFonts.poppins(
                  fontSize: isNarrow ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(
      Map<String, dynamic> v, BuildContext context, bool isNarrow) {
    final name = (v['name'] ?? 'ride').toString().toLowerCase();
    final label = name.length > 1
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : name.toUpperCase();
    final imagePath = v['image']?.toString();
    final imageUrl = imagePath != null && imagePath.isNotEmpty
        ? (imagePath.startsWith('http')
            ? imagePath
            : '${AppConfig.baseApiUrl}${imagePath.startsWith('/') ? '' : '/'}$imagePath')
        : null;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          FFAppState().selectedRideCategory = name;
          context.pushNamed(PlanYourRideWidget.routeName);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: isNarrow ? 90 : 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/$name.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.directions_car,
                                color: Color(0xFFFF7B10)),
                          ),
                        )
                      : Image.asset(
                          'assets/images/$name.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.directions_car,
                              color: Color(0xFFFF7B10))),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: isNarrow ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
