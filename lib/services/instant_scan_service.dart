import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_state.dart';
import '../core/app_config.dart';

class InstantScanService {
  static final InstantScanService _instance = InstantScanService._internal();
  factory InstantScanService() => _instance;
  InstantScanService._internal();

  /// Hooks into the raw QR string processed by scanner UI
  Future<bool> processInstantScan(String scannedVehicleId) async {
    final state = FFAppState();

    // Prevent overriding if already in a ride
    if (state.bookingInProgress) return false;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseApiUrl}/api/rides/scan-book-instant'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${state.accessToken}',
        },
        body: jsonEncode({
          'user_id': state.userid,
          'vehicle_id': int.tryParse(scannedVehicleId) ?? 0,
          'pickup_lat': state.pickupLatitude ?? 0.0,
          'pickup_lng': state.pickupLongitude ?? 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 1. Immediately mutate global Ride State Machine
        state.currentRideId = data['data']['id'];
        state.bookingInProgress = true;

        // 2. We can now safely let the UI redirect or auto-start tracking
        // through the existing Socket Service logic.
        return true;
      }
      return false;
    } catch (e) {
      print('Instant Scan Service Error: $e');
      return false;
    }
  }
}
