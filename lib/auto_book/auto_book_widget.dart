import '../flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_google_map.dart' show GoogleMapStyle, googleMapStyleStrings;
import '/flutter_flow/flutter_flow_util.dart' hide LatLng;
import '/backend/api_requests/api_calls.dart';
import '/index.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import 'auto_book_model.dart';
export 'auto_book_model.dart';

// Component imports
import '/components/searching_ride_component.dart';
import '/components/driver_details_component.dart';
import '/components/ride_cancelled_component.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '/ride_session.dart';
import '/services/route_distance_service.dart';

class AutoBookWidget extends StatefulWidget {
  const AutoBookWidget({
    super.key,
    required this.rideId,
    this.initialRideStatus,
    this.totalDistanceKm,
    this.totalDuration,
  });

  final int rideId;
  final String? initialRideStatus;
  final double? totalDistanceKm;
  final String? totalDuration;

  static String routeName = 'auto-book';
  static String routePath = '/autoBook';

  @override
  State<AutoBookWidget> createState() => _AutoBookWidgetState();
}

class _AutoBookWidgetState extends State<AutoBookWidget>
    with TickerProviderStateMixin {
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================
  late AutoBookModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color primaryColor = Color(0xFFFF7B10);

  // Socket & API
  IO.Socket? socket;
  String get _baseUrl => AppConfig.baseApiUrl;

  // Data Storage
  List<dynamic> ridesCache = [];
  Map<String, dynamic>? driverDetails;

  // State Flags
  bool isLoadingDriver = false;
  bool _isCancelling = false;
  bool _isRebooking = false;
  bool _userInitiatedCancel = false;
  bool _cancelledByDriver = false;
  String? _rideOtp;

  // Decline / extra fare tracking
  int _declineCount = 0;
  int _totalDriversNotified = 0;
  double _estimatedFare = 0;
  double _extraFare = 0;

  // UI Status
  String _rideStatus = 'searching';

  // Timer
  Timer? _searchTimer;
  int _searchSeconds = 0;
  Timer? _distanceUpdateTimer;
  Timer? _rideCheckTimer;
  Timer? _nearbyDriversTimer;
  Timer? _approachRouteTimer;
  Timer? _routeRefreshDebounce;
  bool _rideCheckShown = false;

  // Distance tracking
  double? _currentRemainingDistance;
  String? _liveEtaText;
  double? _totalRoadDistanceKm;

  // Map (like avaliable_options)
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _bikeIcon;
  BitmapDescriptor? _autoIcon;
  BitmapDescriptor? _carIcon;

  // Status Constants
  static const STATUS_SEARCHING = 'searching';
  static const STATUS_ACCEPTED = 'accepted';
  static const STATUS_ARRIVING = 'arriving';
  static const STATUS_PICKED_UP =
      'picked_up'; // Used for 'started'/'in_progress'
  static const STATUS_COMPLETED = 'completed';
  static const STATUS_CANCELLED = 'cancelled';

  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  @override
  void initState() {
    super.initState();
    print('🚀 AutoBookWidget: initState - Ride ID: ${widget.rideId}');
    _model = createModel(context, () => AutoBookModel());
    
    // Initialize with passed values if available
    _totalRoadDistanceKm = widget.totalDistanceKm;
    _liveEtaText = widget.totalDuration;

    // 1. Initialize Status from Constructor (if available) to avoid "Searching" flash
    if (widget.initialRideStatus != null) {
      _mapInitialStatus(widget.initialRideStatus!);
    }

    // 2. Start Timers & Socket
    _startSearchTimer();
    _startNearbyDriversTimer();
    _initializeSocket();

    // 3. ✅ CRITICAL: Always fetch fresh status on load
    _fetchInitialRideStatus();
    
    // 4. Ensure total road distance is fetched
    _ensureTotalRoadDistance();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isPrePickupTracking) _startApproachRouteTimer();
    });
  }

  Future<void> _ensureTotalRoadDistance() async {
    if (_totalRoadDistanceKm != null) return;
    final appState = FFAppState();
    
    double? pLat = appState.pickupLatitude;
    double? pLng = appState.pickupLongitude;
    double? dLat = appState.dropLatitude;
    double? dLng = appState.dropLongitude;

    if (pLat == null || pLng == null) return;
    
    if (dLat == null || dLng == null) {
      if (ridesCache.isNotEmpty) {
        dLat = double.tryParse(ridesCache[0]['drop_latitude']?.toString() ?? '');
        dLng = double.tryParse(ridesCache[0]['drop_longitude']?.toString() ?? '');
      }
    }

    if (pLat != null && pLng != null && dLat != null && dLng != null) {
      final roadDistance = await RouteDistanceService().getDrivingDistanceKm(
        originLat: pLat,
        originLng: pLng,
        destLat: dLat,
        destLng: dLng,
      );
      if (roadDistance != null && mounted) {
        setState(() => _totalRoadDistanceKm = roadDistance);
      }
    }
  }

  Future<void> _loadVehicleIconsIfNeeded() async {
    if (_bikeIcon != null) return;
    try {
      final config = const ImageConfiguration(size: Size(48, 48));
      final results = await Future.wait([
        BitmapDescriptor.asset(config, 'assets/images/bike.png'),
        BitmapDescriptor.asset(config, 'assets/images/auto.png'),
        BitmapDescriptor.asset(config, 'assets/images/car.png'),
      ]);
      if (mounted) {
        _bikeIcon = results[0];
        _autoIcon = results[1];
        _carIcon = results[2];
      }
    } catch (e) {
      debugPrint('Error loading vehicle icons: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  static const double _minBoundsSpan = 0.004;

  void _animateCameraToBounds(List<LatLng> points, {double paddingPx = 100}) {
    if (points.isEmpty || _mapController == null) return;
    final valid =
        points.where((p) => p.latitude.abs() > 1e-6 || p.longitude.abs() > 1e-6).toList();
    if (valid.isEmpty) return;

    if (valid.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(valid.first, 15),
      );
      return;
    }

    double minLat = valid.first.latitude, maxLat = valid.first.latitude;
    double minLng = valid.first.longitude, maxLng = valid.first.longitude;
    for (final point in valid) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    double latPad = (maxLat - minLat) * 0.15;
    double lngPad = (maxLng - minLng) * 0.15;
    if (maxLat - minLat < _minBoundsSpan) {
      latPad = _minBoundsSpan / 2;
      minLat -= latPad;
      maxLat += latPad;
    } else {
      minLat -= latPad;
      maxLat += latPad;
    }
    if (maxLng - minLng < _minBoundsSpan) {
      lngPad = _minBoundsSpan / 2;
      minLng -= lngPad;
      maxLng += lngPad;
    } else {
      minLng -= lngPad;
      maxLng += lngPad;
    }

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          paddingPx,
        ),
      );
    } catch (e) {
      debugPrint('Camera bounds failed, falling back to zoom: $e');
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
          12,
        ),
      );
    }
  }

  /// Fits camera to driver + pickup (pre-trip) or pickup + drop + driver (in-trip).
  void _fitMapToRideContext() {
    final appState = FFAppState();
    final pts = <LatLng>[];

    void addPickup() {
      final la = appState.pickupLatitude;
      final ln = appState.pickupLongitude;
      if (la != null && ln != null) pts.add(LatLng(la, ln));
    }

    void addDrop() {
      var dLat = appState.dropLatitude;
      var dLng = appState.dropLongitude;
      if ((dLat == null || dLng == null) && ridesCache.isNotEmpty) {
        dLat = double.tryParse(ridesCache[0]['drop_latitude']?.toString() ?? '');
        dLng = double.tryParse(ridesCache[0]['drop_longitude']?.toString() ?? '');
      }
      if (dLat != null && dLng != null) pts.add(LatLng(dLat, dLng));
    }

    void addDriver() {
      if (ridesCache.isEmpty) return;
      final ride = ridesCache[0];
      final dLat = double.tryParse(ride['driver_latitude']?.toString() ?? '');
      final dLng = double.tryParse(ride['driver_longitude']?.toString() ?? '');
      if (dLat != null && dLng != null) pts.add(LatLng(dLat, dLng));
    }

    if (_rideStatus == STATUS_ACCEPTED || _rideStatus == STATUS_ARRIVING) {
      addDriver();
      addPickup();
    } else if (_rideStatus == STATUS_PICKED_UP) {
      addPickup();
      addDrop();
      addDriver();
    } else if (_rideStatus == STATUS_SEARCHING) {
      addPickup();
      addDrop();
    } else {
      addPickup();
      addDrop();
      addDriver();
    }

    if (pts.isEmpty) {
      final la = appState.pickupLatitude ?? AppConfig.defaultLat;
      final ln = appState.pickupLongitude ?? AppConfig.defaultLng;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(la, ln), 14),
      );
      return;
    }

    final bottomInset = MediaQuery.sizeOf(context).height * 0.35;
    _animateCameraToBounds(pts, paddingPx: 72 + bottomInset * 0.15);
  }

  Future<void> _initializeMap() async {
    await _addMarkers();
    await _getRoutePolyline();
  }

  Future<void> _addMarkers() async {
    final appState = FFAppState();
    final pickupLat = appState.pickupLatitude;
    final pickupLng = appState.pickupLongitude;
    final dropLat = appState.dropLatitude ?? (ridesCache.isNotEmpty
        ? double.tryParse(ridesCache[0]['drop_latitude']?.toString() ?? '')
        : null);
    final dropLng = appState.dropLongitude ?? (ridesCache.isNotEmpty
        ? double.tryParse(ridesCache[0]['drop_longitude']?.toString() ?? '')
        : null);

    final newMarkers = <Marker>{};

    // Pickup (green)
    if (pickupLat != null && pickupLng != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickupLat, pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    // Drop (red)
    if (dropLat != null && dropLng != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(dropLat, dropLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    // Driver marker (when accepted/arriving/started)
    if (_rideStatus != STATUS_SEARCHING && ridesCache.isNotEmpty) {
      final ride = ridesCache[0];
      final dLat = double.tryParse(ride['driver_latitude']?.toString() ?? '');
      final dLng = double.tryParse(ride['driver_longitude']?.toString() ?? '');
      if (dLat != null && dLng != null) {
        await _loadVehicleIconsIfNeeded();
        final vtId = getJsonField(ride, r'''$.vehicle_type_id''');
        final vt = vtId is int ? vtId : int.tryParse(vtId?.toString() ?? '');
        final orangeIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        final driverIcon = (vt == 1 ? _autoIcon : vt == 2 ? _bikeIcon : _carIcon) ?? orangeIcon;
        newMarkers.add(Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(dLat, dLng),
          icon: driverIcon,
        ));
      }
    }

    if (mounted) {
      setState(() {
        // Preserve nearby_ markers (managed by _refreshNearbyDriverMarkers)
        final nearbyMarkers =
            _markers.where((m) => m.markerId.value.startsWith('nearby_')).toSet();
        _markers.clear();
        _markers.addAll(newMarkers);
        if (_rideStatus == STATUS_SEARCHING) {
          _markers.addAll(nearbyMarkers);
        }
      });
    }
  }

  bool get _isPrePickupTracking =>
      _rideStatus == STATUS_ACCEPTED || _rideStatus == STATUS_ARRIVING;

  double _mapFitPaddingPx() {
    if (!mounted) return 100;
    final h = MediaQuery.sizeOf(context).height;
    return 88 + h * 0.12;
  }

  void _stopApproachRouteTimer() {
    _approachRouteTimer?.cancel();
    _approachRouteTimer = null;
  }

  void _startApproachRouteTimer() {
    _stopApproachRouteTimer();
    _approachRouteTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || !_isPrePickupTracking) {
        _stopApproachRouteTimer();
        return;
      }
      unawaited(_getRoutePolyline(fitCamera: false));
    });
  }

  void _debouncedLiveRefreshFromDriver() {
    if (!mounted) return;
    if (!_isPrePickupTracking && _rideStatus != STATUS_PICKED_UP) return;
    _routeRefreshDebounce?.cancel();
    _routeRefreshDebounce = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      unawaited(_refreshAfterDriverLocation());
    });
  }

  Future<void> _refreshAfterDriverLocation() async {
    await _addMarkers();
    if (_isPrePickupTracking) {
      await _getRoutePolyline(fitCamera: false);
    }
  }

  /// Fetches directions and updates polyline. [fitCamera] when false avoids fighting user pan/zoom during live updates.
  Future<void> _getRoutePolyline({bool fitCamera = true}) async {
    final appState = FFAppState();
    double? fromLat, fromLng, toLat, toLng;
    final bool fullTripRoute =
        _rideStatus == STATUS_SEARCHING || _rideStatus == STATUS_PICKED_UP;

    if (_isPrePickupTracking) {
      if (ridesCache.isNotEmpty) {
        final ride = ridesCache[0];
        fromLat = double.tryParse(ride['driver_latitude']?.toString() ?? '');
        fromLng = double.tryParse(ride['driver_longitude']?.toString() ?? '');
      }
      toLat = appState.pickupLatitude;
      toLng = appState.pickupLongitude;
    } else if (fullTripRoute) {
      fromLat = appState.pickupLatitude;
      fromLng = appState.pickupLongitude;
      toLat = appState.dropLatitude ??
          (ridesCache.isNotEmpty
              ? double.tryParse(ridesCache[0]['drop_latitude']?.toString() ?? '')
              : null);
      toLng = appState.dropLongitude ??
          (ridesCache.isNotEmpty
              ? double.tryParse(ridesCache[0]['drop_longitude']?.toString() ?? '')
              : null);
    } else {
      return;
    }

    if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
      return;
    }

    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$fromLat,$fromLng&destination=$toLat,$toLng'
          '&key=${AppConfig.googleMapsApiKey}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK' ||
          json['routes'] == null ||
          (json['routes'] as List).isEmpty) {
        return;
      }

      final route = (json['routes'] as List).first as Map<String, dynamic>;
      final poly = route['overview_polyline'];
      if (poly is! Map || poly['points'] == null) return;
      final points = _decodePolyline(poly['points'].toString());

      double? roadDistance;
      String? etaText;
      if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
        final leg = (route['legs'] as List).first as Map<String, dynamic>;
        final distanceMeters = leg['distance']?['value'] ?? 0;
        roadDistance = (distanceMeters is num) ? distanceMeters / 1000.0 : null;
        etaText = leg['duration']?['text'] as String?;

        if (_rideStatus == STATUS_SEARCHING || _totalRoadDistanceKm == null) {
          final dLat = appState.dropLatitude ??
              (ridesCache.isNotEmpty
                  ? double.tryParse(
                      ridesCache[0]['drop_latitude']?.toString() ?? '')
                  : null);
          if (fromLat == appState.pickupLatitude && toLat == dLat) {
            _totalRoadDistanceKm = roadDistance;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFFFF7B10),
            width: 5,
            geodesic: true,
          ));

        if (_isPrePickupTracking) {
          if (roadDistance != null) _currentRemainingDistance = roadDistance;
          if (etaText != null) _liveEtaText = etaText;
        } else if (_rideStatus == STATUS_PICKED_UP) {
          // Full pickup→drop polyline only; remaining distance comes from driver↔drop (_updateRemainingDistance).
        } else if (_rideStatus == STATUS_SEARCHING) {
          if (roadDistance != null) _currentRemainingDistance = roadDistance;
          if (etaText != null) _liveEtaText = etaText;
        }
      });

      if (fitCamera && _mapController != null && points.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          _animateCameraToBounds(points, paddingPx: _mapFitPaddingPx());
        }
      }
    } catch (e) {
      debugPrint('Route polyline error: $e');
    }
  }

  void _mapInitialStatus(String status) {
    status = status.toLowerCase();
    if (status == 'started' ||
        status == 'in_progress' ||
        status == 'picked_up' ||
        status == 'ontrip' ||
        status == 'trip_started') {
      _rideStatus = STATUS_PICKED_UP;
    } else if (status == 'arriving' || status == 'arrived') {
      _rideStatus = STATUS_ARRIVING;
    } else if (status == 'accepted' || status == 'driver_assigned') {
      _rideStatus = STATUS_ACCEPTED;
    }
  }

  void _startSearchTimer() {
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _rideStatus == STATUS_SEARCHING) {
        setState(() => _searchSeconds++);
      }
    });
  }

  void _startDistanceUpdateTimer() {
    _distanceUpdateTimer?.cancel();
    _distanceUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _rideStatus == STATUS_PICKED_UP) {
        _updateRemainingDistance();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopDistanceUpdateTimer() {
    _distanceUpdateTimer?.cancel();
    _distanceUpdateTimer = null;
  }

  void _startNearbyDriversTimer() {
    _nearbyDriversTimer?.cancel();
    _refreshNearbyDriverMarkers();
    _nearbyDriversTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted && _rideStatus == STATUS_SEARCHING) {
        _refreshNearbyDriverMarkers();
      } else {
        _nearbyDriversTimer?.cancel();
      }
    });
  }

  void _stopNearbyDriversTimer() {
    _nearbyDriversTimer?.cancel();
    _nearbyDriversTimer = null;
  }

  Future<void> _refreshNearbyDriverMarkers() async {
    final appState = FFAppState();
    final pickupLat = appState.pickupLatitude;
    final pickupLng = appState.pickupLongitude;
    if (pickupLat == null || pickupLng == null) return;

    try {
      await _loadVehicleIconsIfNeeded();
      final response = await GetNearbyDriversCall.call(
        lat: pickupLat,
        lon: pickupLng,
        radius: 5.0,
        token: appState.accessToken,
      );
      if (!response.succeeded || !mounted) return;

      final allDrivers =
          (getJsonField(response.jsonBody, r'''$.data''') as List?)?.toList() ?? [];
      final category = appState.selectedRideCategory?.toLowerCase();
      int? targetVt;
      if (category == 'bike') targetVt = 2;
      else if (category == 'auto') targetVt = 1;
      else if (category == 'car') targetVt = 3;

      final orangeIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      final driverMarkers = <Marker>{};
      int idx = 0;

      for (final d in allDrivers) {
        if (getJsonField(d, r'''$.is_active''') != true ||
            getJsonField(d, r'''$.is_online''') != true) continue;
        final dVt = getJsonField(d, r'''$.vehicle_type_id''');
        final driverVt = dVt is int ? dVt : int.tryParse(dVt?.toString() ?? '');
        if (targetVt != null && driverVt != targetVt) continue;
        final lat = getJsonField(d, r'''$.current_location_latitude''');
        final lng = getJsonField(d, r'''$.current_location_longitude''');
        if (lat == null || lng == null) continue;
        final latVal = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
        final lngVal = lng is num ? lng.toDouble() : double.tryParse(lng.toString());
        if (latVal == null || lngVal == null) continue;
        final driverIcon =
            (driverVt == 1 ? _autoIcon : driverVt == 2 ? _bikeIcon : _carIcon) ??
                orangeIcon;
        driverMarkers.add(Marker(
          markerId: MarkerId('nearby_$idx'),
          position: LatLng(latVal, lngVal),
          icon: driverIcon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ));
        idx++;
      }

      if (mounted) {
        setState(() {
          _markers.removeWhere(
              (m) => m.markerId.value.startsWith('nearby_'));
          _markers.addAll(driverMarkers);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing nearby drivers: $e');
    }
  }

  void _clearNearbyDriverMarkers() {
    if (mounted) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value.startsWith('nearby_'));
      });
    }
  }

  // ============================================================================
  // API & SOCKET LOGIC
  // ============================================================================

  Future<void> _fetchInitialRideStatus() async {
    print('📡 Fetching initial ride status...');
    try {
      final response = await GetRideDetailsCall.call(
        rideId: widget.rideId,
        token: FFAppState().accessToken,
      );
      if (response.succeeded) {
        final rideData =
            getJsonField(response.jsonBody, r'$.data') ?? response.jsonBody;
        print("✅ Initial Ride Data Fetched");

        // Populate Session Data
        RideSession().rideData = rideData;

        if (mounted) {
          _processRideUpdate(rideData);
        }
      }
    } catch (e) {
      print("❌ Error fetching initial ride status: $e");
    }
  }

  void _initializeSocket() {
    final String token = FFAppState().accessToken;
    if (token.isEmpty) {
      print("⚠️ No Access Token for Socket!");
      return;
    }

    try {
      // 1. Initialize Socket
      socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew()
            .setAuth({'token': token})
            .setReconnectionAttempts(5)
            .build(),
      );

      // 2. Setup Listeners
      socket!.onConnect((_) {
        print("✅ Socket CONNECTED: ${socket?.id}");
        // Join the specific ride room
        socket!.emit("watch_entity", {
          "type": "ride",
          "id": widget.rideId,
        });
      });

      socket!
          .onConnectError((data) => print("❌ Socket Connection Error: $data"));
      socket!.onError((data) => print("❌ Socket Error: $data"));
      socket!.onDisconnect((_) => print("⚠️ Socket Disconnected"));

      // 3. Listen for Updates
      socket!.on("ride_updated", (data) {
        print("📡 Socket Event Received");
        if (data != null) {
          _processRideUpdate(data);
        }
      });

      // Scan-to-Book flow: location_update, ride_completed
      void applyDriverLatLng(Map<String, dynamic> m) {
        final lat = m['lat'] ?? m['latitude'];
        final lng = m['lng'] ?? m['longitude'];
        if (lat != null && lng != null && ridesCache.isNotEmpty) {
          final ride = Map<String, dynamic>.from(ridesCache.first);
          ride['driver_latitude'] =
              lat is num ? lat.toDouble() : double.tryParse(lat.toString());
          ride['driver_longitude'] =
              lng is num ? lng.toDouble() : double.tryParse(lng.toString());
          if (m['eta'] != null) ride['eta'] = m['eta'];
          setState(() => ridesCache = [ride]);
          RideSession().rideData = ride;
          _debouncedLiveRefreshFromDriver();
        }
      }

      socket!.on("location_update", (data) {
        if (data is Map && mounted) {
          applyDriverLatLng(Map<String, dynamic>.from(data));
        }
      });

      socket!.on("driver_location_update", (data) {
        if (data is! Map || !mounted) return;
        final m = Map<String, dynamic>.from(data);
        final driver = m['driver'];
        if (driver is Map) {
          applyDriverLatLng(Map<String, dynamic>.from(driver));
        } else {
          applyDriverLatLng(m);
        }
      });

      socket!.on("ride_completed", (data) {
        if (data != null && mounted) {
          final m = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
          m['ride_status'] = 'completed';
          m['status'] = 'completed';
          _processRideUpdate(m);
        }
      });

      // 4. Connect
      socket!.connect();
    } catch (e) {
      print("❌ Socket Initialization Exception: $e");
    }
  }

  void _processRideUpdate(dynamic data) {
    try {
      final updatedRide = Map<String, dynamic>.from(data);
      if (!mounted) return;

      // Update Global Session
      RideSession().rideData = updatedRide;

      final rawStatus = updatedRide['ride_status'] ?? updatedRide['status'];
      final status = rawStatus?.toString().toLowerCase().trim();
      updatedRide['ride_status'] = status;

      print('🔄 Processing Status: "$status"');

      bool navigateToComplete = false;
      String previousStatus = _rideStatus;

      setState(() {
        // 1. Update Cache (Trigger Map Rebuild)
        if (ridesCache.isNotEmpty) {
          ridesCache = [
            {...ridesCache.first, ...updatedRide}
          ];
        } else {
          ridesCache = [updatedRide];
        }

        // 1b. Extract decline count and fare info
        final dc = updatedRide['decline_count'];
        if (dc != null) _declineCount = int.tryParse(dc.toString()) ?? _declineCount;
        final tdn = updatedRide['total_drivers_notified'];
        if (tdn != null) _totalDriversNotified = int.tryParse(tdn.toString()) ?? _totalDriversNotified;
        final ef = updatedRide['estimated_fare'];
        if (ef != null) _estimatedFare = double.tryParse(ef.toString()) ?? _estimatedFare;
        final xf = updatedRide['extra_fare'];
        if (xf != null) _extraFare = double.tryParse(xf.toString()) ?? _extraFare;

        // 2. OTP Extraction (sync to app state for Secure Ride Start UI)
        final incomingOtp = updatedRide['otp'] ??
            updatedRide['ride_otp'] ??
            updatedRide['booking_otp'];
        if (incomingOtp != null) {
          _rideOtp = incomingOtp.toString();
        }

        // 3. Status State Machine
        if (status == 'cancelled') {
          _rideStatus = STATUS_CANCELLED;
          _cancelledByDriver = !_userInitiatedCancel;
          _searchTimer?.cancel();
          _rideCheckTimer?.cancel();
          _stopDistanceUpdateTimer();
          _stopNearbyDriversTimer();
          _stopApproachRouteTimer();
          _routeRefreshDebounce?.cancel();
          _markers.removeWhere((m) => m.markerId.value.startsWith('nearby_'));
          socket?.off("ride_updated");
          FFAppState().bookingInProgress = false;
          FFAppState().currentRideId = null;
          RideSession().clear();
        } else if (['accepted', 'driver_assigned'].contains(status)) {
          if (_rideStatus == STATUS_SEARCHING) {
            _rideStatus = STATUS_ACCEPTED;
          }
          _searchTimer?.cancel();
          _stopNearbyDriversTimer();
          _markers.removeWhere((m) => m.markerId.value.startsWith('nearby_'));
          _startApproachRouteTimer();
        } else if (status == 'arriving' || status == 'arrived') {
          // Backend/driver sends 'arrived' when driver reaches pickup; treat same as 'arriving'
          _rideStatus = STATUS_ARRIVING;
          _stopDistanceUpdateTimer();
          _startApproachRouteTimer();
        } else if (status == 'started' ||
            status == 'picked_up' ||
            status == 'in_progress' ||
            status == 'ontrip' ||
            status == 'trip_started') {
          _stopApproachRouteTimer();
          // ✅ THIS HANDLES DIRECT START
          _rideStatus = STATUS_PICKED_UP;
          _searchTimer
              ?.cancel(); // Stop searching timer if coming from direct start

          if (previousStatus != STATUS_PICKED_UP) {
            _updateRemainingDistance();
            _startDistanceUpdateTimer();
            // PRD: In-trip RideCheck - show "Are you OK?" after 45s
            _rideCheckTimer?.cancel();
            _rideCheckTimer = Timer(const Duration(seconds: 45), _showRideCheckDialog);
          }
        } else if (status == 'completed' || status == 'complete') {
          if (_rideStatus != STATUS_COMPLETED) {
            _rideStatus = STATUS_COMPLETED;
            _searchTimer?.cancel();
            _rideCheckTimer?.cancel();
            _stopDistanceUpdateTimer();
            _stopNearbyDriversTimer();
            _stopApproachRouteTimer();
            _routeRefreshDebounce?.cancel();
            navigateToComplete = true;
          }
        }
      });

      // 4. Update Distance Calculation
      if (_rideStatus == STATUS_PICKED_UP) {
        _updateRemainingDistance();
      }
      
      _ensureTotalRoadDistance();

      // 5. Navigation Handling
      if (navigateToComplete) {
        _handleCompletedRideNavigation(updatedRide);
        return;
      }

      // 6. Fetch Driver Details if missing
      final driverId = updatedRide['driver_id'];
      if (driverId != null &&
          (driverDetails == null || driverDetails!['id'] != driverId) &&
          !isLoadingDriver) {
        _fetchDriverDetails(driverId);
      }

      // 7. Refresh map when status changes
      if (_rideStatus == STATUS_SEARCHING) {
        if (_nearbyDriversTimer == null || !_nearbyDriversTimer!.isActive) {
          _startNearbyDriversTimer();
        }
        _initializeMap();
      } else if (_rideStatus == STATUS_ACCEPTED ||
          _rideStatus == STATUS_ARRIVING ||
          _rideStatus == STATUS_PICKED_UP) {
        _initializeMap();
      }
    } catch (e) {
      print("❌ Error processing ride update: $e");
    }
  }

  // ... (Distance Math Helpers - Unchanged) ...
  void _updateRemainingDistance() {
    if (ridesCache.isEmpty) return;
    try {
      final ride = ridesCache[0];
      final driverLat = ride['driver_latitude'];
      final driverLng = ride['driver_longitude'];
      final dropLat = ride['drop_latitude'];
      final dropLng = ride['drop_longitude'];

      if (driverLat != null &&
          driverLng != null &&
          dropLat != null &&
          dropLng != null) {
        double newDistance = _calculateDistance(
          double.parse(driverLat.toString()),
          double.parse(driverLng.toString()),
          double.parse(dropLat.toString()),
          double.parse(dropLng.toString()),
        );
        if (mounted) setState(() => _currentRemainingDistance = newDistance);
      }
    } catch (e) {
      print('Error updating distance: $e');
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = (_sin(dLat / 2) * _sin(dLat / 2)) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            (_sin(dLon / 2) * _sin(dLon / 2));
    double c = 2 * _asin(_sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180.0);
  double _sin(double x) {
    double r = x;
    double t = x;
    for (int n = 1; n <= 10; n++) {
      t *= -x * x / ((2 * n) * (2 * n + 1));
      r += t;
    }
    return r;
  }

  double _cos(double x) {
    double r = 1;
    double t = 1;
    for (int n = 1; n <= 10; n++) {
      t *= -x * x / ((2 * n - 1) * (2 * n));
      r += t;
    }
    return r;
  }

  double _sqrt(double x) {
    if (x < 0) return 0;
    double g = x / 2;
    for (int i = 0; i < 10; i++) g = (g + x / g) / 2;
    return g;
  }

  double _asin(double x) => x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;

  // ... (Keep existing Navigation & Fetch Driver logic) ...
  Future<void> _handleCompletedRideNavigation(
      Map<String, dynamic> rideData) async {
    _stopDistanceUpdateTimer();
    socket?.off("ride_updated");

    RideSession().rideData = rideData;
    FFAppState().currentRideId = widget.rideId;

    // Ensure we have driver data before navigating
    if (driverDetails != null) {
      RideSession().driverData = driverDetails;
    } else if (rideData['driver'] != null) {
      final nestedDriver = rideData['driver'];
      RideSession().driverData = nestedDriver is Map<String, dynamic>
          ? nestedDriver
          : Map<String, dynamic>.from(nestedDriver);
    } else if (rideData['driver_id'] != null) {
      await _fetchDriverDetailsSync(rideData['driver_id']);
    }

    // ✅ REFRESH WALLET BALANCE IF WALLET PAYMENT WAS USED
    final paymentMethod =
        rideData['payment_method'] ?? rideData['payment_type'];
    if (paymentMethod != null &&
        paymentMethod.toString().toLowerCase() == 'wallet') {
      print(
          '💳 Ride completed with Wallet payment, refreshing wallet balance...');
      try {
        final appState = FFAppState();
        final walletRes = await GetwalletCall.call(
          userId: appState.userid,
          token: appState.accessToken,
        );

        if (walletRes.succeeded) {
          final balanceStr = GetwalletCall.walletBalance(walletRes.jsonBody);
          final double balance = double.tryParse(balanceStr ?? '0') ?? 0.0;
          appState.walletBalance = balance;
          print('✅ Wallet balance refreshed: ₹${balance.toStringAsFixed(2)}');
        }
      } catch (e) {
        print('⚠️ Error refreshing wallet: $e');
        // Don't fail the navigation if wallet refresh fails
      }
    }

    if (mounted) {
      context.goNamed(
        RidecompleteWidget.routeName,
        queryParameters: {'rideId': widget.rideId.toString()},
      );
    }
  }

  Future<void> _fetchDriverDetailsSync(dynamic driverId) async {
    try {
      final response = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: FFAppState().accessToken,
      );
      if (response.succeeded && mounted) {
        RideSession().driverData = response.jsonBody;
      }
    } catch (e) {
      print('Sync driver fetch failed: $e');
    }
  }

  Future<void> _fetchDriverDetails(dynamic driverId) async {
    if (!mounted) return;
    setState(() => isLoadingDriver = true);
    try {
      final response = await GetDriverDetailsCall.call(
        driverId: driverId,
        token: FFAppState().accessToken,
      );
      if (response.succeeded && mounted) {
        setState(() {
          driverDetails = response.jsonBody;
          isLoadingDriver = false;
          RideSession().driverData = driverDetails;

          // If we are searching/accepted, and we found a driver, imply arriving
          if (_rideStatus == STATUS_SEARCHING) {
            _rideStatus = STATUS_ACCEPTED;
          }
        });
      } else {
        if (mounted) setState(() => isLoadingDriver = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingDriver = false);
    }
  }

  Future<void> _cancelRide(String reason) async {
    if (_isCancelling) return;
    setState(() {
      _isCancelling = true;
      _userInitiatedCancel = true;
    });
    try {
      final response = await CancelRide.call(
        rideId: widget.rideId,
        cancellationReason: reason,
        token: FFAppState().accessToken,
        cancelledBy: 'user',
      );
      if (mounted) {
        if (response.succeeded) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(FFLocalizations.of(context).getText('ride_cancelled_success')),
              backgroundColor: Colors.green));
          setState(() {
            _rideStatus = STATUS_CANCELLED;
            _searchTimer?.cancel();
            _stopDistanceUpdateTimer();
            _stopApproachRouteTimer();
            _routeRefreshDebounce?.cancel();
          });
          FFAppState().bookingInProgress = false;
          FFAppState().currentRideId = null;
          RideSession().clear();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.pop();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(FFLocalizations.of(context).getText('ride_cancel_failed')),
              backgroundColor: Colors.red));
        }
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _handleRebook() async {
    if (_isRebooking) return;
    setState(() => _isRebooking = true);

    try {
      final response = await RebookRideCall.call(
        rideId: widget.rideId,
        token: FFAppState().accessToken,
      );

      if (response.succeeded) {
        // Clear cancel flags and reset status to searching
        setState(() {
          _rideStatus = STATUS_SEARCHING;
          _cancelledByDriver = false;
          _userInitiatedCancel = false;
          _isRebooking = false;
          _searchSeconds = 0;
        });

        _startSearchTimer();
        _startNearbyDriversTimer();
        _initializeSocket();
        _initializeMap();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rebooking successful! Searching for drivers...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rebooking failed: ${RebookRideCall.message(response.jsonBody) ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isRebooking = false);
      }
    } catch (e) {
      print('❌ Error during rebooking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during rebooking.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isRebooking = false);
    }
  }

  Future<void> _handleRebookWithExtra(int extraAmount) async {
    if (_isRebooking) return;
    setState(() => _isRebooking = true);

    try {
      final response = await RebookRideCall.call(
        rideId: widget.rideId,
        token: FFAppState().accessToken,
        extraFare: extraAmount,
      );

      if (response.succeeded) {
        final newRideId = RebookRideCall.newRideId(response.jsonBody);
        final newFare = RebookRideCall.estimatedFare(response.jsonBody) ?? _estimatedFare;
        final newExtra = RebookRideCall.extraFareResponse(response.jsonBody) ?? extraAmount.toDouble();

        setState(() {
          _rideStatus = STATUS_SEARCHING;
          _cancelledByDriver = false;
          _userInitiatedCancel = false;
          _isRebooking = false;
          _searchSeconds = 0;
          _declineCount = 0;
          _totalDriversNotified = 0;
          _estimatedFare = newFare;
          _extraFare = newExtra;
        });

        _startSearchTimer();
        _startNearbyDriversTimer();
        _initializeSocket();
        _initializeMap();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Searching with + ₹$extraAmount extra!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rebook failed: ${RebookRideCall.message(response.jsonBody) ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isRebooking = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during rebooking.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isRebooking = false);
    }
  }

  Future<void> _makeCall(String? phoneNumber) async {
    final raw = (phoneNumber ?? '').trim();
    if (raw.isEmpty || raw == 'null') return;
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (!clean.startsWith('+') && RegExp(r'^\d{10}$').hasMatch(clean))
      clean = '+91$clean';
    try {
      await launchUrl(Uri(scheme: 'tel', path: clean),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(FFLocalizations.of(context).getText('ride_cancel_dialog_title'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(FFLocalizations.of(context).getText('ride_cancel_dialog_text')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(FFLocalizations.of(context).getText('no'))),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelRide('Customer requested cancellation');
              },
              child: Text(FFLocalizations.of(context).getText('yes_cancel'),
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onBackPressed() async {
    if (_rideStatus == STATUS_CANCELLED || _rideStatus == STATUS_COMPLETED)
      return true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(FFLocalizations.of(context).getText('ride_back_restriction'))));
    return false;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _rideCheckTimer?.cancel();
    _stopDistanceUpdateTimer();
    _stopNearbyDriversTimer();
    _stopApproachRouteTimer();
    _routeRefreshDebounce?.cancel();
    try {
      socket?.off("ride_updated");
      socket?.disconnect();
      socket?.dispose();
    } catch (_) {}
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false prevents the user from leaving unless you manually trigger it
      // canPop: true allows the back button to work naturally
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // If the system already handled the pop, do nothing
        if (didPop) {
          return;
        }

        // Call your existing _onBackPressed function
        final shouldPop = await _onBackPressed();

        // If your logic says "yes, let's leave", trigger the pop manually
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Map (Full Screen)
            Positioned.fill(
              child: GoogleMap(
                style: googleMapStyleStrings[GoogleMapStyle.uber],
                onMapCreated: (c) {
                  _mapController = c;
                  _initializeMap();
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    FFAppState().pickupLatitude ?? AppConfig.defaultLat,
                    FFAppState().pickupLongitude ?? AppConfig.defaultLng,
                  ),
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.4, // Keep markers above collapsed sheet
                ),
              ),
            ),

            // Map refresh / recenter button (similar to driver app)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: Material(
                color: Colors.white,
                elevation: 6.0,
                shadowColor: Colors.black26,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Show full route',
                  onPressed: () async {
                    try {
                      await _initializeMap();
                      if (mounted) _fitMapToRideContext();
                    } catch (e) {
                      debugPrint('Error refreshing map: $e');
                    }
                  },
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFFFF7B10),
                  ),
                ),
              ),
            ),

            // Header (Stays on top)
            Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

            // 3. Draggable Bottom Sheet (Driver Details / Search)
            DraggableScrollableSheet(
              initialChildSize: _rideStatus == STATUS_SEARCHING || _rideStatus == STATUS_CANCELLED ? 0.45 : 0.45,
              minChildSize: _rideStatus == STATUS_SEARCHING || _rideStatus == STATUS_CANCELLED ? 0.45 : 0.25,
              maxChildSize: _rideStatus == STATUS_SEARCHING || _rideStatus == STATUS_CANCELLED ? 0.45 : 0.90,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _buildBottomComponent(scrollController),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static const String _supportNumber = '+919100088718';
  static const String _emergencyNumber = '112';

  Future<void> _callEmergencySosApi() async {
    final userId = FFAppState().userid;
    if (userId == 0) return;
    double lat = 0, lng = 0;
    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}
    try {
      await EmergencySosCall.call(
        rideId: widget.rideId,
        userId: userId,
        latitude: lat,
        longitude: lng,
        token: FFAppState().accessToken,
      );
    } catch (e) {
      debugPrint('EmergencySos API error: $e');
    }
  }

  Future<void> _createSupportTicketForIncident(String title, String source) async {
    final userId = FFAppState().userid;
    if (userId == 0) return;
    final rideId = widget.rideId;
    final desc = 'User triggered $source during active ride. Ride ID: $rideId.';
    await CreateSupportTicketCall.call(
      ticketType: 'ride_issue',
      ticketTitle: title,
      ticketDescription: desc,
      userId: userId,
      priorityLevel: 'high',
      token: FFAppState().accessToken,
    );
  }

  void _showRideCheckDialog() {
    if (!mounted || _rideCheckShown) return;
    _rideCheckShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(FFLocalizations.of(context).getText('ride_check_title'), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Text(
          FFLocalizations.of(context).getText('ride_check_text'),
          style: GoogleFonts.inter(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _callEmergencySosApi();
              _createSupportTicketForIncident('RideCheck - I need help', 'RideCheck');
              launchUrl(Uri(scheme: 'tel', path: _supportNumber), mode: LaunchMode.externalApplication);
            },
            child: Text(FFLocalizations.of(context).getText('ride_check_help'), style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            child: Text(FFLocalizations.of(context).getText('ride_check_fine'), style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleShareTrip() {
    final ride = ridesCache.isNotEmpty ? ridesCache[0] : null;
    final pickup = ride?['pickup_location_address'] ?? FFAppState().pickuplocation;
    final drop = ride?['drop_location_address'] ?? FFAppState().droplocation;
    final rideId = ride?['id'] ?? widget.rideId;
    final eta = _currentRemainingDistance != null
        ? '~${(_currentRemainingDistance! / 0.5).round() * 2} mins'
        : 'En route';
    final shareText = 'My UGO ride: $pickup → $drop. Ride ID: $rideId. ETA: $eta. Track: https://ugotaxiservices.com';
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(FFLocalizations.of(context).getText('ride_share_trip'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 24),
                ),
                title: Text('WhatsApp', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}'), mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(Icons.sms, color: Colors.blue[700], size: 24),
                ),
                title: Text('SMS', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri(scheme: 'sms', queryParameters: {'body': shareText}), mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSosPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                FFLocalizations.of(context).getText('sos_title'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FFLocalizations.of(context).getText('sos_text'),
              style: GoogleFonts.inter(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                launchUrl(Uri(scheme: 'tel', path: _emergencyNumber),
                    mode: LaunchMode.externalApplication);
              },
              icon: Icon(Icons.emergency, size: 16, color: Colors.red),
              label: Text(FFLocalizations.of(context).getText('sos_call_112'), style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(FFLocalizations.of(context).getText('no'), style: GoogleFonts.inter(color: FlutterFlowTheme.of(context).secondaryText)),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              _callEmergencySosApi();
              _createSupportTicketForIncident('SOS - Emergency support requested', 'SOS');
              launchUrl(Uri(scheme: 'tel', path: _supportNumber),
                  mode: LaunchMode.externalApplication);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Expanded(child: Text(FFLocalizations.of(context).getText('sos_calling'))),
                      ],
                    ),
                    backgroundColor: Colors.green[700],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: Icon(Icons.phone, size: 18, color: Colors.white),
            label: Text(FFLocalizations.of(context).getText('sos_call_support')),
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _rideStatus == STATUS_SEARCHING
                  ? FFLocalizations.of(context).getText('finding_ride')
                  : FFLocalizations.of(context).getText('your_ride'),
              style:
                  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          if (_rideStatus != STATUS_SEARCHING) ...[
            GestureDetector(
              onTap: _handleSosPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FlutterFlowTheme.of(context).error.withValues(alpha: 0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency, size: 18, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Text(
                      FFLocalizations.of(context).getText('sos'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FlutterFlowTheme.of(context).error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 16, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(FFLocalizations.of(context).getText('safety'),
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _driverDisplayName() {
    final d = driverDetails;
    if (d == null) return 'Driver';
    final f = d['first_name']?.toString() ?? '';
    final l = d['last_name']?.toString() ?? '';
    final n = '$f $l'.trim();
    return n.isNotEmpty ? n : 'Driver';
  }

  void _openRideChat() {
    final ride = ridesCache.isNotEmpty ? ridesCache[0] : null;
    final id = ride?['id'] ?? widget.rideId;
    if (!context.mounted) return;
    context.pushNamed(
      RideChatWidget.routeName,
      queryParameters: {
        'rideId': id.toString(),
        'partnerName': _driverDisplayName(),
      },
    );
  }

  bool get _isChatAvailableForStatus {
    final s = _rideStatus.toLowerCase();
    return s == STATUS_ACCEPTED || s == STATUS_ARRIVING || s == STATUS_PICKED_UP;
  }

  Widget _buildBottomComponent(ScrollController scrollController) {
    if (_rideStatus == STATUS_SEARCHING) {
      return SingleChildScrollView(
        controller: scrollController,
        child: SearchingRideComponent(
          searchSeconds: _searchSeconds,
          onCancel: _showCancelDialog,
          declineCount: _declineCount,
          totalDriversNotified: _totalDriversNotified,
          estimatedFare: _estimatedFare,
          extraFare: _extraFare,
          onRebookWithExtra: _handleRebookWithExtra,
        ),
      );
    } else if (_rideStatus == STATUS_CANCELLED) {
      return SingleChildScrollView(
        controller: scrollController,
        child: RideCancelledComponent(
          onBackToHome: () {
            FFAppState().bookingInProgress = false;
            FFAppState().currentRideId = null;
            FFAppState().currentRideOtp = '';
            if (context.mounted) context.goNamed(HomeWidget.routeName);
          },
          onFindNewRide: _cancelledByDriver
              ? () {
                  FFAppState().bookingInProgress = false;
                  FFAppState().currentRideId = null;
                  FFAppState().currentRideOtp = '';
                  if (context.mounted) context.pop();
                }
              : null,
          onRebook: _cancelledByDriver ? _handleRebook : null,
          rebookingFee: 20,
          cancelledByDriver: _cancelledByDriver,
        ),
      );
    } else {
      return DriverDetailsComponent(
        isLoading: isLoadingDriver,
        driverDetails: driverDetails,
        driverId: ridesCache.isNotEmpty ? ridesCache[0]['driver_id'] : null,
        rideOtp: _rideOtp,
        ridesCache: ridesCache,
        onCall: _makeCall,
        onCancel: _showCancelDialog,
        onShare: _handleShareTrip,
        onChat: _isChatAvailableForStatus ? _openRideChat : null,
        rideStatus: _rideStatus,
        currentRemainingDistance: _currentRemainingDistance,
        liveEtaText: _liveEtaText,
        totalRoadDistanceKm: _totalRoadDistanceKm,
        scrollController: scrollController,
      );
    }
  }

}
