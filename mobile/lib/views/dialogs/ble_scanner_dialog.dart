import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../services/iot_device_service.dart';

class BleScannerDialog extends StatefulWidget {
  final IotDeviceService iotService;

  const BleScannerDialog({super.key, required this.iotService});

  static Future<void> show(BuildContext context) {
    final iot = IotDeviceService();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BleScannerDialog(iotService: iot),
    );
  }

  @override
  State<BleScannerDialog> createState() => _BleScannerDialogState();
}

class _BleScannerDialogState extends State<BleScannerDialog> {
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    // Start scanning immediately when sheet opens
    widget.iotService.addListener(_onServiceUpdate);
    widget.iotService.scanForBleDevices(autoConnect: false);
  }

  @override
  void dispose() {
    widget.iotService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleConnect(ScanResult result) async {
    setState(() {
      _connectingDeviceId = result.device.remoteId.str;
    });

    final success = await widget.iotService.connectToBleDevice(result.device);

    if (mounted) {
      setState(() {
        _connectingDeviceId = null;
      });

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Linked to ${result.device.platformName.isNotEmpty ? result.device.platformName : 'ESP32'} via BLE!"),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("❌ Connection failed. Ensure ESP32 is nearby and powered ON."),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.iotService.discoveredBleDevices;
    final isScanning = widget.iotService.isScanning;

    // Sort devices so Raksha / ESP32 candidates appear at the top
    final sortedDevices = List<ScanResult>.from(devices);
    sortedDevices.sort((a, b) {
      final aName = "${a.device.platformName} ${a.advertisementData.advName}".toLowerCase();
      final bName = "${b.device.platformName} ${b.advertisementData.advName}".toLowerCase();
      final aIsEsp = aName.contains("raksha") || aName.contains("esp32") || aName.contains("sos");
      final bIsEsp = bName.contains("raksha") || bName.contains("esp32") || bName.contains("sos");
      if (aIsEsp && !bIsEsp) return -1;
      if (!aIsEsp && bIsEsp) return 1;
      return b.rssi.compareTo(a.rssi);
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bluetooth_searching, color: Colors.blue[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Link Raksha IoT Wearable",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isScanning
                          ? "Scanning for Bluetooth devices..."
                          : "${sortedDevices.length} devices discovered nearby",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isScanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.indigo),
                  tooltip: "Scan Again",
                  onPressed: () => widget.iotService.scanForBleDevices(autoConnect: false),
                ),
            ],
          ),
          const Divider(height: 24),

          // Device List
          if (sortedDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(
                    isScanning ? Icons.radar : Icons.bluetooth_disabled,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isScanning
                        ? "Searching for Raksha-IoT-SOS...\nKeep your ESP32 within range."
                        : "No BLE devices discovered yet.\nCheck that Bluetooth and Location are ON.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  if (!isScanning)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => widget.iotService.scanForBleDevices(autoConnect: false),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Scan Again"),
                    ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sortedDevices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = sortedDevices[index];
                  final name = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : (result.advertisementData.advName.isNotEmpty
                          ? result.advertisementData.advName
                          : "Unknown BLE Device");

                  final combined = "$name ${result.advertisementData.advName}".toLowerCase();
                  final isEsp = combined.contains("raksha") ||
                      combined.contains("esp32") ||
                      combined.contains("sos") ||
                      result.advertisementData.serviceUuids.any(
                        (u) => u.toString().toLowerCase().contains("4fafc201"),
                      );

                  final isConnecting = _connectingDeviceId == result.device.remoteId.str;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isEsp ? Colors.green[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEsp ? Colors.green[400]! : Colors.grey[200]!,
                        width: isEsp ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Icon(
                        isEsp ? Icons.memory : Icons.bluetooth,
                        color: isEsp ? Colors.green[700] : Colors.grey[600],
                        size: 28,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: isEsp ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                                color: isEsp ? Colors.green[900] : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isEsp)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "ESP32",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        "ID: ${result.device.remoteId.str} • RSSI: ${result.rssi} dBm",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      trailing: isConnecting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEsp ? Colors.green[700] : Colors.indigo[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _handleConnect(result),
                              child: const Text("LINK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),
          // Tip Footer
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Tip: Turn ON Bluetooth & GPS on phone. ESP32 red power LED must be lit.",
                    style: TextStyle(fontSize: 10.5, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
