import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'refer_and_earn_model.dart';
export 'refer_and_earn_model.dart';

class ReferAndEarnWidget extends StatefulWidget {
  const ReferAndEarnWidget({super.key});

  static String routeName = 'ReferAndEarn';
  static String routePath = '/referAndEarn';

  @override
  State<ReferAndEarnWidget> createState() => _ReferAndEarnWidgetState();
}

class _ReferAndEarnWidgetState extends State<ReferAndEarnWidget> {
  late ReferAndEarnModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  String _referralCode = '';
  int _totalReferrals = 0;
  double _totalEarned = 0.0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReferAndEarnModel());
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;
    
    if (userId != null && token != null && token.isNotEmpty) {
      _model.referralStats = await GetUserReferralStatsCall.call(
        userId: userId,
        token: token,
      );
      
      if (_model.referralStats?.succeeded ?? false) {
        if (mounted) {
          setState(() {
            _referralCode = GetUserReferralStatsCall.referralCode(_model.referralStats?.jsonBody)?.toString() ?? '';
            _totalReferrals = GetUserReferralStatsCall.totalReferrals(_model.referralStats?.jsonBody) ?? 0;
            _totalEarned = (GetUserReferralStatsCall.totalEarned(_model.referralStats?.jsonBody) ?? 0).toDouble();
            _isLoading = false;
          });
        }
        return;
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            'Refer & Earn',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10)))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Icon(Icons.card_giftcard, size: 100, color: const Color(0xFFFF7B10)),
                    const SizedBox(height: 24),
                    Text(
                      'Invite Friends & Earn!',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Share your referral code with friends. When they complete a Pro Ride, you earn a commission!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF7B10).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'YOUR REFERRAL CODE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF7B10),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _referralCode.isEmpty ? 'LOADING...' : _referralCode,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FFButtonWidget(
                      onPressed: () {
                        if (_referralCode.isNotEmpty) {
                          Share.share('Join UGO built for Pro Rides! Use my code: $_referralCode to sign up.');
                        }
                      },
                      text: 'Share Code',
                      icon: const Icon(Icons.share, size: 20),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 56,
                        color: const Color(0xFFFF7B10),
                        textStyle: GoogleFonts.interTight(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBox('Friends Referred', _totalReferrals.toString()),
                        _buildStatBox('Total Earned', '\$${_totalEarned.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.interTight(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF7B10),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
