import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import '../../core/constants/app_constants.dart';

class MeshNetworkService extends ChangeNotifier {
  static final MeshNetworkService _instance = MeshNetworkService._internal();
  factory MeshNetworkService() => _instance;
  MeshNetworkService._internal();

  NearbyService? _nearbyService;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _dataSubscription;

  List<Device> _devices = [];
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  String _statusMessage = "Starting...";
  final String _nodeId = "phone_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
  late final String _localDeviceName = "Guardian-Node-${_nodeId.substring(_nodeId.length - 4)}";

  // Auto-connect to discovered bystander peers without requiring manual taps
  bool _autoConnectPeers = true;
  final Set<String> _pendingInvites = {};

  Function(dynamic data)? onDataReceived;

  String get nodeId => _nodeId;
  String get localDeviceName => _localDeviceName;
  List<Device> get devices => _devices;
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;
  String get statusMessage => _statusMessage;
  bool get autoConnectPeers => _autoConnectPeers;
  int get connectedCount => _devices.where((d) => d.state == SessionState.connected).length;

  void setAutoConnect(bool enable) {
    _autoConnectPeers = enable;
    notifyListeners();
  }

  Future<void> init({required Function(dynamic data) onData}) async {
    onDataReceived = onData;

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _isAdvertising = true;
      _isDiscovering = true;
      _statusMessage = "💻 Preview Mode (Simulated Mesh Active)";
      _devices = [
        Device("phone_b_id", "Phone B (Relay Node)", SessionState.connected.index),
        Device("phone_c_id", "Phone C (Responder Node)", SessionState.connected.index),
      ];
      notifyListeners();
      return;
    }

    try {
      _nearbyService = NearbyService();
      await _nearbyService!.init(
        serviceType: AppConstants.meshServiceType,
        strategy: Strategy.P2P_CLUSTER,
        deviceName: _localDeviceName,
        callback: (isRunning) async {
          debugPrint("🚀 [Mesh Nearby] Service running state: $isRunning");
          if (isRunning) {
            try {
              debugPrint("📢 [Mesh Nearby] Starting Advertising as $_localDeviceName...");
              _nearbyService!.startAdvertisingPeer();
            } catch (e) {
              debugPrint("⚠️ [Mesh Nearby] startAdvertising error: $e");
            }

            await Future.delayed(const Duration(milliseconds: 300));

            try {
              debugPrint("🔍 [Mesh Nearby] Starting Browsing for peers...");
              _nearbyService!.startBrowsingForPeers();
            } catch (e) {
              debugPrint("⚠️ [Mesh Nearby] startBrowsing error: $e");
            }

            _isAdvertising = true;
            _isDiscovering = true;
            _statusMessage = "🚀 Mesh Advertising & Scanning active";
            notifyListeners();
          }
        },
      );

      _stateSubscription = _nearbyService!.stateChangedSubscription(
        callback: (devicesList) {
          debugPrint("📡 [Mesh Nearby] Discovered ${devicesList.length} peers: ${devicesList.map((d) => "${d.deviceName}(${d.deviceId}): state ${d.state}").join(", ")}");

          // Filter out our own self-advertisement if detected
          _devices = devicesList.where((d) {
            if (d.deviceName.trim() == _localDeviceName.trim()) return false;
            if (d.deviceId == _nodeId) return false;
            return true;
          }).toList();

          // Auto-connect to discovered bystander phones for instant emergency routing
          if (_autoConnectPeers) {
            for (var dev in _devices) {
              if (dev.state == SessionState.connected) {
                _pendingInvites.remove(dev.deviceId);
              } else if (dev.state == SessionState.notConnected) {
                if (!_pendingInvites.contains(dev.deviceId)) {
                  _pendingInvites.add(dev.deviceId);
                  debugPrint("🤝 [Mesh Nearby] Inviting peer: ${dev.deviceName} (${dev.deviceId})");
                  _nearbyService?.invitePeer(
                    deviceID: dev.deviceId,
                    deviceName: _localDeviceName,
                  );
                  // Allow retry after 6 seconds if connection is still pending or lost
                  Future.delayed(const Duration(seconds: 6), () {
                    _pendingInvites.remove(dev.deviceId);
                  });
                }
              }
            }
          }

          notifyListeners();
        },
      );

      _dataSubscription = _nearbyService!.dataReceivedSubscription(
        callback: (data) {
          onDataReceived?.call(data);
        },
      );
    } catch (e) {
      _statusMessage = "⚠️ Mesh Service warning: $e";
      notifyListeners();
    }
  }

  void inviteOrDisconnect(Device device) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      final index = _devices.indexWhere((d) => d.deviceId == device.deviceId);
      if (index != -1) {
        final newState = device.state == SessionState.connected
            ? SessionState.notConnected
            : SessionState.connected;
        _devices[index] = Device(device.deviceId, device.deviceName, newState.index);
        notifyListeners();
      }
      return;
    }

    if (device.state == SessionState.notConnected) {
      _nearbyService?.invitePeer(
        deviceID: device.deviceId,
        deviceName: _localDeviceName,
      );
    } else if (device.state == SessionState.connected) {
      _nearbyService?.disconnectPeer(deviceID: device.deviceId);
    }
  }

  int broadcastData(String data) => broadcastMessage(data);

  int broadcastMessage(String messageJson, {String? excludeDeviceId}) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return 2;
    }

    int sentCount = 0;
    for (var device in _devices) {
      if (device.state == SessionState.connected && device.deviceId != excludeDeviceId) {
        _nearbyService?.sendMessage(device.deviceId, messageJson);
        sentCount++;
      }
    }
    return sentCount;
  }

  /// Broadcast Gateway ACK back across mesh to confirm cloud/police dispatch
  int broadcastGatewayAck(String alertId, String gatewayNodeId) {
    final ackMap = {
      'type': 'GATEWAY_ACK',
      'alert_id': alertId,
      'gateway_node_id': gatewayNodeId,
      'status': 'POLICE_112_NOTIFIED',
      'timestamp': DateTime.now().toIso8601String().substring(11, 19),
    };
    return broadcastMessage(jsonEncode(ackMap));
  }

  Future<void> restartDiscovery() async {
    _statusMessage = "🔄 Scanning for nearby mesh phones...";
    _pendingInvites.clear();
    _devices.clear();
    notifyListeners();
    try {
      if (_nearbyService != null) {
        try {
          await _nearbyService!.stopBrowsingForPeers();
        } catch (_) {}
        try {
          await _nearbyService!.stopAdvertisingPeer();
        } catch (_) {}
        await _stateSubscription?.cancel();
        _stateSubscription = null;
        await _dataSubscription?.cancel();
        _dataSubscription = null;
        await Future.delayed(const Duration(milliseconds: 400));
        await init(onData: onDataReceived ?? (_) {});
      }
    } catch (e) {
      _statusMessage = "⚠️ Mesh restart notice: $e";
      notifyListeners();
    }
  }

  void disposeService() {
    _stateSubscription?.cancel();
    _dataSubscription?.cancel();
    _pendingInvites.clear();
  }
}
