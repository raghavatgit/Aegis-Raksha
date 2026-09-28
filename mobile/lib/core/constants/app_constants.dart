class AppConstants {
  // Application Info
  static const String appTitle = 'Raksha Emergency Mesh';
  static const String defaultSenderId = 'Android_Node';

  // Hive Box Names
  static const String boxAlerts = 'alerts';
  static const String boxRelayLog = 'relay_log';
  static const String boxChatMessages = 'chat_messages';
  static const String boxSyncLog = 'firebase_sync_log';

  // Default GPS Coordinates (Fall-back)
  static const double defaultLat = 28.7585;
  static const double defaultLng = 77.1093;

  // Emergency Alert Types
  static const String typeMedical = 'ACCIDENT_MEDICAL';
  static const String typeSecurity = 'SECURITY_THREAT';
  static const String typeFire = 'FIRE_HAZARD';

  // Emergency Severity Levels
  static const String severityCritical = 'RED_CRITICAL';
  static const String severityHigh = 'YELLOW_HIGH';
  static const String severityModerate = 'GREEN_MODERATE';

  // BLE Specifications for IoT Wearable
  static const String bleDeviceName = 'Raksha-IoT-SOS';
  static const String bleServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String bleAlertCharUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const String bleCommandCharUuid = 'beb5483f-36e1-4688-b7f5-ea07361b26a8';

  // Mesh Specifications
  static const int defaultTtlHops = 5;
  static const String meshServiceType = 'mp-connection';

  // Geofence & Triage Distance Thresholds (Meters)
  static const double localResponderThresholdMeters = 500.0; // Zone 1: Inner 500m active responder ring
  static const double maxSiphonGeofenceCeilingMeters = 1500.0; // Zone 2: 1.5 km maximum boundary for silent siphon
  static const double earthRadiusMeters = 6371000.0; // WGS-84 Mean Earth Radius
}
