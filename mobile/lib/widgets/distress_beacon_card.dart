class DistressBeaconCard {
  final int senderId;
  final double latitude;
  final double longitude;
  final int batteryLevel;

  DistressBeaconCard({
    required this.senderId,
    required this.latitude,
    required this.longitude,
    required this.batteryLevel,
  });

  String formatCoordinates() {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }
}
