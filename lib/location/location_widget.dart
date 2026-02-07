import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/permissions_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'location_model.dart';
export 'location_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Allow Location for Faster Ride Booking
class LocationWidget extends StatefulWidget {
  const LocationWidget({
    super.key,
    required this.mobile,
    required this.firstname,
    required this.lastname,
    required this.email,
  });

  final int? mobile;
  final String? firstname;
  final String? lastname;
  final String? email;

  static String routeName = 'location';
  static String routePath = '/location';

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  late LocationModel _model;
  String? fcm_token;
  bool _isLoading = false; // Added to prevent double-clicks

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocationModel());
    _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      fcm_token = await FirebaseMessaging.instance.getToken();
      print('FCM TOKEN: $fcm_token');
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Unified Registration Function
  Future<void> _registerUser() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. Call Backend API
      _model.apiResultblh = await CreateUserCall.call(
        mobileNumber: widget.mobile,
        firstName: widget.firstname,
        lastName: widget.lastname,
        email: widget.email,
        fcmToken: fcm_token,
      );

      print('Register Response: ${_model.apiResultblh?.jsonBody}');

      // 2. Check Success
      if ((_model.apiResultblh?.succeeded ?? false)) {
        // 3. PERSIST SESSION DATA (Crucial for AppState)
        final responseData = _model.apiResultblh!.jsonBody;

        FFAppState().accessToken = getJsonField(
          responseData,
          r'$.data.accessToken',
        ).toString();

        FFAppState().userid = getJsonField(
          responseData,
          r'$.data.user.id',
        );

        // 4. Navigate to Home
        if (mounted) {
          context.goNamedAuth(HomeWidget.routeName, context.mounted);
        }
      } else {
        // 5. Handle Errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                getJsonField(
                  (_model.apiResultblh?.jsonBody ?? ''),
                  r'$.message',
                ).toString(),
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
              ),
              duration: Duration(seconds: 4),
              backgroundColor: FlutterFlowTheme.of(context).secondary,
            ),
          );
        }
      }
    } catch (e) {
      print('Exception during registration: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        backgroundColor: Color(0xFFF5F5F5),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(32.0, 100.0, 32.0, 50.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 200.0,
                      height: 200.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFFCB896),
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Container(
                          width: 114.0,
                          height: 114.0,
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Icon(
                              Icons.location_on,
                              color: Color(0xFFFF7B10),
                              size: 60.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            'r0jmuvmm' /* Allow Location */,
                          ),
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .fontStyle,
                            ),
                            color: Colors.black,
                            fontSize: 24.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .fontStyle,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 0.0, 20.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              'nqodqk44' /* Allow location to book your ri... */,
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.normal,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: Colors.black,
                              fontSize: 16.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                          ),
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                  ].divide(SizedBox(height: 40.0)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FFButtonWidget(
                      onPressed: _isLoading
                          ? null
                          : () async {
                        // 1. Request Permission
                        await requestPermission(locationPermission);
                        // 2. Register (regardless of permission result)
                        await _registerUser();
                      },
                      text: _isLoading
                          ? 'Creating Account...'
                          : FFLocalizations.of(context).getText('nk8owetj' /* Allow */),
                      options: FFButtonOptions(
                        width: 349.0,
                        height: 56.0,
                        padding: EdgeInsets.all(8.0),
                        iconPadding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: Color(0xFFFF7B10),
                        textStyle:
                        FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                          ),
                          color: Color(0xFFF5F5F5),
                          fontSize: 24.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.normal,
                          fontStyle: FlutterFlowTheme.of(context)
                              .titleMedium
                              .fontStyle,
                        ),
                        elevation: 0.0,
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(28.0),
                        disabledColor: Colors.grey.shade400,
                      ),
                    ),
                    InkWell(
                      onTap: _isLoading
                          ? null
                          : () async {
                        // Skip permission request, just register
                        await _registerUser();
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'uskmg48m' /* Skip */,
                          ),
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: _isLoading ? Colors.grey : Colors.black,
                            fontSize: 20.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                          ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 20.0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}