import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/geodesic_engine.dart';
import '../../data/models/emergency_alert.dart';

class ResponderAlertDialog extends StatefulWidget {
  final EmergencyAlert alert;
  final GeodesicResult? geodesicResult;
  final VoidCallback onDismiss;
  final Function(String responseText) onRespond;

  const ResponderAlertDialog({
    super.key,
    required this.alert,
    this.geodesicResult,
    required this.onDismiss,
    required this.onRespond,
  });

  static Future<void> show(
    BuildContext context, {
    required EmergencyAlert alert,
    GeodesicResult? geodesicResult,
    required VoidCallback onDismiss,
    required Function(String responseText) onRespond,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ResponderAlertDialog(
        alert: alert,
        geodesicResult: geodesicResult,
        onDismiss: onDismiss,
        onRespond: onRespond,
      ),
    );
  }

  @override
  State<ResponderAlertDialog> createState() => _ResponderAlertDialogState();
}

class _ResponderAlertDialogState extends State<ResponderAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final geo = widget.geodesicResult;

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final color = Color.lerp(const Color(0xFFB71C1C), const Color(0xFFE53935), _blinkController.value)!;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: color,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 52, color: Colors.white),
                const SizedBox(height: 6),
                Text(
                  "🚨 EMERGENCY ALERT!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                if (geo != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      geo.isGnssDenied
                          ? "📍 ZONE 1: RADIO PROXIMITY (INDOOR / GNSS-DENIED)"
                          : "📍 ZONE 1: ACTIVE RESPONDER RING (≤ 500M)",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFFEB3B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Victim: ${alert.senderId}",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF212121)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alert.severity,
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFC62828)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Threat: ${alert.alertType}",
                        style: GoogleFonts.poppins(color: const Color(0xFFD32F2F), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.description,
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF424242)),
                      ),
                      const Divider(height: 16),
                      // Real-time Radius & Geodesic Navigation Information
                      if (geo != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF1976D2)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Distance: ${geo.formattedDistance} (${geo.formattedBearing})",
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1976D2)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.directions_walk_rounded, size: 16, color: Color(0xFF388E3C)),
                            const SizedBox(width: 6),
                            Text(
                              "ETA: ~${geo.walkingEtaMinutes} min walk • ~${geo.runningEtaMinutes} min run",
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF388E3C)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        (alert.hasGpsLock && alert.location['lat'] != null && alert.location['lat'] != 0.0)
                            ? "GPS: ${alert.location['lat']?.toStringAsFixed(4)}, ${alert.location['lng']?.toStringAsFixed(4)} (Satellite Lock)"
                            : "GPS: Indoor / GNSS-Denied (Radio Proximity Lock)",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: alert.hasGpsLock ? FontWeight.normal : FontWeight.w600,
                          color: alert.hasGpsLock ? const Color(0xFF757575) : const Color(0xFFE65100),
                        ),
                      ),
                      Text(
                        "Time: ${alert.timestamp} | Hops: ${alert.ttlHops}",
                        style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF424242),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDismiss();
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text("DISMISS", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onRespond("I am responding to your emergency alert!");
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text("RESPOND", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
