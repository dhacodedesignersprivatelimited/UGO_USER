import '/components/menu_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'home_model.dart';
export 'home_model.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/services.dart';

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

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // State Flags
  bool isScanning = false;
  bool _isCheckingRideStatus = false;

  // Performance Optimization: Notifier for Notification Count
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier<int>(0);
  Timer? _notificationTimer;

  // Color Constants
  static const Color primaryOrange = Color(0xFFFF7B10);
  static const Color deepOrange = Color(0xFFE65100);
  static const Color lightOrange = Color(0xFFFFAB40);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());

    // 1. Setup Pulse Animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. IMPORTANT: Check for active rides immediately on app launch
    _checkRideStatus();

    // 3. Start Notification polling
    _updateNotificationCount();
    _startNotificationRefresh();
  }

  void _startNotificationRefresh() {
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (mounted) {
          _updateNotificationCount();
        }
      },
    );
  }

  /// ✅ FIXED: Logic to restore active ride session
  Future<void> _checkRideStatus() async {
    // Prevent concurrent checks, but ALLOW check even if local bookingInProgress is false
    // This ensures cross-device/restart synchronization.
    if (_isCheckingRideStatus) return;

    final token = FFAppState().accessToken;
    if (token.isEmpty) return;

    setState(() => _isCheckingRideStatus = true);

    try {
      final response = await GetRideStatus.call(
        userId: FFAppState().userid,
        token: token,
      );

      _model.apiResult85c = response;
      if (!mounted) return;

      if (response.succeeded) {
        final rideList = getJsonField(response.jsonBody, r'''$.data.rides''');

        if (rideList != null && rideList is List && rideList.isNotEmpty) {
          // Assuming the API returns the most recent ride first
          final activeRide = rideList.first;

          // Robust ID Extraction
          final rideId = activeRide is Map ? activeRide['id'] : activeRide;

          // Robust Status Extraction
          final status = (activeRide is Map ? activeRide['status'] : null)
              ?.toString()
              .toLowerCase();

          // Define statuses that should trigger a redirection
          // (Exclude completed/cancelled so we don't get stuck in a loop)
          const activeStatuses = [
            'searching',
            'driver_assigned',
            'accepted',
            'arriving',
            'picked_up',
            'started',
            'in_progress'
          ];

          final isActive = status == null || activeStatuses.contains(status);

          if (rideId != null && isActive) {
            print(
                '🚀 Active ride detected (ID: $rideId). Restoring session...');
            FFAppState().bookingInProgress = true;

            if (mounted) {
              context.pushNamed(
                AutoBookWidget.routeName,
                queryParameters: {'rideId': rideId.toString()},
              );
            }
          } else {
            FFAppState().bookingInProgress = false;
          }
        } else {
          FFAppState().bookingInProgress = false;
        }
      }
    } catch (e) {
      debugPrint('Ride status check failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingRideStatus = false);
      }
    }
  }

  Future<void> _updateNotificationCount() async {
    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty) return;

      final response = await GetAllNotificationsCall.call(token: token);

      if (response.succeeded) {
        final allNotifications =
            GetAllNotificationsCall.notifications(response.jsonBody);

        if (allNotifications != null) {
          final currentUserId = FFAppState().userid;
          final lastCheckTime = FFAppState().lastNotificationCheckTime;

          int freshUnreadCount = 0;

          for (var notification in allNotifications) {
            final notificationUserId =
                getJsonField(notification, r'''$.user_id''');
            final isRead = getJsonField(notification, r'''$.is_read''');
            final createdAtString =
                getJsonField(notification, r'''$.created_at''')?.toString();

            if (notificationUserId?.toString() == currentUserId.toString() &&
                isRead != true) {
              if (lastCheckTime != null && createdAtString != null) {
                final createdAt = DateTime.tryParse(createdAtString);
                if (createdAt != null && createdAt.isAfter(lastCheckTime)) {
                  freshUnreadCount++;
                }
              } else {
                freshUnreadCount++;
              }
            }
          }
          _unreadCountNotifier.value = freshUnreadCount;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _notificationTimer?.cancel();
    _unreadCountNotifier.dispose();
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

      if (scanResult == '-1') {
        setState(() => isScanning = false);
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      int? driverId;
      int? vehicleType;
      double? baseFare;
      double? pricePerKm;
      double? baseKmStart;
      double? baseKmEnd;

      try {
        if (scanResult.trim().startsWith('{')) {
          final decodedData = jsonDecode(scanResult);
          driverId = int.tryParse(decodedData['driver_id']?.toString() ?? '');
          vehicleType =
              int.tryParse(decodedData['vehicle_type_id']?.toString() ?? '');

          final pricing = decodedData['pricing'] ?? {};
          baseFare = double.tryParse(pricing['base_fare']?.toString() ?? '0');
          pricePerKm =
              double.tryParse(pricing['price_per_km']?.toString() ?? '0');
          baseKmStart =
              double.tryParse(pricing['base_km_start']?.toString() ?? '1');
          baseKmEnd =
              double.tryParse(pricing['base_km_end']?.toString() ?? '5');
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
            'vehicleType': vehicleType?.toString() ?? '',
            'baseFare': baseFare?.toString() ?? '0',
            'pricePerKm': pricePerKm?.toString() ?? '0',
            'baseKmStart': baseKmStart?.toString() ?? '1',
            'baseKmEnd': baseKmEnd?.toString() ?? '5',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR Code')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
            onTap: () {},
            child: wrapWithModel(
              model: _model.menuModel,
              updateCallback: () => safeSetState(() {}),
              child: const MenuWidget(),
            ),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: screenHeight * 0.38,
              floating: false,
              pinned: true,
              backgroundColor: primaryOrange,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 30),
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
                  child: ValueListenableBuilder<int>(
                    valueListenable: _unreadCountNotifier,
                    builder: (context, unreadCount, child) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              context
                                  .pushNamed(PushnotificationsWidget.routeName);
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding:
                                    EdgeInsets.all(unreadCount > 9 ? 4 : 5),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 1),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: unreadCount > 9 ? 9 : 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
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
                        horizontalPadding, 70, horizontalPadding, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildSearchBar(context, isSmallScreen),
                        SizedBox(height: screenHeight * 0.02),
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
                            context, screenWidth, isSmallScreen),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
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
                        _buildRideTypeCard(
                          context,
                          image: 'assets/images/bike.png',
                          comingSoonMessage: 'Bike rides coming soon',
                        ),
                        _buildRideTypeCard(
                          context,
                          image: 'assets/images/car.png',
                          comingSoonMessage: 'Car rides coming soon',
                        ),
                        _buildRideTypeCard(
                          context,
                          image: 'assets/images/auto.png',
                          comingSoonMessage:
                              'Auto ride available. Use "Where to go?"',
                        ),
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

  Widget _buildRideTypeCard(BuildContext context,
      {required String image, required String comingSoonMessage}) {
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
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        comingSoonMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: primaryOrange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
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
              child: Image.asset(image, fit: BoxFit.contain),
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
              child: const Icon(Icons.search_rounded,
                  color: primaryOrange, size: 22),
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
      BuildContext context, double screenWidth, bool isSmallScreen) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.location_on_rounded,
          iconColor: FFAppState().droplocation.isEmpty
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
                      ? Border.all(color: lightOrange, width: 2)
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner_rounded,
                              color: Colors.white, size: 18),
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
        child: Icon(icon, color: iconColor, size: width * 0.4),
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
              Image.asset('assets/images/skdkzv.png', fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upfront fares doorstep pickup',
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
