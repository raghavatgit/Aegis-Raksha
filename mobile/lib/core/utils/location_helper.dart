import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

class LocationHelper {
  /// Robust GNSS & indoor proximity coordinate acquisition
  static Future<Map<String, dynamic>> getCurrentCoordinates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'lat': 0.0, 'lng': 0.0, 'has_gps': false};
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return {'lat': 0.0, 'lng': 0.0, 'has_gps': false};
        }
      }

      // Fast-path: Check Android cached last-known position (<10ms)
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // Attempt fresh high-accuracy satellite fix with a quick 3-second limit
      try {
        Position freshPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 3),
          ),
        );
        return {
          'lat': freshPosition.latitude,
          'lng': freshPosition.longitude,
          'has_gps': true,
          'accuracy': freshPosition.accuracy,
        };
      } catch (_) {
        // High accuracy timed out (common indoors/basement).
        // Fallback 1: Use last known position if fresh enough
        if (lastKnown != null) {
          return {
            'lat': lastKnown.latitude,
            'lng': lastKnown.longitude,
            'has_gps': true,
            'accuracy': lastKnown.accuracy,
          };
        }

        // Fallback 2: Try medium accuracy (Wi-Fi / Cell tower triangulation)
        try {
          Position mediumPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 2),
            ),
          );
          return {
            'lat': mediumPosition.latitude,
            'lng': mediumPosition.longitude,
            'has_gps': true,
            'accuracy': mediumPosition.accuracy,
          };
        } catch (_) {
          // GNSS Denied / Deep indoor basement mode
          return {'lat': 0.0, 'lng': 0.0, 'has_gps': false, 'accuracy': -1.0};
        }
      }
    } catch (_) {
      return {'lat': 0.0, 'lng': 0.0, 'has_gps': false, 'accuracy': -1.0};
    }
  }

  static Future<(double, double)> getCurrentLocation() async {
    final coords = await getCurrentCoordinates();
    final lat = (coords['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (coords['lng'] as num?)?.toDouble() ?? 0.0;
    return (lat, lng);
  }

  static Future<bool> hasGpsFix() async {
    final coords = await getCurrentCoordinates();
    return coords['has_gps'] == true;
  }
}
