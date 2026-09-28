# 📋 Product Requirements Document (PRD)
## Raksha: Offline Peer-to-Peer Emergency Mesh Network & IoT Safety System

---

## 1. Executive Summary & Vision
**Raksha** is an autonomous, decentralized disaster-response and personal safety ecosystem built for high-stakes, network-denied environments. When catastrophic events (floods, earthquakes, structural collapses) or security incidents sever cellular towers and internet backbones, Raksha enables standard commercial smartphones and paired ESP32 IoT wearable badges to self-assemble into a multi-hop, peer-to-peer (P2P) wireless mesh. The system guarantees delivery of life-critical distress telemetry, location coordinates, and two-way tactical messaging without external infrastructure.

---

## 2. Problem Statement
1. **Critical Infrastructure Vulnerability**: 82% of cellular base stations fail within the first 4 hours of major natural disasters due to power grid blackout, backhaul fiber cuts, or physical antenna destruction.
2. **Signal-Jammed & Dead Zones**: Underpasses, subterranean transit tunnels, remote campuses, and industrial plants exhibit severe RF attenuation where traditional emergency calls (911/112) fail entirely.
3. **Incapacitation Factor**: Victims undergoing severe medical trauma, entrapment, or physical assault often cannot unlock a smartphone, navigate an app, or dial emergency numbers.

---

## 3. Target User Personas
| Persona | Profile | Core Needs | Primary Actions |
| :--- | :--- | :--- | :--- |
| **P1: Civilian / Potential Victim** | Students, commuters, residents in disaster/hazard zones. | Zero-effort distress triggering, battery efficiency, offline survival messaging. | One-touch physical button SOS, automatic acoustic scream detection, offline chat. |
| **P2: First Responder / Citizen Volunteer** | Community volunteers, rescue guards, medical wardens. | Instant proximity situational awareness, distress triage by severity. | Receive heads-up emergency alarms, sound hardware deterrent sirens, coordinate search. |
| **P3: Emergency Operations Center (EOC)** | Central disaster command officers (civil defense/NDRF). | Holistic incident heatmaps, post-disaster audit trails, victim registry. | Cloud ingestion of batched offline mesh logs once any node touches Wi-Fi/4G/5G. |

---

## 4. Product Scope & Functional Requirements

### 4.1 Zero-Infrastructure Mesh Networking
- **FR-01 (Dynamic Discovery)**: Mobile clients must continuously advertise and discover nearby peer nodes within 30–80m radio radius using Wi-Fi Direct and Bluetooth Low Energy (BLE) via `P2P_CLUSTER` topology.
- **FR-02 (Multi-Hop Relay)**: Devices must relay received alerts to other connected nodes using a decremented Time-To-Live counter ($TTL=5$ hops max), extending overall network coverage up to 300+ meters across crowds.
- **FR-03 (De-duplication)**: The network layer must maintain an in-memory and on-disk cryptographic digest cache (`relay_log`) to reject duplicated packets and prevent broadcast storms.

### 4.2 Autonomous IoT Wearable Safety Node
- **FR-04 (Dual-Trigger Mechanism)**:
  - *Manual*: Debounced tactile push button on ESP32 GPIO 4.
  - *Acoustic*: High-sensitivity microphone sensor on GPIO 18 detecting human screams/distress audio spikes ($>85\text{ dB}$) via moving-window spike accumulator.
- **FR-05 (Local Deterrent Siren & Visual Strobe)**: Instant activation of piezo buzzer (220µs/320µs dual frequency) and high-luminosity red strobe LED (GPIO 23).
- **FR-06 (Hardware OLED Telemetry)**: 0.96" SSD1306 display rendering multi-state tactical feedback (`[SAFE]`, `[SOS SENT]`, `[REMOTE MESH SOS]`).

### 4.3 Mobile Client & Emergency Dispatch
- **FR-07 (Automated Telemetry Capture)**: Instantaneous attachment of high-accuracy GPS coordinates (lat, lng), local ISO8601 timestamp, and sender node ID to the alert payload.
- **FR-08 (5-Second Safety Countdown)**: High-urgency audio-visual countdown dialog allowing users to abort accidental triggers before network-wide mesh propagation.
- **FR-09 (Bi-directional Hardware Synchronization)**:
  - Outbound: App commands ESP32 hardware (`SIREN_ON`, `RESET`).
  - Inbound: ESP32 hardware triggers app mesh broadcast automatically.

### 4.4 Offline Data Persistence & Cloud Auto-Sync
- **FR-10 (Local NoSQL Storage)**: 100% offline persistence using Hive binary boxes (`alerts`, `relay_log`, `chat_messages`).
- **FR-11 (Opportunistic Cloud Sync)**: Automatic, non-blocking batch upload of offline incident logs to Firebase Realtime Database upon detection of WAN connectivity.

---

## 5. Non-Functional Requirements & Performance SLAs
- **NFR-01 (Packet Latency)**: Single-hop packet transit time must not exceed $350\text{ ms}$; end-to-end 5-hop relay must complete within $2.2\text{ seconds}$.
- **NFR-02 (Power Consumption)**: Background mesh discovery must consume $<4.5\%\text{ battery per hour}$ in continuous active mode.
- **NFR-03 (Cold-Start SLA)**: The mobile application must achieve interactive frame render within $1.2\text{ seconds}$ on mid-tier Android devices.
- **NFR-04 (Hardware Resilience)**: ESP32 firmware watchdog timer must automatically recover within $200\text{ ms}$ in the event of power rail fluctuation or heap exhaustion.

---

## 6. Success Metrics & Key Performance Indicators (KPIs)
1. **Mean Time to Alert (MTTA)**: Time from physical sensor trigger to neighboring phone display $< 1.5\text{ s}$.
2. **Mesh Packet Delivery Ratio (PDR)**: $> 96.5\%$ successful receipt across 3-hop dense mobile networks.
3. **False Positive Rate for Acoustic Detection**: $< 2.0\%$ under typical ambient street noise ($60\text{--}70\text{ dB}$).
