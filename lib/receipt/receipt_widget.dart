import '/flutter_flow/flutter_flow_theme.dart';
import '/ride_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceiptWidget extends StatelessWidget {
  const ReceiptWidget({super.key});

  static String routeName = 'receipt';
  static String routePath = '/receipt';

  @override
  Widget build(BuildContext context) {
    final rideData = RideSession().rideData ?? {};
    final rideId = rideData['id']?.toString() ?? 'N/A';
    final pickup = rideData['pickup_location_address'] ?? 'Pickup';
    final drop = rideData['drop_location_address'] ?? 'Drop';
    final fare = rideData['estimated_fare']?.toString() ?? '0';
    final payment =
        (rideData['payment_method'] ?? rideData['payment_type'] ?? 'cash')
            .toString();

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
            _row('Fare', '₹$fare'),
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
