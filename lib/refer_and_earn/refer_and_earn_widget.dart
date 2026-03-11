import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  int _successfulConversions = 0;
  double _coinsEarned = 0.0;
  double _moneyEarned = 0.0;
  List<dynamic> _referralHistory = [];

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
      // 1. Get Status (Code, Total, Conversions, Coins)
      final statusResp = await GetReferralStatusCall.call(userId: userId, token: token);
      
      // 2. Get Earnings (Money, Coins)
      final earningsResp = await GetReferralEarningsCall.call(userId: userId, token: token);

      // 3. Get History
      final historyResp = await GetReferralHistoryCall.call(userId: userId, token: token);
      
      if (mounted) {
        setState(() {
          if (statusResp.succeeded) {
            _referralCode = GetReferralStatusCall.referralCode(statusResp.jsonBody) ?? '';
            _totalReferrals = GetReferralStatusCall.totalReferrals(statusResp.jsonBody) ?? 0;
            _successfulConversions = GetReferralStatusCall.successfulConversions(statusResp.jsonBody) ?? 0;
            _coinsEarned = (GetReferralStatusCall.coinsEarned(statusResp.jsonBody) ?? 0).toDouble();
          }

          if (earningsResp.succeeded) {
            _moneyEarned = (GetReferralEarningsCall.moneyEarned(earningsResp.jsonBody) ?? 0).toDouble();
          }

          if (historyResp.succeeded) {
            _referralHistory = GetReferralHistoryCall.history(historyResp.jsonBody) ?? [];
          }
          
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateCode() async {
    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;
    if (userId == null) return;

    setState(() => _isLoading = true);
    final resp = await GenerateReferralCodeCall.call(userId: userId, token: token);
    if (resp.succeeded) {
      await _fetchStats();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate referral code')),
      );
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
        backgroundColor: Colors.grey[50],
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
            : RefreshIndicator(
                onRefresh: _fetchStats,
                color: const Color(0xFFFF7B10),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header Section with Welcome & Main Illustration
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7B10),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        child: Column(
                          children: [
                            const Icon(Icons.card_giftcard, size: 70, color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              'Share UGO, Reap Rewards!',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Invite friends and earn money & coins when they ride with UGO.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Referral Code Card
                            Center(
                              child: _referralCode.isEmpty 
                                ? FFButtonWidget(
                                    onPressed: _generateCode,
                                    text: 'Generate My Referral Code',
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 56,
                                      color: const Color(0xFFFF7B10),
                                      textStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                      border: Border.all(color: Colors.orange.shade50),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'YOUR UNIQUE CODE',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[500],
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(width: 48), // Spacer for centering
                                            SelectableText(
                                              _referralCode,
                                              style: GoogleFonts.inter(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black87,
                                                letterSpacing: 3,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 20, color: Color(0xFFFF7B10)),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: _referralCode));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Code copied to clipboard!'), duration: Duration(seconds: 1)),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        FFButtonWidget(
                                          onPressed: () {
                                            Share.share('Join UGO built for Pro Rides! Use my code: $_referralCode to sign up.');
                                          },
                                          text: 'Share via Invitation',
                                          icon: const Icon(Icons.share_outlined, size: 20),
                                          options: FFButtonOptions(
                                            width: double.infinity,
                                            height: 50,
                                            color: const Color(0xFFFF7B10),
                                            textStyle: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),

                            const SizedBox(height: 32),
                            // How it Works Guide
                            Text(
                              'How it Works',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            _buildStepItem(Icons.send_rounded, 'First Step', 'Invite your friends by sharing your unique code.'),
                            _buildStepItem(Icons.app_registration_rounded, 'Then', 'Your friends sign up using your referral code.'),
                            _buildStepItem(Icons.stars_rounded, 'Finally', 'You both receive rewards after their first completed ride!'),

                            const SizedBox(height: 32),
                            // Stats Grid
                            Text(
                              'Your Impact',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.4,
                              children: [
                                _buildStatBox('Total Referred', _totalReferrals.toString(), Icons.people_alt_rounded),
                                _buildStatBox('Conversions', _successfulConversions.toString(), Icons.verified_rounded),
                                _buildStatBox('Money Earned', '\$${_moneyEarned.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded),
                                _buildStatBox('Coins Earned', _coinsEarned.toStringAsFixed(0), Icons.monetization_on_rounded),
                              ],
                            ),

                            const SizedBox(height: 32),
                            // History Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Referral History',
                                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                if (_referralHistory.isNotEmpty)
                                  Text(
                                    '${_referralHistory.length} total',
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _referralHistory.isEmpty
                              ? _buildEmptyHistory()
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _referralHistory.length,
                                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                                    itemBuilder: (context, index) {
                                      final item = _referralHistory[index];
                                      final status = item['status']?.toString().toLowerCase() ?? 'pending';
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.orange[50],
                                          child: Icon(Icons.person_rounded, color: const Color(0xFFFF7B10)),
                                        ),
                                        title: Text(
                                          item['referred_user_name'] ?? 'UGO Explorer',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            item['date_referred'] != null 
                                              ? DateFormat('MMM dd, yyyy').format(DateTime.parse(item['date_referred']))
                                              : 'Recently joined',
                                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                                          ),
                                        ),
                                        trailing: _buildStatusBadge(status),
                                      );
                                    },
                                  ),
                                ),
                            const SizedBox(height: 40),
                          ],
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

  Widget _buildStepItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7B10).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFFF7B10)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: const Color(0xFFFF7B10)),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    if (status == 'completed' || status == 'success') {
      color = Colors.green;
      label = 'COMPLETED';
    } else if (status == 'failed' || status == 'cancelled') {
      color = Colors.red;
      label = 'CANCELLED';
    } else {
      color = Colors.orange;
      label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No referrals yet',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your code to see history here!',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
