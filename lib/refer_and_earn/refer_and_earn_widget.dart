import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'refer_and_earn_model.dart';
export 'refer_and_earn_model.dart';

class ReferAndEarnWidget extends StatefulWidget {
  const ReferAndEarnWidget({super.key});

  static String routeName = 'ReferAndEarn';
  static String routePath = '/referAndEarn';

  @override
  State<ReferAndEarnWidget> createState() => _ReferAndEarnWidgetState();
}

class _ReferAndEarnWidgetState extends State<ReferAndEarnWidget>
    with SingleTickerProviderStateMixin {
  late ReferAndEarnModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  String _referralCode = '';
  int _totalReferrals = 0;
  double _totalEarned = 0.0;
  int _coinsBalance = 0;
  String _firstName = '';
  String _lastName = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReferAndEarnModel());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchUserData();
  }

  // ─── API CALL: Get user by ID ─────────────────────────────────────────────
  Future<void> _fetchUserData() async {
    // From app_state.dart:
    //   int _userid = 0;       → default 0 means NOT logged in (not null)
    //   String _accessToken = ''; → empty string means NOT authenticated
    final int    userId = FFAppState().userid;
    final String token  = FFAppState().accessToken;

    debugPrint('▶ ReferAndEarn: userId=$userId  tokenEmpty=${token.isEmpty}');

    // Guard: 0 = not logged in, empty token = not authenticated
    if (userId <= 0 || token.isEmpty) {
      debugPrint('✖ Skipping API – userId=$userId  token.isEmpty=${token.isEmpty}');
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
      return;
    }

    // ── 1. Fetch user profile from GET /api/users/{userId} ───────────────
    try {
      final userResponse = await GetUserByIdCall.call(
        userId: userId,
        token: token,
      );

      debugPrint('◀ GetUserByIdCall status: ${userResponse.statusCode}');
      debugPrint('◀ GetUserByIdCall body: ${userResponse.jsonBody}');

      if (userResponse.statusCode >= 200 && userResponse.statusCode < 300) {
        final body = userResponse.jsonBody;
        // Exact paths matching your API: { "success":true, "data": { "referral_code":"USR19THM3", ... } }
        final String code  = getJsonField(body, r'''$.data.referral_code''')?.toString() ?? '';
        final int    coins = int.tryParse(getJsonField(body, r'''$.data.coins_balance''')?.toString() ?? '') ?? 0;
        final String fName = getJsonField(body, r'''$.data.first_name''')?.toString() ?? '';
        final String lName = getJsonField(body, r'''$.data.last_name''')?.toString() ?? '';

        debugPrint('✔ code=$code  coins=$coins  name="$fName $lName"');

        if (mounted) {
          FFAppState().coinsBalance = coins;
          setState(() {
            _referralCode = code;
            _coinsBalance = coins;
            _firstName    = fName;
            _lastName     = lName;
          });
        }
      } else {
        debugPrint('✖ GetUserByIdCall HTTP ${userResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('✖ GetUserByIdCall exception: $e');
    }

    // ── 2. Fetch referral stats (non-critical) ────────────────────────────
    try {
      final statsResponse = await GetUserReferralStatsCall.call(
        userId: userId,
        token: token,
      );
      if (statsResponse.statusCode >= 200 && statsResponse.statusCode < 300) {
        final int    refs   = int.tryParse(getJsonField(statsResponse.jsonBody, r'''$.data.total_referrals''')?.toString() ?? '') ?? 0;
        final double earned = double.tryParse(getJsonField(statsResponse.jsonBody, r'''$.data.total_earned''')?.toString() ?? '') ?? 0.0;
        if (mounted) {
          setState(() {
            _totalReferrals = refs;
            _totalEarned    = earned;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠ ReferralStats non-fatal: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  // ─── Share via WhatsApp ───────────────────────────────────────────────────
  Future<void> _shareOnWhatsApp() async {
    if (_referralCode.isEmpty) return;
    final message = Uri.encodeComponent(
      'Hey! 👋 Join UGO – built for Pro Rides! 🚗\n\nUse my referral code *$_referralCode* when you sign up and get started.\n\nDownload now and let\'s ride! 🎉',
    );
    final whatsappUrl = Uri.parse('whatsapp://send?text=$message');
    final fallbackUrl =
        Uri.parse('https://api.whatsapp.com/send?text=$message');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Copy code to clipboard ───────────────────────────────────────────────
  void _copyCode() {
    if (_referralCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Referral code copied!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF7B10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Coins → Rupees conversion ────────────────────────────────────────────
  double get _coinsInRupees => _coinsBalance / 10.0;

  @override
  void dispose() {
    _animController.dispose();
    _model.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF7F7F7),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFFF7B10)),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Collapsible AppBar with gradient ──────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              backgroundColor: const Color(0xFFFF7B10),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => context.safePop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                titlePadding:
                    const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  'Refer & Earn',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF9A3C),
                            Color(0xFFFF6B00),
                          ],
                        ),
                      ),
                    ),
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Hero content
                    Positioned(
                      top: 56,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_firstName.isNotEmpty)
                            Text(
                              'Hi $_firstName! Invite & Earn 🎉',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body Content ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Description card
                    _buildDescriptionCard(),
                    const SizedBox(height: 20),

                    // Referral code card
                    _buildReferralCodeCard(),
                    const SizedBox(height: 16),

                    // Share on WhatsApp button
                    _buildWhatsAppButton(),
                    const SizedBox(height: 28),

                    // Stats row
                    _buildStatsRow(),
                    const SizedBox(height: 20),

                    // Coins card
                    _buildCoinsCard(),
                    const SizedBox(height: 28),

                    // How it works
                    _buildHowItWorks(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7B10).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFFFF7B10),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Share your code with friends. When they complete a Pro Ride, you earn a commission!',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E8), Color(0xFFFFE8CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF7B10).withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'YOUR REFERRAL CODE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF7B10),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _referralCode.isEmpty ? '––––––––' : _referralCode,
            style: GoogleFonts.spaceMono(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          // Copy button
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: const Color(0xFFFF7B10).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded,
                      size: 15, color: Color(0xFFFF7B10)),
                  const SizedBox(width: 6),
                  Text(
                    'Copy Code',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF7B10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    return GestureDetector(
      onTap: _shareOnWhatsApp,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // WhatsApp icon (using custom painter or image asset)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'W',
                  style: TextStyle(
                    color: Color(0xFF25D366),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Share on WhatsApp',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.group_rounded,
            iconColor: const Color(0xFF5B7BFE),
            bgColor: const Color(0xFFEEF1FF),
            label: 'Friends Referred',
            value: _totalReferrals.toString(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.currency_rupee_rounded,
            iconColor: const Color(0xFF34C759),
            bgColor: const Color(0xFFEAF9EE),
            label: 'Total Earned',
            value: '₹${_totalEarned.toStringAsFixed(2)}',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsCard() {
    final rupees = _coinsInRupees;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    'My Coin Wallet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7B10).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '10 coins = ₹1',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF7B10),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coins Balance',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_coinsBalance',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'coins',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 1,
                height: 60,
                color: Colors.white12,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Worth in Cash',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${rupees.toStringAsFixed(2)}',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF34C759),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'rupees',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white12,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                _coinsBalance == 0
                    ? 'Start referring friends to earn coins!'
                    : 'You can redeem ₹${rupees.toStringAsFixed(2)} from your rides.',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      {
        'icon': Icons.share_rounded,
        'color': const Color(0xFFFF7B10),
        'title': 'Share Your Code',
        'desc': 'Send your unique referral code to friends via WhatsApp or any platform.',
      },
      {
        'icon': Icons.person_add_alt_1_rounded,
        'color': const Color(0xFF5B7BFE),
        'title': 'Friend Signs Up',
        'desc': 'Your friend downloads UGO and enters your code during registration.',
      },
      {
        'icon': Icons.directions_car_filled_rounded,
        'color': const Color(0xFF34C759),
        'title': 'They Complete a Ride',
        'desc': 'When your friend finishes their first Pro Ride, your reward is triggered.',
      },
      {
        'icon': Icons.wallet_rounded,
        'color': const Color(0xFFFF9500),
        'title': 'You Earn Coins',
        'desc': 'Coins are added to your wallet. 10 coins = ₹1 redeemable on rides!',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (step['color'] as Color).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: step['color'] as Color,
                        size: 20,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 28,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.grey[200],
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['desc'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}