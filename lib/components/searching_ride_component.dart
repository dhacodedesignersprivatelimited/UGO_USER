import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SearchingRideComponent extends StatefulWidget {
  final int searchSeconds;
  final VoidCallback onCancel;
  final int declineCount;
  final int totalDriversNotified;
  final double estimatedFare;
  final double extraFare;
  final void Function(int extraAmount)? onRebookWithExtra;

  const SearchingRideComponent({
    Key? key,
    required this.searchSeconds,
    required this.onCancel,
    this.declineCount = 0,
    this.totalDriversNotified = 0,
    this.estimatedFare = 0,
    this.extraFare = 0,
    this.onRebookWithExtra,
  }) : super(key: key);

  @override
  State<SearchingRideComponent> createState() => _SearchingRideComponentState();
}

class _SearchingRideComponentState extends State<SearchingRideComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color primaryColor = Color(0xFFFF7B10);
  static const int _searchWindowSeconds = 120;
  static const List<int> _extraOptions = [30, 40, 50, 60];
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

          // Decline count banner
          if (widget.declineCount > 0) ...[
            const SizedBox(height: 16),
            _buildDeclineBanner(theme),
          ],

          const SizedBox(height: 20),

          // Ride info row (type + fare)
          _buildRideInfoRow(theme, rideType),

          const SizedBox(height: 20),

          // Search Animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                color: primaryColor,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Finding your $rideType ride',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),

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
          const SizedBox(height: 20),

          // Extra fare section
          _buildExtraFareSection(theme),

          const SizedBox(height: 16),

          // Rebook with extra button
          if (_selectedExtra != null && widget.onRebookWithExtra != null)
            _buildRebookButton(theme),

          if (_selectedExtra != null && widget.onRebookWithExtra != null)
            const SizedBox(height: 12),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 52,
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
                  fontSize: 15,
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

  Widget _buildDeclineBanner(FlutterFlowTheme theme) {
    final total = widget.totalDriversNotified > 0
        ? widget.totalDriversNotified
        : widget.declineCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_off_rounded,
                color: primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF5D4037),
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: '${widget.declineCount}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      fontSize: 15,
                    ),
                  ),
                  if (total > widget.declineCount) ...[
                    TextSpan(
                      text: ' of $total',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                  TextSpan(
                    text: " captain${widget.declineCount == 1 ? '' : 's'} didn't accept your ride",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideInfoRow(FlutterFlowTheme theme, String rideType) {
    if (widget.estimatedFare <= 0) return const SizedBox.shrink();

    final displayFare = widget.estimatedFare + widget.extraFare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              rideType.toLowerCase() == 'bike'
                  ? Icons.two_wheeler_rounded
                  : rideType.toLowerCase() == 'car'
                      ? Icons.directions_car_rounded
                      : Icons.local_taxi_rounded,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rideType Ride',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '₹${displayFare.toStringAsFixed(1)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryText,
                      ),
                    ),
                    if (widget.extraFare > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+₹${widget.extraFare.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Trip Details',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraFareSection(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/boost_icon.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: primaryColor, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Increase your chances by adding extra',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    '+ ₹$amount',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? primaryColor : theme.secondaryText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRebookButton(FlutterFlowTheme theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          if (_selectedExtra != null) {
            widget.onRebookWithExtra?.call(_selectedExtra!);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'New Search with + ₹${_selectedExtra}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
