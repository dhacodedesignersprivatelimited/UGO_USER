import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for custom auth
import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    authManager.handlePhoneAuthStateChanges(context);
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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30.0),
            onPressed: () => context.pop(),
          ),
          title: Text(
            FFLocalizations.of(context).getText('mc86snxk'),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              fontFamily: 'InterTight',
              color: Colors.white,
              fontSize: 22.0,
            ),
          ),
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Text
                  Text(
                    FFLocalizations.of(context).getText('0wqdgogt'),
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'InterTight',
                      color: Colors.black,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w600,
                      lineHeight: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                    child: Text(
                      FFLocalizations.of(context).getText('lu0ku0g6'),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.black,
                        fontSize: 16.0,
                        lineHeight: 1.5,
                      ),
                    ),
                  ),

                  // Phone Number Input
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FFLocalizations.of(context).getText('kd9srmop'),
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                        child: Container(
                          width: double.infinity,
                          child: TextFormField(
                            controller: _model.textController,
                            focusNode: _model.textFieldFocusNode,
                            autofocus: false,
                            textInputAction: TextInputAction.send,
                            obscureText: false,
                            decoration: InputDecoration(
                              hintText: FFLocalizations.of(context).getText('398um26d'),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xC7000000), width: 2.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFFFF7B10), width: 2.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0x00000000), width: 2.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0x00000000), width: 2.0),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                              contentPadding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium.override(color: Colors.black),
                            keyboardType: TextInputType.phone,
                            cursorColor: const Color(0x00FF7B10),
                            validator: _model.textControllerValidator?.asValidator(context),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
                          ),
                        ),
                      ),
                    ].divide(const SizedBox(height: 16.0)),
                  ),

                  // Send OTP Button
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                    child: FFButtonWidget(
                      onPressed: () async {
                        final phoneNumberVal = '+91${_model.textController.text}';
                        if (phoneNumberVal.isEmpty || !phoneNumberVal.startsWith('+')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Phone Number is required and has to start with +.')),
                          );
                          return;
                        }
                        await authManager.beginPhoneAuth(
                          context: context,
                          phoneNumber: phoneNumberVal,
                          onCodeSent: (context) async {
                            context.goNamedAuth(
                              OtpverificationWidget.routeName,
                              context.mounted,
                              queryParameters: {
                                'mobile': serializeParam(int.tryParse(_model.textController.text), ParamType.int),
                              }.withoutNulls,
                              ignoreRedirect: true,
                            );
                          },
                        );
                      },
                      text: FFLocalizations.of(context).getText('m21mv0lk'),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 56.0,
                        padding: const EdgeInsets.all(8.0),
                        color: const Color(0xFFFF7B10),
                        textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'InterTight',
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          fontSize: 24.0,
                        ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                    ),
                  ),

                  // 🔥 SOCIAL LOGIN SECTION - FIXED
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 1.0,
                          decoration: const BoxDecoration(color: Color(0xFFCCCCCC)),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 16.0),
                          child: Text(
                            FFLocalizations.of(context).getText('hczr77o0'),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: Colors.black,
                              fontSize: 16.0,
                              lineHeight: 1.2,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 🟢 GOOGLE BUTTON - FIXED CENTER ALIGNMENT
                            GestureDetector(
                              onTap: () async {
                                try {
                                  GoRouter.of(context).prepareAuthEvent();
                                  final user = await authManager.signInWithGoogle(context);
                                  if (user != null && mounted) {
                                    context.goNamedAuth('HomePage', context.mounted);
                                  }
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google failed: $e')));
                                }
                              },
                              child: Container(
                                width: 50.0,
                                height: 50.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEFAFA),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: const Color(0xFFCCCCCC), width: 1.0),
                                ),
                                child: const Align(  // ✅ ADDED ALIGN FOR CENTERING
                                  alignment: AlignmentDirectional(0.0, 0.0),  // ✅ PERFECT CENTER
                                  child: FaIcon(
                                    FontAwesomeIcons.google,
                                    color: Color(0xFF4285F4),
                                    size: 25.0,
                                  ),
                                ),
                              ),
                            ),


                            const SizedBox(width: 16.0),

                            // 🔵 FACEBOOK (Using Direct FirebaseAuth)
                            GestureDetector(
                              onTap: () async {
                                try {
                                  // Direct Firebase call bypassing FlutterFlow manager
                                  final userCredential = await FirebaseAuth.instance.signInWithPopup(
                                    FacebookAuthProvider(),
                                  );
                                  if (userCredential.user != null && mounted) {
                                    context.goNamedAuth('HomePage', context.mounted);
                                  }
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Facebook failed: $e')));
                                }
                              },
                              child: Container(
                                width: 50.0,
                                height: 50.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEFAFA),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: const Color(0xFFCCCCCC), width: 1.0),
                                ),
                                child: const Icon(
                                  Icons.facebook,
                                  color: Color(0xFF1877F2),
                                  size: 25.0,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16.0),

                            // 🟤 APPLE (Using Direct FirebaseAuth)
                            GestureDetector(
                              onTap: () async {
                                try {
                                  // Direct Firebase call bypassing FlutterFlow manager
                                  final userCredential = await FirebaseAuth.instance.signInWithPopup(
                                    AppleAuthProvider(),
                                  );
                                  if (userCredential.user != null && mounted) {
                                    context.goNamedAuth('HomePage', context.mounted);
                                  }
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Apple failed: $e')));
                                }
                              },
                              child: Container(
                                width: 50.0,
                                height: 50.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEFAFA),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: const Color(0xFFCCCCCC), width: 1.0),
                                ),
                                child: const Icon(
                                  Icons.apple,
                                  color: Colors.black,
                                  size: 25.0,
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(width: 16.0)),
                        ),
                      ].divide(const SizedBox(height: 24.0)),
                    ),
                  ),
                ].divide(const SizedBox(height: 24.0)).addToStart(const SizedBox(height: 60.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
