import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class SearchingRideComponent extends StatefulWidget {
  final int searchSeconds;
  final VoidCallback onCancel;

  const SearchingRideComponent({
    Key? key,
    required this.searchSeconds,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SearchingRideComponent> createState() => _SearchingRideComponentState();
}

class _SearchingRideComponentState extends State<SearchingRideComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color primaryColor = Color(0xFFFF7B10);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24), // Reduced from 32

          // Search Animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80, // Reduced from 100
              height: 80, // Reduced from 100
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                color: primaryColor,
                size: 40, // Reduced from 50
              ),
            ),
          ),
          const SizedBox(height: 20), // Reduced from 24

          // Title
          Text(
            'Finding your Ride',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20, // Reduced from 22
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Searching for nearby drivers...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),

          // Timer
          Text(
            '${widget.searchSeconds}s',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20), // Added spacing back but smaller

          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 52, // Slightly smaller from 56
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.alternate),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel Search',
                style: GoogleFonts.inter(
                  fontSize: 15, // Slightly smaller
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
