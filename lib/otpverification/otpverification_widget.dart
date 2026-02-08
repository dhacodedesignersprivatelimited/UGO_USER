import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otpverification_model.dart';
export 'otpverification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// OTP Verification Screen
class OtpverificationWidget extends StatefulWidget {
  const OtpverificationWidget({
    super.key,
    required this.mobile,
  });

  final int? mobile;

  static String routeName = 'otpverification';
  static String routePath = '/otpverification';

  @override
  State<OtpverificationWidget> createState() => _OtpverificationWidgetState();
}

class _OtpverificationWidgetState extends State<OtpverificationWidget> {
  late OtpverificationModel _model;
  String? fcm_token;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // 🔹 RESEND OTP STATE
  int _resendSeconds = 60;
  bool _canResendOtp = false;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OtpverificationModel());
    _model.pinCodeFocusNode ??= FocusNode();

    _initFCM();
    _startResendTimer();
  }

  Future<void> _initFCM() async {
    try {
      fcm_token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM TOKEN: $fcm_token');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 60;
      _canResendOtp = false;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds == 0) {
        timer.cancel();
        setState(() {
          _canResendOtp = true;
        });
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _model.dispose();
    super.dispose();
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10), // Primary Orange
          automaticallyImplyLeading: false,
          title: Text(
            'Verification',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              font: GoogleFonts.interTight(),
              color: Colors.white,
              fontSize: 22.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(32.0, 0.0, 32.0, 0.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Enter OTP',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.interTight(),
                      color: Colors.black,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "We've sent a 6-digit code to \n",
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(),
                            color: Colors.grey[600],
                            fontSize: 16.0,
                          ),
                        ),
                        TextSpan(
                          text: "+91 ${widget.mobile}",
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(),
                            color: const Color(0xFFFF7B10),
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  PinCodeTextField(
                    autoDisposeControllers: false,
                    appContext: context,
                    length: 6,
                    textStyle: FlutterFlowTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.inter(),
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    enableActiveFill: true,
                    autoFocus: true,
                    focusNode: _model.pinCodeFocusNode,
                    enablePinAutofill: true,
                    errorTextSpace: 16.0,
                    showCursor: true,
                    cursorColor: const Color(0xFFFF7B10),
                    obscureText: false,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      fieldHeight: 50.0,
                      fieldWidth: 50.0,
                      borderWidth: 1.5,
                      borderRadius: BorderRadius.circular(12.0),
                      shape: PinCodeFieldShape.box,
                      activeColor: const Color(0xFFFF7B10),
                      inactiveColor: Colors.grey[300]!,
                      selectedColor: const Color(0xFFFF7B10),
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.grey[50]!,
                      selectedFillColor: Colors.white,
                    ),
                    controller: _model.pinCodeController,
                    onChanged: (_) {},
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _model.pinCodeControllerValidator.asValidator(context),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _canResendOtp
                          ? () async {
                        try {
                          final phoneNumber = '+91${widget.mobile}';
                          await authManager.beginPhoneAuth(
                            context: context,
                            phoneNumber: phoneNumber,
                            onCodeSent: (context) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP sent successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          );
                          _startResendTimer();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                          : null,
                      child: Text(
                        _canResendOtp
                            ? 'RESEND OTP'
                            : 'Resend in $_resendSeconds s',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(),
                          color: _canResendOtp
                              ? const Color(0xFFFF7B10)
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FFButtonWidget(
                    onPressed: () async {
                      final smsCodeVal = _model.pinCodeController!.text;
                      if (smsCodeVal.isEmpty || smsCodeVal.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid 6-digit code.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // 1. Verify with Firebase
                      GoRouter.of(context).prepareAuthEvent();
                      final phoneVerifiedUser = await authManager.verifySmsCode(
                        context: context,
                        smsCode: smsCodeVal,
                      );

                      if (phoneVerifiedUser == null) {
                        return; // Auth failed (AuthManager handles the snackbar usually)
                      }

                      // 2. Check Backend for User Existence
                      _model.apiResultx4u = await LoginCall.call(
                        mobile: widget.mobile,
                        fcmToken: fcm_token,
                      );

                      if (!mounted) return;

                      // 3. Navigate based on Backend Result
                      if ((_model.apiResultx4u?.succeeded ?? false)) {
                        // User EXISTS
                        FFAppState().accessToken = getJsonField(
                          (_model.apiResultx4u?.jsonBody ?? ''),
                          r'''$.data.accessToken''',
                        ).toString();

                        FFAppState().userid = getJsonField(
                          (_model.apiResultx4u?.jsonBody ?? ''),
                          r'''$.data.user.id''',
                        );

                        context.goNamedAuth(HomeWidget.routeName, context.mounted);
                      } else {
                        // User DOES NOT EXIST -> Registration
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New user detected. Please complete registration.'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        context.pushNamedAuth(
                          DetailspageWidget.routeName,
                          context.mounted,
                          queryParameters: {
                            'mobile': serializeParam(
                              widget.mobile,
                              ParamType.int,
                            ),
                          }.withoutNulls,
                        );
                      }
                    },
                    text: 'VERIFY',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56.0,
                      padding: const EdgeInsets.all(8.0),
                      color: const Color(0xFFFF7B10),
                      textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                        font: GoogleFonts.interTight(),
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ].addToStart(const SizedBox(height: 20.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}