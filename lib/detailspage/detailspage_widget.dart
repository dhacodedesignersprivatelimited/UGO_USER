import 'dart:async';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('First Name is required'),
          backgroundColor: Colors.red));
      return;
    }
    if (_model.textController3!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email is required'), backgroundColor: Colors.red));
      return;
    }

    // 2. Check Token
    if (_currentFcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Initializing... please wait'),
          backgroundColor: Colors.orange));
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
        profileImage: _model.uploadedLocalFile.bytes != null
            ? _model.uploadedLocalFile
            : null,
        fcmToken: _currentFcmToken,
      );

      if (!mounted) return;

      if (_model.apiResultRegister?.succeeded ?? false) {
        // 5. Success - Save Session
        print('✅ Registration Successful. Saving session...');
        final token = LoginCall.accesToken(_model.apiResultRegister?.jsonBody);
        final userId = LoginCall.userid(_model.apiResultRegister?.jsonBody);

        if (token != null) FFAppState().accessToken = token;
        if (userId != null) FFAppState().userid = userId;

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Welcome to UGO!'), backgroundColor: Colors.green));

        // 6. Navigate to Home
        print('🚀 Navigating to Home...');
        context.goNamedAuth('Home', mounted);
      } else {
        final errorMsg = getJsonField(
                _model.apiResultRegister?.jsonBody, r'''$.message''') ??
            'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMsg.toString()), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
            onPressed: () => context.pop(),
          ),
          title: Text('Complete Profile',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
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
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!)
                              : null,
                          child: _imageBytes == null
                              ? const Icon(Icons.person_add,
                                  size: 50, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                                color: Color(0xFFFF7B10),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _imageBytes != null ? 'Photo selected' : 'Tap to add photo',
                    style: TextStyle(
                        color: _imageBytes != null
                            ? Colors.green
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField("First name *", _model.textController1,
                      _model.textFieldFocusNode1),
                  const SizedBox(height: 20),
                  _buildTextField("Last name", _model.textController2,
                      _model.textFieldFocusNode2),
                  const SizedBox(height: 20),
                  _buildTextField("Email *", _model.textController3,
                      _model.textFieldFocusNode3,
                      isEmail: true),
                  const SizedBox(height: 40),
                  FFButtonWidget(
                    onPressed:
                        (_model.isRegistering || _currentFcmToken == null)
                            ? null
                            : _handleRegistration,
                    text: _model.isRegistering
                        ? 'CREATING ACCOUNT...'
                        : 'Complete Registration',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56,
                      color: const Color(0xFFFF7B10),
                      textStyle: GoogleFonts.interTight(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      disabledColor: Colors.orange.withOpacity(0.5),
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
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.name,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xFFFF7B10), width: 2),
                borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: GoogleFonts.inter(fontSize: 16),
        ),
      ],
    );
  }
}
