import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class MeshDevicesSection extends StatelessWidget {
  final List<Device> devices;
  final Function(Device device) onDeviceAction;
  final VoidCallback? onRefresh;

  const MeshDevicesSection({
    super.key,
    required this.devices,
    required this.onDeviceAction,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Nearby Mesh Phones (${devices.length})",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            Row(
              children: [
                if (onRefresh != null)
                  InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF616161)),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_tethering, color: Color(0xFF2E7D32), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "SCANNING",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2E7D32),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (devices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                const Icon(Icons.cell_tower, color: AppTheme.primaryBerry, size: 38),
                const SizedBox(height: 10),
                Text(
                  "Looking for nearby phones...",
                  style: GoogleFonts.poppins(
                    color: AppTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Other phones running Raksha-Net nearby connect automatically via Bluetooth and Wi-Fi Direct to form an offline emergency mesh.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF757575),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (onRefresh != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: Text(
                      "Scan Nearby Phones",
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBerry,
                      side: const BorderSide(color: Color(0xFFF8BBD0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final device = devices[index];

              String stateText = "Disconnected";
              Color btnColor = AppTheme.primaryBerry;
              String btnText = "Connect";

              if (device.state == SessionState.connected) {
                stateText = "Connected";
                btnColor = const Color(0xFFD32F2F);
                btnText = "Disconnect";
              } else if (device.state == SessionState.connecting) {
                stateText = "Connecting...";
                btnColor = const Color(0xFFF57F17);
                btnText = "Cancel";
              }

              final isConnected = device.state == SessionState.connected;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFFEEEEEE),
                    width: isConnected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? const Color(0xFFE8F5E9)
                            : AppTheme.lightBlush,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.phone_android_rounded,
                        color: isConnected ? const Color(0xFF2E7D32) : AppTheme.primaryBerry,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.deviceName,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$stateText • Mesh Node",
                            style: GoogleFonts.poppins(
                              color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFF757575),
                              fontSize: 11,
                              fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => onDeviceAction(device),
                      child: Text(
                        btnText,
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
