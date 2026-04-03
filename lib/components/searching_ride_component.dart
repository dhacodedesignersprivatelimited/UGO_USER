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
  final VoidCallback? onTripDetails;

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
    this.onTripDetails,
    this.serverNudgeMessage,
    this.serverSuggestedExtra,
  }) : super(key: key);

  @override
  State<SearchingRideComponent> createState() => _SearchingRideComponentState();
}

class _SearchingRideComponentState extends State<SearchingRideComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  static const Color _primary = Color(0xFFFF7B10);
  static const Color _primaryDeep = Color(0xFFE86500);

  static const int _searchWindowSeconds = 30;
  static const List<int> _extraOptions = [30, 40, 50, 60];
  int? _selectedExtra;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchingRideComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sug = widget.serverSuggestedExtra;
    if (sug != null && sug > 0 && sug != oldWidget.serverSuggestedExtra) {
      _selectNearestExtraChip(sug);
    }
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

  String get _rideType {
    final raw = (FFAppState().selectedRideCategory ?? '').trim();
    if (raw.isEmpty) return 'Bike';
    return '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
  }

  String _formatFare(double fare) {
    if (fare == fare.roundToDouble()) return '₹${fare.toStringAsFixed(0)}';
    return '₹${fare.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final remainingSec = (_searchWindowSeconds - widget.searchSeconds)
        .clamp(0, _searchWindowSeconds);
    final progress =
        _searchWindowSeconds > 0 ? remainingSec / _searchWindowSeconds : 0.0;
    final total = widget.totalDriversNotified > 0
        ? widget.totalDriversNotified
        : widget.declineCount;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            const SizedBox(height: 14),
            if (widget.declineCount > 0) ...[
              _declineBanner(total, theme),
              const SizedBox(height: 12),
            ],
            _progressBar(progress),
            const SizedBox(height: 16),
            _rideInfoRow(theme),
            const SizedBox(height: 16),
            if (widget.serverNudgeMessage != null &&
                widget.serverNudgeMessage!.trim().isNotEmpty) ...[
              _serverNudgeBanner(theme),
              const SizedBox(height: 16),
            ],
            _extraFareCard(theme),
            if (_selectedExtra != null && widget.onRebookWithExtra != null) ...[
              const SizedBox(height: 14),
              _rebookCta(theme),
            ],
            const SizedBox(height: 12),
            _cancelButton(theme),
          ],
        ),
      ),
    );
  }

  // ── Drag Handle ──

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Decline Banner ──

  Widget _declineBanner(int total, FlutterFlowTheme theme) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: '${widget.declineCount}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: _primary,
              fontSize: 16,
            ),
          ),
          if (total > widget.declineCount)
            TextSpan(
              text: ' of $total',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: _primary,
                fontSize: 16,
              ),
            ),
          TextSpan(
            text:
                " captain${widget.declineCount == 1 ? '' : 's'} didn't accept your ride",
          ),
        ],
      ),
    );
  }

  // ── Progress Bar ──

  Widget _progressBar(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 6,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) {
            final displayProgress = progress > 0 ? progress : 0.05;
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.grey.shade200),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: displayProgress.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primary.withValues(
                            alpha: 0.7 + _pulseController.value * 0.3,
                          ),
                          _primaryDeep,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Ride Info + Trip Details ──

  Widget _rideInfoRow(FlutterFlowTheme theme) {
    final fareText = _formatFare(widget.estimatedFare);
    final rideType = _rideType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rideType Ride',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      fareText,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (widget.extraFare > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+₹${widget.extraFare.toStringAsFixed(0)}',
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTripDetails,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD4D4D4)),
                ),
                child: Text(
                  'Trip Details',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Server Nudge Banner ──

  Widget _serverNudgeBanner(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.trending_up_rounded, color: _primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.serverNudgeMessage!.trim(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5D4037),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Extra Fare Card (Chips) ──

  Widget _extraFareCard(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
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
                    gradient: LinearGradient(colors: [
                      _primary.withValues(alpha: 0.18),
                      _primary.withValues(alpha: 0.06),
                    ]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.bolt_rounded, color: _primary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Increase your chances by adding extra',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _extraOptions.map(_buildChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(int amount) {
    final isSelected = _selectedExtra == amount;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedExtra = isSelected ? null : amount;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primary : const Color(0xFFD4D4D4),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          '+ ₹$amount',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }

  // ── Rebook CTA ──

  Widget _rebookCta(FlutterFlowTheme theme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_selectedExtra != null) {
              widget.onRebookWithExtra?.call(_selectedExtra!);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFBF00), Color(0xFFFFA000)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFBF00).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'New Search with + ₹$_selectedExtra',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Cancel ──

  Widget _cancelButton(FlutterFlowTheme theme) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: widget.onCancel,
        style: TextButton.styleFrom(
          foregroundColor: theme.secondaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Cancel search',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
