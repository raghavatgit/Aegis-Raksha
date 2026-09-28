# 🎨 Mobile UI/UX Design System & Wireframe Architecture
## Raksha: Offline Peer-to-Peer Emergency Mesh Network & IoT Safety System

---

## 1. Design Philosophy: High-Contrast Emergency HUD
Raksha's interface is engineered for **crisis usability**: high adrenaline, low lighting, reduced fine-motor coordination, and extreme panic.
- **Cognitive Load Minimization**: Critical statuses use single-tap large touch targets ($>64\text{ dp}$).
- **High-Visibility Color Hierarchy**: Universal color coding:
  - 🔴 **Red (`#D32F2F`)**: Active Emergency / SOS / Hardware Siren active.
  - 🟠 **Amber (`#FFA000`)**: High Hazard / Warning / Scanning mesh.
  - 🟢 **Green (`#2E7D32`)**: Armed / Safe / Mesh Linked.
  - 🔵 **Indigo (`#303F9F`)**: Offline Tactical Mesh Messaging.

---

## 2. Design Tokens & Palette

| Token | Hex Value | Semantic Usage |
| :--- | :--- | :--- |
| `primaryRed` | `#D32F2F` | Top App Bar, Primary SOS button, Critical alerts |
| `alertStrobeDark` | `#B71C1C` | Pulsating background for incoming responder dialog |
| `safeGreen` | `#2E7D32` | Connected status badges, Safe confirmation chips |
| `meshIndigo` | `#303F9F` | Mesh offline text chat bubbles & Send button |
| `surfaceBackground`| `#F8F9FA` | Main dashboard card canvas |
| `cardBorderLight` | `#E0E0E0` | Neutral structural card borders |
| `textPrimary` | `#212121` | High-contrast body typography |
| `textSecondary` | `#757575` | Captions, timestamps, and hop telemetry |

---

## 3. Screen Hierarchy & Wireframe Layout

```
┌────────────────────────────────────────────────────────┐
│ [🆘 Raksha Emergency Mesh]           [☁️ Sync Cloud]   │  <- App Bar
├────────────────────────────────────────────────────────┤
│ Status: Advertising & Scanning Active                  │
│ [Advertising: ON]  [Discovering: ON]   Connected: (3)  │  <- Status Ribbon
├────────────────────────────────────────────────────────┤
│ 🛡️ Raksha IoT Hardware Node            [LINKED (ESP32)]│  <- IoT Hardware HUD
│ ESP32 Wearable • BLE / Serial 115200       🔋 94% [📜] │
│ Status: 🛡️ Monitoring GPIO 4 (Btn) & GPIO 18 (Mic)    │
│ [🔘 Button D4] [🎙️ Mic D18] [📢 Siren D19] [📺 OLED]   │
│ [ Test Button SOS ]          [ Test Scream Sensor ]    │
│ [ Test Hardware Siren ]      [ Silence Hardware ]      │
├────────────────────────────────────────────────────────┤
│ 📱 Discovered Mesh Devices (3)                     [📶]│  <- Peer Devices
│  • Phone B (Relay Node)   [CONNECTED]   [Disconnect]   │
│  • Phone C (Responder)    [CONNECTING]  [Cancel]       │
├────────────────────────────────────────────────────────┤
│ 💬 Mesh Offline Messenger                              │  <- Mesh P2P Chat
│  ┌──────────────────────────────────────────────────┐  │
│  │ [14:22] Phone B: Trapped near Block 3 staircase  │  │
│  │ [14:23] Me: Responders alerted, stay in place!   │  │
│  └──────────────────────────────────────────────────┘  │
│  [ Type offline text message...           ] [ Send ]   │
├────────────────────────────────────────────────────────┤
│ 💾 Saved SOS Alerts (4)       [Demo Data]   [Clear]    │  <- Hive Incident Log
│  ┌──────────────────────────────────────────────────┐  │
│  │ 🏥 MEDICAL / ACCIDENT (RED_CRITICAL)             │  │
│  │ Severe road accident near Tihar Gate 3           │  │
│  │ Lat: 28.7585, Lng: 77.1093 | 14:50:00 | Hops: 4 │  │
│  └──────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────┤
│                      🆘                                │
│                  [ GLOBAL SOS ]                        │  <- Floating Huge
│              (105dp Pulsating Circle)                  │     Distress Button
└────────────────────────────────────────────────────────┘
```

---

## 4. Key Interactive Modals

### 4.1 SOS Confirmation with 5-Second Countdown
- **Purpose**: Prevents accidental false-alarm transmissions across the entire mesh.
- **UI Element**: Centered modal with large $64\text{ dp}$ circular countdown timer.
- **Controls**:
  - `CANCEL`: Aborts the trigger immediately.
  - `SEND NOW`: Bypasses countdown and fires instant broadcast.
  - Category selector: Medical, Security Threat, Fire Hazard.

### 4.2 Inbound Responder Alert Screen
- **Visual Trigger**: Full-screen dialog with smooth dual-phase red pulsating animation ($500\text{ ms}$ interval).
- **Audio Feedback**: Looping siren sound effect (`siren.mp3`) accompanied by vibration.
- **Action Buttons**:
  - `DISMISS`: Silences phone siren, silences physical IoT wearable buzzer, closes dialog.
  - `RESPOND`: Silences alarm, sends automated mesh response confirmation to sender.

### 4.3 IoT Packet Inspector
- **Access**: Tap history icon `[📜]` in the IoT Hardware Card.
- **Display**: Scrollable monospace telemetry console displaying raw JSON packets sent and received over BLE and UART Serial at 115200 baud.
