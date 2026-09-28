import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/geodesic_engine.dart';
import '../../core/utils/location_helper.dart';
import '../../data/local/hive_storage_service.dart';
import '../../data/models/emergency_alert.dart';
import '../../services/emergency_services_dispatcher.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/hybrid_engine_service.dart';
import '../../services/iot_device_service.dart';
import '../../services/mesh_network_service.dart';
import '../../services/notification_service.dart';
import '../dialogs/responder_alert_dialog.dart';
import '../dialogs/sos_countdown_dialog.dart';
import '../widgets/hybrid_engine_card.dart';
import '../widgets/hybrid_relay_card.dart';
import '../widgets/iot_devices_section.dart';
import '../widgets/mesh_devices_section.dart';
import '../widgets/mesh_messenger_box.dart';
import '../widgets/mesh_radar_widget.dart';
import '../widgets/saved_alerts_list.dart';

class HomeDashboardScreen extends StatefulWidget {
  final String title;
  const HomeDashboardScreen({super.key, required this.title});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _selectedSectorIndex = 0; // 0: Radar & Mesh, 1: Emergency SOS, 2: Chat & Logs

  bool _permissionsGranted = false;
  String _permissionStatus = "Initializing...";

  final MeshNetworkService _meshService = MeshNetworkService();
  final HybridEngineService _hybridService = HybridEngineService();
  final IotDeviceService _iotService = IotDeviceService();

  List<EmergencyAlert> _savedAlerts = [];
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isAlertModalOpen = false;
  bool _isOutboundSosActive = false;
  String? _currentActiveAlertId;
  final Set<String> _processedPacketIds = {};
  DateTime? _lastAlertBroadcastTime;

  bool _gatewayAckReceived = false;
  String? _gatewayAckInfo;

  double? _currentLat;
  double? _currentLng;

  bool? _manualRoleOverride;

  /// Role determination: The phone connected to the IoT wearable over BLE or initiating the SOS is the Parent Node.
  bool get isParentNode {
    if (_isOutboundSosActive) return true;
    if (_manualRoleOverride != null) return _manualRoleOverride!;
    return _iotService.isBleConnected;
  }

  void toggleRole() {
    setState(() {
      _manualRoleOverride = !isParentNode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isParentNode ? "👑 Role set to PARENT (VICTIM NODE)" : "🛡️ Role set to RESPONDER (GUARDIAN MESH)",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _initHybridService();
    _requestPermissionsAndInitMesh();
    _triggerFirebaseSync();
    _fetchLocationPreview();
  }

  Future<void> _fetchLocationPreview() async {
    try {
      final (lat, lng) = await LocationHelper.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentLat = lat;
          _currentLng = lng;
        });
      }
    } catch (_) {}
  }

  void _initHybridService() {
    _hybridService.init();
    _hybridService.addListener(() {
      if (mounted) setState(() {});
    });

    _iotService.init(
      onSos: (source, note) {
        triggerSosOutbound(
          type: AppConstants.typeSecurity,
          severity: AppConstants.severityCritical,
          note: "[IoT Alert] $note",
        );
      },
    );
    _iotService.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _meshService.disposeService();
    _hybridService.disposeService();
    _iotService.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _loadLocalData() {
    setState(() {
      _savedAlerts = HiveStorageService.getSavedAlerts();
    });
  }

  Future<void> _triggerFirebaseSync() async {
    int synced = await FirebaseSyncService.syncOfflineAlerts();
    if (synced > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Auto-synced $synced alerts to Cloud",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _requestPermissionsAndInitMesh() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      setState(() {
        _permissionsGranted = true;
      });
      _meshService.init(onData: _handleReceivedPayload);
      return;
    }

    try {
      List<Permission> permissions = [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
        Permission.notification,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();
      bool allEssentialGranted = true;

      if (statuses[Permission.location]?.isDenied == true ||
          statuses[Permission.location]?.isPermanentlyDenied == true) {
        allEssentialGranted = false;
      }

      setState(() {
        _permissionsGranted = allEssentialGranted;
        _permissionStatus = allEssentialGranted
            ? "Permissions Active"
            : "Bluetooth & Location are needed for offline mesh safety.";
      });

      _meshService.init(onData: _handleReceivedPayload);
      _meshService.addListener(() {
        if (mounted) setState(() {});
      });
    } catch (e) {
      setState(() {
        _permissionsGranted = true;
      });
      _meshService.init(onData: _handleReceivedPayload);
      _meshService.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _handleReceivedPayload(dynamic rawPayload) {
    try {
      String payloadStr;
      if (rawPayload is Map && rawPayload.containsKey('message')) {
        payloadStr = rawPayload['message'];
      } else {
        payloadStr = rawPayload is String ? rawPayload : jsonEncode(rawPayload);
      }
      final decoded = jsonDecode(payloadStr);

      // 1. Handle chat messages
      if (decoded["type"] == "CHAT_MSG") {
        if (!mounted) return;
        setState(() {
          _chatMessages.add({
            "sender": decoded["senderId"] ?? "Node",
            "text": decoded["text"] ?? "",
            "time": TimeOfDay.now().format(context),
          });
        });
        return;
      }

      // 2. Handle Cloud Gateway Return ACK (Confirming Police 112 / Firebase dispatch)
      if (decoded["type"] == "GATEWAY_ACK") {
        if (!mounted) return;
        final ackAlertId = decoded["alert_id"] ?? "";
        final gwNode = decoded["gateway_node_id"] ?? "Gateway";
        debugPrint("📡 [Gateway ACK] Received ACK for alert $ackAlertId from $gwNode");
        setState(() {
          _gatewayAckReceived = true;
          _gatewayAckInfo = "Confirmed by Gateway $gwNode";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Police 112 / Cloud Gateway Confirmed: Emergency Alert Dispatched!",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 3. Handle SOS_CANCEL from Victim Node
      if (decoded["type"] == "SOS_CANCEL") {
        if (!mounted) return;
        final cancelledAlertId = decoded["alert_id"] ?? "";
        debugPrint("🛑 [Mesh] Received SOS_CANCEL for alert $cancelledAlertId");
        NotificationService.stopSirenSound();
        if (_isAlertModalOpen && mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
          _isAlertModalOpen = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🟢 Emergency Cancelled: Victim reported All Clear.",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final alert = EmergencyAlert.fromJson(decoded);

      // STRICT PARENT NODE PROTECTION:
      // The parent phone (connected to IoT wearable or with outbound SOS) must NEVER prompt itself to respond!
      if (isParentNode || alert.originDeviceId == _meshService.nodeId) {
        debugPrint("🛡️ [Parent Node] Suppressing responder modal for local emergency / wearable link.");
        return;
      }

      if (_processedPacketIds.contains(alert.alertId) || HiveStorageService.hasAlert(alert.alertId)) {
        return;
      }
      
      _processedPacketIds.add(alert.alertId);
      if (_processedPacketIds.length > 100) {
        _processedPacketIds.remove(_processedPacketIds.first);
      }

      handleInboundSosAlert(alert);
    } catch (e) {
      debugPrint("Error handling payload: $e");
    }
  }

  Future<void> handleInboundSosAlert(EmergencyAlert alert) async {
    HiveStorageService.saveAlert(alert);
    _loadLocalData();

    // 1. Compute Geodesic Triage (Distance, Direction, Geofence Zone)
    final (myLat, myLng) = await LocationHelper.getCurrentLocation();
    final myHasGps = await LocationHelper.hasGpsFix();
    final victimLat = (alert.location['lat'] as num?)?.toDouble() ?? 0.0;
    final victimLng = (alert.location['lng'] as num?)?.toDouble() ?? 0.0;
    final victimHasGps = alert.hasGpsLock && victimLat != 0.0;

    final isDirectRadio = alert.ttlHops >= (AppConstants.defaultTtlHops - 1);

    final geo = GeodesicEngine.computeNavigationTriage(
      responderLat: myLat,
      responderLng: myLng,
      victimLat: victimLat,
      victimLng: victimLng,
      victimHasGps: victimHasGps,
      responderHasGps: myHasGps,
      hopCount: (AppConstants.defaultTtlHops - alert.ttlHops).clamp(1, 5),
      isDirectRadio: isDirectRadio,
    );

    debugPrint("🌐 [Triage] Distance: ${geo.formattedDistance} | Bearing: ${geo.formattedBearing} | Zone: ${geo.zoneLabel}");

    // Drop packet ONLY if outside 1.5 km ceiling and NOT received via direct local radio link
    if (geo.zone == GeofenceZone.outOfBounds && !isDirectRadio) {
      debugPrint("🛑 [Triage] Alert outside 1.5km geofence ceiling. Discarding relay.");
      return;
    }

    // 2. Opportunistic Hybrid Gateway: If online, upload to Firebase and broadcast return ACK!
    if (_hybridService.isOnline) {
      final published = await FirebaseSyncService.publishAlertNow(alert);
      if (published) {
        await HiveStorageService.markAlertAsSynced(alert.alertId);
        _meshService.broadcastGatewayAck(alert.alertId, _meshService.nodeId);
      }
    }

    // 3. Multi-hop Mesh Relay (Forward packet across mesh)
    if (alert.ttlHops > 1) {
      alert.decrementHop();
      _meshService.broadcastData(jsonEncode(alert.toJson()));
    }

    // 4. ZONE 2: SILENT SIPHON (500m - 1500m)
    // Silently relayed without loud alarms or responder modals
    if (geo.zone == GeofenceZone.silentSiphon) {
      debugPrint("🤫 [Triage] Zone 2 (500m-1500m): Siphoning packet quietly towards Cloud Gateways.");
      NotificationService.showLocalAlert(
        title: "📡 Mesh Relay Active",
        body: "Silently siphoning SOS alert from ${alert.senderId} (${geo.formattedDistance})",
      );
      return;
    }

    // 5. ZONE 1: ACTIVE RESPONDER RING (≤ 500m)
    // Physical bystander response required!
    NotificationService.showEmergencyNotification(
      "🚨 SOS Alert: ${alert.alertType} (~${geo.formattedDistance})",
      "${alert.description} | Bearing: ${geo.formattedBearing} | ETA: ~${geo.walkingEtaMinutes}m walk",
    );
    NotificationService.playSirenSound();

    if (!_isAlertModalOpen && mounted) {
      _isAlertModalOpen = true;
      ResponderAlertDialog.show(
        context,
        alert: alert,
        geodesicResult: geo,
        onDismiss: () {
          NotificationService.stopSirenSound();
        },
        onRespond: (_) {
          // Send automated response over mesh without typing
          _sendCustomChatMessage("Hold on, I am coming to help! (~${geo.formattedDistance} away)");
          NotificationService.stopSirenSound();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Response sent to the victim over Mesh! (~${geo.formattedDistance})",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ).then((_) {
        if (mounted) {
          setState(() {
            _isAlertModalOpen = false;
          });
        }
      });
    }
  }

  void _sendCustomChatMessage(String text) {
    if (text.isEmpty) return;
    
    setState(() {
      _chatMessages.add({
        "sender": "Me",
        "text": text,
        "time": TimeOfDay.now().format(context),
      });
    });

    final payload = {
      "type": "CHAT_MSG",
      "senderId": _meshService.nodeId.substring(0, 4),
      "text": text,
    };
    _meshService.broadcastData(jsonEncode(payload));
  }

  Future<void> triggerSosOutbound({
    required String type,
    required String severity,
    required String note,
  }) async {
    final now = DateTime.now();
    if (_lastAlertBroadcastTime != null &&
        now.difference(_lastAlertBroadcastTime!).inSeconds < 3) {
      return;
    }
    _lastAlertBroadcastTime = now;

    final coords = await LocationHelper.getCurrentCoordinates();
    final lat = (coords['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (coords['lng'] as num?)?.toDouble() ?? 0.0;
    final hasGps = coords['has_gps'] == true;
    _currentLat = lat;
    _currentLng = lng;
    final alertId = const Uuid().v4().substring(0, 8);
    _currentActiveAlertId = alertId;

    final alert = EmergencyAlert(
      alertId: alertId,
      senderId: _meshService.nodeId,
      timestamp: DateTime.now().toIso8601String(),
      location: {"lat": lat, "lng": lng, "has_gps": hasGps},
      alertType: type,
      severity: severity,
      description: note.isEmpty ? "Distress SOS Triggered!" : note,
      ttlHops: AppConstants.defaultTtlHops,
      isSynced: false,
      hasGpsLock: hasGps,
    );

    _processedPacketIds.add(alert.alertId);

    await HiveStorageService.saveAlert(alert);
    _loadLocalData();

    // Broadcast via offline Mesh
    _meshService.broadcastData(jsonEncode(alert.toJson()));

    // Opportunistic Hybrid mode: sync if online
    if (_hybridService.isOnline) {
      await _hybridService.syncPendingAlertsToCloud();
    }

    setState(() {
      _isOutboundSosActive = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🆘 SOS Active: Broadcast sent to nearby mesh nodes!",
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Cancel mechanism: retracts the active SOS and broadcasts ALL CLEAR across the mesh
  Future<void> cancelSosOutbound() async {
    final alertId = _currentActiveAlertId ?? "active_sos";

    final cancelPayload = {
      "type": "SOS_CANCEL",
      "alert_id": alertId,
      "senderId": _meshService.nodeId,
      "timestamp": DateTime.now().toIso8601String(),
      "message": "Emergency Alert Cancelled by User (All Clear)",
    };

    // 1. Broadcast cancel packet over offline Mesh
    _meshService.broadcastData(jsonEncode(cancelPayload));

    // 2. Silence hardware buzzer on wearable if connected
    _iotService.silenceHardware();

    // 3. Reset local states
    setState(() {
      _isOutboundSosActive = false;
      _currentActiveAlertId = null;
      _gatewayAckReceived = false;
      _gatewayAckInfo = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Emergency Cancelled: 'All Clear' broadcast sent across mesh.",
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.primaryBerry,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _hybridService.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _hybridService.isOnline ? Colors.white : Colors.white60,
              size: 20,
            ),
            tooltip: _hybridService.isOnline ? "Online: Auto-Syncing" : "Offline: Mesh Only",
            onPressed: () {
              if (_hybridService.isOnline) {
                _triggerFirebaseSync();
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedSectorIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedSectorIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: _selectedSectorIndex == 1
              ? const Color(0xFFFFCDD2)
              : const Color(0xFFE2E8F0),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.radar_outlined),
              selectedIcon: Icon(Icons.radar, color: Color(0xFF0F172A)),
              label: "Radar & Mesh",
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _isOutboundSosActive,
                backgroundColor: const Color(0xFFD32F2F),
                child: const Icon(Icons.emergency_share_outlined),
              ),
              selectedIcon: const Icon(Icons.emergency_share, color: Color(0xFFD32F2F)),
              label: "Emergency SOS",
            ),
            const NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum, color: Color(0xFF0F172A)),
              label: "Chat & Logs",
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: !_permissionsGranted
            ? _buildPermissionDeniedScreen()
            : Column(
                children: [
                  // Global Persistent Outbound SOS Bar (Visible across all tabs when emergency active)
                  if (_isOutboundSosActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: const Color(0xFFB71C1C),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "🚨 SOS BROADCAST ACTIVE",
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: cancelSosOutbound,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFB71C1C),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: const Size(60, 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.cancel, size: 14),
                            label: Text("CANCEL", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  // Top Status Strip (Clean, Non-Intrusive)
                  _buildTopStatusStrip(),

                  // Navigable Sector Body
                  Expanded(
                    child: IndexedStack(
                      index: _selectedSectorIndex,
                      children: [
                        _buildRadarSector(),
                        _buildEmergencySector(),
                        _buildChatAndLogsSector(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: toggleRole,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isParentNode ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isParentNode ? Icons.shield : Icons.wifi_channel,
                    size: 13,
                    color: isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isParentNode ? "👑 PARENT (VICTIM NODE)" : "🛡️ RESPONDER (GUARDIAN MESH)",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.swap_horiz,
                    size: 12,
                    color: isParentNode ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                _iotService.isBleConnected ? Icons.watch : Icons.watch_off_outlined,
                color: _iotService.isBleConnected ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _iotService.isBleConnected
                    ? (_iotService.deviceName.length > 10 ? "${_iotService.deviceName.substring(0, 8)}.." : _iotService.deviceName)
                    : "No Wearable",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _iotService.isBleConnected ? const Color(0xFF4CAF50) : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// SECTOR 0: Tactical Radar & Mesh Network
  Widget _buildRadarSector() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Tactical Radar Visualizer
        MeshRadarWidget(
          isParentNode: isParentNode,
          connectedDevices: _meshService.devices,
          isIotConnected: _iotService.isBleConnected,
          localDeviceName: _meshService.localDeviceName,
          onRefresh: () {
            _meshService.restartDiscovery();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Re-scanning for nearby mesh nodes...", style: GoogleFonts.poppins(fontSize: 12)),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // 2. Automated Radius Relay Modes Card
        HybridRelayCard(
          isParentNode: isParentNode,
          connectedCount: _meshService.connectedCount,
          localDeviceName: _meshService.localDeviceName,
          isOutboundSosActive: _isOutboundSosActive,
          isIotConnected: _iotService.isBleConnected,
          onToggleRole: toggleRole,
        ),
        const SizedBox(height: 16),

        // 3. Dual-Engine Hybrid Router & Dead-Zone Simulator
        HybridEngineCard(
          hybridService: _hybridService,
          onManualSyncPressed: _triggerFirebaseSync,
        ),
        const SizedBox(height: 16),

        // 3. Discovered Nearby Mesh Phones
        MeshDevicesSection(
          devices: _meshService.devices,
          onDeviceAction: (device) => _meshService.inviteOrDisconnect(device),
          onRefresh: () {
            _meshService.restartDiscovery();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Re-scanning for nearby offline mesh phones...", style: GoogleFonts.poppins(fontSize: 12)),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // 4. Nearby IoT / Wearable Section
        IotDevicesSection(
          devices: _iotService.discoveredBleDevices,
          isScanning: _iotService.isScanning,
          onConnect: (device) => _iotService.connectToBleDevice(device),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// SECTOR 1: Emergency SOS & Dispatch Controls
  Widget _buildEmergencySector() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // If Active SOS: Prominent Cancel Console
        if (_isOutboundSosActive) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD32F2F), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.podcasts, size: 54, color: Color(0xFFD32F2F)),
                const SizedBox(height: 12),
                Text(
                  "EMERGENCY BROADCAST ACTIVE",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB71C1C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "Transmitting distress beacon over Wi-Fi Direct and BLE mesh. Responders in Zone 1 (≤500m) are alerting.",
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF424242)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // CANCEL SOS BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showCancelConfirmationDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 22),
                    label: Text(
                      "CANCEL SOS (ALL CLEAR)",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_gatewayAckReceived)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _gatewayAckInfo != null
                          ? "POLICE 112 NOTIFIED ($_gatewayAckInfo)"
                          : "POLICE 112 NOTIFIED (Cloud Gateway Confirmed)",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],

        // Giant SOS Action Trigger (when not active)
        if (!_isOutboundSosActive) ...[
          Center(
            child: Column(
              children: [
                Text(
                  "TAP TO TRIGGER EMERGENCY SOS",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    SosCountdownDialog.show(
                      context,
                      onConfirmed: (type, severity, note) {
                        triggerSosOutbound(
                          type: type,
                          severity: severity,
                          note: note,
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 190,
                    height: 190,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFEBEE),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 150,
                      height: 150,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFCDD2),
                      ),
                      child: Container(
                        width: 110,
                        height: 110,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD32F2F).withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],

        // Rapid Emergency Grid
        Text(
          "RAPID DISPATCH ACTIONS",
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            // Band Siren Toggle
            Expanded(
              child: _buildRapidActionButton(
                icon: Icons.volume_up_rounded,
                label: "Band Siren",
                color: const Color(0xFFFFEBEE),
                borderColor: const Color(0xFFFFCDD2),
                iconColor: const Color(0xFFD32F2F),
                onTap: () {
                  if (_iotService.isConnected) {
                    _iotService.triggerHardwareSiren();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("🔊 Wearable Buzzer & Strobe Activated!", style: GoogleFonts.poppins(fontSize: 12)),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    NotificationService.playSirenSound();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("🔊 Phone Siren Activated!", style: GoogleFonts.poppins(fontSize: 12)),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // Call 112
            Expanded(
              child: _buildRapidActionButton(
                icon: Icons.phone_in_talk_rounded,
                label: "Call 112",
                color: const Color(0xFFE3F2FD),
                borderColor: const Color(0xFFBBDEFB),
                iconColor: const Color(0xFF1976D2),
                onTap: () => EmergencyServicesDispatcher.dialNumber('112'),
              ),
            ),
            const SizedBox(width: 8),

            // Share GPS
            Expanded(
              child: _buildRapidActionButton(
                icon: Icons.share_location_rounded,
                label: "Share GPS",
                color: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFFC8E6C9),
                iconColor: const Color(0xFF2E7D32),
                onTap: () {
                  triggerSosOutbound(
                    type: "GPS_BEACON",
                    severity: "MODERATE",
                    note: "Live GPS Pinpoint Shared",
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Live Telemetry Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "GPS TELEMETRY & GEOFENCE",
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                  const Icon(Icons.gps_fixed, size: 14, color: Color(0xFF2E7D32)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currentLat != null && _currentLng != null
                    ? "Lat: ${_currentLat!.toStringAsFixed(6)} | Lng: ${_currentLng!.toStringAsFixed(6)}"
                    : "Acquiring GPS Satellite Lock...",
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(
                "Active Ring: 500m (Zone 1) | Siphon Ceiling: 1500m (Zone 2)",
                style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRapidActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFFD32F2F)),
            const SizedBox(width: 8),
            Text("Cancel Emergency?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel the emergency broadcast? An 'All Clear' notification will be sent across the mesh network.",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Keep Active", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              cancelSosOutbound();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Yes, Cancel SOS", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// SECTOR 2: Offline Mesh Messenger & Dispatched Alerts Log
  Widget _buildChatAndLogsSector() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: MeshMessengerBox(
            chatMessages: _chatMessages,
            controller: _chatController,
            onSend: _sendCustomChatMessage,
          ),
        ),
        const SizedBox(height: 20),
        SavedAlertsList(
          savedAlerts: _savedAlerts,
          onClear: () async {
            await HiveStorageService.clearAlerts();
            _loadLocalData();
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 56, color: AppTheme.primaryBerry),
            const SizedBox(height: 16),
            Text(
              "Permissions Required",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _permissionStatus,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBerry,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _requestPermissionsAndInitMesh,
              icon: const Icon(Icons.refresh),
              label: Text("Enable Permissions", style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}
