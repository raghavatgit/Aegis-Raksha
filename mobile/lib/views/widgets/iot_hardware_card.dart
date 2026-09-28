import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/iot_device_service.dart';
import '../dialogs/iot_logs_dialog.dart';
import '../dialogs/ble_scanner_dialog.dart';

class IotHardwareCard extends StatelessWidget {
  final IotDeviceService iotService;
  final VoidCallback onSilencePressed;
  final VoidCallback? onOpenHub;

  const IotHardwareCard({
    super.key,
    required this.iotService,
    required this.onSilencePressed,
    this.onOpenHub,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = iotService.isConnected;
    final isScanning = iotService.isScanning;
    final isAlert = iotService.isAlertActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFD32F2F)
              : (isConnected ? const Color(0xFF2E7D32) : const Color(0xFFEEEEEE)),
          width: isConnected || isAlert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0xFFE8F5E9) : AppTheme.lightBlush,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.watch_outlined,
                        color: isConnected ? const Color(0xFF2E7D32) : AppTheme.primaryBerry,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Raksha IoT Wearable",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            isConnected ? iotService.deviceName : "ESP32 SOS Band / Pendant",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF757575),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => BleScannerDialog.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAlert
                        ? const Color(0xFFFFEBEE)
                        : (isConnected
                            ? const Color(0xFFE8F5E9)
                            : (isScanning ? const Color(0xFFE3F2FD) : const Color(0xFFF5F5F5))),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAlert
                          ? const Color(0xFFD32F2F)
                          : (isConnected
                              ? const Color(0xFF2E7D32)
                              : (isScanning ? const Color(0xFF1976D2) : const Color(0xFFBDBDBD))),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isScanning) ...[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1976D2)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        isAlert
                            ? "🚨 ALERT ACTIVE"
                            : (isConnected
                                ? "CONNECTED"
                                : (isScanning ? "SCANNING..." : "DISCONNECTED")),
                        style: GoogleFonts.poppins(
                          color: isAlert
                              ? const Color(0xFFD32F2F)
                              : (isConnected
                                  ? const Color(0xFF2E7D32)
                                  : (isScanning ? const Color(0xFF1976D2) : const Color(0xFF616161))),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Battery & Telemetry Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.battery_charging_full, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Text(
                  isConnected ? "${iotService.batteryPercent}% Battery" : "Battery: --",
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => IotLogsDialog.show(context),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 14, color: AppTheme.primaryBerry),
                      const SizedBox(width: 4),
                      Text(
                        "Logs",
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryBerry),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sensor Status Grid
          Row(
            children: [
              Expanded(
                child: _buildSensorChip(
                  icon: Icons.radio_button_checked,
                  title: "Hardware SOS Button",
                  status: isConnected ? "Armed (Ready)" : "Offline",
                  isActive: isConnected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSensorChip(
                  icon: Icons.mic_none_outlined,
                  title: "Acoustic Scream Sensor",
                  status: isConnected ? "Listening" : "Offline",
                  isActive: isConnected,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Control Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? const Color(0xFF757575) : AppTheme.primaryBerry,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    if (isConnected) {
                      iotService.disconnectDevice();
                    } else {
                      BleScannerDialog.show(context);
                    }
                  },
                  icon: Icon(isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching, size: 16),
                  label: Text(
                    isConnected ? "Disconnect" : "Scan & Pair Band",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              if (isConnected) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isAlert ? const Color(0xFFD32F2F) : AppTheme.primaryBerry,
                      side: BorderSide(color: isAlert ? const Color(0xFFD32F2F) : AppTheme.primaryBerry),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      if (isAlert) {
                        onSilencePressed();
                      } else {
                        iotService.sendCustomCommand("SIREN_ON");
                      }
                    },
                    icon: Icon(isAlert ? Icons.volume_off : Icons.volume_up, size: 16),
                    label: Text(
                      isAlert ? "Silence Siren" : "Test Siren",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (onOpenHub != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onOpenHub,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Open Full IoT Hardware Center & Pinouts",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBerry,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryBerry),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensorChip({
    required IconData icon,
    required String title,
    required String status,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isActive ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isActive ? const Color(0xFF2E7D32) : const Color(0xFF757575),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
