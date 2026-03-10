import '/flutter_flow/flutter_flow_theme.dart';
import '/ride_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceiptWidget extends StatelessWidget {
  const ReceiptWidget({super.key});

  static String routeName = 'receipt';
  static String routePath = '/receipt';

  /// GST rate for ride-hailing (India) - 5%
  static const double _gstRate = 0.05;

  @override
  Widget build(BuildContext context) {
    final rideData = RideSession().rideData ?? {};
    final rideId = rideData['id']?.toString() ?? 'N/A';
    final pickup = rideData['pickup_location_address'] ?? 'Pickup';
    final drop = rideData['drop_location_address'] ?? 'Drop';
    final fareStr = rideData['estimated_fare']?.toString() ?? '0';
    final totalAmount = double.tryParse(fareStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    final payment =
        (rideData['payment_method'] ?? rideData['payment_type'] ?? 'cash')
            .toString();

    // GST breakdown (inclusive): base = total / (1 + rate), gst = total - base
    final baseFare = totalAmount / (1 + _gstRate);
    final gstAmount = totalAmount - baseFare;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        title: Text(
          'Receipt',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                font: GoogleFonts.interTight(),
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Ride ID', rideId),
            _row('Pickup', pickup),
            _row('Drop', drop),
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Divider(height: 1),
            ),
            _row('Fare (before GST)', '₹${baseFare.toStringAsFixed(2)}'),
            _row('GST (${(_gstRate * 100).toInt()}%)', '₹${gstAmount.toStringAsFixed(2)}'),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _row('Total', '₹${totalAmount.toStringAsFixed(2)}'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Divider(height: 1),
            ),
            _row('Payment', payment),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
