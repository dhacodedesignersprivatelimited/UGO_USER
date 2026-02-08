import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VoucherModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
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
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter promo code',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
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
                              decoration: InputDecoration(
                                hintText: 'Example: SAVE50',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final code = _model.textController?.text.toUpperCase() ?? '';
                            final coupon = _vouchers.firstWhere(
                              (c) => c['code_name'].toString().toUpperCase() == code,
                              orElse: () => null,
                            );
                            if (coupon != null) {
                              final disc = double.tryParse(coupon['discount_value']?.toString() ?? '0') ?? 0.0;
                              _applyVoucher(code, disc);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invalid promo code'), backgroundColor: Colors.red),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(80, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Text(
                          'Available Offers',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<ApiCallResponse>(
                          future: GetAllVouchersCall.call(token: FFAppState().accessToken),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: Colors.orange));
                            }
                            
                            if (snapshot.hasError || snapshot.data == null || !snapshot.data!.succeeded) {
                              debugPrint('Voucher API Error: ${snapshot.data?.jsonBody}');
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                                    const SizedBox(height: 16),
                                    Text('Failed to load coupons', style: GoogleFonts.inter(color: Colors.grey)),
                                    TextButton(onPressed: () => setState(() {}), child: const Text('Retry'))
                                  ],
                                ),
                              );
                            }
                            
                            _vouchers = GetAllVouchersCall.data(snapshot.data!.jsonBody) ?? [];
                            
                            if (_vouchers.isEmpty) {
                              return Center(
                                child: Text('No offers available at the moment', style: GoogleFonts.inter(color: Colors.grey)),
                              );
                            }

                            return ListView.separated(
                              itemCount: _vouchers.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
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

  Widget _buildCouponCard(dynamic v) {
    final code = v['code_name'] ?? 'PROMO';
    final discount = v['discount_value']?.toString() ?? '0';
    final type = v['discount_type'] ?? 'flat';
    final expiry = v['expiry_date'] != null ? 'Exp: ${v['expiry_date'].toString().split('T')[0]}' : 'No Expiry';
    
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
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_offer_rounded, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('Get a discount on your ride using this promo code.', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(expiry, style: GoogleFonts.inter(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(code, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                TextButton(
                  onPressed: () {
                    final disc = double.tryParse(discount) ?? 0.0;
                    _applyVoucher(code, disc);
                  },
                  child: const Text('APPLY', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
