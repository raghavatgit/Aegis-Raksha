import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HybridRelayCard extends StatelessWidget {
  final bool isParentNode;
  final int connectedCount;
  final String localDeviceName;
  final bool isOutboundSosActive;
  final bool isIotConnected;
  final VoidCallback? onToggleRole;

  const HybridRelayCard({
    super.key,
    required this.isParentNode,
    required this.connectedCount,
    required this.localDeviceName,
    required this.isOutboundSosActive,
    required this.isIotConnected,
    this.onToggleRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isParentNode ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isParentNode ? Icons.shield_rounded : Icons.cell_tower,
                    size: 18,
                    color: isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Hybrid Geodesic Mesh Engine",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onToggleRole,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isParentNode ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isParentNode ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isParentNode ? "👑 PARENT NODE" : "🛡️ GUARDIAN MESH",
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.swap_horiz,
                        size: 11,
                        color: isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Role Explanation Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isParentNode ? const Color(0xFFFFF8E1) : const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isParentNode ? Icons.info_outline : Icons.wifi_protected_setup,
                  size: 14,
                  color: isParentNode ? const Color(0xFFF57F17) : const Color(0xFF33691E),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isParentNode
                        ? "Parent Node: Wearable linked. Self-alert suppressed; SOS relays outward."
                        : "Guardian Node: Standing by for bystander rescue within 500m.",
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isParentNode ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3-Tier Geofence Radius Visualization
          Text(
            "AUTOMATED RADIUS RELAY MODES",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              // Zone 1
              Expanded(
                child: _buildZonePill(
                  title: "Zone 1 (≤500m)",
                  subtitle: "Active Ring",
                  detail: "Siren + 1-Tap SOS",
                  color: const Color(0xFFE8F5E9),
                  borderColor: const Color(0xFF4CAF50),
                  textColor: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(width: 6),

              // Zone 2
              Expanded(
                child: _buildZonePill(
                  title: "Zone 2 (500-1.5km)",
                  subtitle: "Silent Siphon",
                  detail: "Quiet Cloud Hunt",
                  color: const Color(0xFFFFFDE7),
                  borderColor: const Color(0xFFFBC02D),
                  textColor: const Color(0xFFF57F17),
                ),
              ),
              const SizedBox(width: 6),

              // Zone 3
              Expanded(
                child: _buildZonePill(
                  title: "Zone 3 (>1.5km)",
                  subtitle: "Range Drop",
                  detail: "Ceiling Isolation",
                  color: const Color(0xFFF5F5F5),
                  borderColor: const Color(0xFFBDBDBD),
                  textColor: const Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Protocol Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mesh Protocol: Wi-Fi Direct (P2P_STAR)",
                style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFF94A3B8)),
              ),
              Text(
                "ID: $localDeviceName",
                style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZonePill({
    required String title,
    required String subtitle,
    required String detail,
    required Color color,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w600, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: GoogleFonts.poppins(fontSize: 7.5, color: textColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
