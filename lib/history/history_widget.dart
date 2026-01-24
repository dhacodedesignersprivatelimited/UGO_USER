import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'history_model.dart';
export 'history_model.dart';

/// Past Booking History List - Refined for Dynamic Status
class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  static String routeName = 'History';
  static String routePath = '/history';

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> with TickerProviderStateMixin {
  late HistoryModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HistoryModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _animationController.forward();
      await _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    debugPrint('🔄 Fetching ride history for userId: ${FFAppState().userid}');
    final response = await _model.fetchRideHistory();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10),
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              FlutterFlowIconButton(
                borderRadius: 12,
                buttonSize: 40,
                fillColor: Colors.white.withOpacity(0.2),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => context.safePop(),
              ),
              const SizedBox(width: 16),
              Text(
                'Your Trips',
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
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildBody(constraints);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BoxConstraints constraints) {
    if (_model.rideHistoryResponse == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF7B10),
          strokeWidth: 3,
        ),
      );
    }

    var rides = getJsonField(_model.rideHistoryResponse?.jsonBody, r'''$.data.rides''') as List?;
    
    if (rides == null || rides.isEmpty) {
      return _buildEmptyState(constraints.maxHeight);
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFFFF7B10),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index / rides!.length).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOut,
                ),
              )),
              child: _buildRideCard(rides[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(double height) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: const Icon(Icons.history_rounded, size: 48, color: Color(0xFFFF7B10)),
            ),
            const SizedBox(height: 24),
            Text(
              'No trips found',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'Once you take a ride, your history will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            FFButtonWidget(
              onPressed: () => context.pushNamed('home'),
              text: 'Book a ride',
              options: FFButtonOptions(
                width: 180,
                height: 50,
                color: const Color(0xFFFF7B10),
                textStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                borderRadius: BorderRadius.circular(25),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(dynamic rideItem) {
    final rideId = getJsonField(rideItem, r'''$.ride_id''')?.toString() ?? 'N/A';
    final toLoc = getJsonField(rideItem, r'''$.to_location''')?.toString() ?? 'Destination';
    final dateStr = getJsonField(rideItem, r'''$.date''')?.toString() ?? '';
    final timeStr = getJsonField(rideItem, r'''$.time''')?.toString() ?? '';
    final amount = getJsonField(rideItem, r'''$.amount''')?.toString() ?? '0';
    
    // Exact keys from your request: cancelled, completed, Searching in
    final status = getJsonField(rideItem, r'''$.ride_status''')?.toString() ?? 'Completed';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showRideDetails(rideItem),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          status.toLowerCase().contains('cancel') 
                            ? Icons.close_rounded 
                            : status.toLowerCase().contains('search')
                              ? Icons.search_rounded
                              : Icons.directions_car_filled_rounded,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              toLoc,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dateStr • $timeStr',
                              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹$amount',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.black),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trip ID: #$rideId',
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'DETAILS',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF7B10),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRideDetails(dynamic rideItem) {
    final rideId = getJsonField(rideItem, r'''$.ride_id''')?.toString() ?? 'N/A';
    final pickup = getJsonField(rideItem, r'''$.from_location''')?.toString() ?? 'N/A';
    final drop = getJsonField(rideItem, r'''$.to_location''')?.toString() ?? 'N/A';
    final fare = getJsonField(rideItem, r'''$.amount''')?.toString() ?? '0';
    final driverName = getJsonField(rideItem, r'''$.driver_name''')?.toString() ?? 'N/A';
    final date = getJsonField(rideItem, r'''$.date''')?.toString() ?? '';
    final time = getJsonField(rideItem, r'''$.time''')?.toString() ?? '';
    final status = getJsonField(rideItem, r'''$.ride_status''')?.toString() ?? 'Completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ride Details', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _getStatusColor(status))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Trip ID: #$rideId', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.calendar_today_rounded, 'Date & Time', '$date $time'),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.person_rounded, 'Driver', driverName),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [const Icon(Icons.circle, color: Colors.green, size: 14), Container(width: 2, height: 40, color: const Color(0xFFEEEEEE)), const Icon(Icons.location_on, color: Color(0xFFFF7B10), size: 18)]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(pickup, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 20),
                      Text('Drop off', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(drop, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Fare', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  Text('₹$fare', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7B10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: Text('DONE', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text('$label:', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('completed')) return const Color(0xFF10B981);
    if (s.contains('cancelled')) return const Color(0xFFEF4444);
    if (s.contains('search')) return const Color(0xFFF59E0B);
    return const Color(0xFFFF7B10);
  }
}
