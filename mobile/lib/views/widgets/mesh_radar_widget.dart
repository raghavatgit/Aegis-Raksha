import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:google_fonts/google_fonts.dart';

class MeshRadarWidget extends StatefulWidget {
  final bool isParentNode;
  final List<Device> connectedDevices;
  final bool isIotConnected;
  final String localDeviceName;
  final VoidCallback onRefresh;

  const MeshRadarWidget({
    super.key,
    required this.isParentNode,
    required this.connectedDevices,
    required this.isIotConnected,
    required this.localDeviceName,
    required this.onRefresh,
  });

  @override
  State<MeshRadarWidget> createState() => _MeshRadarWidgetState();
}

class _MeshRadarWidgetState extends State<MeshRadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }


  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF1E88E5);
    final connectedPeers = widget.connectedDevices.where((d) => d.state == SessionState.connected).toList();
    final discoveringPeers = widget.connectedDevices.where((d) => d.state != SessionState.connected).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Sleek tactical dark theme for radar
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "TACTICAL MESH RADAR",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF94A3B8)),
                onPressed: widget.onRefresh,
                tooltip: "Re-scan Mesh",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // The Radar Canvas
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: _sweepController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RadarPainter(
                      sweepAngle: _sweepController.value * 2 * math.pi,
                      themeColor: themeColor,
                      isParent: widget.isParentNode,
                      connectedCount: connectedPeers.length,
                      discoveringCount: discoveringPeers.length,
                      isIotConnected: widget.isIotConnected,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Range Legends & Sector Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: const Color(0xFF22C55E),
                label: "Zone 1 (≤500m)",
                sub: "Active Ring",
              ),
              _buildLegendItem(
                color: const Color(0xFFEAB308),
                label: "Zone 2 (1.5km)",
                sub: "Silent Relay",
              ),
              _buildLegendItem(
                color: const Color(0xFF38BDF8),
                label: "${connectedPeers.length} Peers",
                sub: "Connected",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String sub,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE2E8F0),
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.poppins(
                fontSize: 8.5,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final Color themeColor;
  final bool isParent;
  final int connectedCount;
  final int discoveringCount;
  final bool isIotConnected;

  _RadarPainter({
    required this.sweepAngle,
    required this.themeColor,
    required this.isParent,
    required this.connectedCount,
    required this.discoveringCount,
    required this.isIotConnected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF030712)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, bgPaint);

    // Concentric Range Rings (Zone 1: 500m, Middle: 1000m, Zone 2: 1500m)
    final ringPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, maxRadius * 0.35, ringPaint); // 500m Zone 1 ring
    canvas.drawCircle(center, maxRadius * 0.70, ringPaint); // 1000m ring
    canvas.drawCircle(center, maxRadius * 0.98, ringPaint); // 1500m Zone 2 ceiling

    // Zone 1 Highlight Ring
    final zone1Highlight = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, maxRadius * 0.35, zone1Highlight);

    // Crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    // Cardinal Markers (N, S, E, W)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    void drawCardinal(String text, Offset pos) {
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2));
    }

    drawCardinal("N", Offset(center.dx, 10));
    drawCardinal("S", Offset(center.dx, size.height - 10));
    drawCardinal("E", Offset(size.width - 10, center.dy));
    drawCardinal("W", Offset(10, center.dy));

    // Radar Sweeping Beam (Cone Gradient)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          themeColor.withValues(alpha: 0.4),
          themeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle - math.pi / 2);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: maxRadius),
      0,
      math.pi / 2,
      true,
      sweepPaint,
    );

    // Sweep Leading Edge Line
    final edgePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset.zero,
      Offset(maxRadius * math.cos(math.pi / 2), maxRadius * math.sin(math.pi / 2)),
      edgePaint,
    );
    canvas.restore();

    // Center Node (This device)
    final centerNodePaint = Paint()
      ..color = isParent ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerNodePaint);

    final centerGlowPaint = Paint()
      ..color = (isParent ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 9, centerGlowPaint);

    // Wearable Device Blip (if connected, situated close to center in Zone 1)
    if (isIotConnected) {
      final iotPos = Offset(center.dx + 22, center.dy - 18);
      final iotPaint = Paint()
        ..color = const Color(0xFF22C55E)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(iotPos, 4.5, iotPaint);

      final iotGlow = Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(iotPos, 7.5, iotGlow);
    }

    // Connected Mesh Peers Blips (Zone 1 ≤ 500m)
    for (int i = 0; i < connectedCount; i++) {
      final angle = (i * (2 * math.pi / (connectedCount == 0 ? 1 : connectedCount))) + 0.8;
      final dist = maxRadius * 0.28; // within Zone 1
      final peerPos = Offset(center.dx + dist * math.cos(angle), center.dy + dist * math.sin(angle));

      final peerPaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peerPos, 5, peerPaint);

      final peerGlow = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(peerPos, 8, peerGlow);
    }

    // Discovering Peers Blips (in Zone 2)
    for (int i = 0; i < discoveringCount; i++) {
      final angle = (i * 1.5) + 2.2;
      final dist = maxRadius * 0.55;
      final discPos = Offset(center.dx + dist * math.cos(angle), center.dy + dist * math.sin(angle));

      final discPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(discPos, 4, discPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.connectedCount != connectedCount ||
        oldDelegate.isIotConnected != isIotConnected ||
        oldDelegate.isParent != isParent;
  }
}
