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
      final statusResp = await GetReferralStatusCall.call(userId: userId, token: token);
      final earningsResp = await GetReferralEarningsCall.call(userId: userId, token: token);
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
      if (mounted) setState(() => _isLoading = false);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate referral code')));
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
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            'Refer and Earn',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          elevation: 0.5,
          centerTitle: false,
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
                      // Top Banner / Illustration
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7B10).withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.stars_rounded, size: 80, color: Color(0xFFFF7B10)),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Refer Friends and Earn Money',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Share your code and get rewards on their first completed ride.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Referral Code Box (Rapido style dashed border)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _referralCode.isEmpty 
                          ? Center(
                              child: FFButtonWidget(
                                onPressed: _generateCode,
                                text: 'Generate Referral Code',
                                options: FFButtonOptions(
                                  width: double.infinity,
                                  height: 54,
                                  color: const Color(0xFFFF7B10),
                                  textStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                CustomPaint(
                                  painter: DashedBorderPainter(color: const Color(0xFFFF7B10)),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Column(
                                      children: [
                                        Text(
                                          'YOUR REFERRAL CODE',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[400],
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _referralCode,
                                          style: GoogleFonts.inter(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: _referralCode));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 1)),
                                            );
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.copy, size: 16, color: Color(0xFFFF7B10)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'COPY CODE',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFFFF7B10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Social Share Buttons (Rapido WhatsApp focus)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: FFButtonWidget(
                                onPressed: () {
                                  Share.share('Join UGO built for Pro Rides! Use my code: $_referralCode to sign up.');
                                },
                                text: 'WhatsApp Share',
                                icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                                options: FFButtonOptions(
                                  height: 52,
                                  color: const Color(0xFF25D366),
                                  textStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: FFButtonWidget(
                                onPressed: () {
                                  Share.share('Join UGO! Code: $_referralCode');
                                },
                                text: '',
                                icon: const Icon(Icons.share, size: 20, color: Colors.blue),
                                options: FFButtonOptions(
                                  height: 52,
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // How it works (Horizontal Stepper Style)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How it Works',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 24),
                            _buildVerticalStep(1, 'Invite Friends', 'Share your referral code from the app.'),
                            _buildVerticalStep(2, 'Friends Register', 'They use your code while signing up.'),
                            _buildVerticalStep(3, 'Both Earn', 'Get rewards after their first completed ride!'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Dashboard / Earnings
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(top: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Referral Dashboard',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildRapidoStatBox('₹${_moneyEarned.toStringAsFixed(0)}', 'CASH EARNED')),
                                const SizedBox(width: 12),
                                Expanded(child: _buildRapidoStatBox(_coinsEarned.toStringAsFixed(0), 'COINS EARNED')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildRapidoStatBox(_totalReferrals.toString(), 'INVITES')),
                                const SizedBox(width: 12),
                                Expanded(child: _buildRapidoStatBox(_successfulConversions.toString(), 'REDEEMED')),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // History List
                      if (_referralHistory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Referral History',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _referralHistory.length,
                                itemBuilder: (context, index) {
                                  final item = _referralHistory[index];
                                  final isCompleted = (item['status']?.toString().toLowerCase() == 'completed');
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.grey[100],
                                          child: const Icon(Icons.person, size: 18, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['referred_user_name'] ?? 'UGO User',
                                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                                              ),
                                              Text(
                                                item['date_referred'] != null 
                                                  ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['date_referred']))
                                                  : 'Recently Joined',
                                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isCompleted ? Colors.green[50] : Colors.orange[50],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isCompleted ? 'EARNED' : 'PENDING',
                                            style: GoogleFonts.inter(
                                              fontSize: 9, 
                                              fontWeight: FontWeight.w800, 
                                              color: isCompleted ? Colors.green[700] : Colors.orange[700]
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildVerticalStep(int step, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7B10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                step.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            if (step < 3)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRapidoStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[400], letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    final dashWidth = 8.0;
    final dashSpace = 4.0;
    
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = dashWidth;
        dashPath.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        distance += length + dashSpace;
      }
    }
    
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
