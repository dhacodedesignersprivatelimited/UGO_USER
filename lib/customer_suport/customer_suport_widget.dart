import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../backend/api_requests/api_calls.dart';
import 'customer_suport_model.dart';
export 'customer_suport_model.dart';
import 'ai_chat_widget.dart';

class CustomerSuportWidget extends StatefulWidget {
  const CustomerSuportWidget({super.key});

  static String routeName = 'Customer_suport';
  static String routePath = '/customerSuport';

  @override
  State<CustomerSuportWidget> createState() => _CustomerSuportWidgetState();
}

class _CustomerSuportWidgetState extends State<CustomerSuportWidget> {
  late CustomerSuportModel _model;
  String userName = '';
  bool _isLoading = true;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerSuportModel());
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final appState = FFAppState();
    try {
      final response = await GetUserDetailsCall.call(
        userId: appState.userid,
        token: appState.accessToken,
      );
      if (response.succeeded) {
        setState(() {
          userName = GetUserDetailsCall.firstName(response.jsonBody) ?? 'User';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA), // Cleaner, brighter background
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28.0),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Support Center',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10)))
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vibrant Header Greeting
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi $userName,',
                      style: GoogleFonts.interTight(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How can we help\nyou today?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Transformative AI Button (Hero Element)
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiChatWidget()),
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7B10), Color(0xFFFF9F4D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7B10).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ask UGO AI',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Instant smart resolutions',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Quick Help Topics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Topics',
                      style: GoogleFonts.interTight(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHelpTile(Icons.local_taxi_rounded, 'Safety & Driver Feedback'),
                    _buildHelpTile(Icons.receipt_long_rounded, 'Payment & Refunds'),
                    _buildHelpTile(Icons.luggage_rounded, 'I lost an item'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: FlutterFlowTheme.of(context).primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF333333)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          // You can navigate directly to the AI chat and auto-send this as a prompt!
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatWidget()), // In the future, pass initialMsg: title
          );
        },
      ),
    );
  }
}