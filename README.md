# Aegis-Raksha: Decentralized Disaster Emergency Mesh & IoT Dispatch System

A disaster distress communication architecture engineered for infrastructure-collapsed zones. Aegis-Raksha bridges physical ESP32 LoRa RF transceiver nodes with an offline Bluetooth Low Energy (BLE) Flutter mobile application to dispatch distress telemetry without cellular or internet connectivity.

```
+--------------------+        BLE / GATT        +--------------------+
|  Flutter Client    | <---------------------> |  ESP32 LoRa Node   |
|  (GPS / Local SOS) |                          |  (SX1276 Firmware) |
+--------------------+                          +--------------------+
                                                          |
                                                    LoRa RF (868MHz)
                                                    Multi-Hop Flooding
                                                          v
                                                +--------------------+
                                                |  Relay Node 01     |
                                                +--------------------+
                                                          |
                                                          v
                                                +--------------------+
                                                |  Gateway / Cloud   |
                                                |  (Firebase / UART) |
                                                +--------------------+
```

---

## Technical Architecture

### 1. Embedded LoRa Mesh Firmware (`firmware/`)
- **Transceiver Target**: Semtech SX1276 / SX1278 (868 MHz / 915 MHz).
- **Spreading Factor & Modulation**: Configurable SF7 to SF12, 125 kHz bandwidth, CR 4/5 for extended link budget.
- **Routing Protocol**: Controlled flooding with TTL hop decrement and in-memory ring-buffer packet de-duplication to eliminate broadcast storm contention.
- **Microcontroller**: ESP32 dual-core Xtensa LX6.

### 2. Mobile Companion Application (`mobile/`)
- **Framework**: Flutter 3 / Dart.
- **Offline Hardware Integration**: `flutter_blue_plus` peripheral discovery and GATT profile communication.
- **Telemetry Engine**: Background geolocator coordinates acquisition, emergency contact dispatching, and automated audible distress beacons.
- **Cloud Fallback**: Firebase Realtime Database gateway synchronizer when uplink access is re-established.

### 3. Gateway Telemetry Bridge (`bridge/`)
- **Serial Interface**: Python and PowerShell serial bridges (`iot_usb_bridge.py`, `iot_usb_bridge.ps1`) providing high-baud streaming between PC command centers and field LoRa nodes.

---

## Directory Layout

```
Aegis-Raksha/
|-- firmware/             # ESP32 C++ Arduino firmware (Raksha-IoT-Code.ino)
|-- mobile/               # Cross-platform Flutter mobile client (lib, android, ios)
|-- bridge/               # Serial communication bridges for gateway stations
|-- docs/                 # Protocol specifications, hardware specs, PRD, and TRD
|-- LICENSE               # MIT License
```

---

## Engineering Documentation

Detailed specifications are maintained in the [`docs/`](./docs) directory:
- [MESH_PROTOCOL.md](./docs/MESH_PROTOCOL.md): Packet frame encoding, byte layouts, CRC checksums, and relay rules.
- [IOT_HARDWARE_SPEC.md](./docs/IOT_HARDWARE_SPEC.md): Pinout definitions, antenna matching, battery management, and RF parameters.
- [PRD.md](./docs/PRD.md): Product Requirements Document and operational parameters.
- [TRD.md](./docs/TRD.md): Technical Requirements Document and system interfaces.

---

## License

This software is released under the MIT License.
