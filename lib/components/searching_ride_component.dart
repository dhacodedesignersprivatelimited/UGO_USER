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

  /// Socket `no_driver_found` — shown while still searching.
  final String? serverNudgeMessage;
  final double? serverSuggestedExtra;

  const SearchingRideComponent({
    Key? key,
    required this.searchSeconds,
    required this.onCancel,
    this.declineCount = 0,
    this.totalDriversNotified = 0,
    this.estimatedFare = 0,
    this.extraFare = 0,
    this.onRebookWithExtra,
    this.serverNudgeMessage,
    this.serverSuggestedExtra,
  }) : super(key: key);

  @override
  State<SearchingRideComponent> createState() => _SearchingRideComponentState();
}

class _SearchingRideComponentState extends State<SearchingRideComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color primaryColor = Color(0xFFFF7B10);
  static const Color primaryDeep = Color(0xFFE86500);
  static const Color surfaceWarm = Color(0xFFFFFBF7);

  /// Rapido-style first matching window (aligned with driver 30s offer + backend nudge).
  static const int _searchWindowSeconds = 30;
  static const List<int> _extraOptions = [30, 40, 50, 60];
  int? _selectedExtra;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _selectNearestExtraChip(double suggestedRs) {
    if (widget.onRebookWithExtra == null) return;
    int? best;
    var bestDiff = double.infinity;
    for (final o in _extraOptions) {
      final d = (o - suggestedRs).abs();
      if (d < bestDiff) {
        bestDiff = d;
        best = o;
      }
    }
    if (best != null && mounted) {
      setState(() => _selectedExtra = best);
    }
  }

  @override
  void didUpdateWidget(SearchingRideComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sug = widget.serverSuggestedExtra;
    if (sug != null &&
        sug > 0 &&
        sug != oldWidget.serverSuggestedExtra) {
      _selectNearestExtraChip(sug);
    }
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
    final progress = _searchWindowSeconds > 0
        ? remainingSeconds / _searchWindowSeconds
        : 0.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            surfaceWarm,
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Wider drag affordance (pairs with DraggableScrollableSheet)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),

            if (widget.declineCount > 0) ...[
              const SizedBox(height: 14),
              _buildDeclineBanner(theme),
            ],

            if (widget.serverNudgeMessage != null &&
                widget.serverNudgeMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildServerNudgeBanner(theme),
            ],

            const SizedBox(height: 18),

            _buildRideInfoRow(theme, rideType),

            const SizedBox(height: 22),

            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.22),
                        primaryColor.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.radar_rounded,
                      color: primaryColor,
                      size: 38,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Text(
              'Finding your $rideType',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.2,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'We\'re notifying nearby captains.\nHang tight — this usually takes a moment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              remainingSeconds > 0
                  ? '$mins:$secs left · first search round'
                  : 'Still searching — add a little extra to get noticed faster',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.grey.shade200),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryDeep,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            _buildExtraFareSection(theme),

            const SizedBox(height: 14),

            if (_selectedExtra != null && widget.onRebookWithExtra != null)
              _buildRebookButton(theme),

            if (_selectedExtra != null && widget.onRebookWithExtra != null)
              const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: theme.secondaryText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Cancel search',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerNudgeBanner(FlutterFlowTheme theme) {
    final sug = widget.serverSuggestedExtra;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF8F0),
            primaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.trending_up_rounded, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.serverNudgeMessage!.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF3E2723),
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sug != null && sug > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tip: add ~₹${sug.toStringAsFixed(0)} below — drivers prioritise higher fares.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.secondaryText,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCCBC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person_off_rounded, color: primaryDeep, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF5D4037),
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '${widget.declineCount}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: primaryDeep,
                      fontSize: 15,
                    ),
                  ),
                  if (total > widget.declineCount) ...[
                    TextSpan(
                      text: ' of $total',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: primaryDeep,
                        fontSize: 15,
                      ),
                    ),
                  ],
                  TextSpan(
                    text:
                        " captain${widget.declineCount == 1 ? '' : 's'} couldn't take this ride",
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

    final displayFare = widget.estimatedFare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.14),
                  primaryColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              rideType.toLowerCase() == 'bike'
                  ? Icons.two_wheeler_rounded
                  : rideType.toLowerCase() == 'car'
                      ? Icons.directions_car_rounded
                      : Icons.local_taxi_rounded,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rideType ride',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${displayFare.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (widget.extraFare > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+₹${widget.extraFare.toStringAsFixed(0)} boost',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 20, color: theme.secondaryText),
              const SizedBox(height: 4),
              Text(
                'Fare quote',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtraFareSection(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/boost_icon.png',
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.2),
                        primaryColor.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: primaryColor, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get matched faster',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A small add-on helps your offer stand out to captains.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.35,
                        color: theme.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _extraOptions.map((amount) {
              final isSelected = _selectedExtra == amount;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedExtra = isSelected ? null : amount;
                  }),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.12)
                          : const Color(0xFFF7F7F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      '+ ₹$amount',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? primaryDeep : theme.secondaryText,
                      ),
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
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [primaryColor, primaryDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_selectedExtra != null) {
              widget.onRebookWithExtra?.call(_selectedExtra!);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'Search again with + ₹${_selectedExtra}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
