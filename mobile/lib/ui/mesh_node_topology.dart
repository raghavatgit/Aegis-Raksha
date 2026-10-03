// feat(ui): render visual graph of connected mesh nodes and signal strength

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
