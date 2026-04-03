import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/app_config.dart';
import '/index.dart';

/// Scan to Book Service
/// Handles scan-book API, socket subscription, qr_validated, ride_started, confirm.
class ScanBookingService {
  static final ScanBookingService _instance = ScanBookingService._internal();
  factory ScanBookingService() => _instance;
  ScanBookingService._internal();

  IO.Socket? _socket;

  // Stream controllers for UI
  final _qrValidatedController = StreamController<QrValidatedData>.broadcast();
  final _rideStartedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _locationUpdateController =
      StreamController<LocationUpdateData>.broadcast();
  final _rideCompletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<QrValidatedData> get onQrValidated => _qrValidatedController.stream;
  Stream<Map<String, dynamic>> get onRideStarted =>
      _rideStartedController.stream;
  Stream<LocationUpdateData> get onLocationUpdate =>
      _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get onRideCompleted =>
      _rideCompletedController.stream;
  Stream<String> get onError => _errorController.stream;

  String get _baseUrl => AppConfig.baseApiUrl;

  /// Uses POST /api/rides/post (same as normal booking) with driver_id + admin_vehicle_id from QR
  Future<ScanBookResult> scanBookRide({
    required int driverId,
    required int adminVehicleId,
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    required String pickupAddress,
    required String dropAddress,
    String? paymentMethod, // Ignored – scan booking always cash
    required String estimatedFare,
    String? guestName,
    String? guestPhone,
    String? guestInstructions,
  }) async {
    final token = FFAppState().accessToken;
    final userId = FFAppState().userid;
    if (token.isEmpty) {
      return ScanBookResult(error: 'Please log in');
    }

    try {
      final response = await ScanBookRideCall.call(
        driverId: driverId,
        adminVehicleId: adminVehicleId,
        userId: int.parse(userId as String),
        pickupLatitude: pickupLat,
        pickupLongitude: pickupLng,
        dropLatitude: dropLat,
        dropLongitude: dropLng,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        paymentMethod: paymentMethod ?? 'cash',
        estimatedFare: estimatedFare,
        token: token,
        guestName: guestName,
        guestPhone: guestPhone,
        guestInstructions: guestInstructions,
      );

      if (!response.succeeded) {
        final msg =
            getJsonField(response.jsonBody, r'$.message') ?? 'Scan failed';
        return ScanBookResult(error: msg.toString());
      }

      final rideId = ScanBookRideCall.rideId(response.jsonBody) ??
          ScanBookRideCall.rideIdAlt(response.jsonBody);
      final data = response.jsonBody is Map
          ? response.jsonBody as Map<String, dynamic>
          : <String, dynamic>{};
      final dataField = data['data'];
      final rideIdFromData = dataField is Map
          ? (dataField['rideId'] ?? dataField['id'] ?? dataField['ride_id'])
              as int?
          : null;

      int? id = rideId;
      if (id == null && rideIdFromData != null) {
        id = int.tryParse(rideIdFromData.toString());
      }
      if (id == null) {
        return ScanBookResult(error: 'Invalid response: no ride ID');
      }

      _subscribeToRide(id, token);
      return ScanBookResult(rideId: id);
    } catch (e) {
      return ScanBookResult(error: e.toString());
    }
  }

  void _subscribeToRide(int rideId, String token) {
    _unsubscribe();

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth({'token': token})
          .setReconnectionAttempts(3)
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('watch_entity', {'type': 'ride', 'id': rideId});
    });

    _socket!.onConnectError(
        (data) => _errorController.add('Connection error: $data'));
    _socket!.onError((data) => _errorController.add('Socket error: $data'));

    _socket!.on('qr_validated', (data) {
      if (data is Map) {
        try {
          final payload = Map<String, dynamic>.from(data);
          _qrValidatedController.add(QrValidatedData.fromMap(payload));
        } catch (_) {}
      }
    });

    _socket!.on('ride_started', (data) {
      if (data is Map) {
        // Bypassing Search screen UI entirely and syncing session payload
        FFAppState().bookingInProgress = true;
        _rideStartedController.add(Map<String, dynamic>.from(data));
      }
    });

    void handleLiveDriverMap(Map<String, dynamic> m) {
      final latVal = m['lat'] ?? m['latitude'];
      final lngVal = m['lng'] ?? m['longitude'];
      final lat = latVal != null
          ? (latVal is num
              ? latVal.toDouble()
              : double.tryParse(latVal.toString()))
          : null;
      final lng = lngVal != null
          ? (lngVal is num
              ? lngVal.toDouble()
              : double.tryParse(lngVal.toString()))
          : null;

      final status = m['ride_status']?.toString().toUpperCase();

      if (lat != null && lng != null) {
        _locationUpdateController.add(
            LocationUpdateData(lat: lat, lng: lng, eta: m['eta']?.toString()));
      }

      final state = FFAppState();
      if (status == 'COMPLETED') {
        state.bookingInProgress = false;
        _rideCompletedController.add(m);
      } else if (status == 'CANCELLED') {
        state.bookingInProgress = false;
        _errorController.add("Ride Cancelled by Driver.");
      }
    }

    _socket!.on('location_update', (data) {
      if (data is Map) {
        handleLiveDriverMap(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('driver_location_update', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      final driver = m['driver'];
      if (driver is Map) {
        handleLiveDriverMap(Map<String, dynamic>.from(driver));
      } else {
        handleLiveDriverMap(m);
      }
    });

    _socket!.on('ride_completed', (data) {
      if (data is Map) {
        _rideCompletedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('ride_updated', (data) {
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        final status =
            (m['ride_status'] ?? m['status'])?.toString().toLowerCase();
        if (status == 'started' ||
            status == 'in_progress' ||
            status == 'picked_up') {
          _rideStartedController.add(m);
        } else if (status == 'completed' || status == 'complete') {
          _rideCompletedController.add(m);
        }
      }
    });

    _socket!.connect();
  }

  /// Emit confirm_scan_start via socket (fallback if API fails)
  void emitConfirmScanStart(int rideId) {
    _socket?.emit('confirm_scan_start', {'rideId': rideId});
  }

  /// Confirm scan start via API (primary)
  Future<bool> confirmScanStart(int rideId) async {
    final token = FFAppState().accessToken;
    if (token.isEmpty) return false;

    try {
      final response =
          await ConfirmScanStartCall.call(rideId: rideId, token: token);
      return response.succeeded;
    } catch (_) {
      return false;
    }
  }

  void _unsubscribe() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _unsubscribe();
    _qrValidatedController.close();
    _rideStartedController.close();
    _locationUpdateController.close();
    _rideCompletedController.close();
    _errorController.close();
  }
}

class ScanBookResult {
  final int? rideId;
  final String? error;
  ScanBookResult({this.rideId, this.error});
  bool get isSuccess => rideId != null && error == null;
}

class QrValidatedData {
  final int rideId;
  final String driverName;
  final String? driverPhoto;
  final String vehicleNo;
  final double rating;
  final double fareEstimate;

  QrValidatedData({
    required this.rideId,
    required this.driverName,
    this.driverPhoto,
    required this.vehicleNo,
    this.rating = 4.5,
    this.fareEstimate = 0,
  });

  factory QrValidatedData.fromMap(Map<String, dynamic> m) {
    final driver = m['driver'] is Map
        ? m['driver'] as Map<String, dynamic>
        : <String, dynamic>{};
    final rideIdVal = m['rideId'] ?? m['ride_id'] ?? driver['ride_id'] ?? 0;
    final ratingVal = driver['rating'] ?? 4.5;
    final fareVal = m['fare_estimate'] ?? m['fare'] ?? 0;
    return QrValidatedData(
      rideId: rideIdVal is int
          ? rideIdVal
          : (int.tryParse(rideIdVal.toString()) ?? 0),
      driverName:
          (driver['name'] ?? driver['first_name'] ?? 'Driver').toString(),
      driverPhoto:
          driver['photo'] ?? driver['profile_image'] ?? driver['image'],
      vehicleNo: (driver['vehicle_no'] ?? driver['vehicle_number'] ?? 'N/A')
          .toString(),
      rating: ratingVal is num ? ratingVal.toDouble() : 4.5,
      fareEstimate: fareVal is num ? fareVal.toDouble() : 0,
    );
  }
}

class LocationUpdateData {
  final double lat;
  final double lng;
  final String? eta;
  LocationUpdateData({required this.lat, required this.lng, this.eta});
}
