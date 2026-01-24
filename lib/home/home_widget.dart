import '/components/menu_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'home_model.dart';
export 'home_model.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:url_launcher/url_launcher.dart';

/// Taxi Booking App Interface - Enhanced UI
class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> with SingleTickerProviderStateMixin {
  late HomeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool isScanning = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Color Constants for vibrant look
  static const Color primaryOrange = Color(0xFFFF7B10);
  static const Color deepOrange = Color(0xFFE65100);
  static const Color lightOrange = Color(0xFFFFAB40);
  static const Color cardBackground = Color(0xFFFFFBF5);
  static const Color shadowColor = Color(0x1AFF7B10);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());
    print("current location in home${FFAppState().pickupLatitude}and${FFAppState().pickupLongitude  }");
    // Pulse animation for QR button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRideStatus();
    });
  }

  Future<void> _checkRideStatus() async {
    final token = FFAppState().accessToken;
    if (token.isEmpty) return;

    try {
      final response = await GetRideStatus.call(
        userId: FFAppState().userid,
        token: token,
      );

      _model.apiResult85c = response;
      if (!response.succeeded) return;

      final rideId = getJsonField(
        _model.apiResult85c?.jsonBody,
        r'''$.data.rides[:].id''',
      );

      final rideCount = GetRideStatus.count(response.jsonBody);

      if (rideCount == null || rideCount == 0) {
        FFAppState().bookingInProgress = false;
      } else {
        FFAppState().bookingInProgress = true;
        final actualRideId = rideId is List && rideId.isNotEmpty ? rideId.first : rideId;
        if (mounted && actualRideId != null) {
          context.pushNamed(
            AutoBookWidget.routeName,
            queryParameters: {'rideId': actualRideId.toString()},
          );
        }
      }
    } catch (e) {
      debugPrint('Ride status check failed: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _handleQRScan() async {
    setState(() => isScanning = true);

    try {
      final scanResult = await FlutterBarcodeScanner.scanBarcode(
        '#FF7B10',
        FFLocalizations.of(context).getText('b01q6jhz'),
        true,
        ScanMode.BARCODE,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      if (scanResult == '-1') {
        setState(() => isScanning = false);
        return;
      }

      dynamic driverId;
      try {
        final decodedData = jsonDecode(scanResult);
        driverId = decodedData['driver_id'] ?? decodedData['id'];
      } catch (e) {
        driverId = int.tryParse(scanResult);
      }

      if (driverId != null) {
          context.pushNamed(
            DriverDetailsWidget.routeName,
            queryParameters: {
              'driverId': driverId.toString(),
            },
          );
      } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid QR Code. Driver ID not found.')),
          );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: ${e.toString()}')),
      );
    } finally {
      setState(() => isScanning = false);
    }
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = screenWidth * 0.05;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawer: Drawer(
          elevation: 16.0,
          child: InkWell(
            onTap: () => context.pushNamed(ServiceoptionsWidget.routeName),
            child: wrapWithModel(
              model: _model.menuModel,
              updateCallback: () => safeSetState(() {}),
              child: MenuWidget(),
            ),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            // ==================== CUSTOM APP BAR ====================
            SliverAppBar(
              expandedHeight: screenHeight * 0.38,
              floating: false,
              pinned: true,
              backgroundColor: primaryOrange,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 30),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
              ),
              title: Image.asset(
                'assets/images/k45cu8.png',
                width: isSmallScreen ? 70 : 90,
                fit: BoxFit.contain,
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 30),
                    onPressed: () {
                      context.pushNamed(PushnotificationsWidget.routeName);
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryOrange, deepOrange],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 70, horizontalPadding, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Search Bar
                        _buildSearchBar(context, isSmallScreen),
                        SizedBox(height: screenHeight * 0.02),

                        // "Get a Ride" Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              FFLocalizations.of(context).getText('en8fyguh'),
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.pushNamed(AvaliableOptionsWidget.routeName),
                              child: Row(
                                children: [
                                  Text(
                                    FFLocalizations.of(context).getText('76yoeddl'),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 12, color: Colors.white.withOpacity(0.9)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        // Action Buttons Row
                        _buildActionButtonsRow(context, screenWidth, isSmallScreen),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ==================== BODY CONTENT ====================
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Section Header
                    Text(
                      FFLocalizations.of(context).getText('jbh9xjpf'),
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Promotional Banner
                    _buildPromoBanner(context, screenWidth),
                    const SizedBox(height: 20),

                    // Quick Action Card
                    _buildQuickActionCard(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== REUSABLE WIDGETS ====================

  Widget _buildSearchBar(BuildContext context, bool isSmallScreen) {
    return InkWell(
      onTap: () => context.pushNamed(PlanYourRideWidget.routeName),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 20,
          vertical: isSmallScreen ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded, color: primaryOrange, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                FFLocalizations.of(context).getText('h1w2v3fi'),
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: lightOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Now',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: deepOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow(BuildContext context, double screenWidth, bool isSmallScreen) {
    return Row(
      children: [
        // Location Button
        _buildActionButton(
          icon:  Icons.location_on_rounded,
          iconColor:FFAppState().droplocation==null ? const Color(0xFFFF0000) : const Color(0xFF4CAF50),
          onTap: () => context.pushNamed(ChooseDestinationWidget.routeName),
          width: isSmallScreen ? 55 : 65,
        ),
        const SizedBox(width: 12),

        // QR Scan Button (Expanded)
        Expanded(
          child: ScaleTransition(
            scale: isScanning ? const AlwaysStoppedAnimation(1.0) : _pulseAnimation,
            child: InkWell(
              onTap: isScanning
                  ? null
                  : () {
                if (FFAppState().droplocation == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text('Please select a drop location first'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                _handleQRScan();
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 14 : 18,
                  vertical: isSmallScreen ? 14 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isScanning
                      ? Border.all(color: lightOrange, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isSmallScreen ? 32 : 38,
                      height: isSmallScreen ? 32 : 38,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryOrange, deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: isScanning
                          ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        isScanning
                            ? 'Scanning...'
                            : FFLocalizations.of(context).getText('dtkvc9rl'),
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required double width,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        height: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: width * 0.45),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context, double screenWidth) {
    return InkWell(
      onTap: () {
        // Navigate to offers or plan ride
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: screenWidth * 0.45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/skdkzv.png',
                fit: BoxFit.cover,
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Text Content
              Positioned(
                left: 20,
                bottom: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          FFLocalizations.of(context).getText('96ev15d0'),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FFLocalizations.of(context).getText('39myr84r'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context) {
    return InkWell(
      onTap: () {
        // Handle quick booking
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardBackground, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryOrange.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryOrange, deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FFLocalizations.of(context).getText('imvzfpcd'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get a ride in minutes',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: primaryOrange, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
