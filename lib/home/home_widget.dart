import '/components/menu_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  DateTime? _lastBackPress;

  // Our Services - vehicle types from API
  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _vehicleTypesLoading = true;

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

    // 4. Pre-fetch location on load to speed up "Scan to Go"
    _initializePickupLocation();

    // 5. Fetch vehicle types for Our Services
    _fetchVehicleTypes();
  }

  Future<void> _fetchVehicleTypes() async {
    try {
      final res = await GetVehicleTypesCall.call();
      if (mounted && res.succeeded) {
        final list = GetVehicleTypesCall.vehicles(res.jsonBody);
        setState(() {
          _vehicleTypes = (list ?? [])
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList();
          _vehicleTypesLoading = false;
        });
      } else {
        if (mounted) setState(() => _vehicleTypesLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch vehicle types error: $e');
      if (mounted) setState(() => _vehicleTypesLoading = false);
    }
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

  /// Ensure Pickup Location is set (Step 1 of Scan to Book)
  Future<void> _initializePickupLocation() async {
    if (FFAppState().pickupLatitude == 0.0 || FFAppState().pickupLatitude == null) {
      try {
        final loc = await getCurrentUserLocation(defaultLocation: const LatLng(0.0, 0.0));
        if (mounted && loc.latitude != 0.0) {
          setState(() {
            FFAppState().pickupLatitude = loc.latitude;
            FFAppState().pickupLongitude = loc.longitude;
            // Optionally set address string if you have a reverse geocoding function
            // FFAppState().pickuplocation = "Current Location";
          });
        }
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    }
  }

  /// ✅ FIXED: Logic to restore active ride session
  Future<void> _checkRideStatus() async {
    // Prevent concurrent checks, but ALLOW check even if local bookingInProgress is false
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
          final activeRide = rideList.first;
          final rideId = activeRide is Map ? activeRide['id'] : activeRide;
          final status = (activeRide is Map ? activeRide['status'] : null)
              ?.toString()
              .toLowerCase();

          const activeStatuses = [
            'searching',
            'driver_assigned',
            'accepted',
            'arriving',
            'arrived',
            'picked_up',
            'started',
            'in_progress',
            'ontrip'
          ];

          final isActive = status == null || activeStatuses.contains(status);

          if (rideId != null && isActive) {
            print('🚀 Active ride detected (ID: $rideId). Restoring session...');
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
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        FFAppState().clearAuthSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session expired. Please log in again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.goNamedAuth(LoginWidget.routeName, context.mounted);
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
        final serverUnread = GetAllNotificationsCall.unreadCount(response.jsonBody);
        if (serverUnread != null) {
          _unreadCountNotifier.value = serverUnread;
          return;
        }

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

  /// Navigate to Scan to Book flow (new backend: scan-book API + socket)
  void _handleQRScan() {
    context.pushNamed(ScanToBookWidget.routeName);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: GestureDetector(
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
                    _buildOurServicesSection(context, isSmallScreen),
                    const SizedBox(height: 20),
                    _buildPromoBanner(context, screenWidth),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildOurServicesSection(BuildContext context, bool isSmallScreen) {
    if (_vehicleTypesLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: isSmallScreen ? 90 : 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: primaryOrange),
              ),
            ),
          ),
        )),
      );
    }
    final vehicles = _vehicleTypes.isEmpty
        ? [
            {'id': 2, 'name': 'bike', 'image': null},
            {'id': 1, 'name': 'auto', 'image': null},
            {'id': 3, 'name': 'car', 'image': null},
          ]
        : _vehicleTypes;

    // Build display items: 1 vehicle -> [ComingSoon, Vehicle, ComingSoon]
    // 2 vehicles -> [V1, V2, ComingSoon]; 3+ -> all vehicles, then fill to multiple of 3 with ComingSoon
    List<Widget> displayItems = [];
    if (vehicles.length == 1) {
      displayItems = [
        _buildComingSoonCard(context, isSmallScreen),
        _buildVehicleCard(vehicles[0], context, isSmallScreen),
        _buildComingSoonCard(context, isSmallScreen),
      ];
    } else {
      // Add all actual vehicles
      for (final v in vehicles) {
        displayItems.add(_buildVehicleCard(v, context, isSmallScreen));
      }
      // Fill remaining slots in the last row of 3 with Coming Soon
      while (displayItems.length % 3 != 0) {
        displayItems.add(_buildComingSoonCard(context, isSmallScreen));
      }
    }

    // Layout: rows of 3 (1:2:3, then 4:5:6, etc.)
    const rowSpacing = 12.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < displayItems.length; i += 3) ...[
          if (i > 0) const SizedBox(height: rowSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int j = 0; j < 3; j++)
                (i + j) < displayItems.length
                    ? displayItems[i + j]
                    : Expanded(child: const SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildComingSoonCard(BuildContext context, bool isSmallScreen) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('New vehicles will be added soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          splashColor: primaryOrange.withValues(alpha: 0.15),
          highlightColor: primaryOrange.withValues(alpha: 0.08),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: isSmallScreen ? 90 : 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.grey[500], size: isSmallScreen ? 28 : 32),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    'Coming soon',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(
    Map<String, dynamic> v,
    BuildContext context,
    bool isSmallScreen,
  ) {
    final name = (v['name'] ?? 'ride').toString().toLowerCase();
    final label = name.length > 1
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : name.toUpperCase();
    final imagePath = v['image']?.toString();
    final imageUrl = imagePath != null && imagePath.isNotEmpty
        ? (imagePath.startsWith('http')
            ? imagePath
            : '${AppConfig.baseApiUrl}${imagePath.startsWith('/') ? '' : '/'}$imagePath')
        : null;

    return _buildRideTypeCard(
      context,
      image: 'assets/images/$name.png',
      imageUrl: imageUrl,
      label: label,
      onTap: () {
        FFAppState().selectedRideCategory = name;
        context.pushNamed(PlanYourRideWidget.routeName);
      },
      isSmallScreen: isSmallScreen,
    );
  }

  Widget _buildRideTypeCard(
    BuildContext context, {
    required String image,
    String? imageUrl,
    required String label,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: primaryOrange.withValues(alpha: 0.15),
            highlightColor: primaryOrange.withValues(alpha: 0.08),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              height: isSmallScreen ? 90 : 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                image,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.directions_car_rounded,
                                  color: primaryOrange,
                                  size: isSmallScreen ? 28 : 32,
                                ),
                              ),
                            )
                          : Image.asset(
                              image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.directions_car_rounded,
                                color: primaryOrange,
                                size: isSmallScreen ? 28 : 32,
                              ),
                            ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isSmallScreen) {
    return InkWell(
      onTap: () {
        FFAppState().selectedRideCategory = null;
        context.pushNamed(PlanYourRideWidget.routeName);
      },
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
              color: Colors.black.withValues(alpha:0.1),
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
                color: primaryOrange.withValues(alpha:0.1),
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
                      color: Colors.black.withValues(alpha:0.08),
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
              color: Colors.black.withValues(alpha:0.08),
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
      onTap: () {
        FFAppState().selectedRideCategory = 'auto';
        context.pushNamed(PlanYourRideWidget.routeName);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: screenWidth * 0.45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withValues(alpha:0.2),
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
                    colors: [Colors.transparent, Colors.black.withValues(alpha:0.7)],
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
                        color: Colors.white.withValues(alpha:0.85),
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