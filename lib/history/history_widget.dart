import 'dart:async';

import 'package:ugouser/home/home_widget.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'booking_history_types.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'history_model.dart';
export 'history_model.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  static String routeName = 'History';
  static String routePath = '/history';

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  late HistoryModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  static const _brand = Color(0xFFFF7B10);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HistoryModel());
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _model.reloadBookings();
      if (mounted) setState(() {});
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      if (_model.hasMorePages &&
          !_model.isLoadingMore &&
          !_model.isLoadingInitial) {
        unawaited(_loadMore());
      }
    }
  }

  Future<void> _loadMore() async {
    await _model.loadBookingPage(reset: false);
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await _model.reloadBookings();
    if (mounted) setState(() {});
  }

  Future<void> _onStatusTab(BookingStatusTab tab) async {
    if (_model.statusTab == tab) return;
    setState(() => _model.statusTab = tab);
    await _model.reloadBookings();
    if (mounted) setState(() {});
  }

  Future<void> _onDatePreset(DateRangePreset preset) async {
    if (preset == DateRangePreset.custom) {
      await _pickCustomDateRange();
      return;
    }
    setState(() {
      _model.datePreset = preset;
      _model.customRangeStart = null;
      _model.customRangeEnd = null;
    });
    await _model.reloadBookings();
    if (mounted) setState(() {});
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _model.customRangeStart != null &&
              _model.customRangeEnd != null
          ? DateTimeRange(
              start: _model.customRangeStart!,
              end: _model.customRangeEnd!,
            )
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _brand),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (range == null) return;

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    if (start.isAfter(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date must be on or before end date'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _model.datePreset = DateRangePreset.custom;
      _model.customRangeStart = start;
      _model.customRangeEnd = end;
    });
    await _model.reloadBookings();
    if (mounted) setState(() {});
  }

  Future<void> _rebookRide(dynamic rideItem) async {
    final rawRideId = getJsonField(rideItem, r'''$.ride_id''');
    final rideId =
        rawRideId is int ? rawRideId : int.tryParse(rawRideId?.toString() ?? '');
    if (rideId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid trip id for rebooking')),
      );
      return;
    }

    final token = FFAppState().accessToken;
    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again to continue')),
      );
      return;
    }

    final response = await RebookRideCall.call(rideId: rideId, token: token);
    if (!mounted) return;
    if (response.succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ride booked again. Finding nearby driver...')),
      );
      context.goNamed(HomeWidget.routeName);
      return;
    }

    final message =
        RebookRideCall.message(response.jsonBody) ?? 'Unable to rebook this trip';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.goNamed(HomeWidget.routeName);
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: _brand,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                FlutterFlowIconButton(
                  borderRadius: 12,
                  buttonSize: 40,
                  fillColor: Colors.white.withValues(alpha: 0.2),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => context.goNamed(HomeWidget.routeName),
                ),
                const SizedBox(width: 16),
                Text(
                  'Booking history',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            elevation: 0,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusTabs(),
              _buildDateChips(),
              Expanded(child: _buildListArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: BookingStatusTab.values.map((tab) {
            final selected = _model.statusTab == tab;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: selected
                      ? _brand.withValues(alpha: 0.12)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _onStatusTab(tab),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        tab.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                          color: selected ? _brand : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateChips() {
    final presets = [
      DateRangePreset.allTime,
      DateRangePreset.today,
      DateRangePreset.yesterday,
      DateRangePreset.thisWeek,
      DateRangePreset.thisMonth,
      DateRangePreset.custom,
    ];

    String customLabel() {
      if (_model.datePreset != DateRangePreset.custom) {
        return DateRangePreset.custom.label;
      }
      if (_model.customRangeStart != null && _model.customRangeEnd != null) {
        final a = _model.customRangeStart!;
        final b = _model.customRangeEnd!;
        String m(DateTime d) =>
            '${d.day}/${d.month}/${d.year.toString().substring(2)}';
        return '${m(a)} – ${m(b)}';
      }
      return 'Custom range';
    }

    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final selected = _model.datePreset == p;
              final label =
                  p == DateRangePreset.custom ? customLabel() : p.label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => _onDatePreset(p),
                  selectedColor: _brand,
                  backgroundColor: const Color(0xFFF1F5F9),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: selected ? _brand : const Color(0xFFE2E8F0),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListArea() {
    if (_model.isLoadingInitial && _model.bookingRides.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _brand, strokeWidth: 3),
      );
    }

    if (_model.rideErrorMessage != null && _model.bookingRides.isEmpty) {
      return _buildMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        subtitle: _model.rideErrorMessage!,
        action: TextButton(
          onPressed: _refresh,
          child: Text('Retry', style: GoogleFonts.inter(color: _brand)),
        ),
      );
    }

    if (_model.bookingRides.isEmpty) {
      return RefreshIndicator(
        color: _brand,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: _buildMessageState(
                icon: Icons.event_busy_rounded,
                title: _model.bookingEmptyMessage(),
                subtitle:
                    'Try another tab or date filter, or book a new ride.',
                action: FFButtonWidget(
                  onPressed: () => context.goNamed(HomeWidget.routeName),
                  text: 'Book a ride',
                  options: FFButtonOptions(
                    width: 180,
                    height: 48,
                    color: _brand,
                    textStyle: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600),
                    borderRadius: BorderRadius.circular(24),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _brand,
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _model.bookingRides.length + (_model.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _model.bookingRides.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _brand,
                  ),
                ),
              ),
            );
          }
          return _buildRideCard(_model.bookingRides[index]);
        },
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(icon, size: 40, color: _brand),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _tierChip(dynamic bookingMode) {
    final colors = rideTierChipColors(bookingMode);
    final pro = isProBookingMode(bookingMode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
        boxShadow: pro
            ? [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pro) ...[
            Icon(Icons.workspace_premium_rounded, size: 15, color: colors.$2),
            const SizedBox(width: 5),
          ],
          Text(
            pro ? 'PRO' : 'Standard',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.$2,
              letterSpacing: pro ? 0.6 : 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(dynamic rideItem) {
    final rideId = getJsonField(rideItem, r'''$.ride_id''')?.toString() ?? '—';
    final pickup =
        getJsonField(rideItem, r'''$.from_location''')?.toString() ?? 'Pickup';
    final drop =
        getJsonField(rideItem, r'''$.to_location''')?.toString() ?? 'Drop-off';
    final dateStr = getJsonField(rideItem, r'''$.date''')?.toString() ?? '';
    final timeStr = getJsonField(rideItem, r'''$.time''')?.toString() ?? '';
    final amount = getJsonField(rideItem, r'''$.amount''')?.toString() ?? '0';
    final rawStatus =
        getJsonField(rideItem, r'''$.ride_status''')?.toString() ?? '';
    final badge = displayBookingStatus(rawStatus);
    final statusColor = bookingStatusColor(rawStatus);
    final bookingMode = getJsonField(rideItem, r'''$.booking_mode''');
    final tierAccent = rideTierCardAccent(bookingMode);
    final vehicleLabel = formatVehicleRideType(
        getJsonField(rideItem, r'''$.ride_type'''));

    const cardRadius = 16.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tierAccent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(cardRadius),
                        bottomLeft: Radius.circular(cardRadius),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showRideDetails(rideItem),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _tierChip(bookingMode),
                              const Spacer(),
                              if (vehicleLabel.isNotEmpty)
                                Text(
                                  '$vehicleLabel ride',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _locationRow(
                                      Icons.circle,
                                      const Color(0xFF22C55E),
                                      'Pickup',
                                      pickup,
                                    ),
                                    const SizedBox(height: 12),
                                    _locationRow(
                                      Icons.location_on_rounded,
                                      _brand,
                                      'Drop-off',
                                      drop,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹$amount',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      badge.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 6),
                              Text(
                                '$dateStr · $timeStr',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'ID #$rideId',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _showRideDetails(rideItem),
                                child: Text(
                                  'Details',
                                  style: GoogleFonts.inter(
                                    color: _brand,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _rebookRide(rideItem),
                                child: Text(
                                  'Book again',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationRow(
    IconData icon,
    Color color,
    String label,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRideDetails(dynamic rideItem) {
    final rideId = getJsonField(rideItem, r'''$.ride_id''')?.toString() ?? '—';
    final pickup =
        getJsonField(rideItem, r'''$.from_location''')?.toString() ?? '—';
    final drop =
        getJsonField(rideItem, r'''$.to_location''')?.toString() ?? '—';
    final fare = getJsonField(rideItem, r'''$.amount''')?.toString() ?? '0';
    final driverName =
        getJsonField(rideItem, r'''$.driver_name''')?.toString() ?? '—';
    final date = getJsonField(rideItem, r'''$.date''')?.toString() ?? '';
    final time = getJsonField(rideItem, r'''$.time''')?.toString() ?? '';
    final rawStatus =
        getJsonField(rideItem, r'''$.ride_status''')?.toString() ?? '';
    final badge = displayBookingStatus(rawStatus);
    final statusColor = bookingStatusColor(rawStatus);
    final bookingMode = getJsonField(rideItem, r'''$.booking_mode''');
    final tierDesc = rideTierDescription(bookingMode);
    final vehicleLabel = formatVehicleRideType(
        getJsonField(rideItem, r'''$.ride_type'''));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, 32 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ride details',
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Booking ID #$rideId',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _tierChip(bookingMode),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isProBookingMode(bookingMode)
                        ? 'Premium vehicles & priority matching'
                        : 'Everyday ride',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.calendar_today_rounded, 'Date & time', '$date $time'),
            const SizedBox(height: 14),
            _detailRow(
              Icons.local_taxi_rounded,
              'Ride class',
              vehicleLabel.isNotEmpty ? '$tierDesc · $vehicleLabel' : tierDesc,
            ),
            const SizedBox(height: 14),
            _detailRow(Icons.person_rounded, 'Driver', driverName),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 14),
                    Container(
                        width: 2, height: 40, color: const Color(0xFFEEEEEE)),
                    const Icon(Icons.location_on, color: _brand, size: 18),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(pickup,
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Text('Drop-off',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(drop,
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total fare',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('₹$fare',
                      style: GoogleFonts.inter(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rebookRide(rideItem),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _brand, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Book again',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: _brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label:',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.grey[600])),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
