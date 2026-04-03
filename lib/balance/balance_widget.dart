import '/app_state.dart';
import '/backend/api_requests/api_calls.dart';
import '/utils/coin_wallet_inr.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'balance_model.dart';
export 'balance_model.dart';

/// Balance Overview Screen
class BalanceWidget extends StatefulWidget {
  const BalanceWidget({super.key});

  static String routeName = 'Balance';
  static String routePath = '/balance';

  @override
  State<BalanceWidget> createState() => _BalanceWidgetState();
}

class _BalanceWidgetState extends State<BalanceWidget> {
  late BalanceModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;
  double _balance = 0;
  double _totalAdded = 0;
  double _totalSpent = 0;
  int _coinsBalance = 0;
  List<Map<String, String>> _recentLines = [];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BalanceModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBalanceData());
  }

  Future<void> _loadBalanceData() async {
    final app = FFAppState();
    final uid = app.userid;
    final token = app.accessToken;
    if (uid <= 0 || token.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    double bal = 0;
    double added = 0;
    double spent = 0;
    final List<Map<String, String>> lines = [];
    var coinsLoadedFromSummary = false;

    try {
      final sum = await GetWalletSummaryCall.call(token: token);
      if (sum.succeeded) {
        final main = GetWalletSummaryCall.mainWalletInr(sum.jsonBody);
        if (main != null) bal = main;
        final c = GetWalletSummaryCall.coins(sum.jsonBody) ?? 0;
        app.coinsBalance = c;
        coinsLoadedFromSummary = true;
      }
    } catch (_) {}

    if (!coinsLoadedFromSummary) {
      try {
        final userRes = await GetUserByIdCall.call(userId: uid, token: token);
        if (userRes.succeeded) {
          app.coinsBalance =
              GetUserByIdCall.coinsBalance(userRes.jsonBody) ?? 0;
        }
      } catch (_) {}
    }

    try {
      final w = await GetwalletCall.call(userId: uid, token: token);
      if (w.succeeded) {
        if (bal == 0) {
          bal = GetwalletCall.walletBalanceDouble(w.jsonBody) ??
              double.tryParse(GetwalletCall.walletBalance(w.jsonBody) ?? '') ??
              0;
        }
        added = double.tryParse(
                GetwalletCall.totalRechargeAmount(w.jsonBody) ?? '') ??
            0;
        spent =
            double.tryParse(GetwalletCall.totalSpentAmount(w.jsonBody) ?? '') ??
                0;
      }
    } catch (_) {}

    try {
      final t = await GetUserTransactionsCall.call(
        userId: uid,
        token: token,
        page: 1,
        limit: 15,
      );
      if (t.succeeded) {
        final raw = GetUserTransactionsCall.transactions(t.jsonBody) ?? [];
        for (final item in raw) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final amt = (m['amount'] is num)
              ? (m['amount'] as num).toDouble()
              : double.tryParse(m['amount']?.toString() ?? '') ?? 0;
          final desc = m['description']?.toString() ??
              m['type']?.toString() ??
              'Activity';
          final type = m['type']?.toString() ?? '';
          final when =
              m['created_at']?.toString() ?? m['date']?.toString() ?? '';
          final sign = amt >= 0 ? '+' : '';
          lines.add({
            'title': desc,
            'subtitle': '$type • ${_shortDate(when)}',
            'amount': '$sign₹${amt.abs().toStringAsFixed(2)}',
            'positive': amt >= 0 ? '1' : '0',
          });
          if (lines.length >= 15) break;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _balance = bal;
      _totalAdded = added;
      _totalSpent = spent;
      _coinsBalance = app.coinsBalance;
      _recentLines = lines;
      _loading = false;
    });
  }

  String _shortDate(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  void dispose() {
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
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'cw8x5cg4' /* Ugo balance */,
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
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                  child: _loading
                      ? SizedBox(
                          height: 44,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: FlutterFlowTheme.of(context).accent1,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              '₹${_balance.toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .displaySmall
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .displaySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).accent1,
                                    fontSize: 36.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .displaySmall
                                        .fontStyle,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Money you can pay with at checkout (wallet). Referral coins stay on the Wallet tab.',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.normal,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 12.0,
                                    ),
                              ),
                            ),
                            if (!_loading) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14.0),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Referral coins',
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.interTight(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .accent1,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CoinWalletInr.rateCaption(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.inter(),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 11,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Coins',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                              ),
                                            ),
                                            Text(
                                              '$_coinsBalance',
                                              style: GoogleFonts.interTight(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .accent1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Ride value',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                              ),
                                            ),
                                            Text(
                                              CoinWalletInr.formatInrLabel(
                                                  _coinsBalance),
                                              style: GoogleFonts.interTight(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .accent1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FFLocalizations.of(context).getText(
                        '8fo1zywz' /* Monthly activity */,
                      ),
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).accent1,
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                          ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: FlutterFlowTheme.of(context).accent1,
                              size: 20.0,
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                'hsnf3c9h' /* Ugo cash added */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).accent1,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                        Text(
                          _loading ? '…' : _totalAdded.toStringAsFixed(2),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).accent1,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ],
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: Color(0xFFE0E0E0),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: FlutterFlowTheme.of(context).accent1,
                              size: 20.0,
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                '9hrlimpg' /* Ugo cash spent */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).accent1,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(width: 12.0)),
                        ),
                        Text(
                          _loading ? '…' : _totalSpent.toStringAsFixed(2),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).accent1,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ],
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: Color(0xFFE0E0E0),
                    ),
                    Align(
                      alignment: AlignmentDirectional(-1.0, 0.0),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Totals above are all-time (from your wallet record).',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.inter(
                                  fontWeight: FontWeight.normal,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 12.0,
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        'Recent wallet activity (last 30 days)',
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  color: FlutterFlowTheme.of(context).accent1,
                                  fontSize: 16.0,
                                ),
                      ),
                    ),
                    if (_recentLines.isEmpty && !_loading)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          'No wallet transactions in the last 30 days. Add money from the Wallet screen or pay for a ride with wallet to see history here.',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                font: GoogleFonts.inter(),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 13.0,
                              ),
                        ),
                      )
                    else
                      ..._recentLines.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row['title'] ?? '',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            fontSize: 14.0,
                                          ),
                                    ),
                                    if ((row['subtitle'] ?? '').isNotEmpty)
                                      Text(
                                        row['subtitle']!,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              font: GoogleFonts.inter(),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 11.0,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                row['amount'] ?? '',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      color: row['positive'] == '1'
                                          ? const Color(0xFF2E7D32)
                                          : FlutterFlowTheme.of(context)
                                              .accent1,
                                      fontSize: 14.0,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ),
            ].divide(SizedBox(height: 24.0)).addToStart(SizedBox(height: 24.0)),
          ),
        ),
      ),
    );
  }
}
