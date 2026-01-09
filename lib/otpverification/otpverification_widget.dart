// import '/auth/firebase_auth/auth_util.dart';
// import '/backend/api_requests/api_calls.dart';
// import '/flutter_flow/flutter_flow_icon_button.dart';
// import '/flutter_flow/flutter_flow_theme.dart';
// import '/flutter_flow/flutter_flow_util.dart';
// import '/flutter_flow/flutter_flow_widgets.dart';
// import '/index.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'otpverification_model.dart';
// export 'otpverification_model.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// /// OTP Verification Screen
// class OtpverificationWidget extends StatefulWidget {
//   const OtpverificationWidget({
//     super.key,
//     required this.mobile,
//   });

//   final int? mobile;

//   static String routeName = 'otpverification';
//   static String routePath = '/otpverification';

//   @override
//   State<OtpverificationWidget> createState() => _OtpverificationWidgetState();
// }

// class _OtpverificationWidgetState extends State<OtpverificationWidget> {
//   late OtpverificationModel _model;
//   String? fcm_token;

//   final scaffoldKey = GlobalKey<ScaffoldState>();

//   @override
//   void initState() {
//     super.initState();
//     _model = createModel(context, () => OtpverificationModel());

//     _model.pinCodeFocusNode ??= FocusNode();
//     _initFCM();
//   }

//   Future<void> _initFCM() async {
//     fcm_token = await FirebaseMessaging.instance.getToken();
//     print('FCM TOKEN: $fcm_token');
//   }

//   @override
//   void dispose() {
//     _model.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         FocusScope.of(context).unfocus();
//         FocusManager.instance.primaryFocus?.unfocus();
//       },
//       child: Scaffold(
//         key: scaffoldKey,
//         backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
//         appBar: AppBar(
//           backgroundColor: FlutterFlowTheme.of(context).primary,
//           automaticallyImplyLeading: false,
//           leading: FlutterFlowIconButton(
//             borderColor: Colors.transparent,
//             borderRadius: 30.0,
//             borderWidth: 1.0,
//             buttonSize: 60.0,
//             icon: Icon(
//               Icons.arrow_back_rounded,
//               color: Colors.white,
//               size: 30.0,
//             ),
//             onPressed: () async {
//               context.pop();
//             },
//           ),
//           title: Text(
//             FFLocalizations.of(context).getText(
//               'duko62qy' /* Verification */,
//             ),
//             style: FlutterFlowTheme.of(context).headlineMedium.override(
//                   font: GoogleFonts.interTight(
//                     fontWeight:
//                         FlutterFlowTheme.of(context).headlineMedium.fontWeight,
//                     fontStyle:
//                         FlutterFlowTheme.of(context).headlineMedium.fontStyle,
//                   ),
//                   color: Colors.white,
//                   fontSize: 22.0,
//                   letterSpacing: 0.0,
//                   fontWeight:
//                       FlutterFlowTheme.of(context).headlineMedium.fontWeight,
//                   fontStyle:
//                       FlutterFlowTheme.of(context).headlineMedium.fontStyle,
//                 ),
//           ),
//           actions: [],
//           centerTitle: true,
//           elevation: 2.0,
//         ),
//         body: SafeArea(
//           top: true,
//           child: Padding(
//             padding: EdgeInsetsDirectional.fromSTEB(32.0, 0.0, 32.0, 0.0),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.max,
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Text(
//                     FFLocalizations.of(context).getText(
//                       'ujhimmtb' /* Enter the OTP to continue. */,
//                     ),
//                     textAlign: TextAlign.center,
//                     style: FlutterFlowTheme.of(context).headlineMedium.override(
//                           font: GoogleFonts.interTight(
//                             fontWeight: FontWeight.w600,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .headlineMedium
//                                 .fontStyle,
//                           ),
//                           color: Colors.black,
//                           fontSize: 24.0,
//                           letterSpacing: 0.0,
//                           fontWeight: FontWeight.w600,
//                           fontStyle: FlutterFlowTheme.of(context)
//                               .headlineMedium
//                               .fontStyle,
//                         ),
//                   ),
//                   Text(
//                     FFLocalizations.of(context).getText(
//                       'xupvugn4' /* We've sent you a 6-digit code ... */,
//                     ),
//                     textAlign: TextAlign.center,
//                     style: FlutterFlowTheme.of(context).bodyMedium.override(
//                           font: GoogleFonts.inter(
//                             fontWeight: FontWeight.normal,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .fontStyle,
//                           ),
//                           color: Colors.black,
//                           fontSize: 16.0,
//                           letterSpacing: 0.0,
//                           fontWeight: FontWeight.normal,
//                           fontStyle:
//                               FlutterFlowTheme.of(context).bodyMedium.fontStyle,
//                         ),
//                   ),
//                   PinCodeTextField(
//                     autoDisposeControllers: false,
//                     appContext: context,
//                     length: 6,
//                     textStyle: FlutterFlowTheme.of(context).bodyLarge.override(
//                           font: GoogleFonts.inter(
//                             fontWeight: FlutterFlowTheme.of(context)
//                                 .bodyLarge
//                                 .fontWeight,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyLarge
//                                 .fontStyle,
//                           ),
//                           letterSpacing: 0.0,
//                           fontWeight:
//                               FlutterFlowTheme.of(context).bodyLarge.fontWeight,
//                           fontStyle:
//                               FlutterFlowTheme.of(context).bodyLarge.fontStyle,
//                         ),
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     enableActiveFill: false,
//                     autoFocus: true,
//                     focusNode: _model.pinCodeFocusNode,
//                     enablePinAutofill: false,
//                     errorTextSpace: 16.0,
//                     showCursor: true,
//                     cursorColor: FlutterFlowTheme.of(context).primary,
//                     obscureText: false,
//                     hintCharacter: '●',
//                     keyboardType: TextInputType.number,
//                     pinTheme: PinTheme(
//                       fieldHeight: 44.0,
//                       fieldWidth: 44.0,
//                       borderWidth: 2.0,
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(12.0),
//                         bottomRight: Radius.circular(12.0),
//                         topLeft: Radius.circular(12.0),
//                         topRight: Radius.circular(12.0),
//                       ),
//                       shape: PinCodeFieldShape.box,
//                       activeColor: FlutterFlowTheme.of(context).primaryText,
//                       inactiveColor: FlutterFlowTheme.of(context).alternate,
//                       selectedColor: FlutterFlowTheme.of(context).primary,
//                     ),
//                     controller: _model.pinCodeController,
//                     onChanged: (_) {},
//                     autovalidateMode: AutovalidateMode.onUserInteraction,
//                     validator:
//                         _model.pinCodeControllerValidator.asValidator(context),
//                   ),
//                   Row(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       Align(
//                         alignment: AlignmentDirectional(0.0, 0.0),
//                         child: FFButtonWidget(
//                           onPressed: () {
//                             print('Button pressed ...');
//                           },
//                           text: FFLocalizations.of(context).getText(
//                             'f9214evl' /* RESEND OTP */,
//                           ),
//                           options: FFButtonOptions(
//                             height: 40.0,
//                             padding: EdgeInsetsDirectional.fromSTEB(
//                                 16.0, 0.0, 16.0, 0.0),
//                             iconPadding: EdgeInsetsDirectional.fromSTEB(
//                                 0.0, 0.0, 0.0, 0.0),
//                             color: FlutterFlowTheme.of(context).alternate,
//                             textStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .override(
//                                   font: GoogleFonts.inter(
//                                     fontWeight: FontWeight.normal,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                                   color:
//                                       FlutterFlowTheme.of(context).primaryText,
//                                   fontSize: 14.0,
//                                   letterSpacing: 0.0,
//                                   fontWeight: FontWeight.normal,
//                                   fontStyle: FlutterFlowTheme.of(context)
//                                       .bodyMedium
//                                       .fontStyle,
//                                 ),
//                             elevation: 0.0,
//                             borderRadius: BorderRadius.circular(20.0),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   FFButtonWidget(
//                     onPressed: () async {
//                       GoRouter.of(context).prepareAuthEvent();
//                       final smsCodeVal = _model.pinCodeController!.text;
//                       if (smsCodeVal.isEmpty) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text('Enter SMS verification code.'),
//                           ),
//                         );
//                         return;
//                       }
//                       final phoneVerifiedUser = await authManager.verifySmsCode(
//                         context: context,
//                         smsCode: smsCodeVal,
//                       );
//                       if (phoneVerifiedUser == null) {
//                         return;
//                       }

//                       _model.apiResultx4u = await LoginCall.call(
//                         mobile: widget.mobile,
//                         fcmToken: fcm_token,
//                       );

//                       if ((_model.apiResultx4u?.succeeded ?? true)) {
//                         context.pushNamedAuth(
//                             HomeWidget.routeName, context.mounted);

//                         FFAppState().accessToken = getJsonField(
//                           (_model.apiResultx4u?.jsonBody ?? ''),
//                           r'''$.data.accessToken''',
//                         ).toString();
//                         FFAppState().userid = getJsonField(
//                           (_model.apiResultx4u?.jsonBody ?? ''),
//                           r'''$.data.user.id''',
//                         );
//                         safeSetState(() {});
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Register You Dont Have Account',
//                               style: TextStyle(
//                                 color: FlutterFlowTheme.of(context).primaryText,
//                               ),
//                             ),
//                             duration: Duration(milliseconds: 4000),
//                             backgroundColor:
//                                 FlutterFlowTheme.of(context).secondary,
//                           ),
//                         );

//                         context.pushNamedAuth(
//                           DetailspageWidget.routeName,
//                           context.mounted,
//                           queryParameters: {
//                             'mobile': serializeParam(
//                               widget.mobile,
//                               ParamType.int,
//                             ),
//                           }.withoutNulls,
//                         );
//                       }

//                       safeSetState(() {});
//                     },
//                     text: FFLocalizations.of(context).getText(
//                       'k9o36d8i' /* VERIFY */,
//                     ),
//                     options: FFButtonOptions(
//                       width: double.infinity,
//                       height: 56.0,
//                       padding: EdgeInsets.all(8.0),
//                       iconPadding:
//                           EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
//                       color: Color(0xFFFF7B10),
//                       textStyle:
//                           FlutterFlowTheme.of(context).titleMedium.override(
//                                 font: GoogleFonts.interTight(
//                                   fontWeight: FontWeight.normal,
//                                   fontStyle: FlutterFlowTheme.of(context)
//                                       .titleMedium
//                                       .fontStyle,
//                                 ),
//                                 color: FlutterFlowTheme.of(context)
//                                     .secondaryBackground,
//                                 fontSize: 24.0,
//                                 letterSpacing: 0.0,
//                                 fontWeight: FontWeight.normal,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .titleMedium
//                                     .fontStyle,
//                               ),
//                       elevation: 0.0,
//                       borderRadius: BorderRadius.circular(12.0),
//                     ),
//                   ),
//                 ]
//                     .divide(SizedBox(height: 32.0))
//                     .addToStart(SizedBox(height: 60.0)),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
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
    fcm_token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM TOKEN: $fcm_token');
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResendOtp = false;

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 30,
            buttonSize: 60,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Verification',
            style: FlutterFlowTheme.of(context).headlineMedium.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Text(
                    'Enter the OTP to continue.',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).headlineMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "We've sent you a 6-digit code",
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    autoFocus: true,
                    keyboardType: TextInputType.number,
                    controller: _model.pinCodeController,
                    focusNode: _model.pinCodeFocusNode,
                    onChanged: (_) {},
                    validator:
                    _model.pinCodeControllerValidator.asValidator(context),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 44,
                      fieldWidth: 44,
                      activeColor: FlutterFlowTheme.of(context).primaryText,
                      inactiveColor: FlutterFlowTheme.of(context).alternate,
                      selectedColor: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FFButtonWidget(
                      onPressed: _canResendOtp
                          ? () async {
                        try {
                          await authManager.beginPhoneAuth(
                            context: context,
                            phoneNumber: widget.mobile.toString(),
                            onCodeSent: (context) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                  Text('OTP resent successfully'),
                                ),
                              );
                            },
                          );

                          _startResendTimer();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                            ),
                          );
                        }
                      }
                          : null,
                      text: _canResendOtp
                          ? 'RESEND OTP'
                          : 'Resend in $_resendSeconds s',
                      options: FFButtonOptions(
                        height: 40,
                        color: _canResendOtp
                            ? FlutterFlowTheme.of(context).alternate
                            : Colors.grey.shade300,
                        textStyle:
                        FlutterFlowTheme.of(context).bodyMedium.copyWith(
                          color: _canResendOtp
                              ? FlutterFlowTheme.of(context).primaryText
                              : Colors.grey,
                        ),
                        elevation: 0,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  FFButtonWidget(
                    onPressed: () async {
                      GoRouter.of(context).prepareAuthEvent();

                      final smsCode = _model.pinCodeController!.text;

                      if (smsCode.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter SMS verification code'),
                          ),
                        );
                        return;
                      }

                      final user = await authManager.verifySmsCode(
                        context: context,
                        smsCode: smsCode,
                      );

                      if (user == null) return;

                      _model.apiResultx4u = await LoginCall.call(
                        mobile: widget.mobile,
                        fcmToken: fcm_token,
                      );

                      if (_model.apiResultx4u?.succeeded ?? true) {
                        FFAppState().accessToken = getJsonField(
                          _model.apiResultx4u!.jsonBody,
                          r'$.data.accessToken',
                        ).toString();

                        FFAppState().userid = getJsonField(
                          _model.apiResultx4u!.jsonBody,
                          r'$.data.user.id',
                        );

                        context.pushNamedAuth(
                          HomeWidget.routeName,
                          context.mounted,
                        );
                      } else {
                        context.pushNamedAuth(
                          DetailspageWidget.routeName,
                          context.mounted,
                          queryParameters: {
                            'mobile': widget.mobile!.toString(),
                          },
                        );
                      }
                    },
                    text: 'VERIFY',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56,
                      color: const Color(0xFFFF7B10),
                      textStyle:
                      FlutterFlowTheme.of(context).titleMedium.copyWith(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ].divide(const SizedBox(height: 32)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}