import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  // Phaltan rural cluster fallback coordinates
  static const double defaultLat = 17.9856;
  static const double defaultLng = 74.4331;

  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(milliseconds: 600), onTimeout: () => false);
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(milliseconds: 600), onTimeout: () => LocationPermission.denied);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(milliseconds: 600), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }
}
