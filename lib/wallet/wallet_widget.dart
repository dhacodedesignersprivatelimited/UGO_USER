import 'package:ugouser/backend/api_requests/api_calls.dart';

import '/utils/coin_wallet_inr.dart';
import '/voucher/voucher_widget.dart';
import '/wallet_history/wallet_history_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wallet_model.dart';
export 'wallet_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:ugouser/config/payment_config.dart';

/// Wallet Management Interface
class WalletWidget extends StatefulWidget {
  const WalletWidget({super.key});

  static String routeName = 'Wallet';
  static String routePath = '/wallet';

  @override
  State<WalletWidget> createState() => _WalletWidgetState();
}

class _WalletWidgetState extends State<WalletWidget> {
  late WalletModel _model;
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// From GET /wallets/me/summary when available; else null (UI uses [CoinWalletInr]).
  double? _coinsValueInrFromApi;
  List<Map<String, dynamic>> _recentWalletTx = [];
  final ScrollController _scrollController = ScrollController();

  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WalletModel());
    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );
    _loadWalletData();
  }

  /// Wallet (recharge / UPI) + coins (rides only). Prefers summary endpoint for one round-trip.
  Future<void> _loadWalletData() async {
    final app = FFAppState();
    final token = app.accessToken;

    if (token.isNotEmpty) {
      final sum = await GetWalletSummaryCall.call(token: token);
      if (sum.succeeded) {
        final main = GetWalletSummaryCall.mainWalletInr(sum.jsonBody);
        final coins = GetWalletSummaryCall.coins(sum.jsonBody) ?? 0;
        final cv = GetWalletSummaryCall.coinsValueInr(sum.jsonBody);
        if (main != null) app.walletBalance = main;
        app.coinsBalance = coins;
        await _loadRecentTransactions(token);
        if (mounted) {
          setState(() => _coinsValueInrFromApi = cv);
        } else {
          _coinsValueInrFromApi = cv;
        }
        return;
      }
    }

    final response = await GetwalletCall.call(
      userId: app.userid,
      token: app.accessToken,
    );

    if (response.succeeded) {
      final balanceString = GetwalletCall.walletBalance(response.jsonBody);
      final double balance = double.tryParse(balanceString ?? "0") ?? 0.0;
      app.walletBalance = balance;
    }

    if (app.userid > 0 && app.accessToken.isNotEmpty) {
      try {
        final userRes = await GetUserByIdCall.call(
          userId: app.userid,
          token: app.accessToken,
        );
        if (userRes.succeeded) {
          final coins = GetUserByIdCall.coinsBalance(userRes.jsonBody) ?? 0;
          app.coinsBalance = coins;
        }
      } catch (_) {}
    }

    final t = app.accessToken;
    if (t.isNotEmpty) await _loadRecentTransactions(t);
    if (mounted) setState(() => _coinsValueInrFromApi = null);
  }

  Future<void> _loadRecentTransactions(String token) async {
    try {
      final res = await GetWalletTransactionsMeCall.call(
        token: token,
        page: 1,
        limit: 5,
      );
      final raw = GetWalletTransactionsMeCall.transactions(res.jsonBody) ?? [];
      final list = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) list.add(Map<String, dynamic>.from(item));
      }
      if (mounted) setState(() => _recentWalletTx = list);
    } catch (_) {}
  }

  Widget _buildWalletHomeSummary(BuildContext context) {
    final app = FFAppState();
    final coins = app.coinsBalance;
    final inr = app.walletBalance;
    final coinRs = CoinWalletInr.toInr(coins);
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: theme.accent1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _miniStat(
                context,
                'Ugo cash',
                '₹${inr.toStringAsFixed(2)}',
                Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniStat(
                context,
                'Coins → rides',
                '$coins · ₹${coinRs.toStringAsFixed(2)}',
                Icons.monetization_on_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add money'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.secondaryBackground,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pushNamed(VoucherWidget.routeName),
                icon: const Icon(Icons.local_offer_outlined, size: 20),
                label: const Text('Vouchers'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Transfer coins'),
                    content: const Text(
                      'Coin transfers to other users are not available yet. Use ride booking to spend coins as discount.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Transfer coins'),
            ),
            TextButton.icon(
              onPressed: () => context.pushNamed(WalletHistoryWidget.routeName),
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Full history'),
            ),
          ],
        ),
        if (_recentWalletTx.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Recent transactions',
            style: theme.titleSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          ..._recentWalletTx.map((m) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${m['transaction_type'] ?? '—'}',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${m['description'] ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11),
              ),
              trailing: Text(
                '₹${m['amount'] ?? '0'}',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w700,
                  color: theme.accent1,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _miniStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.accent1),
          const SizedBox(height: 6),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 11, color: theme.secondaryText)),
          Text(value,
              style: GoogleFonts.interTight(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// Referral coins shown as in-wallet ride credit (Mana Savari–style: in-app only, no withdrawal).
  Widget _buildReferralRewardsCard(BuildContext context) {
    final app = FFAppState();
    final coins = app.coinsBalance;
    final rsInr = _coinsValueInrFromApi ?? CoinWalletInr.toInr(coins);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Referral rewards',
                    style: GoogleFonts.interTight(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rides only',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFB366),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              CoinWalletInr.rateCaption(),
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coin balance',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$coins',
                        style: GoogleFonts.interTight(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'coins',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white24,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Worth on rides',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${rsInr.toStringAsFixed(2)}',
                        style: GoogleFonts.interTight(
                          color: const Color(0xFFFFB366),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'INR ride discount',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFB366).withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Applied at booking (not added to Ugo cash). Not withdrawable.',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    context.pushNamed(ReferAndEarnWidget.routeName);
                  },
                  child: Text(
                    'Invite friends',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFB366),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.pushNamed(VoucherWidget.routeName);
                  },
                  child: Text(
                    'Promotions',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRazorpay(double amount) async {
    try {
      String? orderId;
      try {
        // Create order on backend for payment verification (if supported)
        final orderRes = await CreateRazorpayOrderCall.call(
          amount: amount,
          token: FFAppState().accessToken,
        );
        orderId = CreateRazorpayOrderCall.orderId(orderRes.jsonBody);
      } catch (_) {
        // Backend may not support wallet orders; continue with amount only
      }

      final options = <String, dynamic>{
        'key': PaymentConfig().getRazorpayKey(),
        'amount': (amount * 100).toInt(), // paise
        'name': 'Ugo App',
        'description': 'Wallet Recharge',
        'prefill': {
          'contact': '9885881832',
          'email': 'test@email.com',
        },
      };
      if (orderId != null && orderId.isNotEmpty) {
        options['order_id'] = orderId;
      }

      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${FFLocalizations.of(context).getText('val_payment_start_fail')}: $e'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ));
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    try {
      final apiResponse = await AddMoneyToWalletCall.call(
        userId: FFAppState().userid,
        amount: amount,
        token: FFAppState().accessToken,
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
      );

      if (AddMoneyToWalletCall.success(apiResponse.jsonBody) == true) {
        final balanceString =
            AddMoneyToWalletCall.walletBalance(apiResponse.jsonBody);
        final balance = double.tryParse(balanceString ?? "0") ?? 0.0;

        if (mounted) {
          await _loadWalletData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "${FFLocalizations.of(context).getText('wallet_updated_success')}: ₹${balance.toStringAsFixed(2)}"),
              backgroundColor: FlutterFlowTheme.of(context).success,
            ),
          );
        }
      } else {
        final msg = AddMoneyToWalletCall.message(apiResponse.jsonBody);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg ??
                  FFLocalizations.of(context).getText('wallet_update_failed')),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(FFLocalizations.of(context).getText('payment_failed'))),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    _scrollController.dispose();
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).secondaryBackground,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              '8bs46fqf' /* Wallet */,
            ),
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleLarge.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildWalletHomeSummary(context),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      context.pushNamed(BalanceWidget.routeName);
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 2.0,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  FFLocalizations.of(context).getText(
                                    '7idwe1xc' /* Ugo cash */,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .accent1,
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                      ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "₹ ${FFAppState().walletBalance.toStringAsFixed(2)}",
                                          style: FlutterFlowTheme.of(context)
                                              .titleLarge
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .accent1,
                                                fontSize: 20.0,
                                              ),
                                        ),
                                        Text(
                                          'Indian rupees (recharge)',
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                font: GoogleFonts.inter(),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),

                                    // InkWell(
                                    //   splashColor: Colors.transparent,
                                    //   focusColor: Colors.transparent,
                                    //   hoverColor: Colors.transparent,
                                    //   highlightColor: Colors.transparent,
                                    //   onTap: () async {
                                    //     context
                                    //         .pushNamed(BalanceWidget.routeName);
                                    //   },
                                    //   child: Icon(
                                    //     Icons.chevron_right,
                                    //     color: FlutterFlowTheme.of(context)
                                    //         .accent1,
                                    //     size: 20.0,
                                    //   ),
                                    // ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ],
                            ),
                            Text(
                              'Use with Wallet at checkout. This balance is separate from referral coins (rides only, not cash out).',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 12.0,
                                  ),
                            ),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: FFLocalizations.of(context)
                                          .getText('val_enter_amount'),
                                      prefixIcon: Icon(Icons.currency_rupee),
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return FFLocalizations.of(context)
                                            .getText('val_amount_required');
                                      }
                                      final amount = double.tryParse(value);
                                      if (amount == null || amount <= 0) {
                                        return FFLocalizations.of(context)
                                            .getText('val_amount_invalid');
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 12),

                                  /// ADD AMOUNT BUTTON
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          FlutterFlowTheme.of(context).primary,
                                      minimumSize: Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        double amount = double.parse(
                                            _amountController.text.trim());

                                        _openRazorpay(amount);
                                      }
                                    },
                                    child: Text(
                                      FFLocalizations.of(context)
                                          .getText('add_amount_button'),
                                      style: TextStyle(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _buildReferralRewardsCard(context),
                ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'ktxa402r' /* Payment methods */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.qr_code_scanner,
                //                   color: Color(0xFF756F6F),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'oao5dvnw' /* Upi scan and pay */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF756F6F),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.attach_money,
                //                   color: Color(0xFF756F6F),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'mcje350w' /* Cash */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF756F6F),
                //                         fontSize: 16.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Icon(
                //               Icons.add,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //             Padding(
                //               padding: EdgeInsetsDirectional.fromSTEB(
                //                   12.0, 0.0, 12.0, 0.0),
                //               child: Text(
                //                 FFLocalizations.of(context).getText(
                //                   'zsnn2w5x' /* Add payment method */,
                //                 ),
                //                 style: FlutterFlowTheme.of(context)
                //                     .bodyMedium
                //                     .override(
                //                       font: GoogleFonts.inter(
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                       color:
                //                           FlutterFlowTheme.of(context).accent1,
                //                       fontSize: 14.0,
                //                       letterSpacing: 0.0,
                //                       fontWeight: FontWeight.normal,
                //                       fontStyle: FlutterFlowTheme.of(context)
                //                           .bodyMedium
                //                           .fontStyle,
                //                     ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ].divide(SizedBox(height: 8.0)),
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'vo9mscox' /* Rides profiles */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.person,
                //                   color: Color(0xFF948C8C),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'ksdpgb8i' /* Personal */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF948C8C),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.business,
                //                   color: Color(0xFF948C8C),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'qnqo8992' /* Starting using Ugo for busines... */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF948C8C),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //       ].divide(SizedBox(height: 8.0)),
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'hk03dlx6' /* Shared with you */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Row(
                //       mainAxisSize: MainAxisSize.max,
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       crossAxisAlignment: CrossAxisAlignment.center,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           children: [
                //             Icon(
                //               Icons.people,
                //               color: Color(0xFF948C8C),
                //               size: 20.0,
                //             ),
                //             Text(
                //               FFLocalizations.of(context).getText(
                //                 '5iatkiuw' /* Manage business rides for othe... */,
                //               ),
                //               style: FlutterFlowTheme.of(context)
                //                   .bodyMedium
                //                   .override(
                //                     font: GoogleFonts.inter(
                //                       fontWeight: FontWeight.normal,
                //                       fontStyle: FlutterFlowTheme.of(context)
                //                           .bodyMedium
                //                           .fontStyle,
                //                     ),
                //                     color: Color(0xFF948C8C),
                //                     fontSize: 14.0,
                //                     letterSpacing: 0.0,
                //                     fontWeight: FontWeight.normal,
                //                     fontStyle: FlutterFlowTheme.of(context)
                //                         .bodyMedium
                //                         .fontStyle,
                //                   ),
                //             ),
                //           ].divide(SizedBox(width: 12.0)),
                //         ),
                //         Icon(
                //           Icons.chevron_right,
                //           color: FlutterFlowTheme.of(context).accent1,
                //           size: 20.0,
                //         ),
                //       ],
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'ijvyfwt8' /* Vouchers */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.card_giftcard,
                //                   color: Color(0xFF948C8C),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'uy42yrs1' /* Vouchers */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF948C8C),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     '6sj8408l' /* 0 */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: FlutterFlowTheme.of(context)
                //                             .accent1,
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //                 Icon(
                //                   Icons.chevron_right,
                //                   color: FlutterFlowTheme.of(context).accent1,
                //                   size: 20.0,
                //                 ),
                //               ].divide(SizedBox(width: 8.0)),
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Icon(
                //               Icons.add,
                //               color: Color(0xFF948C8C),
                //               size: 20.0,
                //             ),
                //             Padding(
                //               padding: EdgeInsetsDirectional.fromSTEB(
                //                   12.0, 0.0, 12.0, 0.0),
                //               child: Text(
                //                 FFLocalizations.of(context).getText(
                //                   'i796wiq8' /* Add vouchers code */,
                //                 ),
                //                 style: FlutterFlowTheme.of(context)
                //                     .bodyMedium
                //                     .override(
                //                       font: GoogleFonts.inter(
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                       color: Color(0xFF948C8C),
                //                       fontSize: 14.0,
                //                       letterSpacing: 0.0,
                //                       fontWeight: FontWeight.normal,
                //                       fontStyle: FlutterFlowTheme.of(context)
                //                           .bodyMedium
                //                           .fontStyle,
                //                     ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ].divide(SizedBox(height: 8.0)),
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         '9n8ry32v' /* Promotions */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Row(
                //               mainAxisSize: MainAxisSize.max,
                //               children: [
                //                 Icon(
                //                   Icons.local_offer,
                //                   color: Color(0xFF948C8C),
                //                   size: 20.0,
                //                 ),
                //                 Text(
                //                   FFLocalizations.of(context).getText(
                //                     'gb7bjv1c' /* Promotions */,
                //                   ),
                //                   style: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .override(
                //                         font: GoogleFonts.inter(
                //                           fontWeight: FontWeight.normal,
                //                           fontStyle:
                //                               FlutterFlowTheme.of(context)
                //                                   .bodyMedium
                //                                   .fontStyle,
                //                         ),
                //                         color: Color(0xFF948C8C),
                //                         fontSize: 14.0,
                //                         letterSpacing: 0.0,
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                 ),
                //               ].divide(SizedBox(width: 12.0)),
                //             ),
                //             Icon(
                //               Icons.chevron_right,
                //               color: FlutterFlowTheme.of(context).accent1,
                //               size: 20.0,
                //             ),
                //           ],
                //         ),
                //         Divider(
                //           height: 1.0,
                //           thickness: 1.0,
                //           color: Color(0xFFD9D9D9),
                //         ),
                //         Row(
                //           mainAxisSize: MainAxisSize.max,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Icon(
                //               Icons.add,
                //               color: Color(0xFF948C8C),
                //               size: 20.0,
                //             ),
                //             Padding(
                //               padding: EdgeInsetsDirectional.fromSTEB(
                //                   12.0, 0.0, 12.0, 0.0),
                //               child: Text(
                //                 FFLocalizations.of(context).getText(
                //                   'ae6qnm0p' /* Add promo code */,
                //                 ),
                //                 style: FlutterFlowTheme.of(context)
                //                     .bodyMedium
                //                     .override(
                //                       font: GoogleFonts.inter(
                //                         fontWeight: FontWeight.normal,
                //                         fontStyle: FlutterFlowTheme.of(context)
                //                             .bodyMedium
                //                             .fontStyle,
                //                       ),
                //                       color: Color(0xFF948C8C),
                //                       fontSize: 14.0,
                //                       letterSpacing: 0.0,
                //                       fontWeight: FontWeight.normal,
                //                       fontStyle: FlutterFlowTheme.of(context)
                //                           .bodyMedium
                //                           .fontStyle,
                //                     ),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ].divide(SizedBox(height: 8.0)),
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
                // Column(
                //   mainAxisSize: MainAxisSize.max,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       FFLocalizations.of(context).getText(
                //         'gtwmsvor' /* Referrals */,
                //       ),
                //       style: FlutterFlowTheme.of(context).titleMedium.override(
                //             font: GoogleFonts.interTight(
                //               fontWeight: FontWeight.w500,
                //               fontStyle: FlutterFlowTheme.of(context)
                //                   .titleMedium
                //                   .fontStyle,
                //             ),
                //             color: FlutterFlowTheme.of(context).accent1,
                //             fontSize: 16.0,
                //             letterSpacing: 0.0,
                //             fontWeight: FontWeight.w500,
                //             fontStyle: FlutterFlowTheme.of(context)
                //                 .titleMedium
                //                 .fontStyle,
                //           ),
                //     ),
                //     Row(
                //       mainAxisSize: MainAxisSize.max,
                //       crossAxisAlignment: CrossAxisAlignment.center,
                //       children: [
                //         Icon(
                //           Icons.add,
                //           color: Color(0xFF948C8C),
                //           size: 20.0,
                //         ),
                //         Padding(
                //           padding: EdgeInsetsDirectional.fromSTEB(
                //               12.0, 0.0, 12.0, 0.0),
                //           child: Text(
                //             FFLocalizations.of(context).getText(
                //               'bqk65ixo' /* Add referral code */,
                //             ),
                //             style: FlutterFlowTheme.of(context)
                //                 .bodyMedium
                //                 .override(
                //                   font: GoogleFonts.inter(
                //                     fontWeight: FontWeight.normal,
                //                     fontStyle: FlutterFlowTheme.of(context)
                //                         .bodyMedium
                //                         .fontStyle,
                //                   ),
                //                   color: Color(0xFF948C8C),
                //                   fontSize: 14.0,
                //                   letterSpacing: 0.0,
                //                   fontWeight: FontWeight.normal,
                //                   fontStyle: FlutterFlowTheme.of(context)
                //                       .bodyMedium
                //                       .fontStyle,
                //                 ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ].divide(SizedBox(height: 16.0)),
                // ),
              ]
                  .divide(SizedBox(height: 24.0))
                  .addToStart(SizedBox(height: 16.0))
                  .addToEnd(SizedBox(height: 24.0)),
            ),
          ),
        ),
      ),
    );
  }
}
