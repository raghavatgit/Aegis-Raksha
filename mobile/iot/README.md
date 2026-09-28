# 🛡️ Raksha IoT Emergency Node (ESP32 Firmware)

This directory contains the firmware for the **Raksha Wearable / Fixed Emergency IoT Node**. It links physical safety sensors (Push Button, Acoustic Scream Microphone, Deterrent Siren, SSD1306 OLED) directly with the **Raksha Emergency Mesh** Flutter smartphone application.

---

## 📌 Hardware Pinout & Wiring Specification

| Component | Pin on ESP32 | Mode | Description |
| :--- | :--- | :--- | :--- |
| **Emergency SOS Button** | **GPIO 4** (D4) | `INPUT_PULLUP` | Active-LOW button. Tap to send SOS; tap again while active to cancel. |
| **Acoustic Scream Sensor** | **GPIO 18** (D18) | `INPUT` | Digital OUT from Sound/Microphone sensor module. Detects acoustic spikes (shouts/screams). |
| **Deterrent Siren Buzzer** | **GPIO 19** (D19) | `OUTPUT` | Piezo/Electromagnetic Buzzer. Emits oscillating dual-frequency siren (220µs / 320µs). |
| **Emergency Red Strobe LED** | **GPIO 23** (D23) | `OUTPUT` | High-visibility red flashing strobe synchronized with siren audio. |
| **Status Green LED** | **GPIO 5** (D5) | `OUTPUT` | Steady green when system is armed and in `[SAFE]` state. |
| **SSD1306 OLED (SDA)** | **GPIO 21** | `I2C SDA` | 128x64 Monochrome OLED Display data line. |
| **SSD1306 OLED (SCL)** | **GPIO 22** | `I2C SCL` | 128x64 Monochrome OLED Display clock line. |
| **VCC & GND** | **3.3V / 5V & GND**| Power | Power distribution for sensors and display. |

---

## ⚙️ Arduino IDE Setup

1. **Board Manager**: Install `esp32 by Espressif Systems` (Tools -> Board -> Boards Manager).
2. **Target Board**: Select `ESP32 Dev Module` or `DOIT ESP32 DEVKIT V1`.
3. **Required Libraries** (Install via Sketch -> Include Library -> Manage Libraries):
   - `Adafruit SSD1306` (by Adafruit)
   - `Adafruit GFX Library` (by Adafruit)
   - `BLEDevice` (Built-in with ESP32 board package)
   - `Wire` (Built-in)
4. **Upload Speed**: `921600` or `115200` baud.
5. **Serial Monitor**: Set to `115200` baud.

---

## 📡 Wireless & Serial Communication Protocol

### 1. Bluetooth Low Energy (BLE)
- **Device Advertised Name**: `Raksha-IoT-SOS`
- **Primary Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Alert Characteristic (Notify / Read)**: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
  - Sends immediate notification to mobile app when triggered:
    ```json
    {"event":"SOS_TRIGGERED","source":"BUTTON","timestamp":15420}
    {"event":"SOS_TRIGGERED","source":"SCREAM","timestamp":24300}
    {"event":"ALERT_RESET","timestamp":32100}
    ```
- **Command Characteristic (Write)**: `beb5483f-36e1-4688-b7f5-ea07361b26a8`
  - Allows mobile app to control hardware:
    - `"SIREN_ON"` or `"REMOTE_ALERT"`: Activates siren and displays `[REMOTE MESH SOS]`.
    - `"SIREN_OFF"` or `"RESET"`: Resets hardware to safe state.
    - `"PING"`: Verifies connection.

### 2. USB Serial Protocol (115200 Baud)
All events are simultaneously streamed over Serial. Commands can also be typed into the Serial Monitor or sent via USB-OTG:
- Type `SIREN_ON` + Enter -> triggers siren.
- Type `RESET` + Enter -> silences siren.
- Type `PING` + Enter -> returns `{"event":"PONG","connected":...}`.

---

## 🧪 Demonstration & Viva Protocol

1. **Manual Trigger**:
   - Press the physical red push button on D4.
   - Observe: OLED switches to `[SOS SENT]`, Red Strobe flashes, Buzzer sounds siren.
   - On Phone App: Immediate SOS notification appears, GPS is attached, and alert is broadcasted over the offline mesh network!
2. **Acoustic Scream Detection**:
   - Make a sharp shout/scream or clap near the microphone module.
   - Observe: OLED indicates `SRC: SCREAM DETECTED`, siren triggers, phone app automatically initiates emergency broadcast.
3. **Mesh Peer In Danger (Bi-Directional Feedback)**:
   - When another peer on the mesh network broadcasts an SOS, the phone transmits `SIREN_ON` to the IoT wearable.
   - The ESP32 OLED shows `>> PEER IN DANGER <<`, sounding an alert to deter threats in the vicinity.
4. **App Dismissal**:
   - Tapping "DISMISS" on the smartphone sends `RESET` to the wearable, restoring the green LED and `[SAFE]` OLED status.
