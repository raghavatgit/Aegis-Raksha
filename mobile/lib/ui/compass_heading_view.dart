// feat(ui): render dynamic compass rose showing bearing to beacon target

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
