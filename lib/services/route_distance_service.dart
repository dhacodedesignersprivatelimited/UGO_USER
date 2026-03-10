import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

class RouteDistanceService {
  /// Fetches driving distance in Km using Google Directions API.
  Future<double?> getDrivingDistanceKm({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (originLat == 0 || originLng == 0 || destLat == 0 || destLng == 0) return null;

    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$originLat,$originLng'
          '&destination=$destLat,$destLng'
          '&key=${AppConfig.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && json['routes'] != null && (json['routes'] as List).isNotEmpty) {
          final route = json['routes'][0];
          final leg = route['legs'][0];
          final distanceMeters = leg['distance']['value'] ?? 0;
          return distanceMeters / 1000.0;
        }
      }
    } catch (e) {
      print('❌ RouteDistanceService Error: $e');
    }
    return null;
  }
}
