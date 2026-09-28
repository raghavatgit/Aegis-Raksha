import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../core/constants/app_constants.dart';

enum IotConnectionStatus {
  disconnected,
  scanning,
  connected,
}

enum IotTriggerSource {
  none,
  button,
  scream,
  remoteMesh,
}

class IotDeviceService extends ChangeNotifier {
  static final IotDeviceService _instance = IotDeviceService._internal();
  factory IotDeviceService() => _instance;
  IotDeviceService._internal();

  IotConnectionStatus _status = IotConnectionStatus.disconnected;
  bool _isAlertActive = false;
  IotTriggerSource _lastTriggerSource = IotTriggerSource.none;
  DateTime? _lastEventTime;
  int _batteryPercent = 94;
  String _deviceName = "Raksha-IoT-SOS (ESP32)";
  final List<String> _eventLogs = [];

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _alertCharacteristic;
  BluetoothCharacteristic? _commandCharacteristic;
  StreamSubscription? _scanSub;
  StreamSubscription? _notifySub;
  StreamSubscription? _connectionStateSub;

  RawDatagramSocket? _udpSocket;

  // Callback to main application when hardware detects emergency
  Function(IotTriggerSource source, String note)? onHardwareSosTriggered;
  Function()? onHardwareReset;

  final List<ScanResult> _discoveredBleDevices = [];
  bool _isScanning = false;

  IotConnectionStatus get status => _status;
  bool get isConnected => isBleConnected;
  bool get isBleConnected =>
      _connectedDevice != null &&
      _status == IotConnectionStatus.connected &&
      _alertCharacteristic != null;
  bool get isScanning => _isScanning;
  bool get isAlertActive => _isAlertActive;
  IotTriggerSource get lastTriggerSource => _lastTriggerSource;
  DateTime? get lastEventTime => _lastEventTime;
  int get batteryPercent => _batteryPercent;
  String get deviceName => _deviceName;
  List<String> get eventLogs => List.unmodifiable(_eventLogs);
  List<ScanResult> get discoveredBleDevices => List.unmodifiable(_discoveredBleDevices);

  String get triggerSourceDescription {
    switch (_lastTriggerSource) {
      case IotTriggerSource.button:
        return "🔘 Physical SOS Button Pressed (GPIO 4)";
      case IotTriggerSource.scream:
        return "🎙️ Acoustic Scream / Shout Detected (GPIO 18)";
      case IotTriggerSource.remoteMesh:
        return "📡 Triggered from Nearby Mesh Node";
      default:
        return isConnected
            ? "🛡️ Linked via BLE • Standby Monitoring"
            : "⚠️ Disconnected • Tap 'Scan & Connect BLE'";
    }
  }

  void init({
    Function(IotTriggerSource source, String note)? onSos,
    Function()? onReset,
  }) {
    onHardwareSosTriggered = onSos;
    onHardwareReset = onReset;
    _log("Initialized Raksha IoT Service.");

    // Start background UDP listener for local Wi-Fi
    _initUdpListener();

    // Automatically initiate BLE scan and connect to Raksha-IoT-SOS
    scanAndConnect();
  }

  ServerSocket? _tcpServer;
  Socket? _connectedTcpClient;
  Socket? _tcpClientSocket;
  Timer? _tcpClientRetryTimer;

  /// Initialize local TCP server on port 8888 for USB cable bridge via ADB forward
  void _initTcpServer() async {
    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, 8888);
      _log("🔌 USB Cable ADB Bridge Server ready on port 8888.");
      _tcpServer!.listen((Socket client) {
        _connectedTcpClient = client;
        _status = IotConnectionStatus.connected;
        _log("✅ USB Serial Bridge linked from Laptop (Server Mode)!");
        notifyListeners();

        client.listen((List<int> data) {
          try {
            final text = utf8.decode(data).trim();
            for (final line in text.split('\n')) {
              if (line.trim().isNotEmpty) {
                _log("📩 USB Bridge packet: ${line.trim()}");
                processIncomingJson(line.trim());
              }
            }
          } catch (e) {
            _log("USB packet error: $e");
          }
        }, onDone: () {
          _connectedTcpClient = null;
          if (_connectedDevice == null && _tcpClientSocket == null) {
            _status = IotConnectionStatus.disconnected;
          }
          _log("⚠️ USB Bridge client disconnected.");
          notifyListeners();
        });
      });
    } catch (e) {
      _log("TCP bridge notice: $e");
    }
  }

  /// Connect as client to 127.0.0.1:8888 in case laptop script is running as TCP Server via ADB reverse
  void _initTcpClient() {
    _tcpClientRetryTimer?.cancel();
    _tcpClientRetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_status == IotConnectionStatus.connected || _connectedTcpClient != null) return;
      try {
        final socket = await Socket.connect('127.0.0.1', 8888, timeout: const Duration(seconds: 2));
        _tcpClientSocket = socket;
        _connectedTcpClient = socket;
        _status = IotConnectionStatus.connected;
        _log("✅ USB Serial Bridge linked from Laptop (Client Mode)!");
        notifyListeners();

        socket.listen((data) {
          try {
            final text = utf8.decode(data).trim();
            for (final line in text.split('\n')) {
              if (line.trim().isNotEmpty) {
                _log("📩 USB Bridge packet: ${line.trim()}");
                processIncomingJson(line.trim());
              }
            }
          } catch (e) {
            _log("USB packet error: $e");
          }
        }, onDone: () {
          _tcpClientSocket = null;
          if (_connectedTcpClient == socket) _connectedTcpClient = null;
          if (_connectedDevice == null) _status = IotConnectionStatus.disconnected;
          _log("⚠️ USB Bridge disconnected.");
          notifyListeners();
        }, onError: (e) {
          _tcpClientSocket = null;
          if (_connectedTcpClient == socket) _connectedTcpClient = null;
        });
      } catch (_) {
        // Normal when laptop has not bound server yet
      }
    });
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _eventLogs.insert(0, "[$timestamp] $message");
    if (_eventLogs.length > 50) {
      _eventLogs.removeLast();
    }
    debugPrint("[IotDeviceService] $message");
  }

  /// Initialize local network UDP socket on port 8888
  void _initUdpListener() {
    try {
      RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888).then((socket) {
        _udpSocket = socket;
        _socketListen(socket);
        _log("📡 Local Wi-Fi/UDP bridge listening on port 8888");
      }).catchError((e) {
        _log("UDP bind error (can ignore if using BLE): $e");
      });
    } catch (_) {}
  }

  void _socketListen(RawDatagramSocket socket) {
    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = socket.receive();
        if (dg != null) {
          try {
            final raw = utf8.decode(dg.data).trim();
            _log("📩 Incoming UDP Packet: $raw");
            processIncomingJson(raw);
          } catch (e) {
            _log("UDP decode error: $e");
          }
        }
      }
    });
  }

  /// Public method to initiate BLE scan (with optional auto-connect)
  Future<void> scanAndConnect() => scanForBleDevices(autoConnect: true);

  /// Scan for all nearby Bluetooth devices without restrictive hardware filters
  Future<void> scanForBleDevices({bool autoConnect = true}) async {
    if (_isScanning) return;

    _isScanning = true;
    _status = IotConnectionStatus.scanning;
    _discoveredBleDevices.clear();
    _log("🔍 Scanning for nearby BLE devices...");
    notifyListeners();

    try {
      // 1. Verify Bluetooth Adapter State
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _log("⚠️ Bluetooth is OFF. Attempting to enable...");
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      // 2. Check already connected / bonded system devices first
      try {
        final bonded = await FlutterBluePlus.bondedDevices;
        for (final d in bonded) {
          final name = d.platformName.trim().toLowerCase();
          if (name.contains("raksha") || name.contains("esp32") || name.contains("sos")) {
            _log("🎯 Found already-bonded ESP32 '$name' (${d.remoteId}). Connecting...");
            await connectToBleDevice(d);
            _isScanning = false;
            return;
          }
        }
      } catch (_) {}

      await _scanSub?.cancel();
      bool autoMatched = false;

      // 3. Listen for discovered scan results in real-time
      _scanSub = FlutterBluePlus.scanResults.listen((results) async {
        _discoveredBleDevices.clear();
        _discoveredBleDevices.addAll(results);
        notifyListeners();

        if (!autoConnect || autoMatched || _status == IotConnectionStatus.connected) return;

        for (final r in results) {
          final name = r.device.platformName.trim();
          final advName = r.advertisementData.advName.trim();
          final combined = "$name $advName".toLowerCase();

          final isRaksha = combined.contains("raksha");
          final isEsp32 = combined.contains("esp32");
          final isSos = combined.contains("sos");
          final matchesService = r.advertisementData.serviceUuids.any(
            (u) => u.toString().toLowerCase().contains("4fafc201"),
          );

          if (isRaksha || isEsp32 || isSos || matchesService) {
            autoMatched = true;
            _log("🎯 Auto-matched ESP32 Node: '$name' (${r.device.remoteId}). Connecting...");
            try { await FlutterBluePlus.stopScan(); } catch (_) {}
            _isScanning = false;
            await connectToBleDevice(r.device);
            break;
          }
        }
      });

      // 4. Start scan WITHOUT restrictive name/service filters to capture Scan Responses
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 12),
        androidUsesFineLocation: true,
      );

      await Future.delayed(const Duration(seconds: 12));
      _isScanning = false;

      if (!autoMatched && _status != IotConnectionStatus.connected) {
        if (_discoveredBleDevices.isEmpty) {
          _log("⚠️ No BLE devices discovered in 12s. Ensure ESP32 is powered ON and Bluetooth/Location are active.");
        } else {
          _log("ℹ️ Found ${_discoveredBleDevices.length} BLE devices. Tap 'Scan & Link BLE' to select manually.");
        }
        if (_status == IotConnectionStatus.scanning) {
          _status = IotConnectionStatus.disconnected;
        }
        notifyListeners();
      }
    } catch (e) {
      _isScanning = false;
      if (_status == IotConnectionStatus.scanning) {
        _status = IotConnectionStatus.disconnected;
      }
      _log("BLE Scan notice: $e");
      notifyListeners();
    }
  }

  /// Connect to a specific BluetoothDevice (user tap or auto-match)
  Future<bool> connectToBleDevice(BluetoothDevice device) async {
    try {
      _status = IotConnectionStatus.scanning;
      _log("🔗 Establishing GATT connection to ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}...");
      notifyListeners();

      try { await FlutterBluePlus.stopScan(); } catch (_) {}
      _isScanning = false;
      _connectedDevice = device;

      // Listen for connection state changes
      await _connectionStateSub?.cancel();
      _connectionStateSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          _status = IotConnectionStatus.connected;
          _log("✅ BLE Connection Established with ${device.platformName}!");
          notifyListeners();
        } else if (state == BluetoothConnectionState.disconnected) {
          _status = IotConnectionStatus.disconnected;
          _connectedDevice = null;
          _alertCharacteristic = null;
          _commandCharacteristic = null;
          _log("⚠️ BLE Device Disconnected.");
          notifyListeners();
        }
      });

      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 10),
      );

      // Discover GATT Services
      _log("🔎 Discovering GATT Services...");
      List<BluetoothService> services = await device.discoverServices();
      _log("Found ${services.length} GATT services on device.");

      bool alertSubscribed = false;

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          final cUuid = c.uuid.toString().toLowerCase();

          // Match Alert Characteristic (Notify)
          if (cUuid == AppConstants.bleAlertCharUuid.toLowerCase() ||
              (c.properties.notify && _alertCharacteristic == null)) {
            _alertCharacteristic = c;
            _log("✅ Subscribing to Alert Notifications ($cUuid)...");
            await c.setNotifyValue(true);
            await _notifySub?.cancel();
            _notifySub = c.onValueReceived.listen((bytes) {
              if (bytes.isNotEmpty) {
                final raw = utf8.decode(bytes, allowMalformed: true).trim();
                _log("🚨 Received BLE Notification: $raw");
                processIncomingJson(raw);
              }
            });
            c.lastValueStream.listen((bytes) {
              if (bytes.isNotEmpty) {
                final raw = utf8.decode(bytes, allowMalformed: true).trim();
                processIncomingJson(raw);
              }
            });
            alertSubscribed = true;
          }

          // Match Command Characteristic (Write)
          if (cUuid == AppConstants.bleCommandCharUuid.toLowerCase() ||
              ((c.properties.write || c.properties.writeWithoutResponse) && _commandCharacteristic == null)) {
            _commandCharacteristic = c;
            _log("✅ Command Characteristic Ready ($cUuid)");
          }
        }
      }

      _status = IotConnectionStatus.connected;
      _deviceName = device.platformName.isNotEmpty ? device.platformName : "Raksha-IoT-SOS (ESP32)";
      _log("🛡️ Raksha IoT Node Fully Linked & Armed over BLE!");
      notifyListeners();
      return true;
    } catch (e) {
      _status = IotConnectionStatus.disconnected;
      _connectedDevice = null;
      _alertCharacteristic = null;
      _commandCharacteristic = null;
      _log("❌ Error connecting to BLE device: $e");
      notifyListeners();
      return false;
    }
  }

  /// Disconnect the IoT node
  Future<void> disconnect() async {
    _status = IotConnectionStatus.disconnected;
    _isAlertActive = false;
    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _connectionStateSub?.cancel();
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
    _deviceName = "Raksha-IoT-SOS (ESP32)";
    _log("⚠️ Disconnected from IoT Node.");
    notifyListeners();
  }

  DateTime? _lastHardwareTriggerTime;
  DateTime? _muteTriggersUntil;

  /// Process incoming JSON packet from BLE notify characteristic or USB Serial or UDP
  void processIncomingJson(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    _log("📥 Processing Hardware Signal: $text");

    // 1. Try strict JSON parse first
    try {
      final data = jsonDecode(text);
      if (data is Map) {
        final event = (data['event'] ?? '').toString().toUpperCase();
        final src = (data['source'] ?? '').toString().toUpperCase();

        // Prevent echo loop: Ignore events that originated from the phone/app
        if (src.contains("REMOTE") || src.contains("PHONE") || src.contains("APP")) {
          _log("ℹ️ Remote siren echo ignored.");
          return;
        }

        if (event == "SOS_TRIGGERED" || event == "ALERT" || event == "EMERGENCY") {
          if (src.contains("SCREAM") || src.contains("MIC")) {
            handleHardwareTrigger(
              IotTriggerSource.scream,
              "High decibel acoustic distress detected by Raksha wearable microphone",
            );
          } else {
            handleHardwareTrigger(
              IotTriggerSource.button,
              "Wearable emergency push button pressed by user",
            );
          }
          return;
        } else if (event == "ALERT_RESET" || event == "RESET" || event == "SAFE") {
          handleHardwareReset();
          return;
        } else if (event == "HEARTBEAT") {
          _log("💓 Hardware Heartbeat OK (Sensors Normal)");
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Fall through to keyword matching
    }

    // 2. Keyword fallback matching
    final upper = text.toUpperCase();

    // Ignore remote echo keywords
    if (upper.contains("REMOTE") || upper.contains("PHONE_APP")) {
      return;
    }

    if (upper.contains("SCREAM") || (upper.contains("MIC") && upper.contains("SOS"))) {
      handleHardwareTrigger(
        IotTriggerSource.scream,
        "High decibel acoustic distress detected by Raksha wearable microphone",
      );
    } else if (upper.contains("SOS_TRIGGERED") ||
               upper.contains("BUTTON") ||
               upper.contains("SOS SENT") ||
               upper.contains("TRIGGER_SOS") ||
               upper.contains("EMERGENCY")) {
      handleHardwareTrigger(
        IotTriggerSource.button,
        "Wearable emergency push button pressed by user",
      );
    } else if (upper.contains("ALERT_RESET") || upper.contains("RESET") || upper.contains("[SAFE]")) {
      handleHardwareReset();
    } else if (upper.contains("HEARTBEAT") || upper.contains("PONG")) {
      _log("💓 Hardware Telemetry: $text");
      notifyListeners();
    } else {
      _log("📩 Hardware packet received: $text");
    }
  }

  /// Hardware triggered an alert (button or microphone scream)
  void handleHardwareTrigger(IotTriggerSource source, String note) {
    final now = DateTime.now();

    // Check silence cooldown (e.g. after user tapped "I AM RESPONDING" or pressed reset)
    if (_muteTriggersUntil != null && now.isBefore(_muteTriggersUntil!)) {
      _log("⏳ Ignoring trigger during silence cooldown window.");
      return;
    }

    // Debounce rapid triggers (must be at least 3 seconds apart)
    if (_lastHardwareTriggerTime != null &&
        now.difference(_lastHardwareTriggerTime!) < const Duration(seconds: 3)) {
      _log("⏳ Debouncing duplicate rapid trigger.");
      return;
    }
    _lastHardwareTriggerTime = now;

    _isAlertActive = true;
    _lastTriggerSource = source;
    _lastEventTime = now;

    final label = source == IotTriggerSource.scream ? "SCREAM DETECTED" : "BUTTON PRESSED";
    _log("🚨 ALERT: $label on IoT Hardware! Firing Emergency Mesh Broadcast...");
    notifyListeners();

    // Notify main app to initiate mesh broadcast and alert responders across the network
    onHardwareSosTriggered?.call(source, note);
  }

  /// Mobile app commands hardware to sound its physical siren & strobe
  /// (e.g. When a mesh alert is received from a peer, or app user triggers SOS)
  void triggerHardwareSiren({String source = "REMOTE_MESH"}) {
    _isAlertActive = true;
    _lastTriggerSource = IotTriggerSource.remoteMesh;
    _lastEventTime = DateTime.now();
    _log("📢 Transmitting command 'SIREN_ON' to ESP32: Buzzer & Red Strobe ACTIVE.");

    // Send command via BLE
    if (_commandCharacteristic != null) {
      try {
        _commandCharacteristic!.write(utf8.encode("SIREN_ON\n"), withoutResponse: true);
      } catch (e) {
        _log("BLE write error: $e");
      }
    }

    // Send command via USB Cable TCP Bridge
    if (_connectedTcpClient != null) {
      try {
        _connectedTcpClient!.write("SIREN_ON\n");
      } catch (_) {}
    }

    notifyListeners();
  }

  /// Mobile app commands hardware to silence siren and return to [SAFE]
  void silenceHardware() {
    _isAlertActive = false;
    _lastTriggerSource = IotTriggerSource.none;
    _muteTriggersUntil = DateTime.now().add(const Duration(seconds: 4));
    _log("🔕 Transmitting command 'RESET' to ESP32: Siren silenced, OLED reset to [SAFE].");

    // Send command via BLE
    if (_commandCharacteristic != null) {
      try {
        _commandCharacteristic!.write(utf8.encode("RESET\n"), withoutResponse: true);
      } catch (e) {
        _log("BLE write error: $e");
      }
    }

    // Send command via USB Cable TCP Bridge
    if (_connectedTcpClient != null) {
      try {
        _connectedTcpClient!.write("RESET\n");
      } catch (_) {}
    }

    notifyListeners();
    onHardwareReset?.call();
  }

  void _sendUdpBroadcast(String msg) {
    try {
      if (_udpSocket != null) {
        final data = utf8.encode(msg);
        _udpSocket!.send(data, InternetAddress("255.255.255.255"), 8888);
      }
    } catch (_) {}
  }

  /// Hardware reset received from device itself
  void handleHardwareReset() {
    _isAlertActive = false;
    _lastTriggerSource = IotTriggerSource.none;
    _muteTriggersUntil = DateTime.now().add(const Duration(seconds: 4));
    _log("✅ Hardware returned to SAFE monitoring state.");
    notifyListeners();
    onHardwareReset?.call();
  }

  void disconnectDevice() => disconnect();

  void sendCustomCommand(String cmd) {
    if (cmd == "SIREN_ON") {
      triggerHardwareSiren();
    } else if (cmd == "RESET" || cmd == "SIREN_OFF") {
      silenceHardware();
    }
  }

  /// Test / Demo simulation for presentations and grading
  void simulateHardwareTrigger(IotTriggerSource source) {
    if (source == IotTriggerSource.scream) {
      handleHardwareTrigger(
        IotTriggerSource.scream,
        "🚨 High-decibel shout/scream detected by Wearable Microphone (GPIO 18)",
      );
    } else {
      handleHardwareTrigger(
        IotTriggerSource.button,
        "🆘 Wearable Physical Red Push Button Pressed (GPIO 4)",
      );
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _notifySub?.cancel();
    _connectionStateSub?.cancel();
    _udpSocket?.close();
    _tcpServer?.close();
    _connectedTcpClient?.destroy();
    _tcpClientRetryTimer?.cancel();
    _tcpClientSocket?.destroy();
    super.dispose();
  }
}
