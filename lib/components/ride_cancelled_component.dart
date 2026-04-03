import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class RideCancelledComponent extends StatelessWidget {
  final VoidCallback onBackToHome;
  final VoidCallback? onFindNewRide;
  final VoidCallback? onRebook;
  final int rebookingFee;
  final bool cancelledByDriver;

  const RideCancelledComponent({
    Key? key,
    required this.onBackToHome,
    this.onFindNewRide,
    this.onRebook,
    this.rebookingFee = 20,
    this.cancelledByDriver = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cancel Icon
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cancel_outlined,
              size: 60,
              color: theme.error,
            ),
          ),
          SizedBox(height: 24),

          // Title
          Text(
            'Ride Cancelled',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          SizedBox(height: 12),

          // Subtitle
          Text(
            cancelledByDriver
                ? 'Driver not available. You can rebook instantly.'
                : 'Your ride has been cancelled successfully',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          SizedBox(height: 32),

          // Rebook Ride Button (Rapido Style)
          if (onRebook != null) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onRebook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Rebook Ride + ₹$rebookingFee',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Find new ride (primary when driver cancels)
          if (onFindNewRide != null) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onFindNewRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Find new ride',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryBackground,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: onBackToHome,
              child: Text(
                'Back to Home',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: onBackToHome,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
