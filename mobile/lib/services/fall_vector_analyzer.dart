import 'dart:math';

class FallVectorAnalyzer {
  static const double freeFallThreshold = 0.5; // g
  static const double impactThreshold = 2.8;   // g

  bool evaluateFall(List<List<double>> accelerometerWindow) {
    if (accelerometerWindow.isEmpty) return false;

    bool detectedFreeFall = false;
    bool detectedImpact = false;

    for (final sample in accelerometerWindow) {
      final double magnitude = sqrt(
        sample[0] * sample[0] +
        sample[1] * sample[1] +
        sample[2] * sample[2],
      );

      if (magnitude < freeFallThreshold) {
        detectedFreeFall = true;
      }
      if (detectedFreeFall && magnitude > impactThreshold) {
        detectedImpact = true;
      }
    }

    return detectedFreeFall && detectedImpact;
  }
}
