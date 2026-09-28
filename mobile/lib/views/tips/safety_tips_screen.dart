import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/iot_device_service.dart';
import '../../services/mesh_network_service.dart';
import '../widgets/iot_hardware_card.dart';
import '../widgets/mesh_devices_section.dart';

class SafetyTipsScreen extends StatelessWidget {
  final IotDeviceService iotService;
  final MeshNetworkService meshService;

  const SafetyTipsScreen({
    super.key,
    required this.iotService,
    required this.meshService,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Safety Advice & Preparedness",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Practical precautions for everyday transit & isolated locations",
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),

          _buildTipCard(
            icon: Icons.directions_car_rounded,
            title: "Cab & Ride Safety",
            description:
                "Always verify driver details and vehicle license plate before entering. Share live GPS location with your trusted circle right from the home screen.",
            tag: "TRANSIT",
          ),
          const SizedBox(height: 10),

          _buildTipCard(
            icon: Icons.nightlife_rounded,
            title: "Late Night Walking",
            description:
                "Keep your phone in your palm with your thumb near the SOS button or use the discreet ESP32 hardware band in your pocket for 1-click trigger.",
            tag: "SOLO WALK",
          ),
          const SizedBox(height: 10),

          _buildTipCard(
            icon: Icons.phone_android_rounded,
            title: "Using Fake Call",
            description:
                "If someone is following you or making you uncomfortable, tap 'Fake Call' on the home screen to simulate an urgent incoming phone call to excuse yourself.",
            tag: "DISCREET",
          ),
          const SizedBox(height: 10),

          _buildTipCard(
            icon: Icons.wifi_off_rounded,
            title: "Zero-Internet Offline Mesh",
            description:
                "In basements or remote rural zones with no 4G signal, RakshaNet automatically relays distress packets phone-to-phone via Wi-Fi Aware & BLE.",
            tag: "OFF-GRID",
          ),
          const SizedBox(height: 20),

          Text(
            "Hardware & Offline Radios",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),

          IotHardwareCard(
            iotService: iotService,
            onSilencePressed: () {
              iotService.silenceHardware();
            },
          ),
          const SizedBox(height: 14),

          MeshDevicesSection(
            devices: meshService.devices,
            onDeviceAction: (device) => meshService.inviteOrDisconnect(device),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.blushPink.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.lightBlush,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryBerry, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlush,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBerry,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
