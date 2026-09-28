import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/local/hive_storage_service.dart';
import '../data/models/emergency_alert.dart';
import 'firebase_sync_service.dart';
import 'iot_device_service.dart';
import 'mesh_network_service.dart';
import 'notification_service.dart';

enum NetworkRoutingState {
  offlineMeshOnly,
  hybridCloudAndMesh,
  syncingOfflineData,
}

class HybridEngineService extends ChangeNotifier {
  static final HybridEngineService _instance = HybridEngineService._internal();
  factory HybridEngineService() => _instance;
  HybridEngineService._internal();

  bool _isOnline = false;
  bool _isHybridModeActive = true;
  bool _isForceOfflineSimulated = false;
  NetworkRoutingState _routingState = NetworkRoutingState.offlineMeshOnly;
  
  int _pendingSyncCount = 0;
  int _lastSyncedCount = 0;
  String _networkStatusMessage = "Checking Network Connection...";
  
  Timer? _connectivityTimer;
  final MeshNetworkService _meshService = MeshNetworkService();
  final IotDeviceService _iotService = IotDeviceService();

  bool get isOnline => _isOnline && !_isForceOfflineSimulated;
  bool get isHybridModeActive => _isHybridModeActive;
  bool get isForceOfflineSimulated => _isForceOfflineSimulated;
  NetworkRoutingState get routingState => _routingState;
  int get pendingSyncCount => _pendingSyncCount;
  int get lastSyncedCount => _lastSyncedCount;
  String get networkStatusMessage => _networkStatusMessage;

  String get hardwareTransportStatus {
    final hasBle = _iotService.isConnected;
    final hasUsb = _iotService.eventLogs.any((l) => l.contains("USB Bridge linked"));
    
    if (hasBle && hasUsb) {
      return "⚡ DUAL REDUNDANCY: BLE + USB Cable Active";
    } else if (hasBle) {
      return "📶 BLE Wireless Active";
    } else if (hasUsb) {
      return "🔌 USB Cable Bridge Active";
    } else {
      return "⚠️ IoT Standby (Scanning BLE & USB)";
    }
  }

  void init() {
    _startConnectivityMonitoring();
    _updatePendingSyncCount();
  }

  void toggleHybridMode(bool value) {
    _isHybridModeActive = value;
    _evaluateRoutingState();
    notifyListeners();
  }

  void toggleForceOfflineSimulation(bool value) {
    _isForceOfflineSimulated = value;
    _evaluateRoutingState();
    notifyListeners();
  }

  void _startConnectivityMonitoring() {
    _checkConnectivity();
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    bool previousOnline = _isOnline;
    bool currentOnline = false;

    if (kIsWeb) {
      currentOnline = true;
    } else {
      try {
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 3),
        );
        currentOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        currentOnline = false;
      }
    }

    _isOnline = currentOnline;
    _evaluateRoutingState();

    // Transition from Offline -> Online triggers automatic background cloud sync
    if (!previousOnline && isOnline && _isHybridModeActive) {
      syncPendingAlertsToCloud();
    }
  }

  void _evaluateRoutingState() {
    _updatePendingSyncCount();

    if (isOnline && _isHybridModeActive) {
      _routingState = NetworkRoutingState.hybridCloudAndMesh;
      _networkStatusMessage = "🌐 HYBRID MODE ACTIVE (Simultaneous Firebase Cloud + P2P Mesh)";
    } else if (_isForceOfflineSimulated) {
      _routingState = NetworkRoutingState.offlineMeshOnly;
      _networkStatusMessage = "⚡ OFFLINE MESH SIMULATION ACTIVE (100% P2P Local Routing)";
    } else {
      _routingState = NetworkRoutingState.offlineMeshOnly;
      _networkStatusMessage = "📡 OFFLINE P2P MESH ACTIVE (Cellular Dead-Zone Fallback)";
    }

    notifyListeners();
  }

  void _updatePendingSyncCount() {
    _pendingSyncCount = HiveStorageService.getUnsyncedAlertsCount();
  }

  /// Master Dispatch Function for Emergency SOS Alerts
  Future<Map<String, dynamic>> dispatchEmergencyAlert({
    required EmergencyAlert alert,
    required String alertJsonString,
  }) async {
    int meshPeersReached = 0;
    bool cloudPublished = false;

    // 1. Local Offline Persistence
    await HiveStorageService.saveAlert(alert);

    // 2. Hardware Deterrent Siren & Strobe Activation (BLE + USB Serial Bridge)
    _iotService.triggerHardwareSiren(source: "PHONE_APP");

    // 3. Local Heads-Up System Notification & Siren Sound
    NotificationService.showEmergencyNotification(
      "🆘 EMERGENCY ALERT: ${alert.alertType} (${alert.severity})",
      "${alert.description} | Location: ${alert.location['lat']?.toStringAsFixed(3)}, ${alert.location['lng']?.toStringAsFixed(3)}",
    );
    NotificationService.playSirenSound();

    // 4. Local P2P Mesh Broadcast (Wi-Fi Direct / Bluetooth to nearby peers)
    meshPeersReached = _meshService.broadcastMessage(alertJsonString);

    // 5. Dual-Engine Cloud Dispatch (if Online & Hybrid Mode Enabled)
    if (isOnline && _isHybridModeActive) {
      cloudPublished = await FirebaseSyncService.publishAlertNow(alert);
      if (cloudPublished) {
        await HiveStorageService.markAlertAsSynced(alert.alertId);
      }
    } else {
      // Offline: Queue for future cloud sync
      _updatePendingSyncCount();
    }

    _evaluateRoutingState();

    return {
      'meshPeersReached': meshPeersReached,
      'cloudPublished': cloudPublished,
      'isHybrid': isOnline && _isHybridModeActive,
    };
  }

  /// Manually or automatically trigger background sync of queued offline alerts
  Future<int> syncPendingAlertsToCloud() async {
    if (!isOnline) {
      _networkStatusMessage = "⚠️ Cannot sync: Device is offline.";
      notifyListeners();
      return 0;
    }

    _routingState = NetworkRoutingState.syncingOfflineData;
    _networkStatusMessage = "☁️ Synchronizing offline emergency records to Firebase Cloud...";
    notifyListeners();

    int synced = await FirebaseSyncService.syncOfflineAlerts();
    _lastSyncedCount = synced;
    _updatePendingSyncCount();

    _evaluateRoutingState();
    return synced;
  }

  void disposeService() {
    _connectivityTimer?.cancel();
  }
}
