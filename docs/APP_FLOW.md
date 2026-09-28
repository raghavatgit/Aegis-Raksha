# 🔄 Application & State Machine Flow
## Raksha: Offline Peer-to-Peer Emergency Mesh Network & IoT Safety System

---

## 1. High-Level System State Machine

```mermaid
stateDiagram-v2
    [*] --> Initializing
    Initializing --> PermissionDenied : Permissions Missing
    PermissionDenied --> Initializing : User Grants Location & BT
    Initializing --> ArmedMonitoring : Permissions Granted

    state ArmedMonitoring {
        [*] --> ScanningAndAdvertising
        ScanningAndAdvertising --> PeerConnected : Auto-handshake P2P
        PeerConnected --> ScanningAndAdvertising : Disconnect
    }

    ArmedMonitoring --> CountdownActive : Manual SOS Pressed
    ArmedMonitoring --> AlertDispatched : IoT Button / Scream Detected

    state CountdownActive {
        [*] --> TickingDown : 5s Timer
        TickingDown --> ArmedMonitoring : Cancel Pressed
        TickingDown --> AlertDispatched : Timer Expired / Send Now
    }

    state AlertDispatched {
        [*] --> LocalAudioVisualAlarm
        LocalAudioVisualAlarm --> HivePersist
        HivePersist --> MeshRelaying
        MeshRelaying --> HardwareSirenTrigger
    }

    AlertDispatched --> ArmedMonitoring : User Dismisses / Resets
```

---

## 2. Emergency Trigger Sequences

### 2.1 Hardware Sensor Initiated SOS (Button or Scream)
```mermaid
sequenceDiagram
    autonumber
    participant H as ESP32 Wearable
    participant P as Victim Phone
    participant G as GPS Engine
    participant DB as Hive Local DB
    participant M as Nearby Mesh Nodes
    participant C as Firebase Cloud

    H->>P: BLE Characteristic Notify {"event":"SOS_TRIGGERED","source":"SCREAM"}
    P->>G: Query high-accuracy GPS coordinates (lat, lng)
    G-->>P: Lat: 28.7585, Lng: 77.1093
    P->>DB: Store Alert into Box('alerts') & Box('relay_log')
    P->>P: Fire local siren audio & system notification
    P->>M: Broadcast JSON Payload (TTL=5) via P2P Cluster
    P->>H: Update OLED to [SOS SENT] & Activate Siren
    opt Network Available
        P->>C: Auto-sync /emergency_alerts/{alertId}
    end
```

### 2.2 Peer Inbound Alert & Multi-Hop Relay Sequence
```mermaid
sequenceDiagram
    autonumber
    participant Sender as Inbound Mesh Peer
    participant Receiver as Local Phone Node
    participant Log as Hive Relay Log
    participant UI as Responder Alert Modal
    participant Hardware as Local ESP32 Node
    participant NextPeers as Other Mesh Peers

    Sender->>Receiver: Receive Payload via dataReceivedSubscription
    Receiver->>Log: Check if alert_id exists
    alt Alert Already Processed
        Receiver-->>Sender: Drop Packet (Avoid duplicate loop)
    else First Time Receipt
        Receiver->>Log: Record alert_id in relay_log
        Receiver->>UI: Render blinking red modal & play siren
        Receiver->>Hardware: Command "SIREN_ON" via BLE (Activate buzzer & strobe)
        alt alert.ttl_hops > 0
            Receiver->>Receiver: Decrement ttl_hops = ttl_hops - 1
            Receiver->>NextPeers: Re-broadcast to all other connected nodes
        end
    end
```

---

## 3. P2P Mesh Session States
In accordance with `flutter_nearby_connections`, each discovered peer transitions through the following lifecycle states:

```
[ NOT CONNECTED ] ──(Tap Connect)──> [ CONNECTING ]
        ▲                                    │
        │                               (Handshake OK)
        │                                    ▼
 (Disconnect) <─────────────────────── [ CONNECTED ]
                                             │
                                     (Data Transmission)
                                             ▼
                                     [ RELAYING DATA ]
```

- **Not Connected (`0`)**: Node is visible in radio range.
- **Connecting (`1`)**: Symmetric cryptographic handshake in progress.
- **Connected (`2`)**: Full-duplex byte stream socket established for binary/text payloads.
