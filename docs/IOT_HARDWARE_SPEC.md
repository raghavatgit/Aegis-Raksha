# ⚡ IoT Hardware & Embedded Firmware Specification
## Raksha: Offline Peer-to-Peer Emergency Mesh Network & IoT Safety System

---

## 1. Hardware Architecture Overview
The Raksha IoT Node is a compact, body-worn or fixed emergency sentinel powered by an **Espressif ESP32-WROOM-32** microcontroller. It bridges low-latency tactile and acoustic sensors with the smartphone app over Bluetooth Low Energy (BLE) and high-speed UART Serial.

```
                  ┌──────────────────────┐
                  │   ESP32 MCU (3.3V)   │
                  └──────────┬───────────┘
         ┌───────────────────┼───────────────────┐
         │                   │                   │
  [GPIO 4 (D4)]       [GPIO 18 (D18)]     [GPIO 19 (D19)]
  Tactile Button      Microphone Module   Piezo Siren Buzzer
  (INPUT_PULLUP)      (Digital Comparator) (Dual-freq PWM)
         │                   │                   │
  [GPIO 23 (D23)]     [GPIO 5 (D5)]       [I2C: 21 SDA, 22 SCL]
  Red Emergency LED   Green Status LED    SSD1306 128x64 OLED
```

---

## 2. Electrical Pinout & Component Bill of Materials (BOM)

| Item | Component | ESP32 Pin | Mode | Electrical Specs |
| :--- | :--- | :--- | :--- | :--- |
| **U1** | ESP32-WROOM-32 DevKit | Core | Master MCU | $3.3\text{V}$ logic, Dual-core $240\text{ MHz}$, BLE 4.2 |
| **SW1**| Momentary Red Push Button | **GPIO 4** | `INPUT_PULLUP` | Active-LOW, internal $45\text{ k}\Omega$ pullup resistor |
| **S1** | Sound / Microphone Sensor | **GPIO 18**| `INPUT` | Digital Out (DO), LM393 comparator, potentiometer |
| **LS1**| Piezoelectric Buzzer | **GPIO 19**| `OUTPUT` | $85\text{ dB} @ 10\text{ cm}$, dual-tone square wave |
| **D1** | Red Emergency LED | **GPIO 23**| `OUTPUT` | High-brightness $5\text{ mm}$, $220\Omega$ series resistor |
| **D2** | Green Armed LED | **GPIO 5** | `OUTPUT` | Standard $5\text{ mm}$, $330\Omega$ series resistor |
| **DIS1**| SSD1306 OLED Display | **GPIO 21, 22**| `I2C` | $128\times 64$ pixels, I2C address `0x3C`, $400\text{ kHz}$ |

---

## 3. Acoustic Scream Detection Algorithm

```
    Acoustic Sound Wave
           │
           ▼
    [ Microphone Sensor ] ──> Analog to LM393 Comparator
                                      │
                                      ▼ Digital Out (DO)
                               [ ESP32 GPIO 18 ]
                                      │
               Is State != Baseline? ─┴─ No ──> [ Idle / Armed ]
                        │ Yes
                        ▼
               Sample 15 iterations (6ms delay)
                        │
             Detections >= 6 out of 15?
               ├── Yes ──> [ TRIGGER SOS (Source: SCREAM) ]
               └── No  ──> [ Discard Noise Transient ]
```

- **Calibration Routine**: Upon boot, reads 10 digital samples ($20\text{ ms}$ interval) to determine ambient noise baseline.
- **Debouncing & Stabilization**: Following an alert reset, the microphone sensor is muted for $2500\text{ ms}$ to allow decoupling capacitors and power rails to stabilize.

---

## 4. BLE GATT Profile Specifications

### 4.1 Service & Characteristic UUIDs
- **Primary Service**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Alert Characteristic (Notify / Read)**:
  - UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
  - Payloads Transmitted:
    - SOS Triggered: `{"event":"SOS_TRIGGERED","source":"BUTTON"|"SCREAM","timestamp":...}`
    - Alert Reset: `{"event":"ALERT_RESET","timestamp":...}`
    - Telemetry Heartbeat: `{"event":"HEARTBEAT","connected":true,"mic":0}`
- **Command Characteristic (Write)**:
  - UUID: `beb5483f-36e1-4688-b7f5-ea07361b26a8`
  - Inbound Commands Accepted:
    - `"SIREN_ON"` / `"TRIGGER_SOS"`: Activates hardware buzzer & strobe.
    - `"SIREN_OFF"` / `"RESET"`: Silences buzzer & resets display to `[SAFE]`.
    - `"PING"`: Returns connection pong packet.

---

## 5. SSD1306 OLED Display Layouts

### 5.1 Normal Monitoring Mode (`[SAFE]`)
```
+------------------------+
|      RAKSHA IoT        |
|------------------------|
|        [SAFE]          |
| BLE: LINKED  MIC: ARMED|
+------------------------+
```

### 5.2 Outbound Trigger Mode (`[SOS SENT]`)
```
+------------------------+
|       EMERGENCY        |
|------------------------|
|       [SOS SENT]       |
|  SRC: SCREAM DETECTED  |
+------------------------+
```

### 5.3 Inbound Mesh Threat Mode (`[REMOTE MESH SOS]`)
```
+------------------------+
|       MESH ALERT       |
|------------------------|
|  >> PEER IN DANGER <<  |
| Siren Deterrent ACTIVE |
+------------------------+
```
