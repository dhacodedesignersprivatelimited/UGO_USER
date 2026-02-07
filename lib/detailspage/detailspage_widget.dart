import 'dart:async';
import 'dart:typed_data';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ Add this
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
  String? _currentFcmToken; // ✅ Store FCM token here

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailspageModel());

    // ✅ Generate FCM token immediately
    _initFCMToken();
  }

  // ✅ FCM Token Generation (handles null case)
  Future<void> _initFCMToken() async {
    try {
      // First try to use passed token
      if (widget.fcmToken != null && widget.fcmToken!.isNotEmpty) {
        _currentFcmToken = widget.fcmToken;
        print('✅ Using passed FCM Token: $_currentFcmToken');
        return;
      }

      // Otherwise generate new one
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        setState(() => _currentFcmToken = token);
        print('✅ FCM Token generated: $token');
      } else {
        print('⚠️ FCM Token is null - retrying in 2s...');
        // Retry after 2 seconds
        Timer(const Duration(seconds: 2), () => _initFCMToken());
      }
    } catch (e) {
      print('❌ FCM Token Error: $e');
      // Set default token to avoid backend error
      setState(() => _currentFcmToken = 'temp_token_${widget.mobile}');
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      _model.uploadedLocalFile = FFUploadedFile(
        bytes: bytes,
        name: 'profile_${widget.mobile}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      setState(() => _imageBytes = bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo selected'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
            onPressed: () => context.pop(),
          ),
          title: Text('Complete Profile', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile Photo Picker
                  GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                          child: _imageBytes == null
                              ? const Icon(Icons.person_add, size: 50, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(color: Color(0xFFFF7B10), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _imageBytes != null ? null : _pickProfilePhoto,
                    child: Text(
                      _imageBytes != null ? '✅ Photo ready' : 'Add profile photo (optional)',
                      style: TextStyle(color: _imageBytes != null ? Colors.green : const Color(0xFFFF7B10), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // First Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('First name *', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _model.textController1,
                          focusNode: _model.textFieldFocusNode1,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFFF7B10), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            hintText: 'Enter first name',
                          ),
                          style: GoogleFonts.inter(fontSize: 16),
                          validator: _model.textController1Validator?.asValidator(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Last Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last name (optional)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _model.textController2,
                          focusNode: _model.textFieldFocusNode2,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFFF7B10), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            hintText: 'Enter last name',
                          ),
                          style: GoogleFonts.inter(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Email *', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _model.textController3,
                          focusNode: _model.textFieldFocusNode3,
                          autofocus: false,
                          obscureText: false,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFFF7B10), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.red),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            hintText: 'Enter email',
                          ),
                          style: GoogleFonts.inter(fontSize: 16),
                          keyboardType: TextInputType.emailAddress,
                          validator: _model.textController3Validator?.asValidator(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Register Button
                  FFButtonWidget(
                    onPressed: (_model.isRegistering || _currentFcmToken == null) ? null : () async {
                      final validationError = _model.validateForm();
                      if (validationError != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(validationError), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      // ✅ Check FCM token before proceeding
                      if (_currentFcmToken == null || _currentFcmToken!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Waiting for notification setup... Please try again in a moment.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        // Retry FCM token generation
                        _initFCMToken();
                        return;
                      }

                      _model.isRegistering = true;

                      try {
                        print('🔵 Registering with FCM Token: $_currentFcmToken'); // Debug log

                        _model.apiResultRegister = await CreateUserCall.call(
                          mobileNumber: widget.mobile,
                          firstName: _model.firstName,
                          lastName: _model.lastName,
                          email: _model.email,
                          profileImage: (_model.uploadedLocalFile.bytes?.isNotEmpty ?? false)
                              ? _model.uploadedLocalFile
                              : null,
                          fcmToken: _currentFcmToken!, // ✅ Use generated token
                        );

                        print('API RESPONSE: ${_model.apiResultRegister?.jsonBody}'); // Debug log

                        if ((_model.apiResultRegister?.succeeded ?? false) && mounted) {
                          FFAppState().accessToken = LoginCall.accesToken(_model.apiResultRegister?.jsonBody) ?? '';
                          FFAppState().userid = LoginCall.userid(_model.apiResultRegister?.jsonBody) ?? 0;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Welcome to UGO!'), backgroundColor: Colors.green),
                          );
                          context.goNamedAuth('Home', mounted);
                        } else if (mounted) {
                          final errorMsg = getJsonField(_model.apiResultRegister?.jsonBody ?? '', r'''$.message''') ?? 'Registration failed';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg.toString()), backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (mounted) {
                          _model.isRegistering = false;
                        }
                      }
                    },
                    text: _model.isRegistering ? 'CREATING...' :
                    _currentFcmToken == null ? 'LOADING...' : 'Complete Registration',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56,
                      color: const Color(0xFFFF7B10),
                      textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Inter Tight',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
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
}
