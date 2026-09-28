import 'dart:math' as math;
import '../constants/app_constants.dart';

enum GeofenceZone {
  localResponder,  // <= 500m: Audible Siren + Visual Modal + Interactive [RESPOND] / [DISMISS]
  silentSiphon,    // 500m - 1500m: Silent Background Relay + Internet Gateway Hunting
  outOfBounds,     // > 1500m: Hard Ceiling Boundary (Packet dropped to prevent infinite storms)
}

class GeodesicResult {
  final double distanceMeters;
  final double bearingDegrees;
  final String cardinalDirection;
  final GeofenceZone zone;
  final int walkingEtaMinutes;
  final int runningEtaMinutes;
  final bool isGnssDenied;

  GeodesicResult({
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.cardinalDirection,
    required this.zone,
    required this.walkingEtaMinutes,
    required this.runningEtaMinutes,
    this.isGnssDenied = false,
  });

  String get formattedDistance {
    if (isGnssDenied) {
      return "~${distanceMeters.toStringAsFixed(0)}m (Direct Radio Proximity)";
    }
    if (distanceMeters < 1000) {
      return "${distanceMeters.toStringAsFixed(0)} m";
    }
    return "${(distanceMeters / 1000).toStringAsFixed(2)} km";
  }

  String get formattedBearing {
    if (isGnssDenied) {
      return "Immediate Vicinity";
    }
    return "${bearingDegrees.toStringAsFixed(0)}° $cardinalDirection";
  }

  String get zoneLabel {
    if (isGnssDenied) {
      return "ZONE 1: LOCAL RADIO PROXIMITY (INDOOR / GNSS-DENIED)";
    }
    switch (zone) {
      case GeofenceZone.localResponder:
        return "LOCAL 500M INNER RING";
      case GeofenceZone.silentSiphon:
        return "SILENT SIPHON (GATEWAY HUNT)";
      case GeofenceZone.outOfBounds:
        return "OUT OF BOUNDS (> 1.5 KM)";
    }
  }

  bool get shouldTriggerAudibleSiren => zone == GeofenceZone.localResponder;
  bool get shouldRelayPacket => zone != GeofenceZone.outOfBounds;
}

/// High-Precision Geodesic & Navigation Engine for Emergency Mesh Triage
class GeodesicEngine {
  static const double earthRadiusMeters = 6371000.0; // WGS-84 Mean Earth Radius in meters

  /// Computes Great-Circle Distance using the Haversine Formula
  static double haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final phi1 = _degreesToRadians(lat1);
    final phi2 = _degreesToRadians(lat2);
    final deltaPhi = _degreesToRadians(lat2 - lat1);
    final deltaLambda = _degreesToRadians(lon2 - lon1);

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
        math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Computes Initial Forward Azimuth (True Bearing) from point 1 to point 2
  static double forwardAzimuth({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final phi1 = _degreesToRadians(lat1);
    final phi2 = _degreesToRadians(lat2);
    final deltaLambda = _degreesToRadians(lon2 - lon1);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final theta = math.atan2(y, x);
    final bearingDegrees = (_radiansToDegrees(theta) + 360.0) % 360.0;
    return bearingDegrees;
  }

  /// Converts bearing angle (0°-360°) into 16-point Compass Cardinal Direction
  static String bearingToCardinal(double bearingDegrees) {
    const directions = [
      "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"
    ];
    final index = (((bearingDegrees + 11.25) % 360) / 22.5).floor();
    return directions[index % 16];
  }

  /// Classifies a target distance into the 3-Tier Adaptive Geofence
  static GeofenceZone classifyGeofenceZone(double distanceMeters) {
    if (distanceMeters <= AppConstants.localResponderThresholdMeters) {
      return GeofenceZone.localResponder;
    } else if (distanceMeters <= AppConstants.maxSiphonGeofenceCeilingMeters) {
      return GeofenceZone.silentSiphon;
    } else {
      return GeofenceZone.outOfBounds;
    }
  }

  /// Complete Geodesic Evaluation between Responder and Victim
  static GeodesicResult computeNavigationTriage({
    required double responderLat,
    required double responderLng,
    required double victimLat,
    required double victimLng,
    bool victimHasGps = true,
    bool responderHasGps = true,
    int hopCount = 1,
    bool isDirectRadio = false,
  }) {
    final bool missingGps = !victimHasGps ||
        !responderHasGps ||
        (victimLat == 0.0 && victimLng == 0.0) ||
        (responderLat == 0.0 && responderLng == 0.0);

    // If either device lacks satellite lock (indoor, basement, jammer),
    // fallback to Direct RF Radio Proximity:
    if (missingGps) {
      final radioDist = (hopCount * 30.0).clamp(15.0, 120.0);
      return GeodesicResult(
        distanceMeters: radioDist,
        bearingDegrees: 0.0,
        cardinalDirection: "Nearby",
        zone: GeofenceZone.localResponder, // Always Zone 1!
        walkingEtaMinutes: 1,
        runningEtaMinutes: 1,
        isGnssDenied: true,
      );
    }

    final distance = haversineDistance(
      lat1: responderLat,
      lon1: responderLng,
      lat2: victimLat,
      lon2: victimLng,
    );

    // Direct RF Link Safety Override:
    // If packet was received directly via 1-hop Wi-Fi Direct or BLE radio,
    // the physical distance is <= 100m. If GPS calculates > 1500m due to stale cached
    // coordinates from another location, override and force Zone 1 to prevent false negative drops!
    if (isDirectRadio && distance > AppConstants.maxSiphonGeofenceCeilingMeters) {
      return GeodesicResult(
        distanceMeters: 40.0,
        bearingDegrees: 0.0,
        cardinalDirection: "Direct Link",
        zone: GeofenceZone.localResponder,
        walkingEtaMinutes: 1,
        runningEtaMinutes: 1,
        isGnssDenied: true,
      );
    }

    final bearing = forwardAzimuth(
      lat1: responderLat,
      lon1: responderLng,
      lat2: victimLat,
      lon2: victimLng,
    );

    final cardinal = bearingToCardinal(bearing);
    final zone = classifyGeofenceZone(distance);

    final walkingEta = (distance / (1.35 * 60)).ceil();
    final runningEta = (distance / (3.5 * 60)).ceil();

    return GeodesicResult(
      distanceMeters: distance,
      bearingDegrees: bearing,
      cardinalDirection: cardinal,
      zone: zone,
      walkingEtaMinutes: walkingEta < 1 ? 1 : walkingEta,
      runningEtaMinutes: runningEta < 1 ? 1 : runningEta,
      isGnssDenied: false,
    );
  }

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);
  static double _radiansToDegrees(double radians) => radians * (180.0 / math.pi);
}
