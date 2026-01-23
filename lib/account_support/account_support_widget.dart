import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_support_model.dart';
export 'account_support_model.dart';

class AccountSupportWidget extends StatefulWidget {
  const AccountSupportWidget({super.key});

  static String routeName = 'Account_support';
  static String routePath = '/accountSupport';

  @override
  State<AccountSupportWidget> createState() => _AccountSupportWidgetState();
}

class _AccountSupportWidgetState extends State<AccountSupportWidget> {
  late AccountSupportModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Mock dynamic data structure like Uber
  final List<Map<String, dynamic>> supportCategories = [
    {
      'title': 'Can\'t sign in or request a trip',
      'icon': Icons.login_rounded,
      'id': 'auth_issues',
    },
    {
      'title': 'Account settings',
      'icon': Icons.settings_outlined,
      'id': 'account_settings',
    },
    {
      'title': 'Payment methods',
      'icon': Icons.payment_rounded,
      'id': 'payment_methods',
    },
    {
      'title': 'Gift cards and vouchers',
      'icon': Icons.card_giftcard_rounded,
      'id': 'vouchers',
    },
    {
      'title': 'Promos and partnerships',
      'icon': Icons.local_offer_outlined,
      'id': 'promos',
    },
    {
      'title': 'Uber Cash',
      'icon': Icons.account_balance_wallet_outlined,
      'id': 'cash',
    },
    {
      'title': 'Receipts and invoices',
      'icon': Icons.receipt_long_rounded,
      'id': 'receipts',
    },
    {
      'title': 'Duplicate or unknown charges',
      'icon': Icons.report_problem_outlined,
      'id': 'charges',
    },
    {
      'title': 'Rider insurance',
      'icon': Icons.verified_user_outlined,
      'id': 'insurance',
    },
    {
      'title': 'I lost my phone',
      'icon': Icons.phone_android_rounded,
      'id': 'lost_phone',
    },
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccountSupportModel());
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
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Account',
            style: GoogleFonts.inter(
              color: Colors.black,
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
              // Dynamic Header like Uber
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Text(
                  'How can we help with your account?',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.black,
                  ),
                ),
              ),
              
              // Dynamic List
              Expanded(
                child: ListView.separated(
                  itemCount: supportCategories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 56,
                    color: Color(0xFFEEEEEE),
                  ),
                  itemBuilder: (context, index) {
                    final item = supportCategories[index];
                    return InkWell(
                      onTap: () {
                        debugPrint('Support tapped: ${item['id']}');
                        // Implementation for specific support route
                      },
                      child: Container(
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFFBDBDBD),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Quick Contact Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Still need help?',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Our support team is available 24/7',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Contact Us',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
