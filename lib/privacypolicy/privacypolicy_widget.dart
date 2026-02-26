import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'privacypolicy_model.dart';
export 'privacypolicy_model.dart';

class PrivacypolicyWidget extends StatefulWidget {
  const PrivacypolicyWidget({super.key});

  static String routeName = 'privacypolicy';
  static String routePath = '/privacypolicy';

  @override
  State<PrivacypolicyWidget> createState() => _PrivacypolicyWidgetState();
}

class _PrivacypolicyWidgetState extends State<PrivacypolicyWidget> {
  late PrivacypolicyModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PrivacypolicyModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7B10),
        automaticallyImplyLeading: true,
        title: Text(
          'Privacy Policy',
          style: FlutterFlowTheme.of(context).headlineMedium.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Introduction'),
                      _buildBodyText(
                          'Welcome to Ugo User. We value your privacy and are committed to protecting your personal data. This policy explains how we handle your information when you use our taxi booking services.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('2. Data Collection'),
                      _buildBodyText(
                          'We collect information you provide directly, such as your name, phone number, and email. We also collect automated data including device info and app usage statistics.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('3. Location Usage'),
                      _buildBodyText(
                          'Ugo User collects precise location data to facilitate ride requests, matching riders with nearby drivers, and providing navigation for the trip. This data is collected even when the app is in the background if a trip is active.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('4. Third-Party Services'),
                      _buildBodyText(
                          'We use third-party services like Google Maps for location and Firebase for authentication and analytics. These services have their own privacy policies.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('5. Security'),
                      _buildBodyText(
                          'We implement industry-standard security measures to protect your data from unauthorized access or disclosure.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('6. Your Rights'),
                      _buildBodyText(
                          'You have the right to access, update, or delete your personal information at any time through the account settings in the app.'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Checkbox(
                    value: _model.checkboxValue ??= false,
                    onChanged: (val) => setState(() => _model.checkboxValue = val),
                    activeColor: const Color(0xFFFF7B10),
                  ),
                  Expanded(
                    child: _buildBodyText('I have read and agree to the Privacy Policy and Terms of Service.'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FFButtonWidget(
                onPressed: (_model.checkboxValue ?? false) 
                  ? () => context.pop() 
                  : null,
                text: 'Accept & Continue',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 56,
                  color: const Color(0xFFFF7B10),
                  textStyle: FlutterFlowTheme.of(context).titleMedium.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                  disabledColor: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.black54,
        height: 1.5,
      ),
    );
  }
}
