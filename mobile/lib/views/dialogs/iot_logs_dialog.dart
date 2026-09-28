import 'package:flutter/material.dart';
import '../../services/iot_device_service.dart';

class IotLogsDialog extends StatelessWidget {
  const IotLogsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const IotLogsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iotService = IotDeviceService();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: const [
          Icon(Icons.history, color: Colors.indigo),
          SizedBox(width: 8),
          Text("IoT Event & Serial Packet Log", style: TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 280,
        child: iotService.eventLogs.isEmpty
            ? const Center(child: Text("No hardware event packets logged yet."))
            : ListView.builder(
                itemCount: iotService.eventLogs.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      iotService.eventLogs[idx],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("CLOSE"),
        ),
      ],
    );
  }
}
