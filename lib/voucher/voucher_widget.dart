import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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

  // Mock coupons list like Uber
  final List<Map<String, dynamic>> availableCoupons = [
    {
      'code': 'UGONEW50',
      'title': '50% off on your first 3 rides',
      'expiry': 'Valid until 30 Nov',
      'description': 'Max discount ₹50 per ride. Valid on all vehicle types.',
      'color': const Color(0xFFFF7B10),
    },
    {
      'code': 'OFFICE20',
      'title': '₹20 off on daily commute',
      'expiry': 'Valid until 15 Nov',
      'description': 'Valid between 8 AM - 11 AM and 5 PM - 8 PM.',
      'color': Colors.blue,
    },
    {
      'code': 'WEEKEND30',
      'title': '30% off on Weekend trips',
      'expiry': 'Valid Sat & Sun',
      'description': 'Valid on rides above ₹100. Max discount ₹100.',
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VoucherModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
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
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Promo Code Input Section
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
                        color: Colors.grey[600],
                      ),
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
                                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            debugPrint('Applying code: ${_model.textController?.text}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(80, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Available Offers Section
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
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: availableCoupons.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final coupon = availableCoupons[index];
                            return _buildCouponCard(coupon);
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

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (coupon['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_offer_rounded, color: coupon['color'] as Color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon['title'] as String,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon['description'] as String,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coupon['expiry'] as String,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00D084)),
                      ),
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    coupon['code'] as String,
                    style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _model.textController?.text = coupon['code'] as String;
                    setState(() {});
                  },
                  child: Text(
                    'APPLY',
                    style: GoogleFonts.inter(color: const Color(0xFFFF7B10), fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
