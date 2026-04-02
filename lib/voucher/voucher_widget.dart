import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/coin_wallet_inr.dart';
import 'package:provider/provider.dart';
import '/refer_and_earn/refer_and_earn_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'voucher_model.dart';
export 'voucher_model.dart';

class VoucherWidget extends StatefulWidget {
  const VoucherWidget({super.key});

  static String routeName = 'voucher';
  static String routePath = '/voucher';

  @override
  State<VoucherWidget> createState() => _VoucherWidgetState();
}

class _VoucherWidgetState extends State<VoucherWidget> {
  late VoucherModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> _vouchers = [];
  List<Map<String, dynamic>> _myWalletVouchers = [];
  bool _referralsLoading = true;
  int _referralTotal = 0;
  List<dynamic> _referralRows = [];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VoucherModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _loadCoinsAndReferrals();
  }

  Future<void> _loadCoinsAndReferrals() async {
    final app = FFAppState();
    if (app.userid > 0 && app.accessToken.isNotEmpty) {
      try {
        final userRes = await GetUserByIdCall.call(
          userId: app.userid,
          token: app.accessToken,
        );
        if (userRes.succeeded && mounted) {
          final c = GetUserByIdCall.coinsBalance(userRes.jsonBody) ?? 0;
          app.coinsBalance = c;
        }
      } catch (_) {}

      try {
        final refRes = await GetUserReferralsCall.call(
          userId: app.userid,
          token: app.accessToken,
        );
        if (refRes.succeeded && mounted) {
          _referralTotal = GetUserReferralsCall.total(refRes.jsonBody) ?? 0;
          _referralRows = GetUserReferralsCall.referrals(refRes.jsonBody);
        }
      } catch (_) {}
    }
    if (app.userid > 0 && app.accessToken.isNotEmpty) {
      try {
        final vRes = await ListMyVouchersCall.call(
          token: app.accessToken,
          includeUsed: true,
        );
        if (vRes.succeeded && mounted) {
          final raw = ListMyVouchersCall.vouchers(vRes.jsonBody) ?? [];
          _myWalletVouchers = raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _referralsLoading = false);
    }
  }

  void _applyVoucher(String code, double discount) {
    final appState = FFAppState();
    appState.appliedCouponCode = code;
    appState.discountAmount = discount;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher $code applied! ₹$discount saved.'),
        backgroundColor: const Color(0xFF00D084),
      ),
    );
    context.pop();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Widget _buildCoinsAndReferralsCard() {
    final app = FFAppState();
    final coins = app.coinsBalance;
    final rupees = CoinWalletInr.toInr(coins);
    const primaryOrange = Color(0xFFFF7B10);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    'Coin balance',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  CoinWalletInr.rateCaption(),
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFB366),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$coins',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'coins',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Ride value',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${rupees.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFB366),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 12),
          if (_referralsLoading)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFFB366),
                ),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your referrals',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$_referralTotal joined',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (_referralRows.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._referralRows.take(3).map((r) {
                final name = r is Map
                    ? (r['referred_user'] is Map
                        ? ((r['referred_user']['name'] ?? '') as String)
                        : '')
                    : '';
                final status = r is Map ? (r['status']?.toString() ?? '') : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'Friend' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        status,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    context.pushNamed(ReferAndEarnWidget.routeName),
                child: Text(
                  'Invite & earn more',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFB366),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.orange,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Promotions',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Material(
                color: Colors.white,
                child: SwitchListTile(
                  title: Text(
                    'Auto-apply best voucher when booking',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'We pick the highest discount for your fare (you can turn this off).',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                  value: context.watch<FFAppState>().autoApplyBestVoucher,
                  activeThumbColor: Colors.orange,
                  onChanged: (v) {
                    FFAppState().autoApplyBestVoucher = v;
                  },
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter promo code',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: _model.textController,
                              focusNode: _model.textFieldFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'Example: SAVE50',
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final code = _model.textController?.text
                                    .toUpperCase() ??
                                '';
                            final coupon = _vouchers.firstWhere(
                              (c) =>
                                  c['code_name'].toString().toUpperCase() ==
                                  code,
                              orElse: () => null,
                            );
                            if (coupon != null) {
                              final disc = double.tryParse(
                                      coupon['discount_value']?.toString() ??
                                          '0') ??
                                  0.0;
                              _applyVoucher(code, disc);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Invalid promo code'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(80, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Apply',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCoinsAndReferralsCard(),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_myWalletVouchers.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Your ride vouchers',
                            style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              ..._myWalletVouchers
                                  .where((v) =>
                                      '${v['status']}'.toLowerCase() == 'active')
                                  .map((v) => _walletVoucherTile(v)),
                              const SizedBox(height: 12),
                              Text(
                                'Used / expired',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              ..._myWalletVouchers
                                  .where((v) =>
                                      '${v['status']}'.toLowerCase() != 'active')
                                  .map((v) => _walletVoucherTile(v)),
                            ],
                          ),
                        ),
                        const Divider(height: 32),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Text(
                          'Available Offers',
                          style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<ApiCallResponse>(
                          future: GetAllVouchersCall.call(
                              token: FFAppState().accessToken),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.orange));
                            }

                            if (snapshot.hasError ||
                                snapshot.data == null ||
                                !snapshot.data!.succeeded) {
                              debugPrint(
                                  'Voucher API Error: ${snapshot.data?.jsonBody}');
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.grey, size: 48),
                                    const SizedBox(height: 16),
                                    Text('Failed to load coupons',
                                        style: GoogleFonts.inter(
                                            color: Colors.grey)),
                                    TextButton(
                                        onPressed: () => setState(() {}),
                                        child: const Text('Retry'))
                                  ],
                                ),
                              );
                            }

                            _vouchers = GetAllVouchersCall.data(
                                    snapshot.data!.jsonBody) ??
                                [];

                            if (_vouchers.isEmpty) {
                              return Center(
                                child: Text('No offers available at the moment',
                                    style:
                                        GoogleFonts.inter(color: Colors.grey)),
                              );
                            }

                            return ListView.separated(
                              itemCount: _vouchers.length,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final v = _vouchers[index];
                                return _buildCouponCard(v);
                              },
                            );
                          },
                        ),
                      ),
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

  Widget _walletVoucherTile(Map<String, dynamic> v) {
    final exp = v['expires_at']?.toString() ?? '';
    final st = '${v['status'] ?? ''}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${v['title'] ?? v['code'] ?? 'Voucher'}',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '$st${exp.isNotEmpty ? ' · exp $exp' : ''}',
        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildCouponCard(dynamic v) {
    final code = v['code_name'] ?? 'PROMO';
    final discount = v['discount_value']?.toString() ?? '0';
    final type = v['discount_type'] ?? 'flat';
    final expiry = v['expiry_date'] != null
        ? 'Exp: ${v['expiry_date'].toString().split('T')[0]}'
        : 'No Expiry';

    String title = type == 'percentage' ? '$discount% OFF' : '₹$discount OFF';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_offer_rounded,
                      color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                          'Get a discount on your ride using this promo code.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(expiry,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(code,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                TextButton(
                  onPressed: () {
                    final disc = double.tryParse(discount) ?? 0.0;
                    _applyVoucher(code, disc);
                  },
                  child: const Text('APPLY',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
