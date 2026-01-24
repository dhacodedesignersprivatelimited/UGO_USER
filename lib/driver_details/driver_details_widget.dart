import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'driver_details_model.dart';
export 'driver_details_model.dart';

/// Driver Information Summary
class DriverDetailsWidget extends StatefulWidget {
  const DriverDetailsWidget({
    super.key,
    required this.driverId,
  });

  final dynamic driverId;

  static String routeName = 'Driver_details';
  static String routePath = '/driverDetails';

  @override
  State<DriverDetailsWidget> createState() => _DriverDetailsWidgetState();
}

class _DriverDetailsWidgetState extends State<DriverDetailsWidget> {
  late DriverDetailsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  dynamic _driverData;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverDetailsModel());
    _fetchDriverDetails();
  }

  Future<void> _fetchDriverDetails() async {
    try {
      final response = await GetDriverDetailsCall.call(
        driverId: widget.driverId,
        token: FFAppState().accessToken,
      );
      if (mounted) {
        setState(() {
          if (response.succeeded) {
            _driverData = response.jsonBody;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final driverName = GetDriverDetailsCall.name(_driverData) ?? 'Captain';
    final vehicleNum = GetDriverDetailsCall.vehicleNumber(_driverData) ?? 'N/A';
    final rating = GetDriverDetailsCall.rating(_driverData) ?? '4.8';
    final phoneNumber = DriverIdfetchCall.mobileNumber(_driverData);
    final profileImg = GetDriverDetailsCall.profileImage(_driverData);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'UGO TAXI',
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .headlineLarge
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        color: Colors.white,
                                      ),
                                ),
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16.0),
                                    child: profileImg != null 
                                      ? Image.network(profileImg, fit: BoxFit.cover)
                                      : Image.asset('assets/images/0l6yw6.png', fit: BoxFit.cover),
                                  ),
                                ),
                              ].divide(const SizedBox(height: 16.0)),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver details',
                                style: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      color: Colors.white,
                                    ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Driver name: $driverName',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      font: GoogleFonts.inter(),
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Vehicle number: $vehicleNum',
                                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                                      font: GoogleFonts.inter(),
                                      color: Colors.white,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        'Rating: ',
                                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                                          font: GoogleFonts.inter(),
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Icon(Icons.star, color: Color(0xFFFFDE14), size: 20.0),
                                      Text(
                                        rating,
                                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                                          font: GoogleFonts.inter(),
                                          color: Colors.white,
                                        ),
                                      ),
                                    ].divide(const SizedBox(width: 4.0)),
                                  ),
                                  if (phoneNumber != null)
                                    InkWell(
                                      onTap: () => _makeCall(phoneNumber),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.call, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              phoneNumber,
                                              style: FlutterFlowTheme.of(context).bodyLarge.override(
                                                font: GoogleFonts.inter(),
                                                color: Colors.white,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ].divide(const SizedBox(height: 8.0)),
                              ),
                            ].divide(const SizedBox(height: 16.0)),
                          ),
                        ].divide(const SizedBox(height: 24.0)),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FFButtonWidget(
                      onPressed: () => Navigator.pop(context),
                      text: 'Cancel',
                      options: FFButtonOptions(
                        width: 113.0,
                        height: 56.0,
                        color: const Color(0xFFF01C1C),
                        textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.interTight(),
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    FFButtonWidget(
                      onPressed: () async {
                         // Logic to proceed with this driver (if this is part of book flow)
                         // For now keeping it simple as per original
                         context.pushNamed(AutoBookWidget.routeName, queryParameters: {'rideId': '0'}); 
                      },
                      text: 'Continue',
                      options: FFButtonOptions(
                        width: 219.0,
                        height: 56.0,
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.interTight(),
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ].divide(const SizedBox(width: 16.0)),
                ),
              ].divide(const SizedBox(height: 16.0)),
            ),
          ),
        ),
      ),
    );
  }
}
