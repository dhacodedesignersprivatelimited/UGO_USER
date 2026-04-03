import 'dart:async';
import '../flutter_flow/flutter_flow_theme.dart';
import '../login/login_widget.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/notifications/fcm_service.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'detailspage_model.dart';
export 'detailspage_model.dart';

class DetailspageWidget extends StatefulWidget {
  const DetailspageWidget({super.key, required this.mobile, this.fcmToken});

  final int mobile;
  final String? fcmToken;

  static String routeName = 'detailspage';
  static String routePath = '/detailspage';

  @override
  State<DetailspageWidget> createState() => _DetailspageWidgetState();
}

class _DetailspageWidgetState extends State<DetailspageWidget> {
  late DetailspageModel _model;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _currentFcmToken;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailspageModel());

    // Initialize Controllers
    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();
    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();

    _initFCMToken();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _initFCMToken() async {
    try {
      if (widget.fcmToken != null && widget.fcmToken!.isNotEmpty) {
        setState(() => _currentFcmToken = widget.fcmToken);
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        setState(() => _currentFcmToken = token);
      } else {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _generateFallbackToken();
      }
    } catch (e) {
      if (mounted) _generateFallbackToken();
    }
  }

  void _generateFallbackToken() {
    setState(() => _currentFcmToken =
        'temp_token_${widget.mobile}_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _model.uploadedLocalFile = FFUploadedFile(
          bytes: bytes,
          name: 'profile_${widget.mobile}.jpg',
        );
      });
    } catch (e) {
      print('Image picker error: $e');
    }
  }

  Future<void> _handleRegistration() async {
    // 1. Validate
    if (_model.textController1!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(FFLocalizations.of(context).getText('first_name_required')),
          backgroundColor: FlutterFlowTheme.of(context).error));
      return;
    }
    if (_model.textController3!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(FFLocalizations.of(context).getText('email_required')),
          backgroundColor: FlutterFlowTheme.of(context).error));
      return;
    }

    // 2. Check Token
    if (_currentFcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(FFLocalizations.of(context).getText('initializing_wait')),
          backgroundColor: FlutterFlowTheme.of(context).warning));
      await _initFCMToken();
      return;
    }

    // 3. Start Loading
    setState(() => _model.isRegistering = true);

    try {
      // 4. API Call
      _model.apiResultRegister = await CreateUserCall.call(
        mobileNumber: widget.mobile,
        firstName: _model.textController1!.text,
        lastName: _model.textController2!.text,
        email: _model.textController3!.text,
        referralCode: _model.textController4!.text,
        profileImage: _model.uploadedLocalFile.bytes != null
            ? _model.uploadedLocalFile
            : null,
        fcmToken: _currentFcmToken,
      );

      if (!mounted) return;

      if (_model.apiResultRegister?.succeeded ?? false) {
        // 5. Success - Save Session
        print('✅ Registration Successful. Saving session...');
        final token =
            CreateUserCall.accessToken(_model.apiResultRegister?.jsonBody);
        final refreshToken =
            CreateUserCall.refreshToken(_model.apiResultRegister?.jsonBody);
        final userId =
            CreateUserCall.userid(_model.apiResultRegister?.jsonBody);

        if (token != null) FFAppState().accessToken = token;
        if (refreshToken != null && refreshToken.isNotEmpty) {
          FFAppState().refreshToken = refreshToken;
        }
        if (userId != null) FFAppState().userid = userId;
        syncRideChatFcmRegistration();

        // --- AUTO-GENERATE REFERRAL CODE ---
        try {
          print('🎁 Auto-generating referral code for user $userId...');
          await GenerateReferralCodeCall.call(userId: userId!, token: token);
          print('✅ Referral code generated.');
        } catch (e) {
          print('⚠️ Failed to auto-generate referral code: $e');
        }
        // ------------------------------------

        // --- APPLY REFERRAL CODE (IF ENTERED) ---
        final starterCode = _model.textController4!.text.trim();
        if (starterCode.isNotEmpty) {
          try {
            print(
                '🔗 Applying referral code: $starterCode for user $userId...');
            await ApplyReferralCodeCall.call(
              userId: userId!,
              referralCode: starterCode,
              token: token,
            );
            print('✅ Referral code applied.');
          } catch (e) {
            print('⚠️ Failed to apply referral code: $e');
          }
        }
        // ----------------------------------------

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(FFLocalizations.of(context).getText('welcome_to_ugo')),
            backgroundColor: FlutterFlowTheme.of(context).success));

        // 6. Navigate to Home
        print('🚀 Navigating to Home...');
        context.goNamedAuth('home', mounted);
      } else {
        final errorMsg = (getJsonField(
                    _model.apiResultRegister?.jsonBody, r'''$.message''') ??
                'Registration failed')
            .toString()
            .toLowerCase();

        // Handle "Mobile number already exists" - user is registered, try login
        if (errorMsg.contains('already exists') ||
            errorMsg.contains('mobile number already exists')) {
          final loginRes = await LoginCall.call(
            mobile: widget.mobile,
            fcmToken: _currentFcmToken ?? '',
          );
          if (!mounted) return;
          if (loginRes.succeeded) {
            final token = LoginCall.accessToken(loginRes.jsonBody);
            final refreshToken = LoginCall.refreshToken(loginRes.jsonBody);
            final userId = LoginCall.userid(loginRes.jsonBody);
            if (token != null) FFAppState().accessToken = token;
            if (refreshToken != null && refreshToken.isNotEmpty) {
              FFAppState().refreshToken = refreshToken;
            }
            if (userId != null) FFAppState().userid = userId;
            syncRideChatFcmRegistration();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    FFLocalizations.of(context).getText('login_welcome_back')),
                backgroundColor: FlutterFlowTheme.of(context).success));
            context.goNamedAuth('home', mounted);
            return;
          }
        }

        final displayMsg = getJsonField(
                _model.apiResultRegister?.jsonBody, r'''$.message''') ??
            'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(displayMsg.toString()),
            backgroundColor: FlutterFlowTheme.of(context).error));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error));
      }
    } finally {
      if (mounted) setState(() => _model.isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: FlutterFlowTheme.of(context).secondaryText),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.goNamedAuth(LoginWidget.routeName, context.mounted);
              }
            },
          ),
          title: Text(FFLocalizations.of(context).getText('complete_profile'),
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FlutterFlowTheme.of(context).primaryText)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor:
                              FlutterFlowTheme.of(context).primaryBackground,
                          backgroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!)
                              : null,
                          child: _imageBytes == null
                              ? Icon(Icons.person_add,
                                  size: 50,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText)
                              : null,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary,
                                shape: BoxShape.circle),
                            child: Icon(Icons.camera_alt,
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _imageBytes != null
                        ? FFLocalizations.of(context).getText('photo_selected')
                        : FFLocalizations.of(context)
                            .getText('tap_to_add_photo'),
                    style: TextStyle(
                        color: _imageBytes != null
                            ? FlutterFlowTheme.of(context).success
                            : FlutterFlowTheme.of(context).secondaryText,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                      FFLocalizations.of(context).getText('first_name_label'),
                      _model.textController1,
                      _model.textFieldFocusNode1),
                  const SizedBox(height: 20),
                  _buildTextField(
                      FFLocalizations.of(context).getText('last_name_label'),
                      _model.textController2,
                      _model.textFieldFocusNode2),
                  const SizedBox(height: 20),
                  _buildTextField(
                      FFLocalizations.of(context).getText('email_label'),
                      _model.textController3,
                      _model.textFieldFocusNode3,
                      isEmail: true),
                  const SizedBox(height: 20),
                  _buildTextField(
                      FFLocalizations.of(context)
                          .getText('referral_code_optional'),
                      _model.textController4,
                      _model.textFieldFocusNode4),
                  const SizedBox(height: 40),
                  FFButtonWidget(
                    onPressed:
                        (_model.isRegistering || _currentFcmToken == null)
                            ? null
                            : _handleRegistration,
                    text: _model.isRegistering
                        ? FFLocalizations.of(context)
                            .getText('creating_account')
                        : FFLocalizations.of(context)
                            .getText('complete_registration'),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56,
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle: GoogleFonts.interTight(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      disabledColor: FlutterFlowTheme.of(context)
                          .primary
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController? controller, FocusNode? focusNode,
      {bool isEmail = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: FlutterFlowTheme.of(context).primaryText)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.name,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).alternate, width: 1),
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).primary, width: 2),
                borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: GoogleFonts.inter(fontSize: 16),
        ),
      ],
    );
  }
}
