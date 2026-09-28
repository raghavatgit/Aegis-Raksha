class EmergencyAlert {
  final String alertId;
  final String originDeviceId;
  final String alertType;
  final String severity;
  final Map<String, dynamic> location;
  final String description;
  final String timestamp;
  int ttlHops;
  bool isSynced;
  final bool hasGpsLock;

  String get senderId => originDeviceId;

  EmergencyAlert({
    required this.alertId,
    required String senderId,
    required this.alertType,
    required this.severity,
    required this.location,
    required this.description,
    required this.timestamp,
    this.ttlHops = 5,
    this.isSynced = false,
    bool? hasGpsLock,
  })  : originDeviceId = senderId,
        hasGpsLock = hasGpsLock ??
            (location['has_gps'] == true ||
                (location['lat'] != null &&
                    (location['lat'] as num).toDouble() != 0.0 &&
                    (location['lat'] as num).toDouble() != 28.7585));

  void decrementHop() {
    if (ttlHops > 0) {
      ttlHops--;
    }
  }

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    final originId = json['origin_device_id'] ?? json['sender_id'] ?? '';
    final locMap = json['location'] != null && json['location'] is Map
        ? Map<String, dynamic>.from(json['location'])
        : <String, dynamic>{};

    final lat = (locMap['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (locMap['lng'] as num?)?.toDouble() ?? 0.0;
    final hasGps = json['has_gps_lock'] == true ||
        locMap['has_gps'] == true ||
        (lat != 0.0 && lat != 28.7585);

    return EmergencyAlert(
      alertId: json['alert_id'] ?? '',
      senderId: originId,
      alertType: json['alert_type'] ?? '',
      severity: json['severity'] ?? '',
      location: {
        'lat': lat,
        'lng': lng,
        'has_gps': hasGps,
      },
      description: json['description'] ?? '',
      timestamp: json['timestamp'] ?? '',
      ttlHops: json['ttl_hops'] ?? 5,
      isSynced: json['is_synced'] ?? false,
      hasGpsLock: hasGps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': alertId,
      'origin_device_id': originDeviceId,
      'sender_id': originDeviceId,
      'alert_type': alertType,
      'severity': severity,
      'location': location,
      'description': description,
      'timestamp': timestamp,
      'ttl_hops': ttlHops,
      'is_synced': isSynced,
      'has_gps_lock': hasGpsLock,
    };
  }
}
