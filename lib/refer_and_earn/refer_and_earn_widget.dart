import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/coin_wallet_inr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'refer_and_earn_model.dart';
export 'refer_and_earn_model.dart';

/// Vibrant Refer & Earn palette — high contrast, friendly “coach” energy.
class _ReferPalette {
  static const Color primary = Color(0xFFFF8A00); // Ugo Orange
  static const Color primaryDark = Color(0xFFE67A00);
  static const Color primaryLight = Color(0xFFFFCC99);
  static const Color accent = Color(0xFFFF4D00); // Deep Orange
  static const Color sun = Color(0xFFFFB547);
  static const Color mint = Color(0xFF10B981);
  static const Color ocean = Color(0xFF0EA5E9);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color cream = Color(0xFFFFFBF5);
  static const Color card = Colors.white;
  static const Color glass = Color(0xCCFFFFFF);
}

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
  int _referralsActivated = 0;
  int _referralsPending = 0;
  double _totalEarned = 0.0;
  int _coinsBalance = 0;
  int _proRidePayouts = 0;
  int _referralRewardCoinsTotal = 0;
  Map<String, int>? _walletCoinsLedger;
  List<dynamic> _referralRows = [];
  List<Map<String, dynamic>> _coinLedger = [];
  int _ledgerTotal = 0;
  String _firstName = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReferAndEarnModel());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fetchUserData(showPageLoader: true);
  }

  Future<void> _fetchUserData({bool showPageLoader = true}) async {
    final int userId = FFAppState().userid;
    final String token = FFAppState().accessToken;

    if (userId <= 0 || token.isEmpty) {
      if (mounted) {
        setState(() {
          if (showPageLoader) _isLoading = false;
        });
        if (showPageLoader) _animController.forward();
      }
      return;
    }

    if (showPageLoader && mounted) setState(() => _isLoading = true);

    try {
      final userResponse =
          await GetUserByIdCall.call(userId: userId, token: token);
      if (userResponse.statusCode >= 200 &&
          userResponse.statusCode < 300 &&
          mounted) {
        final body = userResponse.jsonBody;
        final code =
            getJsonField(body, r'''$.data.referral_code''')?.toString() ?? '';
        final coins = int.tryParse(
                getJsonField(body, r'''$.data.coins_balance''')?.toString() ??
                    '') ??
            0;
        final fName =
            getJsonField(body, r'''$.data.first_name''')?.toString() ?? '';
        FFAppState().coinsBalance = coins;
        setState(() {
          _referralCode = code;
          _coinsBalance = coins;
          _firstName = fName;
        });
      }
    } catch (e) {
      debugPrint('GetUserByIdCall: $e');
    }

    try {
      final statsResponse =
          await GetUserReferralStatsCall.call(userId: userId, token: token);
      if (statsResponse.statusCode >= 200 &&
          statsResponse.statusCode < 300 &&
          mounted) {
        final body = statsResponse.jsonBody;
        final refs = int.tryParse(
                GetUserReferralStatsCall.totalReferrals(body)?.toString() ??
                    '') ??
            0;
        final earned = double.tryParse(
                GetUserReferralStatsCall.totalEarned(body)?.toString() ?? '') ??
            0.0;
        final withPro = GetUserReferralStatsCall.referralsWithProReward(body) ??
            int.tryParse(getJsonField(body, r'''$.data.referrals_activated''')
                    ?.toString() ??
                '') ??
            0;
        final pend = int.tryParse(
                getJsonField(body, r'''$.data.referrals_pending''')
                        ?.toString() ??
                    '') ??
            0;
        final proPayouts =
            GetUserReferralStatsCall.referralProRidePayouts(body) ?? 0;
        final refCoins =
            GetUserReferralStatsCall.referralRewardCoinsTotal(body) ?? 0;
        final ledger = GetUserReferralStatsCall.walletCoinsLedger(body);
        final statsCoins = GetUserReferralStatsCall.coinsBalance(body);
        setState(() {
          _totalReferrals = refs;
          _totalEarned = earned;
          _referralsActivated = withPro;
          _referralsPending = pend;
          _proRidePayouts = proPayouts;
          _referralRewardCoinsTotal = refCoins;
          _walletCoinsLedger = ledger;
          if (statsCoins != null) {
            _coinsBalance = statsCoins;
            FFAppState().coinsBalance = statsCoins;
          }
        });
      }
    } catch (e) {
      debugPrint('ReferralStats: $e');
    }

    try {
      final refListRes =
          await GetUserReferralsCall.call(userId: userId, token: token);
      if (refListRes.statusCode >= 200 &&
          refListRes.statusCode < 300 &&
          mounted) {
        setState(() {
          _referralRows = GetUserReferralsCall.referrals(refListRes.jsonBody);
        });
      }
    } catch (e) {
      debugPrint('Referrals list: $e');
    }

    try {
      final ledgerRes = await GetMyCoinLedgerCall.call(token: token, limit: 60);
      if (ledgerRes.statusCode >= 200 &&
          ledgerRes.statusCode < 300 &&
          mounted) {
        setState(() {
          _coinLedger = GetMyCoinLedgerCall.transactions(ledgerRes.jsonBody);
          _ledgerTotal = GetMyCoinLedgerCall.totalCount(ledgerRes.jsonBody) ??
              _coinLedger.length;
        });
      }
    } catch (e) {
      debugPrint('Coin ledger: $e');
    }

    if (mounted) {
      setState(() {
        if (showPageLoader) _isLoading = false;
      });
      if (showPageLoader) _animController.forward();
    }
  }

  String get _referralSharePlain => '🚖 *Join UGO Taxi!* 🚖\n\n'
      'Get premium rides at great prices. Use my Referral Code: *$_referralCode* 🎁\n\n'
      'Download now:\n'
      'https://play.google.com/store/apps/details?id=com.ugotaxi_rajkumar.user';

  Future<XFile> _getLogoXFile() async {
    final byteData =
        await rootBundle.load('assets/images/app_launcher_icon.png');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/ugo_referral_logo.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return XFile(file.path);
  }

  Future<void> _shareOnWhatsApp() async {
    if (_referralCode.isEmpty) return;
    try {
      final logo = await _getLogoXFile();
      await Share.shareXFiles(
        [logo],
        text: _referralSharePlain,
      );
    } catch (e) {
      // Fallback to text only if image fails
      final message = Uri.encodeComponent(_referralSharePlain);
      final fallback = Uri.parse('https://api.whatsapp.com/send?text=$message');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareViaSystemSheet() async {
    if (_referralCode.isEmpty) return;
    try {
      final logo = await _getLogoXFile();
      await Share.shareXFiles(
        [logo],
        text: _referralSharePlain,
        subject: 'UGO — Join me for Pro rides!',
      );
    } catch (e) {
      await Share.share(_referralSharePlain, subject: 'UGO — Referral');
    }
  }

  Future<void> _shareViaSms() async {
    if (_referralCode.isEmpty) return;
    final body = Uri.encodeComponent(_referralSharePlain);
    final sms = Uri.parse('sms:?body=$body');
    if (await canLaunchUrl(sms)) {
      await launchUrl(sms);
    }
  }

  void _copyCode() {
    if (_referralCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Code copied — paste it for your friends!',
                style: GoogleFonts.inter(color: Colors.white)),
          ],
        ),
        backgroundColor: _ReferPalette.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  double get _coinsInRupees => CoinWalletInr.toInr(_coinsBalance);

  String _statusLabel(Map<dynamic, dynamic> row) {
    final rowSt = row['referral_row_status']?.toString().toLowerCase() ?? '';
    if (rowSt == 'fraud_blocked') return 'Blocked';
    final s = row['status']?.toString().toLowerCase() ?? '';
    if (s == 'completed') return 'Earning from Pro rides';
    if (s == 'active') return 'Active — pays per Pro ride';
    if (s == 'pending') return 'Waiting for first Pro ride';
    return s.isEmpty ? '—' : s;
  }

  String _ledgerWhen(Map<String, dynamic> m) {
    final raw = m['created_at'];
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return DateFormat('d MMM · h:mm a').format(dt.toLocal());
  }

  String _ledgerHeadline(Map<String, dynamic> m) {
    final d = (m['description'] ?? '').toString().trim();
    if (d.isEmpty) {
      final isEarn = m['type']?.toString() == 'earn';
      return isEarn ? 'Coins added' : 'Coins used';
    }
    return d;
  }

  @override
  void dispose() {
    _animController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: _ReferPalette.cream,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _ReferPalette.primaryLight,
                          _ReferPalette.accent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _ReferPalette.accent.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.card_giftcard_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading your rewards…',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _ReferPalette.ink,
                    ),
                  ),
                ],
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: RefreshIndicator(
          color: _ReferPalette.accent,
          onRefresh: () => _fetchUserData(showPageLoader: false),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: _ReferPalette.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => context.safePop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsetsDirectional.only(start: 16, bottom: 14),
                  title: Text(
                    'Refer & Earn',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
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
                              _ReferPalette.primaryDark,
                              _ReferPalette.primary,
                              Color(0xFFFFB366), // Peach/Light Orange
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -40,
                        top: 20,
                        child: Icon(Icons.auto_awesome_rounded,
                            size: 120,
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 56,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_firstName.isNotEmpty)
                              Text(
                                'Hi $_firstName 👋',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'Your personal rewards coach — we’ll show every coin you earn.',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCoachCard(),
                      const SizedBox(height: 18),
                      if (_referralsPending > 0) ...[
                        _buildPendingCard(),
                        const SizedBox(height: 18),
                      ],
                      _buildWalletHero(),
                      const SizedBox(height: 16),
                      _buildStatPills(),
                      const SizedBox(height: 20),
                      _buildCodeCard(),
                      const SizedBox(height: 14),
                      _buildShareRow(),
                      const SizedBox(height: 12),
                      _buildShortcutsRow(),
                      const SizedBox(height: 28),
                      _buildSectionTitle(
                        'Your coin diary',
                        'Every +/− in one place — referrals, rides & more',
                        Icons.receipt_long_rounded,
                        _ReferPalette.ocean,
                      ),
                      const SizedBox(height: 12),
                      _buildLedgerSection(),
                      const SizedBox(height: 28),
                      _buildFriendsSection(),
                      const SizedBox(height: 28),
                      _buildJourneySteps(),
                      const SizedBox(height: 20),
                      _buildTipCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _ReferPalette.mint.withValues(alpha: 0.12),
            _ReferPalette.ocean.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ReferPalette.mint.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _ReferPalette.mint.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.support_agent_rounded,
                color: _ReferPalette.mint, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How you earn (simple)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ReferPalette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _coachLine(Icons.tag_rounded,
                    'Share your code — friends add it at signup or Profile.'),
                _coachLine(Icons.directions_car_rounded,
                    'When they finish a Pro ride, you get +10 coins (₹1 off).'),
                _coachLine(Icons.payments_rounded,
                    'Use coins only at ride checkout — not cash out.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coachLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _ReferPalette.primaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ReferPalette.sun.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded,
              color: _ReferPalette.accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_referralsPending friend(s) — not paid yet',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _ReferPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'They need to complete a Pro ride. You’ll get +10 coins each time.',
                  style: GoogleFonts.inter(fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletHero() {
    final r = _coinsInRupees;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ReferPalette.primary.withOpacity(0.9),
            _ReferPalette.primaryDark,
            _ReferPalette.accent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _ReferPalette.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.stars_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '10 coins = ₹1 ride discount',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'YOUR COIN STASH',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_coinsBalance',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                    child: Text(
                      'coins',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '≈ ₹${r.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: _ReferPalette.sun,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'next ride off',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_walletCoinsLedger != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _walletMini('Earned',
                          '${_walletCoinsLedger!['total_earned_coins']}'),
                      _walletMini(
                          'Used', '${_walletCoinsLedger!['total_used_coins']}'),
                      _walletMini('Avail.',
                          '${_walletCoinsLedger!['available_coins']}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletMini(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
        Text(val,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ],
    );
  }

  Widget _buildStatPills() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _pill(Icons.group_rounded, 'Friends', '$_totalReferrals',
            _ReferPalette.ocean),
        _pill(Icons.verified_rounded, 'Paid friends', '$_referralsActivated',
            _ReferPalette.mint),
        _pill(Icons.local_fire_department_rounded, 'Pro payouts',
            '$_proRidePayouts', _ReferPalette.accent),
        _pill(Icons.stars_rounded, 'Ref. coins', '$_referralRewardCoinsTotal',
            _ReferPalette.sun),
        if (_totalEarned > 0)
          _pill(Icons.currency_rupee_rounded, 'Ref. value',
              '₹${_totalEarned.toStringAsFixed(0)}+', _ReferPalette.mint),
      ],
    );
  }

  Widget _pill(IconData icon, String label, String value, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _ReferPalette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _ReferPalette.ink)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ReferPalette.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: _ReferPalette.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _ReferPalette.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'SHARE YOUR UNIQUE CODE',
              style: GoogleFonts.inter(
                letterSpacing: 1.2,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _ReferPalette.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: _ReferPalette.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _ReferPalette.primary.withOpacity(0.3),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                _referralCode.isEmpty ? '••••••••' : _referralCode,
                style: GoogleFonts.spaceMono(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _ReferPalette.ink,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _referralCode.isEmpty ? null : _copyCode,
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: Text('Copy to clipboard',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ReferPalette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareRow() {
    return Row(
      children: [
        Expanded(
          child: _shareBtn(
            'WhatsApp',
            const Color(0xFF25D366),
            Icons.chat_rounded,
            () => _shareOnWhatsApp(), // Always uses logic
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _shareBtn(
            'More',
            _ReferPalette.primaryLight,
            Icons.ios_share_rounded,
            _referralCode.isEmpty ? null : _shareViaSystemSheet,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _shareBtn(
            'SMS',
            _ReferPalette.ocean,
            Icons.sms_rounded,
            _referralCode.isEmpty ? null : _shareViaSms,
          ),
        ),
      ],
    );
  }

  Widget _shareBtn(String label, Color bg, IconData icon, VoidCallback? onTap) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutsRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.pushNamed('Wallet'),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: Text('Wallet',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.pushNamed('voucher'),
            icon: const Icon(Icons.local_offer_outlined, size: 18),
            label: Text('Vouchers',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
      String title, String subtitle, IconData icon, Color c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: c, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ReferPalette.ink,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerSection() {
    if (_coinLedger.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.savings_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No coin moves yet',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _ReferPalette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When you earn from referrals or use coins on a ride, each line will show here with date & amount.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_ledgerTotal > _coinLedger.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Showing ${_coinLedger.length} of $_ledgerTotal — pull to refresh',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ..._coinLedger.map(_buildLedgerTile),
      ],
    );
  }

  Widget _buildLedgerTile(Map<String, dynamic> m) {
    final isEarn = m['type']?.toString() == 'earn';
    final coins = int.tryParse(m['coins']?.toString() ?? '0') ?? 0;
    final absCoins = coins.abs();
    final inr =
        double.tryParse(m['value_inr']?.toString() ?? '') ?? (absCoins / 10.0);
    final rideId = m['ride_id'];
    final c = isEarn ? _ReferPalette.mint : _ReferPalette.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarn ? Icons.add_rounded : Icons.remove_rounded,
              color: c,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ledgerHeadline(m),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _ReferPalette.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ledgerWhen(m),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (rideId != null &&
                    int.tryParse(rideId.toString()) != null &&
                    int.parse(rideId.toString()) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Ride #${rideId.toString()}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _ReferPalette.ocean,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarn ? '+' : '−'}$absCoins',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: c,
                ),
              ),
              Text(
                'coins',
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${inr.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection() {
    if (_referralRows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          'Your invites',
          'See who’s linked and what’s happening',
          Icons.people_alt_rounded,
          _ReferPalette.primaryLight,
        ),
        const SizedBox(height: 12),
        ..._referralRows.take(20).map((r) {
          if (r is! Map) return const SizedBox.shrink();
          final rm = Map<dynamic, dynamic>.from(r);
          final ru = rm['referred_user'];
          String name = 'Friend';
          if (ru is Map) {
            name = (ru['name'] ?? '').toString().trim();
            if (name.isEmpty) name = 'Friend';
          }
          final st = _statusLabel(rm);
          final amt = rm['amount'];
          final amtStr = amt != null &&
                  double.tryParse(amt.toString()) != null &&
                  double.parse(amt.toString()) > 0
              ? ' · ₹${double.parse(amt.toString()).toStringAsFixed(0)} logged'
              : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _ReferPalette.primary.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: _ReferPalette.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$st$amtStr',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJourneySteps() {
    final steps = <Map<String, dynamic>>[
      {
        'icon': Icons.rocket_launch_rounded,
        'color': _ReferPalette.primary,
        'title': 'Share once',
        'desc': 'Send your code on WhatsApp, SMS, or any app.',
      },
      {
        'icon': Icons.person_add_alt_1_rounded,
        'color': _ReferPalette.ocean,
        'title': 'Friend joins',
        'desc': 'They enter your code when they sign up or in Profile.',
      },
      {
        'icon': Icons.electric_car_rounded,
        'color': _ReferPalette.mint,
        'title': 'Pro ride done',
        'desc': '+10 coins for you every time they complete a Pro ride.',
      },
      {
        'icon': Icons.savings_rounded,
        'color': _ReferPalette.sun,
        'title': 'Spend on rides',
        'desc': '10 coins = ₹1 off at checkout. Not withdrawable cash.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The journey',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _ReferPalette.ink,
          ),
        ),
        const SizedBox(height: 14),
        ...steps.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final col = s['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s['icon'] as IconData, color: col, size: 22),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 22,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              col.withValues(alpha: 0.5),
                              Colors.grey.shade200
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title'] as String,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _ReferPalette.ink,
                          ),
                        ),
                        Text(
                          s['desc'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                            height: 1.35,
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

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ReferPalette.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _ReferPalette.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded,
              color: _ReferPalette.primaryLight, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Missed a code at signup? Open Profile → apply a referral code anytime.',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
