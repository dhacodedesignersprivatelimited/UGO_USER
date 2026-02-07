import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'support_model.dart';
export 'support_model.dart';

class SupportWidget extends StatefulWidget {
  const SupportWidget({super.key});

  static String routeName = 'support';
  static String routePath = '/support';

  @override
  State<SupportWidget> createState() => _SupportWidgetState();
}

class _SupportWidgetState extends State<SupportWidget> {
  late SupportModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Company Details
  final String supportNumber = "+919100088718";
  final String supportEmail = "info@ugotaxi.com";
  final String websiteUrl = "https://ugotaxiservices.com";

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // --- ACTION HELPERS ---

  Future<void> _makePhoneCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: supportNumber);
    if (!await launchUrl(launchUri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
      );
    }
  }

  Future<void> _sendEmail() async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Support Request&body=Hi UGO Team,',
    );
    if (!await launchUrl(launchUri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email app')),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    // Remove '+' for WhatsApp URL scheme if present, but keep country code
    String cleanNumber = supportNumber.replaceAll('+', '');
    final Uri launchUri = Uri.parse("https://wa.me/$cleanNumber");

    if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  Future<void> _openWebsite() async {
    final Uri launchUri = Uri.parse(websiteUrl);
    if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch website')),
      );
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10), // Vibrant Orange
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Support Center',
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hero Image / Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: Color(0xFFFF7B10),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Heading
                  Text(
                    'We are here to help!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtext
                  Text(
                    '24/7 Customer support will be available soon. Please contact the company directly for any queries or details.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Contact Cards
                  _buildContactCard(
                    icon: Icons.phone_rounded,
                    title: 'Call Us',
                    subtitle: supportNumber,
                    color: Colors.blue,
                    onTap: _makePhoneCall,
                  ),
                  const SizedBox(height: 16),

                  _buildContactCard(
                    icon: FontAwesomeIcons.whatsapp,
                    title: 'WhatsApp Us',
                    subtitle: 'Chat with support',
                    color: const Color(0xFF25D366),
                    onTap: _openWhatsApp,
                  ),
                  const SizedBox(height: 16),

                  _buildContactCard(
                    icon: Icons.email_rounded,
                    title: 'Email Us',
                    subtitle: supportEmail,
                    color: const Color(0xFFEA4335),
                    onTap: _sendEmail,
                  ),
                  const SizedBox(height: 16),

                  _buildContactCard(
                    icon: Icons.language_rounded,
                    title: 'Visit Website',
                    subtitle: 'ugotaxiservices.com',
                    color: const Color(0xFF9C27B0),
                    onTap: _openWebsite,
                  ),

                  const SizedBox(height: 40),

                  // Footer
                  Text(
                    'UGO Taxi Services',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
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

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }
}