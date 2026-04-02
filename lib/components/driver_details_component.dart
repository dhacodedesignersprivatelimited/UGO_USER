import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_config.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import 'dart:math';

class DriverDetailsComponent extends StatefulWidget {
  final bool isLoading;
  final Map<String, dynamic>? driverDetails;
  final dynamic driverId;
  final String? rideOtp;
  final List<dynamic> ridesCache;
  final Function(String?) onCall;
  final VoidCallback onCancel;
  final String rideStatus;
  final double? currentRemainingDistance;
  final String? liveEtaText;
  final VoidCallback? onShare;
  final VoidCallback? onChat;
  final int unreadChatCount;
  final double? totalRoadDistanceKm;
  final ScrollController? scrollController;
  final VoidCallback? onTripDetails;

  /// After a driver accepts (until trip starts), rider can change pickup/drop via PATCH.
  final bool canEditPickupLocation;
  final bool canEditDropLocation;
  final VoidCallback? onEditPickup;
  final VoidCallback? onEditDrop;

  const DriverDetailsComponent({
    Key? key,
    required this.isLoading,
    this.driverDetails,
    required this.driverId,
    required this.rideOtp,
    required this.ridesCache,
    required this.onCall,
    required this.onCancel,
    required this.rideStatus,
    this.currentRemainingDistance,
    this.liveEtaText,
    this.onShare,
    this.onChat,
    this.unreadChatCount = 0,
    this.totalRoadDistanceKm,
    this.scrollController,
    this.onTripDetails,
    this.canEditPickupLocation = false,
    this.canEditDropLocation = false,
    this.onEditPickup,
    this.onEditDrop,
  }) : super(key: key);

  @override
  State<DriverDetailsComponent> createState() => _DriverDetailsComponentState();
}

class _DriverDetailsComponentState extends State<DriverDetailsComponent>
    with SingleTickerProviderStateMixin {
  bool _isInternalLoading = false;
  Map<String, dynamic>? _fetchedDriverData;
  Map<String, dynamic>? _fetchedVehicleData;
  late AnimationController _pulseController;

  static const _kPrimary = Color(0xFFFF7B10);
  static const _kRed = Color(0xFFEF4444);
  static const _kGreen = Color(0xFF22C55E);
  static const _kAmber = Color(0xFFF59E0B);
  static const _kIndigo = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fetchDynamicData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DriverDetailsComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driverId != oldWidget.driverId) {
      _fetchDynamicData();
    }
  }

  Future<void> _fetchDynamicData() async {
    final dIdRaw = widget.driverId;
    if (dIdRaw == null) return;

    final dId = dIdRaw is int ? dIdRaw : int.tryParse(dIdRaw.toString());
    if (dId == null) return;

    if (mounted) setState(() => _isInternalLoading = true);

    try {
      final token = FFAppState().accessToken;
      final results = await Future.wait([
        DriverIdfetchCall.call(id: dId, token: token),
        GetVehicleInfoByDriverCall.call(driverId: dId, token: token),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].succeeded) _fetchedDriverData = results[0].jsonBody;
          if (results[1].succeeded) _fetchedVehicleData = results[1].jsonBody;
          _isInternalLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching driver/vehicle details: $e');
      if (mounted) setState(() => _isInternalLoading = false);
    }
  }

  double _calculateDistanceKm(
      double startLat, double startLng, double endLat, double endLng) {
    const double earthRadius = 6371;
    double dLat = _degToRad(endLat - startLat);
    double dLng = _degToRad(endLng - startLng);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(startLat)) *
            cos(_degToRad(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  static String _formatDistance(double? km) {
    if (km == null) return '--';
    return km < 1 ? '${(km * 1000).round()}m' : '${km.toStringAsFixed(1)}Km';
  }

  int _calculateEtaMinutes(double distanceKm) {
    const double avgSpeed = 30;
    return (distanceKm / avgSpeed * 60).round();
  }

  TextStyle _font({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double spacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? const Color(0xFF1A1A1A),
      letterSpacing: spacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.rideStatus.toLowerCase().trim();
    final isArriving = status == 'arriving' || status == 'arrived';
    final isAccepted = status == 'accepted' || status == 'driver_assigned';
    final isStarted = status == 'started' ||
        status == 'picked_up' ||
        status == 'in_progress' ||
        status == 'ontrip' ||
        status == 'trip_started';

    final showLoading =
        widget.isLoading || (_isInternalLoading && _fetchedDriverData == null);

    if (showLoading) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.3),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(color: _kPrimary),
            ),
          ),
        ),
      );
    }

    final driverData = _fetchedDriverData ?? widget.driverDetails;
    final ride =
        widget.ridesCache.isNotEmpty ? widget.ridesCache[0] as Map : null;

    // Driver name: socket payload → API
    final driverName = _sanitizePersonName(_firstNonEmpty([
          ride?['driver_name']?.toString(),
          GetDriverDetailsCall.name(driverData),
        ]) ??
        'Captain');

    // Rating
    final driverRating = double.tryParse(
            '${ride?['driver_rating'] ?? GetDriverDetailsCall.rating(driverData) ?? '4.8'}') ??
        4.8;

    // Total rides
    final totalRides = (ride?['driver_total_rides'] as int?) ??
        DriverIdfetchCall.totalRidesCompleted(driverData) ??
        0;

    // Vehicle plate: socket → vehicleAPI → driverAPI
    String vehiclePlate = _firstNonEmpty([
          ride?['vehicle_plate']?.toString(),
          GetVehicleInfoByDriverCall.licensePlate(_fetchedVehicleData),
          GetDriverDetailsCall.vehicleNumber(driverData),
        ]) ??
        '';
    // Vehicle model: build from name + model + color
    final vName = _firstNonEmpty([
      ride?['vehicle_name']?.toString(),
      GetVehicleInfoByDriverCall.vehicleName(_fetchedVehicleData),
      GetDriverDetailsCall.vehicleModel(driverData),
    ]);
    final vModel = _firstNonEmpty([
      ride?['vehicle_model']?.toString(),
      GetVehicleInfoByDriverCall.vehicleModel(_fetchedVehicleData),
    ]);
    final vColor = _firstNonEmpty([
      ride?['vehicle_color']?.toString(),
      GetVehicleInfoByDriverCall.vehicleColor(_fetchedVehicleData),
      GetDriverDetailsCall.vehicleColor(driverData),
    ]);

    final modelParts = <String>[];
    if (vName != null && vName.isNotEmpty) modelParts.add(vName);
    if (vModel != null && vModel.isNotEmpty && vModel != vName) {
      modelParts.add(vModel);
    }
    if (vColor != null && vColor.isNotEmpty) modelParts.add(vColor);
    String vehicleModel = modelParts.join(' · ');

    // Driver phone
    final driverPhone = _firstNonEmpty([
      ride?['driver_phone']?.toString(),
      DriverIdfetchCall.mobileNumber(driverData)?.toString(),
    ]);

    // Driver profile image — cascade: socket flat → ride nested driver → API
    String? resolvedImage = _firstNonEmpty([
      ride?['driver_profile_image']?.toString(),
      (ride?['driver'] is Map)
          ? ride!['driver']['profile_image']?.toString()
          : null,
      GetDriverDetailsCall.profileImage(driverData),
    ]);
    if (resolvedImage == null) {
      try {
        final d = driverData?['data'] ?? driverData;
        if (d is Map) {
          resolvedImage = (d['profile_photo'] ??
                  d['profile_image'] ??
                  d['photo'] ??
                  d['image'])
              ?.toString();
        }
      } catch (_) {}
    }
    if (resolvedImage != null &&
        resolvedImage.isNotEmpty &&
        !resolvedImage.startsWith('http')) {
      resolvedImage = '${AppConfig.baseApiUrl}/$resolvedImage';
    }

    List<String> otpDigits = [];
    bool showOtp = (isAccepted || isArriving) && !isStarted;
    if (showOtp && widget.rideOtp != null && widget.rideOtp!.isNotEmpty) {
      otpDigits = widget.rideOtp!.padRight(4, '-').split('').take(4).toList();
    }

    double? approachingPickupKm;
    int? approachingEtaFallbackMins;
    String pickup = 'Pickup Location';
    String dropoff = 'Drop Location';
    String amount = '₹--';

    if (widget.ridesCache.isNotEmpty) {
      final ride = widget.ridesCache[0];
      pickup = ride['pickup_location_address'] ?? pickup;
      dropoff = ride['drop_location_address'] ?? dropoff;
      amount = '₹${ride['estimated_fare'] ?? '--'}';
      final driverLat =
          double.tryParse(ride['driver_latitude']?.toString() ?? '');
      final driverLng =
          double.tryParse(ride['driver_longitude']?.toString() ?? '');

      if (isAccepted || isArriving) {
        if (widget.currentRemainingDistance != null) {
          approachingPickupKm = widget.currentRemainingDistance;
        } else if (driverLat != null &&
            driverLng != null &&
            FFAppState().pickupLatitude != null &&
            FFAppState().pickupLongitude != null) {
          approachingPickupKm = _calculateDistanceKm(driverLat, driverLng,
              FFAppState().pickupLatitude!, FFAppState().pickupLongitude!);
        }
        if (approachingPickupKm != null) {
          approachingEtaFallbackMins =
              _calculateEtaMinutes(approachingPickupKm);
        }
      }
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: widget.scrollController != null
          ? const ClampingScrollPhysics()
          : const BouncingScrollPhysics(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (isStarted) ...[
              _buildStatusBanner(
                  'Ride in Progress', Icons.navigation_rounded, _kGreen),
              const SizedBox(height: 12),
            ] else if (isAccepted || isArriving) ...[
              _buildPrePickupTrackingCard(
                isArriving: isArriving,
                distanceKm: approachingPickupKm,
                googleEta: widget.liveEtaText,
                fallbackEtaMins: approachingEtaFallbackMins,
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (otpDigits.isNotEmpty) ...[
                    _buildOtpSection(otpDigits),
                    const SizedBox(height: 16),
                  ],
                  _buildDriverInfoCard(
                    driverName: driverName,
                    rating: driverRating,
                    totalTrips: totalRides,
                    vehiclePlate: vehiclePlate,
                    vehicleModel: vehicleModel,
                    imageUrl: resolvedImage,
                  ),
                  const SizedBox(height: 14),
                  _buildActionButtons(driverPhone?.toString()),
                  const SizedBox(height: 14),
                  _buildTripInfoCard(
                    pickup,
                    dropoff,
                    amount,
                    showPickupEdit: widget.canEditPickupLocation &&
                        widget.onEditPickup != null,
                    showDropEdit:
                        widget.canEditDropLocation && widget.onEditDrop != null,
                    onEditPickup: widget.onEditPickup,
                    onEditDrop: widget.onEditDrop,
                  ),
                  const SizedBox(height: 14),
                  if (!isStarted) _buildBottomButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status Banners ─────────────────────────────────────────────────────

  String _formatApproachKm(double? km) {
    if (km == null) return '—';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  Widget _buildPrePickupTrackingCard({
    required bool isArriving,
    required double? distanceKm,
    required String? googleEta,
    required int? fallbackEtaMins,
  }) {
    final title = isArriving ? 'Captain is arriving' : 'Captain is on the way';
    final distLine = distanceKm != null
        ? 'Driver is ${_formatApproachKm(distanceKm)} away'
        : 'Locating driver…';
    final etaLine = (googleEta != null && googleEta.trim().isNotEmpty)
        ? 'Arriving in $googleEta'
        : (fallbackEtaMins != null
            ? 'Arriving in $fallbackEtaMins mins'
            : null);

    final bg = isArriving
        ? _kPrimary.withValues(alpha: 0.08)
        : _kGreen.withValues(alpha: 0.08);
    final border = isArriving
        ? _kPrimary.withValues(alpha: 0.28)
        : _kGreen.withValues(alpha: 0.25);
    final accent = isArriving ? _kPrimary : _kGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Opacity(
                    opacity: 0.5 + _pulseController.value * 0.5,
                    child: child,
                  ),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: _font(
                      size: 15,
                      weight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  isArriving
                      ? Icons.near_me_rounded
                      : Icons.directions_car_rounded,
                  color: accent,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              distLine,
              style: _font(
                size: 16,
                weight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (etaLine != null) ...[
              const SizedBox(height: 4),
              Text(
                etaLine,
                style: _font(
                  size: 14,
                  weight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style:
                      _font(size: 14, weight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── OTP Section ────────────────────────────────────────────────────────

  Widget _buildOtpSection(List<String> digits) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final boxWidth = isNarrow ? 38.0 : 44.0;
        final boxHeight = isNarrow ? 44.0 : 50.0;
        final digitRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: digits.map((d) {
            return Container(
              width: boxWidth,
              height: boxHeight,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                d.toUpperCase(),
                style:
                    _font(size: isNarrow ? 16 : 18, weight: FontWeight.w800, color: _kPrimary),
              ),
            );
          }).toList(),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your OTP',
                      style: _font(
                        size: 11,
                        color: const Color(0xFF6B7280),
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share with captain',
                      style: _font(size: 10, color: const Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: digitRow),
                  ],
                )
              : Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your OTP',
                          style: _font(
                            size: 11,
                            color: const Color(0xFF6B7280),
                            weight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share with captain',
                          style: _font(size: 10, color: const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    digitRow,
                  ],
                ),
        );
      },
    );
  }

  // ─── Driver Info Card ───────────────────────────────────────────────────

  Widget _buildDriverInfoCard({
    required String driverName,
    required double rating,
    required int totalTrips,
    required String vehiclePlate,
    required String vehicleModel,
    String? imageUrl,
  }) {
    final initials = driverName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final avatarSize = isNarrow ? 50.0 : 60.0;
        final plateSize = isNarrow ? 17.0 : 20.0;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 14 : 20,
            vertical: isNarrow ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildAvatar(imageUrl, initials, size: avatarSize),
              SizedBox(width: isNarrow ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: _font(
                        size: isNarrow ? 15 : 16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (rating > 0) ...[
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFB800), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: _font(
                              size: 12,
                              weight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                        if (rating > 0 && totalTrips > 0)
                          Text(' · ',
                              style: _font(
                                  size: 12, color: const Color(0xFF9CA3AF))),
                        if (totalTrips > 0)
                          Text(
                            '${_formatTripCount(totalTrips)} rides',
                            style: _font(
                              size: 12,
                              weight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vehiclePlate.toUpperCase(),
                      style: _font(
                        size: plateSize,
                        weight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                        spacing: 0.5,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (vehicleModel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        vehicleModel,
                        style: _font(size: 13, color: const Color(0xFF6B7280)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? imageUrl, String initials, {double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE5E7EB),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials),
              )
            : _buildInitialsAvatar(initials),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: _font(size: 20, weight: FontWeight.w700, color: _kPrimary),
      ),
    );
  }


  // ─── Action Buttons ─────────────────────────────────────────────────────

  Widget _buildActionButtons(String? phoneNumber) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        if (!isNarrow) {
          return Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: _kGreen,
                  onTap: () => widget.onCall(phoneNumber),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  color: _kAmber,
                  onTap: widget.onChat,
                  badgeCount: widget.unreadChatCount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: _kIndigo,
                  onTap: widget.onShare,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: _kGreen,
                    onTap: () => widget.onCall(phoneNumber),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    color: _kAmber,
                    onTap: widget.onChat,
                    badgeCount: widget.unreadChatCount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    color: _kIndigo,
                    onTap: widget.onShare,
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: _kRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: _font(
                          size: 9,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label,
                style: _font(
                    size: 11,
                    weight: FontWeight.w500,
                    color: const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  // ─── Trip Info Card ─────────────────────────────────────────────────────

  Widget _buildTripInfoCard(
    String pickup,
    String dropoff,
    String amount, {
    bool showPickupEdit = false,
    bool showDropEdit = false,
    VoidCallback? onEditPickup,
    VoidCallback? onEditDrop,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            Icons.radio_button_checked_rounded,
            _kGreen,
            pickup,
            onEdit: showPickupEdit ? onEditPickup : null,
            editTooltip: 'Edit pickup',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 20,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          _buildLocationRow(
            Icons.location_on_rounded,
            _kRed,
            dropoff,
            onEdit: showDropEdit ? onEditDrop : null,
            editTooltip: 'Edit drop',
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance',
                        style:
                            _font(size: 11, color: const Color(0xFF9CA3AF))),
                    const SizedBox(height: 2),
                    Text(
                      _formatDistance(widget.totalRoadDistanceKm),
                      style: _font(size: 15, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Fare',
                      style: _font(size: 11, color: const Color(0xFF9CA3AF))),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    style: _font(
                        size: 18, weight: FontWeight.w800, color: _kPrimary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    Color color,
    String text, {
    VoidCallback? onEdit,
    String? editTooltip,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: _font(size: 13, weight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            tooltip: editTooltip ?? 'Edit',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(Icons.edit_location_alt_outlined,
                size: 20, color: _kPrimary),
          ),
      ],
    );
  }

  // ─── Bottom Buttons ─────────────────────────────────────────────────────

  Widget _buildBottomButtons() {
    return Row(
      children: [
        if (widget.onTripDetails != null)
          Expanded(
            child: InkWell(
              onTap: widget.onTripDetails,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF6B7280), size: 18),
                    const SizedBox(width: 8),
                    Text('Trip Details',
                        style: _font(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
            ),
          ),
        if (widget.onTripDetails != null) const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: widget.onCancel,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kRed.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, color: _kRed, size: 18),
                  const SizedBox(width: 8),
                  Text('Cancel',
                      style: _font(
                          size: 13, weight: FontWeight.w600, color: _kRed)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  static String _formatTripCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
    }
    return count.toString();
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty && v.trim() != 'null') return v;
    }
    return null;
  }

  static String _sanitizePersonName(String raw) {
    final normalized =
        raw.replaceAll(RegExp(r'[\r\n\t]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
    return normalized.trim();
  }
}
