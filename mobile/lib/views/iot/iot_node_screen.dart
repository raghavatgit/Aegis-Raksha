import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/iot_device_service.dart';
import '../dialogs/ble_scanner_dialog.dart';
import '../dialogs/iot_logs_dialog.dart';

class IotNodeScreen extends StatefulWidget {
  final IotDeviceService iotService;
  final VoidCallback onHardwareSosTriggered;

  const IotNodeScreen({
    super.key,
    required this.iotService,
    required this.onHardwareSosTriggered,
  });

  @override
  State<IotNodeScreen> createState() => _IotNodeScreenState();
}

class _IotNodeScreenState extends State<IotNodeScreen> {
  @override
  void initState() {
    super.initState();
    widget.iotService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    widget.iotService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.iotService.isConnected;
    final isScanning = widget.iotService.isScanning;
    final isAlert = widget.iotService.isAlertActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Raksha IoT Hardware",
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryBerry),
            tooltip: "Hardware Terminal Logs",
            onPressed: () => IotLogsDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBerry),
            tooltip: "Scan BLE",
            onPressed: () => widget.iotService.scanForBleDevices(autoConnect: false),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Connection & Telemetry Hero Card
          _buildHeroCard(isConnected, isScanning, isAlert),
          const SizedBox(height: 16),

          // 2. Hardware Sensors & Pinout Status
          _buildSensorStatusSection(isConnected, isAlert),
          const SizedBox(height: 16),

          // 3. Hardware Test & Simulation Lab
          _buildHardwareTestLab(isConnected, isAlert),
          const SizedBox(height: 16),

          // 4. ESP32 Pinout & Wiring Schematic
          _buildSchematicCard(),
          const SizedBox(height: 16),

          // 5. Live Telemetry Console Stream
          _buildTelemetryConsole(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isConnected, bool isScanning, bool isAlert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFD32F2F)
              : (isConnected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0)),
          width: isConnected || isAlert ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAlert ? Colors.red : Colors.black).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Device icon + Name + Status pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAlert
                      ? const Color(0xFFFFEBEE)
                      : (isConnected ? const Color(0xFFE8F5E9) : AppTheme.lightBlush),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.watch_outlined,
                  color: isAlert
                      ? const Color(0xFFD32F2F)
                      : (isConnected ? const Color(0xFF2E7D32) : AppTheme.primaryBerry),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? widget.iotService.deviceName : "Raksha ESP32 Node",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? "BLE Linked • Dual Radio Standby"
                          : "Bluetooth Low Energy SOS Wearable",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAlert
                      ? const Color(0xFFFFCDD2)
                      : (isConnected
                          ? const Color(0xFFE8F5E9)
                          : (isScanning ? const Color(0xFFE3F2FD) : const Color(0xFFEEEEEE))),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAlert
                            ? const Color(0xFFD32F2F)
                            : (isConnected
                                ? const Color(0xFF2E7D32)
                                : (isScanning ? const Color(0xFF1976D2) : const Color(0xFF9E9E9E))),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAlert
                          ? "EMERGENCY"
                          : (isConnected
                              ? "ONLINE"
                              : (isScanning ? "SCANNING" : "OFFLINE")),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAlert
                            ? const Color(0xFFB71C1C)
                            : (isConnected
                                ? const Color(0xFF2E7D32)
                                : (isScanning ? const Color(0xFF1976D2) : const Color(0xFF616161))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Row 2: Battery & Connection Metrics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  icon: Icons.battery_charging_full_rounded,
                  label: "Battery",
                  value: isConnected ? "${widget.iotService.batteryPercent}%" : "Standby",
                  color: const Color(0xFF2E7D32),
                ),
                Container(height: 28, width: 1, color: const Color(0xFFE0E0E0)),
                _buildMetricItem(
                  icon: Icons.bluetooth_audio_rounded,
                  label: "Protocol",
                  value: "BLE 5.0 GATT",
                  color: const Color(0xFF1976D2),
                ),
                Container(height: 28, width: 1, color: const Color(0xFFE0E0E0)),
                _buildMetricItem(
                  icon: Icons.shield_outlined,
                  label: "State",
                  value: isAlert ? "ALARM ACTIVE" : "Armed & Safe",
                  color: isAlert ? const Color(0xFFD32F2F) : AppTheme.primaryBerry,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Row 3: Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? const Color(0xFF616161) : AppTheme.primaryBerry,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (isConnected) {
                      widget.iotService.disconnectDevice();
                    } else {
                      BleScannerDialog.show(context);
                    }
                  },
                  icon: Icon(
                    isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching,
                    size: 18,
                  ),
                  label: Text(
                    isConnected ? "Disconnect Node" : "Scan & Pair ESP32",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              if (isConnected) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isAlert ? const Color(0xFFD32F2F) : AppTheme.primaryBerry,
                      side: BorderSide(
                        color: isAlert ? const Color(0xFFD32F2F) : AppTheme.primaryBerry,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      if (isAlert) {
                        widget.iotService.silenceHardware();
                      } else {
                        widget.iotService.sendCustomCommand("SIREN_ON");
                      }
                    },
                    icon: Icon(isAlert ? Icons.volume_off : Icons.volume_up, size: 18),
                    label: Text(
                      isAlert ? "Silence Siren" : "Test Siren",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF757575)),
        ),
      ],
    );
  }

  Widget _buildSensorStatusSection(bool isConnected, bool isAlert) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, color: AppTheme.primaryBerry, size: 20),
              const SizedBox(width: 8),
              Text(
                "Live Hardware Sensors Status",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSensorRow(
            icon: Icons.radio_button_checked,
            name: "Hardware SOS Button (GPIO 4)",
            status: isAlert ? "TRIGGERED (Active Low)" : (isConnected ? "Armed & Ready" : "Standby (Simulatable)"),
            isActive: isAlert || isConnected,
            isEmergency: isAlert,
          ),
          const Divider(height: 18),
          _buildSensorRow(
            icon: Icons.mic_none_outlined,
            name: "Acoustic Scream Sensor (GPIO 18)",
            status: isConnected ? "Listening (Threshold: 80dB)" : "Standby (Simulatable)",
            isActive: isConnected,
            isEmergency: false,
          ),
          const Divider(height: 18),
          _buildSensorRow(
            icon: Icons.volume_up_outlined,
            name: "Deterrent Siren Buzzer (GPIO 19)",
            status: isAlert ? "SOUNDING (85dB Pulsed Alarm)" : "Idle / Standby",
            isActive: isAlert,
            isEmergency: isAlert,
          ),
          const Divider(height: 18),
          _buildSensorRow(
            icon: Icons.lightbulb_outline_rounded,
            name: "Emergency Strobe LED (GPIO 23)",
            status: isAlert ? "RAPID STROBE ACTIVE" : "Armed",
            isActive: isAlert,
            isEmergency: isAlert,
          ),
          const Divider(height: 18),
          _buildSensorRow(
            icon: Icons.tv_rounded,
            name: "OLED Display 128x64 (I2C 0x3C)",
            status: isConnected ? "Showing Live Distress / Safe UI" : "Ready",
            isActive: isConnected,
            isEmergency: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow({
    required IconData icon,
    required String name,
    required String status,
    required bool isActive,
    required bool isEmergency,
  }) {
    final color = isEmergency
        ? const Color(0xFFD32F2F)
        : (isActive ? const Color(0xFF2E7D32) : const Color(0xFF757575));

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isEmergency ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareTestLab(bool isConnected, bool isAlert) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: AppTheme.primaryBerry, size: 20),
              const SizedBox(width: 8),
              Text(
                "Hardware Testing & Simulation Toolkit",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Test ESP32 firmware features even without physical hardware in hand:",
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    widget.iotService.simulateHardwareTrigger(IotTriggerSource.button);
                    widget.onHardwareSosTriggered();
                  },
                  icon: const Icon(Icons.touch_app, size: 16),
                  label: Text(
                    "Simulate Button SOS",
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF880E4F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    widget.iotService.simulateHardwareTrigger(IotTriggerSource.scream);
                    widget.onHardwareSosTriggered();
                  },
                  icon: const Icon(Icons.mic, size: 16),
                  label: Text(
                    "Simulate Scream Trigger",
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    side: const BorderSide(color: Color(0xFF1976D2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    widget.iotService.sendCustomCommand("SIREN_ON");
                  },
                  icon: const Icon(Icons.volume_up, size: 16),
                  label: Text(
                    "Test Deterrent Siren",
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    widget.iotService.silenceHardware();
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    "Reset / Silence",
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchematicCard() {
    final pinouts = [
      {"pin": "GPIO 4", "comp": "Tactile Push Button", "func": "Physical SOS Trigger (Active LOW)"},
      {"pin": "GPIO 18", "comp": "Microphone / Sound Sensor", "func": "Acoustic Scream & Shout Trigger"},
      {"pin": "GPIO 19", "comp": "Active Piezo Buzzer", "func": "85dB Deterrent Siren Alarm"},
      {"pin": "GPIO 23", "comp": "Red 5mm LED", "func": "Emergency Strobe Beacon"},
      {"pin": "GPIO 5", "comp": "Green 5mm LED", "func": "BLE / Mesh Heartbeat Indicator"},
      {"pin": "GPIO 21", "comp": "OLED SDA", "func": "I2C Data for 128x64 SSD1306 Display"},
      {"pin": "GPIO 22", "comp": "OLED SCL", "func": "I2C Clock for 128x64 SSD1306 Display"},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory_rounded, color: AppTheme.primaryBerry, size: 20),
              const SizedBox(width: 8),
              Text(
                "ESP32 Hardware Pinouts & Wiring Guide",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Flash firmware from 'Raksha-IoT-Code/Raksha-IoT-Code.ino' with 115200 baud.",
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(2.3),
            },
            border: TableBorder.all(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(8)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFFAFAFB)),
                children: [
                  _buildTableCell("PIN", isHeader: true),
                  _buildTableCell("COMPONENT", isHeader: true),
                  _buildTableCell("FUNCTION", isHeader: true),
                ],
              ),
              ...pinouts.map((p) {
                return TableRow(
                  children: [
                    _buildTableCell(p["pin"]!, isBold: true, color: AppTheme.primaryBerry),
                    _buildTableCell(p["comp"]!),
                    _buildTableCell(p["func"]!),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isHeader ? const Color(0xFF616161) : AppTheme.textDark),
        ),
      ),
    );
  }

  Widget _buildTelemetryConsole() {
    final logs = widget.iotService.eventLogs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
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
              Row(
                children: [
                  const Icon(Icons.terminal_rounded, color: Color(0xFF64FFDA), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Live Packet Terminal",
                    style: GoogleFonts.firaCode(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                "${logs.length} events",
                style: GoogleFonts.firaCode(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 130,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF13131E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      "Waiting for ESP32 packets...\n(Press simulate button or scan BLE)",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.firaCode(fontSize: 11, color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (ctx, idx) {
                      final line = logs[idx];
                      final isAlert = line.contains("ALERT") || line.contains("🚨");
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          line,
                          style: GoogleFonts.firaCode(
                            fontSize: 10,
                            color: isAlert ? const Color(0xFFFF5252) : const Color(0xFF80CBC4),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
