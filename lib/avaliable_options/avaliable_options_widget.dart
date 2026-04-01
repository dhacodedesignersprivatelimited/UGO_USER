import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_google_map.dart' show GoogleMapStyle, googleMapStyleStrings;
import '/flutter_flow/flutter_flow_util.dart' hide LatLng;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin, sin, min;
import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
export 'avaliable_options_model.dart';

class AvaliableOptionsWidget extends StatefulWidget {
  const AvaliableOptionsWidget({super.key});

  static String routeName = 'avaliable-options';
  static String routePath = '/avaliableOptions';

  @override
  State<AvaliableOptionsWidget> createState() => _AvaliableOptionsWidgetState();
}

class _AvaliableOptionsWidgetState extends State<AvaliableOptionsWidget>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation
  // Removed unused slide controllers

  // State
  String? selectedVehicleType;
  bool isLoadingRide = false;
  bool isCalculatingRoute = false;

  // Map
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // Route Data
  double? googleDistanceKm;
  String? googleDuration;

  // Data Caching
  Future<List<dynamic>>? _vehiclesFuture;
  bool showPaymentOptions = false;
  String selectedPaymentMethod = 'Cash'; // Default

  // Vehicle marker icons (1=auto, 2=bike, 3=car) - distinct Uber-style icons
  BitmapDescriptor? _bikeIcon;
  BitmapDescriptor? _autoIcon;
  BitmapDescriptor? _carIcon;

  // Razorpay & Wallet
  late Razorpay _razorpay;
  /// Rupees to add to wallet after Razorpay (shortfall only).
  double? _pendingWalletShortfall;
  int? _pendingFinalFare;
  int? _pendingCoinsToUse;
  String? _pendingVehicleType;

  /// Referral coins to apply on this booking (multiple of 10; 10 = ₹1).
  int _coinsToUse = 0;

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod =
        _formatPaymentMethod(FFAppState().selectedPaymentMethod);

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    // 1. Vehicles
    _vehiclesFuture = _getVehicleData(); // Fetch once on init
    _initializeMap();
    _refreshCoinsFromBackend();
  }

  /// Backend rule: coins multiple of 10; discount ₹ = coins/10; discount must be less than fare.
  int _maxCoinsUsableForFare(int balance, int fareAfterPromoRupees) {
    if (fareAfterPromoRupees <= 0 || balance < 10) return 0;
    final maxByFare = fareAfterPromoRupees * 10 - 1;
    if (maxByFare < 10) return 0;
    final cap = min(balance, maxByFare);
    return (cap ~/ 10) * 10;
  }

  Future<void> _refreshCoinsFromBackend() async {
    final app = FFAppState();
    if (app.userid <= 0 || app.accessToken.isEmpty) return;
    try {
      final res = await GetUserByIdCall.call(
        userId: app.userid,
        token: app.accessToken,
      );
      if (!res.succeeded || !mounted) return;
      final c = GetUserByIdCall.coinsBalance(res.jsonBody) ?? 0;
      app.coinsBalance = c;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 🗺️ MAP LOGIC
  // ---------------------------------------------------------------------------

  Future<void> _initializeMap() async {
    await _addMarkers();
    await _getRoutePolyline();
  }

  Future<void> _addMarkers() async {
    final appState = FFAppState();
    if (appState.pickupLatitude != null && appState.dropLatitude != null) {
      final newMarkers = <Marker>{};
      // Pickup Marker
      newMarkers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(appState.pickupLatitude!, appState.pickupLongitude!),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
      // Drop Marker
      newMarkers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(appState.dropLatitude!, appState.dropLongitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

      // Driver markers (orange bike/auto/car - Uber style)
      final driverMarkers = await _buildDriverMarkers(appState);
      newMarkers.addAll(driverMarkers);

      if (mounted) {
        setState(() {
          markers.clear();
          markers.addAll(newMarkers);
        });
      }
    }
  }

  Future<void> _loadVehicleIconsIfNeeded() async {
    if (_bikeIcon != null) return;
    try {
      final config = ImageConfiguration(size: Size(48, 48));
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
      print('❌ Error loading vehicle icons: $e');
    }
  }

  Future<Set<Marker>> _buildDriverMarkers(FFAppState appState) async {
    final result = <Marker>{};
    try {
      await _loadVehicleIconsIfNeeded();

      final response = await GetAllDriversCall.call();
      if (!response.succeeded) return result;
      final allDrivers =
          (getJsonField(response.jsonBody, r'''$.data''') as List?)?.toList() ??
              [];
      final filtered =
          _filterDriversByVehicleType(allDrivers, appState.selectedRideCategory);

      final orangeIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

      int index = 0;
      for (final d in filtered) {
        final isActive = getJsonField(d, r'''$.is_active''') == true;
        final isOnline = getJsonField(d, r'''$.is_online''') == true;
        if (!isActive || !isOnline) continue;

        final lat = getJsonField(d, r'''$.current_location_latitude''');
        final lng = getJsonField(d, r'''$.current_location_longitude''');
        if (lat == null || lng == null) continue;

        final latVal = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
        final lngVal = lng is num ? lng.toDouble() : double.tryParse(lng.toString());
        if (latVal == null || lngVal == null) continue;

        final vtId = getJsonField(d, r'''$.vehicle_type_id''');
        final vt = vtId is int ? vtId : int.tryParse(vtId?.toString() ?? '');
        final vehicleLabel = vt == 1 ? 'auto' : vt == 2 ? 'bike' : vt == 3 ? 'car' : 'ride';
        final driverIcon = (vt == 1 ? _autoIcon : vt == 2 ? _bikeIcon : _carIcon) ?? orangeIcon;
        final name = '${getJsonField(d, r'''$.first_name''') ?? ''} ${getJsonField(d, r'''$.last_name''') ?? ''}'.trim();
        final info = name.isNotEmpty ? '$name • $vehicleLabel' : vehicleLabel;

        result.add(Marker(
          markerId: MarkerId('driver_$index'),
          position: LatLng(latVal, lngVal),
          icon: driverIcon,
          infoWindow: InfoWindow(title: vehicleLabel.toUpperCase(), snippet: info),
        ));
        index++;
      }
    } catch (e) {
      print('❌ Error adding driver markers: $e');
    }
    return result;
  }

  Future<void> _getRoutePolyline() async {
    final appState = FFAppState();
    if (appState.pickupLatitude == null || appState.dropLatitude == null)
      return;

    setState(() => isCalculatingRoute = true);

    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${appState.pickupLatitude},${appState.pickupLongitude}'
          '&destination=${appState.dropLatitude},${appState.dropLongitude}'
          '&key=${AppConfig.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final leg = route['legs'][0];
          final points = _decodePolyline(route['overview_polyline']['points']);

          setState(() {
            googleDistanceKm = leg['distance']['value'] / 1000.0;
            googleDuration = leg['duration']['text'];

            polylines.clear();
            polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: Colors.orange,
              width: 4,
              geodesic: true,
            ));
            isCalculatingRoute = false;
          });

          if (mapController != null && points.isNotEmpty) {
            // Wait slightly for map to render before zooming
            await Future.delayed(const Duration(milliseconds: 300));
            _animateCameraToBounds(points);
          }
        }
      }
    } catch (e) {
      print('❌ Route Error: $e');
      _useFallbackDistance();
    }
  }

  void _useFallbackDistance() {
    final appState = FFAppState();
    if (appState.pickupLatitude != null && appState.dropLatitude != null) {
      setState(() {
        googleDistanceKm = calculateDistance(
          appState.pickupLatitude!,
          appState.pickupLongitude!,
          appState.dropLatitude!,
          appState.dropLongitude!,
        );
        googleDuration = 'Estimated';
        isCalculatingRoute = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 🧮 UTILITIES
  // ---------------------------------------------------------------------------

  double calculateTieredFare({
    required double distanceKm,
    required double baseKmStart,
    required double baseKmEnd,
    required double baseFare,
    required double pricePerKm,
  }) {
    if (distanceKm <= 0) return 0;
    if (distanceKm <= baseKmEnd) return baseFare;
    final extraKm = distanceKm - baseKmEnd;
    return baseFare + (extraKm * pricePerKm);
  }

  Future<List<dynamic>> _getVehicleData() async {
    try {
      final vehiclesResponse = await GetVehicleDetailsCall.call();
      final driversResponse = await GetAllDriversCall.call();

      List<dynamic> vehicles = [];
      if (vehiclesResponse.succeeded) {
        vehicles =
            (getJsonField(vehiclesResponse.jsonBody, r'''$.data''') as List?)
                    ?.map((v) => v is Map ? Map<String, dynamic>.from(v) : v)
                    .toList() ??
                [];
      }

      List<dynamic> allDrivers = [];
      if (driversResponse.succeeded) {
        allDrivers =
            (getJsonField(driversResponse.jsonBody, r'''$.data''') as List?)
                    ?.toList() ??
                [];
      }

      vehicles = _filterVehiclesByCategory(vehicles);
      final availableDrivers =
          _filterDriversByVehicleType(allDrivers, FFAppState().selectedRideCategory);

      return _mergeDriverCountsIntoVehicles(vehicles, availableDrivers);
    } catch (e) {
      print('❌ Error fetching vehicles: $e');
    }
    return [];
  }

  List<dynamic> _filterDriversByVehicleType(
      List<dynamic> drivers, String? category) {
    if (category == null || category.isEmpty) return drivers;
    final cat = category.toLowerCase();

    int? targetVehicleTypeId;
    switch (cat) {
      case 'auto':
        targetVehicleTypeId = 1;
        break;
      case 'bike':
        targetVehicleTypeId = 2;
        break;
      case 'car':
        targetVehicleTypeId = 3;
        break;
      default:
        return drivers;
    }

    return drivers.where((d) {
      final isActive = getJsonField(d, r'''$.is_active''') == true;
      final isOnline = getJsonField(d, r'''$.is_online''') == true;
      final vtId = getJsonField(d, r'''$.vehicle_type_id''');
      final driverVtId = vtId is int ? vtId : int.tryParse(vtId?.toString() ?? '');
      return isActive &&
          isOnline &&
          driverVtId != null &&
          driverVtId == targetVehicleTypeId;
    }).toList();
  }

  List<dynamic> _mergeDriverCountsIntoVehicles(
      List<dynamic> vehicles, List<dynamic> drivers) {
    return vehicles.map((v) {
      final m =
          v is Map<String, dynamic> ? v : Map<String, dynamic>.from(v as Map);
      final vehicleTypeId = getJsonField(m, r'''$.vehicle_type_id''');
      final vtId = vehicleTypeId is int
          ? vehicleTypeId
          : int.tryParse(vehicleTypeId?.toString() ?? '');
      final adminVehicleId = getJsonField(m, r'''$.id''');
      final avId = adminVehicleId is int
          ? adminVehicleId
          : int.tryParse(adminVehicleId?.toString() ?? '');

      int count = 0;
      for (final d in drivers) {
        final dVtId = getJsonField(d, r'''$.vehicle_type_id''');
        final driverVtId =
            dVtId is int ? dVtId : int.tryParse(dVtId?.toString() ?? '');
        final dAvId = getJsonField(d, r'''$.admin_vehicle_id''');
        final driverAvId =
            dAvId is int ? dAvId : int.tryParse(dAvId?.toString() ?? '');
        final matchesByType = driverVtId != null && driverVtId == vtId;
        final matchesByAdminVehicle =
            driverAvId != null && avId != null && driverAvId == avId;
        if (matchesByType || matchesByAdminVehicle) count++;
      }
      m['available_drivers_count'] = count;
      return m;
    }).toList();
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'bike':
        return 'Bike';
      case 'auto':
        return 'Auto';
      case 'car':
        return 'Car';
      default:
        return category;
    }
  }

  String _getDriverAvailabilityText(dynamic data) {
    final count = getJsonField(data, r'''$.available_drivers_count''');
    final n = count is int ? count : int.tryParse(count?.toString() ?? '0') ?? 0;
    if (n <= 0) return '10 drivers nearby';
    if (n == 1) return '1 driver available';
    return '$n drivers available';
  }

  /// Filters vehicles by category. Uses vehicle_type_id (1=auto, 2=bike, 3=car)
  /// when available; falls back to name/type string matching.
  List<dynamic> _filterVehiclesByCategory(List<dynamic> vehicles) {
    final category = FFAppState().selectedRideCategory?.toLowerCase();
    if (category == null || category.isEmpty) return vehicles;

    int? targetVehicleTypeId;
    switch (category) {
      case 'auto':
        targetVehicleTypeId = 1;
        break;
      case 'bike':
        targetVehicleTypeId = 2;
        break;
      case 'car':
        targetVehicleTypeId = 3;
        break;
      default:
        return vehicles;
    }

    return vehicles.where((v) {
      final vtId = getJsonField(v, r'''$.vehicle_type_id''');
      final vehicleTypeId =
          vtId is int ? vtId : int.tryParse(vtId?.toString() ?? '');
      if (vehicleTypeId != null && vehicleTypeId == targetVehicleTypeId) {
        return true;
      }
      final name =
          (getJsonField(v, r'''$.vehicle_name''') ?? '').toString().toLowerCase();
      final type =
          (getJsonField(v, r'''$.vehicle_type''') ?? '').toString().toLowerCase();
      final combined = '$name $type';
      switch (category) {
        case 'bike':
          return combined.contains('bike') ||
              combined.contains('motorcycle') ||
              combined.contains('2-wheeler');
        case 'car':
          return (combined.contains('car') ||
                  combined.contains('sedan') ||
                  combined.contains('suv') ||
                  combined.contains('hatchback')) &&
              !combined.contains('auto');
        case 'auto':
          return combined.contains('auto') ||
              combined.contains('rickshaw') ||
              combined.contains('autorickshaw');
        default:
          return true;
      }
    }).toList();
  }

  // Haversine Fallback
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    double dLon = (lon2 - lon1) * (3.141592653589793 / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (3.141592653589793 / 180)) *
            cos(lat2 * (3.141592653589793 / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadius * 2 * asin(sqrt(a));
  }

  static String _formatDistance(double? km) {
    if (km == null) return '--';
    return km < 1 ? '${(km * 1000).round()}m' : '${km.toStringAsFixed(1)}Km';
  }

  // Polyline Decoder
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

  void _animateCameraToBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
          southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      80, // Padding
    ));
  }

  // ---------------------------------------------------------------------------
  // 🚀 BOOKING ACTION
  // ---------------------------------------------------------------------------

  Future<void> _confirmBooking() async {
    final appState = FFAppState();

    if (selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vehicle type')));
      return;
    }

    setState(() => isLoadingRide = true);

    try {
      double distance = googleDistanceKm ??
          calculateDistance(
            appState.pickupLatitude!,
            appState.pickupLongitude!,
            appState.dropLatitude!,
            appState.dropLongitude!,
          );

      final double rawFare = calculateTieredFare(
        distanceKm: distance,
        baseKmStart: appState.selectedBaseKmStart,
        baseKmEnd: appState.selectedBaseKmEnd,
        baseFare: appState.selectedBaseFare,
        pricePerKm: appState.selectedPricePerKm,
      );

      final int finalFare =
          (rawFare - appState.discountAmount).round().clamp(0, 999999);

      final maxCoins = _maxCoinsUsableForFare(
          appState.coinsBalance, finalFare);
      final coinsToSend =
          _coinsToUse > maxCoins ? maxCoins : _coinsToUse;

      // ✅ WALLET PAYMENT LOGIC
      if (selectedPaymentMethod == 'Wallet') {
        final proceedToCreate =
            await _handleWalletPayment(appState, finalFare, coinsToSend);
        if (!proceedToCreate) {
          if (mounted) setState(() => isLoadingRide = false);
          return; // Wait for Razorpay success callback
        }
      }

      await _createRideAndNavigate(finalFare, coinsToSend);
    } catch (e) {
      print('❌ Booking Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => isLoadingRide = false);
    }
  }

  // ✅ WALLET PAYMENT HANDLING
  Future<bool> _handleWalletPayment(
    FFAppState appState,
    int rideAmount,
    int coinsToUse,
  ) async {
    final double coinDiscountRs = coinsToUse / 10.0;
    final double amountDue = rideAmount - coinDiscountRs;

    print('💳 Starting Wallet Payment Process...');
    print('🚗 Ride Amount (after promo): ₹$rideAmount');
    print('🪙 Coin discount: ₹$coinDiscountRs → pay from wallet: ₹$amountDue');

    try {
      // 1️⃣ FETCH WALLET BALANCE
      final walletRes = await GetwalletCall.call(
        userId: appState.userid,
        token: appState.accessToken,
      );

      if (!walletRes.succeeded) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to fetch wallet balance'),
          backgroundColor: Colors.red,
        ));
        return false;
      }

      final walletBalanceStr = GetwalletCall.walletBalance(walletRes.jsonBody);
      final double walletBalance =
          double.tryParse(walletBalanceStr ?? '0') ?? 0.0;

      print('💰 Wallet Balance: ₹$walletBalance');
      print('💰 Shortfall: ₹${amountDue - walletBalance}');

      // 2️⃣ CHECK IF WALLET HAS SUFFICIENT BALANCE (after coin discount)
      if (walletBalance >= amountDue) {
        print('✅ Wallet has sufficient balance');
        return true;
      }

      // 3️⃣ INSUFFICIENT BALANCE - top up shortfall only
      final double shortfall = amountDue - walletBalance;
      final int differenceAmount = shortfall.ceil().clamp(1, 999999);
      print(
          '🔴 Insufficient balance, opening Razorpay for: ₹$differenceAmount');

      _pendingWalletShortfall = shortfall;
      _pendingFinalFare = rideAmount;
      _pendingCoinsToUse = coinsToUse;
      _pendingVehicleType = selectedVehicleType;

      // 4️⃣ OPEN RAZORPAY FOR DIFFERENCE
      _openRazorpayForWallet(differenceAmount, appState);

      // Return false to wait for Razorpay success callback
      return false;
    } catch (e) {
      print('❌ Wallet Payment Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Wallet Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
      return false;
    }
  }

  void _openRazorpayForWallet(int amountInRupees, FFAppState appState) {
    var options = {
      'key': 'rzp_test_SAvHgTPEoPnNo7',
      'amount': (amountInRupees * 100), // Convert to paise
      'name': 'Ugo App',
      'description': 'Wallet Top-up for Ride',
      'prefill': {
        'contact': '9885881832',
        'email': 'test@email.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('❌ Razorpay Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success: ${response.paymentId}');

    final appState = FFAppState();
    final amountToAdd = _pendingWalletShortfall ?? 0.0;

    if (amountToAdd <= 0) {
      print('❌ Invalid amount');
      return;
    }

    try {
      // 5️⃣ ADD MONEY TO WALLET
      final addMoneyRes = await AddMoneyToWalletCall.call(
        userId: appState.userid,
        amount: amountToAdd,
        currency: 'INR',
        token: appState.accessToken,
      );

      if (addMoneyRes.succeeded) {
        print('✅ Money added to wallet successfully');

        // 6️⃣ FETCH UPDATED WALLET BALANCE
        final walletRes = await GetwalletCall.call(
          userId: appState.userid,
          token: appState.accessToken,
        );

        if (walletRes.succeeded) {
          final newBalance = GetwalletCall.walletBalance(walletRes.jsonBody);
          print('✅ Updated Wallet Balance: ₹$newBalance');
          setState(() {
          });

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Payment successful! Wallet updated.'),
            backgroundColor: Colors.green,
          ));
        }

        // Proceed to create ride after wallet top-up
        if (_pendingFinalFare != null) {
          if (mounted) setState(() => isLoadingRide = true);
          await _createRideAndNavigate(
            _pendingFinalFare!,
            _pendingCoinsToUse ?? 0,
          );
          _pendingFinalFare = null;
          _pendingCoinsToUse = null;
          _pendingWalletShortfall = null;
          _pendingVehicleType = null;
        }
      } else {
        print('❌ Failed to add money to wallet');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Failed to update wallet'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _createRideAndNavigate(int finalFare, int coinsToUse) async {
    final appState = FFAppState();
    final String vehicleTypeToUse =
        _pendingVehicleType ?? selectedVehicleType ?? '1';

    final createRideRes = await CreateRideCall.call(
      token: appState.accessToken,
      userId: appState.userid,
      pickupLocationAddress: appState.pickuplocation,
      dropLocationAddress: appState.droplocation,
      pickupLatitude: appState.pickupLatitude,
      pickupLongitude: appState.pickupLongitude,
      dropLatitude: appState.dropLatitude,
      dropLongitude: appState.dropLongitude,
      adminVehicleId: int.tryParse(vehicleTypeToUse) ?? 1,
      estimatedFare: finalFare.toString(),
      paymentType: selectedPaymentMethod.toLowerCase(),
      coinsToUse: coinsToUse > 0 ? coinsToUse : null,
    );

    if (createRideRes.succeeded) {
      final rideId =
          getJsonField(createRideRes.jsonBody, r'''$.data.id''')?.toString();
      if (rideId != null) {
        appState.currentRideId = int.parse(rideId);
        appState.bookingInProgress = true;
        if (coinsToUse > 0) {
          final next = appState.coinsBalance - coinsToUse;
          appState.coinsBalance = next < 0 ? 0 : next;
        }
        _refreshCoinsFromBackend();

        context.pushNamed(
          RideRequestScreen.routeName,
          queryParameters: {
            'rideId': rideId,
            'totalDistanceKm': googleDistanceKm?.toString(),
            'totalDuration': googleDuration,
          },
        );
      }
      print('✅ Ride Created: $rideId');
      print('💳 Payment Method: ${selectedPaymentMethod.toLowerCase()}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(getJsonField(createRideRes.jsonBody, r'$.message') ??
            'Booking failed'),
        backgroundColor: Colors.red,
      ));
    }

    if (mounted) setState(() => isLoadingRide = false);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error: ${response.message}');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('❌ Payment Failed: ${response.message}'),
      backgroundColor: Colors.red,
    ));
  }

  // ---------------------------------------------------------------------------
  // 🖥️ BUILD UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    double currentDistance = googleDistanceKm ?? 0.0;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Map Layer
          Positioned.fill(
            child: GoogleMap(
              style: googleMapStyleStrings[
                  isDark ? GoogleMapStyle.dark : GoogleMapStyle.uber],
              onMapCreated: (c) {
                mapController = c;
                if (markers.isNotEmpty) _initializeMap();
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(appState.pickupLatitude ?? AppConfig.defaultLat,
                    appState.pickupLongitude ?? AppConfig.defaultLng),
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              // IMPORTANT: Add padding to map so Google logo and route stay above bottom sheet
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.55),
            ),
          ),

          // 2. Top Bar (Rapido-style: compact header + trip summary chip)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 10, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withValues(alpha: 0.92),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 20, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your ride',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7B10).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF7B10).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.route_rounded,
                                size: 16,
                                color: const Color(0xFFFF7B10),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${_formatDistance(currentDistance)} · ${googleDuration ?? (isCalculatingRoute ? "Route…" : "—")}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Draggable Bottom Sheet (Vehicle List)
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.45,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Drag Handle
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Header Info inside sheet (if any)
                        if (appState.selectedRideCategory != null && appState.selectedRideCategory!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  _getCategoryLabel(appState.selectedRideCategory!),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'RIDES',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // List area
                        Expanded(
                          child: FutureBuilder<List<dynamic>>(
                            future: _vehiclesFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7B10)));
                              }
                              final vehicles = snapshot.data!;
                              if (vehicles.isEmpty) {
                                return _buildEmptyState(appState, theme);
                              }

                              return ListView.builder(
                                controller: scrollController, // Key for dragging
                                padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 130), // Padding for bottom actions
                                itemCount: vehicles.length,
                                itemBuilder: (context, index) {
                                  return _buildVehicleCard(
                                      vehicles[index], currentDistance, appState, theme);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // Fixed Bottom Section (Payment & Confirm)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: _buildBottomActions(appState, theme),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FFAppState appState, ThemeData theme) {
    final category = appState.selectedRideCategory ?? 'ride';
    final label = category == 'bike' ? 'Bike' : category == 'car' ? 'Car' : category == 'auto' ? 'Auto' : 'ride';
    const brand = Color(0xFFFF7B10);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brand.withValues(alpha: 0.2),
                    brand.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Icon(Icons.two_wheeler_rounded,
                  size: 44, color: brand.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 20),
            Text(
              'No $label rides right now',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'See every vehicle type on the home screen,\nor pick another category.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                FFAppState().selectedRideCategory = null;
                setState(() {
                  _vehiclesFuture = _getVehicleData();
                });
                _addMarkers();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: brand,
                backgroundColor: brand.withValues(alpha: 0.12),
                elevation: 0,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: brand.withValues(alpha: 0.35)),
                ),
              ),
              child: Text(
                'Show all rides',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(
      dynamic data, double distance, FFAppState appState, ThemeData theme) {
    final pricing = getJsonField(data, r'''$.pricing''');
    final String vehicleId =
        getJsonField(data, r'''$.pricing.vehicle_id''')?.toString() ??
        getJsonField(data, r'''$.id''')?.toString() ??
        '1';
    final String name =
        getJsonField(data, r'''$.vehicle_name''')?.toString() ?? 'Ride';

    // 1. IDENTIFY PRO RIDE
    bool isPro = name.toLowerCase().contains('pro') ||
        name.toLowerCase().contains('premium') ||
        name.toLowerCase().contains('prime');

    // Pricing Logic
    final baseKmStart = double.tryParse(
            getJsonField(pricing, r'''$.base_km_start''').toString()) ??
        1;
    final baseKmEnd = double.tryParse(
            getJsonField(pricing, r'''$.base_km_end''').toString()) ??
        5;
    final baseFare =
        double.tryParse(getJsonField(pricing, r'''$.base_fare''').toString()) ??
            0;
    final pricePerKm = double.tryParse(
            getJsonField(pricing, r'''$.price_per_km''').toString()) ??
        0;

    final calculatedFare = calculateTieredFare(
      distanceKm: distance,
      baseKmStart: baseKmStart,
      baseKmEnd: baseKmEnd,
      baseFare: baseFare,
      pricePerKm: pricePerKm,
    ).round();

    final isSelected = selectedVehicleType == vehicleId;
    final displayFare =
        (calculatedFare - appState.discountAmount).clamp(0, 999999).toInt();

    // Image Handling
    String? imgUrl = getJsonField(data, r'''$.vehicle_image''')?.toString();
    if (imgUrl != null && !imgUrl.startsWith('http'))
      imgUrl = 'https://ugo-api.icacorp.org/$imgUrl';

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onVar = theme.colorScheme.onSurfaceVariant;

    Color backgroundColor = isSelected
        ? (isPro
            ? const Color(0xFFFFF9C4)
            : const Color(0xFFFFF8F0))
        : (isPro
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65)
            : surface);

    Color borderColor = isSelected
        ? (isPro ? const Color(0xFFFBC02D) : const Color(0xFFFF7B10))
        : (isPro
            ? const Color(0xFFFFD54F)
            : theme.colorScheme.outline.withValues(alpha: 0.22));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedVehicleType = vehicleId;
            _coinsToUse = 0;
            appState.vehicleselect = vehicleId;
            appState.selectedBaseFare = baseFare;
            appState.selectedPricePerKm = pricePerKm;
            appState.selectedBaseKmStart = baseKmStart;
            appState.selectedBaseKmEnd = baseKmEnd;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : (isPro ? 1.5 : 1),
            ),
            boxShadow: [
              if (isPro)
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else if (isSelected)
                BoxShadow(
                  color: const Color(0xFFFF7B10).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // =========================
              // 3. IMAGE SECTION WITH CROWN STACK
              // =========================
              if (isPro)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // The Framed Image (Pushed down slightly)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFFBC02D), width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFFFBC02D).withValues(alpha:0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imgUrl != null
                              ? Image.network(imgUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.directions_car,
                                      color: Colors.amber))
                              : const Icon(Icons.directions_car,
                                  size: 36, color: Colors.amber),
                        ),
                      ),
                    ),
                    // The Crown Icon (Sitting on top center)
                    // The Crown Icon (Sitting on top center)
                    Positioned(
                      top:
                          -12, // Moves the crown slightly higher to "float" on the edge
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFBC02D), width: 1),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha:0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                        // 👑 Renders the Emoji directly
                        child: const Text(
                          '👑',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // --- NORMAL NO FRAME ---
                SizedBox(
                  width: 60,
                  height: 60,
                  child: imgUrl != null
                      ? Image.network(imgUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.directions_car,
                              color: onVar))
                      : Icon(Icons.directions_car,
                          size: 40, color: onVar),
                ),
              // =========================
              // END IMAGE SECTION
              // =========================

              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: onSurface,
                              )),
                        ),
                        const SizedBox(width: 6),
                        if (isPro)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF7B10),
                                    Color(0xFFE86500),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text('PRO',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        _getDriverAvailabilityText(data),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: onVar)),
                    if (isPro)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Comfy • Top Drivers',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: const Color(0xFFF57F17))),
                      ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('₹$displayFare',
                      style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: onSurface)),
                  if (isPro)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(Icons.star_rounded,
                          size: 18, color: Colors.amber[700]),
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(FFAppState appState, ThemeData theme) {
    final distance = googleDistanceKm ??
        (appState.pickupLatitude != null && appState.dropLatitude != null
            ? calculateDistance(
                appState.pickupLatitude!,
                appState.pickupLongitude!,
                appState.dropLatitude!,
                appState.dropLongitude!,
              )
            : 0.0);
    final estimatedFare = selectedVehicleType != null
        ? (calculateTieredFare(
                distanceKm: distance,
                baseKmStart: appState.selectedBaseKmStart,
                baseKmEnd: appState.selectedBaseKmEnd,
                baseFare: appState.selectedBaseFare,
                pricePerKm: appState.selectedPricePerKm,
              ) -
            appState.discountAmount)
            .round()
            .clamp(0, 999999)
        : null;

    const primaryOrange = Color(0xFFFF7B10);
    final maxCoinsForRide = estimatedFare != null
        ? _maxCoinsUsableForFare(appState.coinsBalance, estimatedFare)
        : 0;
    final coinsApplied =
        maxCoinsForRide > 0 ? (min(_coinsToUse, maxCoinsForRide)) : 0;
    final coinDiscountRs = coinsApplied / 10.0;
    final int amountToPay = estimatedFare == null
        ? 0
        : (estimatedFare - coinDiscountRs).round().clamp(0, 999999);

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onVar = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.fromLTRB(
          18, 14, 18, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Pay with',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: onVar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPaymentChip('Cash', Icons.money_rounded, primaryOrange, apiValue: 'Cash'),
                      const SizedBox(width: 8),
                      _buildPaymentChip('Wallet', Icons.account_balance_wallet_rounded, primaryOrange, apiValue: 'Wallet'),
                      const SizedBox(width: 8),
                      _buildPaymentChip('UPI', Icons.qr_code_rounded, primaryOrange, apiValue: 'Online'),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.pushNamed(VoucherWidget.routeName),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer_rounded, size: 18, color: primaryOrange),
                      const SizedBox(width: 4),
                      Text('Offers',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryOrange)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (selectedPaymentMethod == 'Wallet') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 18, color: primaryOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      coinsApplied > 0
                          ? 'Wallet: ₹${appState.walletBalance.toStringAsFixed(2)} • due ₹$amountToPay after coins'
                          : 'Wallet: ₹${appState.walletBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (maxCoinsForRide >= 10) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Referral coins (${appState.coinsBalance} avail.) · 10 = ₹1',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: coinsApplied < 10
                            ? null
                            : () => setState(() {
                                  _coinsToUse = (coinsApplied - 10)
                                      .clamp(0, maxCoinsForRide);
                                }),
                        icon: const Icon(Icons.remove, size: 20),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$coinsApplied coins → −₹${coinDiscountRs.toStringAsFixed(1)}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryOrange,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: coinsApplied >= maxCoinsForRide
                            ? null
                            : () => setState(() {
                                  final next = coinsApplied + 10;
                                  _coinsToUse =
                                      next.clamp(0, maxCoinsForRide);
                                }),
                        icon: const Icon(Icons.add, size: 20),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: (isLoadingRide || selectedVehicleType == null)
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFF7B10), Color(0xFFE86500)],
                    ),
              color: (isLoadingRide || selectedVehicleType == null)
                  ? theme.colorScheme.surfaceContainerHighest
                  : null,
              boxShadow: (isLoadingRide || selectedVehicleType == null)
                  ? null
                  : [
                      BoxShadow(
                        color: primaryOrange.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoadingRide || selectedVehicleType == null
                    ? null
                    : _confirmBooking,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: isLoadingRide
                      ? SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.onSurfaceVariant,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          selectedVehicleType != null && estimatedFare != null
                              ? 'Book for ₹$amountToPay · ${_paymentDisplayLabel(selectedPaymentMethod)}'
                              : 'Select a ride to continue',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: (isLoadingRide ||
                                    selectedVehicleType == null)
                                ? onVar
                                : Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChip(String label, IconData icon, Color primaryColor,
      {String? apiValue}) {
    final value = apiValue ?? label;
    final isSelected = selectedPaymentMethod == value || selectedPaymentMethod == label;

    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
          FFAppState().selectedPaymentMethod = value.toLowerCase();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.14)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? primaryColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentDisplayLabel(String method) {
    switch (method.toLowerCase()) {
      case 'online':
        return 'UPI';
      default:
        return method;
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'wallet':
        return 'Wallet';
      case 'online':
        return 'Online';
      case 'cash':
      default:
        return 'Cash';
    }
  }
}
