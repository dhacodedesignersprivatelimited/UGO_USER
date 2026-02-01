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
import 'package:flutter/services.dart';

/// Taxi Booking App Interface - Enhanced UI
class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget>
    with SingleTickerProviderStateMixin {
  late HomeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool isScanning = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isCheckingRideStatus = false;

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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkRideStatus();
      });
    });
  }

  Future<void> _checkRideStatus() async {
    if (_isCheckingRideStatus || FFAppState().bookingInProgress) return;

    final token = FFAppState().accessToken;
    if (token.isEmpty) return;

    setState(() => _isCheckingRideStatus = true);

    try {
      final response = await GetRideStatus.call(
        userId: FFAppState().userid,
        token: token,
      );

      _model.apiResult85c = response;
      if (!mounted || !response.succeeded) return;

      final rideList = getJsonField(
        response.jsonBody,
        r'''$.data.rides''',
      );

      final rideCount = GetRideStatus.count(response.jsonBody);

      if (rideCount == null || rideCount == 0 || rideList == null) {
        FFAppState().bookingInProgress = false;
      } else if (rideList is List && rideList.isNotEmpty) {
        dynamic firstRide = rideList.first;
        dynamic rideId;

        if (firstRide is Map<String, dynamic>) {
          rideId = firstRide['id'];
        } else if (firstRide is Map) {
          rideId = firstRide['id'];
        } else {
          rideId = firstRide;
        }

        if (rideId != null) {
          FFAppState().bookingInProgress = true;
          if (mounted) {
            context.pushNamed(
              AutoBookWidget.routeName,
              queryParameters: {
                'rideId': rideId.toString(),
              },
            );
          }
        } else {
          FFAppState().bookingInProgress = false;
        }
      } else {
        FFAppState().bookingInProgress = false;
      }
    } catch (e) {
      debugPrint('Ride status check failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingRideStatus = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _handleQRScan() async {
    if (isScanning) return;

    setState(() => isScanning = true);

    try {
      final scanResult = await FlutterBarcodeScanner.scanBarcode(
        '#FF7B10',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      if (scanResult == '-1') {
        return;
      }

      dynamic driverId;
      try {
        if (scanResult.trim().startsWith('{')) {
          final decodedData = jsonDecode(scanResult);
          driverId = decodedData['driver_id'] ?? decodedData['id'];
        } else {
          driverId = int.tryParse(scanResult);
        }
      } catch (e) {
        debugPrint('QR decode error: $e');
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
          const SnackBar(
            content: Text('Invalid QR Code'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('QR Scan error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isScanning = false);
      }
    }
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

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
              child: const MenuWidget(),
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
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
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
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
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
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      70,
                      horizontalPadding,
                      10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildSearchBar(context, isSmallScreen),
                        SizedBox(height: screenHeight * 0.02),
                        // ✅ HEADER TEXT RESTORED
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Scan to Go',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        _buildActionButtonsRow(
                          context,
                          screenWidth,
                          isSmallScreen,
                        ),
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
                    // ✅ "OUR SERVICES" SECTION TITLE RESTORED
                    Text(
                      'Our Services',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRideTypeCard(image: 'assets/images/bike.png'),
                        _buildRideTypeCard(image: 'assets/images/car.png'),
                        _buildRideTypeCard(image: 'assets/images/auto.png'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildPromoBanner(context, screenWidth),
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
  Widget _buildRideTypeCard({required String image}) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: -4.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value),
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              image,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isSmallScreen) {
    return InkWell(
      onTap: () => context.pushNamed(PlanYourRideWidget.routeName),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 10,
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
              child: const Icon(
                Icons.search_rounded,
                color: primaryOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Where to go ?',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow(
      BuildContext context,
      double screenWidth,
      bool isSmallScreen,
      ) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.location_on_rounded,
          iconColor: FFAppState().droplocation == null
              ? const Color(0xFFFF0000)
              : const Color(0xFF4CAF50),
          onTap: () => context.pushNamed(ChooseDestinationWidget.routeName),
          width: isSmallScreen ? 48 : 56,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ScaleTransition(
            scale: isScanning
                ? const AlwaysStoppedAnimation(1.0)
                : _pulseAnimation,
            child: InkWell(
              onTap: isScanning
                  ? null
                  : () {
                if (FFAppState().droplocation == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select drop location'),
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
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: isScanning
                      ? Border.all(
                    color: lightOrange,
                    width: 2,
                  )
                      : null,
                  borderRadius: BorderRadius.circular(16),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        isScanning
                            ? 'Scanning...'
                            : 'Scan Qr and book the ride',
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
        child: Icon(
          icon,
          color: iconColor,
          size: width * 0.4,
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context, double screenWidth) {
    return InkWell(
      onTap: () {},
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
                          'Auto rides',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upfront fares doorstep pickupd',
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
}
