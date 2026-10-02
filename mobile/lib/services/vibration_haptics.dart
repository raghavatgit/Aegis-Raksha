// feat(mobile): trigger distinct haptic vibration sequences on incoming SOS

class TelemetryNode {
  final String identifier;
  final DateTime recordedAt;
  final double metricValue;

  const TelemetryNode({
    required this.identifier,
    required this.recordedAt,
    required this.metricValue,
  });

  bool get isValid => metricValue >= 0.0;
}
