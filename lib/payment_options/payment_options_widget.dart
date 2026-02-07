import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_options_model.dart';
export 'payment_options_model.dart';

class PaymentOptionsWidget extends StatefulWidget {
  const PaymentOptionsWidget({super.key});

  static String routeName = 'payment_options';
  static String routePath = '/paymentOptions';

  @override
  State<PaymentOptionsWidget> createState() => _PaymentOptionsWidgetState();
}

class _PaymentOptionsWidgetState extends State<PaymentOptionsWidget> {
  late PaymentOptionsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymentOptionsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _selectPaymentMethod(String method) {
    // Return selected method to previous screen
    context.pop(method);
  }

  @override
  Widget build(BuildContext context) {
    final double walletBalance = FFAppState().walletBalance; // Ensure this exists in AppState

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30,
          borderWidth: 1,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Select Payment',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
            font: GoogleFonts.interTight(),
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Choose how you want to pay for your ride',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(),
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CASH
            _buildOption(
              context,
              name: 'Cash',
              icon: Icons.money,
              color: const Color(0xFF1B5E20),
              subtitle: 'Pay directly to driver',
            ),

            // WALLET
            _buildOption(
              context,
              name: 'Wallet',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFFFF7B10),
              subtitle: 'Balance: ₹${walletBalance.toStringAsFixed(2)}',
            ),

            // ONLINE
            _buildOption(
              context,
              name: 'Online',
              icon: Icons.qr_code,
              color: Colors.blue,
              subtitle: 'UPI, Credit/Debit Card',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required String name, required IconData icon, required Color color, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _selectPaymentMethod(name),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}