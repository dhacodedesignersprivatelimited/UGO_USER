import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'wallet_history_model.dart';
export 'wallet_history_model.dart';

/// Full wallet transaction list with filter, search, and text export (PDF-style summary).
class WalletHistoryWidget extends StatefulWidget {
  const WalletHistoryWidget({super.key});

  static String routeName = 'WalletHistory';
  static String routePath = '/walletHistory';

  @override
  State<WalletHistoryWidget> createState() => _WalletHistoryWidgetState();
}

class _WalletHistoryWidgetState extends State<WalletHistoryWidget> {
  late WalletHistoryModel _model;
  final _search = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WalletHistoryModel());
    _load();
  }

  Future<void> _load() async {
    final app = FFAppState();
    if (app.accessToken.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final res = await GetWalletTransactionsMeCall.call(
      token: app.accessToken,
      page: 1,
      limit: 100,
      transactionType: _typeFilter,
    );
    final raw = GetWalletTransactionsMeCall.transactions(res.jsonBody) ?? [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) list.add(Map<String, dynamic>.from(item));
    }
    if (mounted) {
      setState(() {
        _all = list;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _all.where((m) {
      if (q.isEmpty) return true;
      final d = '${m['description'] ?? ''} ${m['transaction_type'] ?? ''}'.toLowerCase();
      return d.contains(q);
    }).toList();
  }

  Future<void> _exportShare() async {
    final buf = StringBuffer('UGO Wallet transactions\n');
    buf.writeln(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));
    buf.writeln('---');
    for (final m in _filtered) {
      final c = m['coins'];
      final amt = m['amount'];
      buf.writeln(
          '${m['created_at'] ?? ''} | ${m['transaction_type'] ?? ''} | amt=${amt ?? ''} coins=${c ?? ''} | ${m['description'] ?? ''}');
    }
    await Share.share(buf.toString(), subject: 'UGO wallet history');
  }

  @override
  void dispose() {
    _search.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.secondaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30,
          buttonSize: 60,
          icon: Icon(Icons.arrow_back_rounded, color: theme.secondaryBackground, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Transaction history',
          style: theme.titleLarge.override(
            font: GoogleFonts.interTight(),
            color: theme.secondaryBackground,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share, color: theme.secondaryBackground),
            onPressed: _filtered.isEmpty ? null : _exportShare,
            tooltip: 'Export / share',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search description or type',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.primaryBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _typeFilter,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      filled: true,
                      fillColor: theme.primaryBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All types')),
                      ...{
                        for (final m in _all) '${m['transaction_type'] ?? ''}'
                      }.where((t) => t.isNotEmpty).map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          ),
                    ],
                    onChanged: (v) {
                      setState(() => _typeFilter = v);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Tip: pick a type to filter on server; search filters the loaded page.',
              style: theme.bodySmall,
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: theme.accent1))
                : _filtered.isEmpty
                    ? Center(child: Text('No transactions', style: theme.bodyLarge))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final m = _filtered[i];
                          final amt = m['amount'];
                          final coinsRaw = m['coins'];
                          final coins = int.tryParse('$coinsRaw');
                          final rupeeEq = m['rupee_equivalent'];
                          final sign = amt != null && (num.tryParse('$amt') ?? 0) >= 0 ? '+' : '';
                          final String trailingText;
                          if (coins != null && coins != 0) {
                            final coinSign = coins > 0 ? '+' : '';
                            trailingText =
                                '$coinSign$coins coins${rupeeEq != null ? ' (₹$rupeeEq)' : ''}';
                          } else {
                            trailingText = '$sign₹${amt ?? '0'}';
                          }
                          return ListTile(
                            title: Text(
                              '${m['transaction_type'] ?? '—'}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${m['description'] ?? ''}\n${m['created_at'] ?? ''}',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            trailing: Text(
                              trailingText,
                              style: GoogleFonts.interTight(
                                fontWeight: FontWeight.w700,
                                color: theme.accent1,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
