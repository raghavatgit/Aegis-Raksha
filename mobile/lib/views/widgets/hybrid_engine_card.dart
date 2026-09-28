import 'package:flutter/material.dart';
import '../../services/hybrid_engine_service.dart';

class HybridEngineCard extends StatelessWidget {
  final HybridEngineService hybridService;
  final VoidCallback onManualSyncPressed;

  const HybridEngineCard({
    super.key,
    required this.hybridService,
    required this.onManualSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = hybridService.isOnline;
    final isHybrid = hybridService.isHybridModeActive;
    final isOfflineSimulated = hybridService.isForceOfflineSimulated;
    final pendingCount = hybridService.pendingSyncCount;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isHybrid && isOnline
                ? [Colors.blue[900]!, Colors.indigo[800]!]
                : [Colors.deepOrange[900]!, Colors.brown[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  isHybrid && isOnline ? Icons.cell_tower : Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "⚡ DUAL-ENGINE HYBRID ROUTER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hybridService.networkStatusMessage,
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green[600] : Colors.amber[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnline ? "ONLINE" : "OFFLINE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),

            // Hardware & Routing Redundancy Badges
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hardware Transport:",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hybridService.hardwareTransportStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "☁️ $pendingCount Unsynced Alert${pendingCount > 1 ? 's' : ''}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Control Toggles & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hybrid Toggle Switch
                Row(
                  children: [
                    Switch(
                      value: isHybrid,
                      activeThumbColor: Colors.lightBlueAccent,
                      onChanged: (val) => hybridService.toggleHybridMode(val),
                    ),
                    Text(
                      isHybrid ? "Hybrid Mode (Cloud + P2P)" : "P2P Mesh Only",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),

                // Force Offline Simulator Switch
                Row(
                  children: [
                    Text(
                      "Simulate Dead-Zone:",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => hybridService.toggleForceOfflineSimulation(!isOfflineSimulated),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOfflineSimulated ? Colors.red[700] : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          isOfflineSimulated ? "OFFLINE ON" : "NORMAL",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (pendingCount > 0 && isOnline) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: onManualSyncPressed,
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: Text(
                    "Sync $pendingCount Offline Records to Firebase Cloud Now",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
