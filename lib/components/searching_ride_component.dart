import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

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
  static const int _searchWindowSeconds = 120; // 2 mins
  static const List<int> _extraOptions = [10, 20, 30, 40];
  int? _selectedExtra;

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
    final rideTypeRaw = (FFAppState().selectedRideCategory ?? '').trim();
    final rideType = rideTypeRaw.isEmpty
        ? 'Bike'
        : '${rideTypeRaw[0].toUpperCase()}${rideTypeRaw.substring(1).toLowerCase()}';
    final remainingSeconds =
        (_searchWindowSeconds - widget.searchSeconds).clamp(0, _searchWindowSeconds);
    final mins = (remainingSeconds ~/ 60).toString();
    final secs = (remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = remainingSeconds / _searchWindowSeconds;

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
            'Finding your $rideType ride',
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
            '$mins:$secs · 2 mins',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 20), // Added spacing back but smaller

          // Extra options
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Increase your chances by adding extra',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _extraOptions.map((amount) {
                    final isSelected = _selectedExtra == amount;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedExtra = isSelected ? null : amount;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '+ ₹$amount',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? primaryColor
                                : theme.secondaryText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
