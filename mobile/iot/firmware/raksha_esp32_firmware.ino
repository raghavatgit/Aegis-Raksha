#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <esp_system.h>

// ================= PIN DEFINITIONS =================
#define BUTTON_PIN     4   // D4  - Red SOS Button (INPUT_PULLUP)
#define SOUND_PIN     18   // D18 - Microphone Digital Out (Scream Sensor)
#define BUZZER_PIN    19   // D19 - Deterrent Siren Buzzer
#define RED_LED_PIN   23   // D23 - Red Emergency LED (Strobe)
#define GREEN_LED_PIN  5   // D5  - Green Status LED

#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT  64
#define OLED_RESET     -1
#define SCREEN_ADDRESS 0x3C

// ================= BLE DEFINITIONS =================
#define DEVICE_NAME         "Raksha-IoT-SOS"
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define ALERT_CHAR_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define COMMAND_CHAR_UUID   "beb5483f-36e1-4688-b7f5-ea07361b26a8"

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ================= 1. PACKET ORIGIN & DEDUPLICATION SCHEMA =================
#pragma pack(push, 1)
typedef struct {
    char packetId[16];
    uint8_t originMac[6];
    uint8_t relayMac[6];
    uint8_t alertType;
    int32_t latE7;
    int32_t lngE7;
    uint32_t timestamp;
    uint8_t ttlHops;
} SosMeshPacket;
#pragma pack(pop)

#define SEEN_CACHE_SIZE 32
static char seenPacketCache[SEEN_CACHE_SIZE][16];
static uint8_t cacheIndex = 0;
String localMacStr = "";

bool isPacketInDeduplicationCache(const char* packetId) {
  for (uint8_t i = 0; i < SEEN_CACHE_SIZE; i++) {
    if (strncmp(seenPacketCache[i], packetId, 16) == 0) {
      return true; // Duplicate / Echo
    }
  }
  return false;
}

void registerPacketInDeduplicationCache(const char* packetId) {
  strncpy(seenPacketCache[cacheIndex], packetId, 16);
  cacheIndex = (cacheIndex + 1) % SEEN_CACHE_SIZE;
}

// BLE Server & Characteristics
BLEServer* pServer = NULL;
BLECharacteristic* pAlertCharacteristic = NULL;
BLECharacteristic* pCommandCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// System States
bool isOutboundActive = false;
bool responderAlertActive = false;
String alertSource = "NONE";
unsigned long alertStartTime = 0;
unsigned long lastResetTime = 0;
unsigned long micMuteUntil = 0;
unsigned long lastHeartbeatTime = 0;

int lastButtonState = HIGH;
volatile bool soundDetected = false;
volatile unsigned long lastSoundEdge = 0;

void IRAM_ATTR soundISR() {
  soundDetected = true;
  lastSoundEdge = millis();
}

// Forward Declarations
void triggerSosOutbound(String source);
void handleInboundSosAlert(String alertId, String originMac, String source);
void resetAlert();
void soundSiren();
void renderSafeScreen();
void renderOutboundScreen();
void renderRemoteMeshScreen();
void handleCommand(String cmd);

// ================= BLE SERVER CALLBACKS =================
class ServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("{\"event\":\"BLE_CONNECTED\"}");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("{\"event\":\"BLE_DISCONNECTED\"}");
  }
};

// ================= BLE COMMAND CALLBACKS =================
class CommandCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue().c_str();
    if (rxValue.length() > 0) {
      rxValue.trim();
      Serial.print("{\"event\":\"BLE_CMD_RECEIVED\",\"cmd\":\"");
      Serial.print(rxValue);
      Serial.println("\"}");
      handleCommand(rxValue);
    }
  }
};

void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.println("{\"system\":\"Raksha IoT Node v2.2 (Loop-Free Mesh) Starting...\"}");

  // Pin Configuration
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(SOUND_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(GREEN_LED_PIN, OUTPUT);

  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(GREEN_LED_PIN, HIGH);

  // Attach Microphone Hardware Interrupt
  attachInterrupt(digitalPinToInterrupt(SOUND_PIN), soundISR, FALLING);

  // Initialize OLED Display
  if(!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println("{\"warning\":\"SSD1306 OLED not found at 0x3C\"}");
  } else {
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(14, 20);
    display.println("RAKSHA-NET");
    display.setCursor(8, 36);
    display.println("Mesh Node Ready");
    display.display();
    delay(1000);
  }

  // Initialize BLE Stack
  BLEDevice::init(DEVICE_NAME);
  localMacStr = BLEDevice::getAddress().toString().c_str();
  localMacStr.toUpperCase();
  Serial.print("{\"local_mac\":\"");
  Serial.print(localMacStr);
  Serial.println("\"}");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pAlertCharacteristic = pService->createCharacteristic(
                      ALERT_CHAR_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pAlertCharacteristic->addDescriptor(new BLE2902());

  pCommandCharacteristic = pService->createCharacteristic(
                      COMMAND_CHAR_UUID,
                      BLECharacteristic::PROPERTY_WRITE
                    );
  pCommandCharacteristic->setCallbacks(new CommandCallbacks());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("{\"status\":\"BLE_ADVERTISING_ACTIVE\",\"device\":\"" DEVICE_NAME "\"}");

  renderSafeScreen();
}

void loop() {
  // 1. RESTART BLE ADVERTISING IF DISCONNECTED
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("{\"status\":\"BLE_ADVERTISING_RESTARTED\"}");
    oldDeviceConnected = deviceConnected;
    renderSafeScreen();
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    renderSafeScreen();
  }

  // 2. CHECK SERIAL INPUT (For USB-OTG or PC / Laptop Bridge)
  if (Serial.available() > 0) {
    String serialLine = Serial.readStringUntil('\n');
    serialLine.trim();
    if (serialLine.length() > 0) {
      handleCommand(serialLine);
    }
  }

  // 3. READ HARDWARE SENSORS
  int currentButton = digitalRead(BUTTON_PIN);

  // 4. BUTTON PRESS (Originator SOS - Non-Self-Alarming)
  if (currentButton == LOW && lastButtonState == HIGH) {
    delay(50); // Debounce
    if (digitalRead(BUTTON_PIN) == LOW) {
      if (isOutboundActive || responderAlertActive) {
        resetAlert();
      } else {
        triggerSosOutbound("BUTTON");
      }
      delay(300);
    }
  }
  lastButtonState = currentButton;

  // 5. RESPONDER ACTIVE ALARM (Siren rings ONLY on peer responder nodes)
  if (responderAlertActive) {
    soundSiren();
    if (millis() - alertStartTime > 20000) {
      resetAlert();
    }
    return;
  }

  // 6. NORMAL MONITORING STATE (Acoustic Scream / Loud Voice Detection)
  digitalWrite(GREEN_LED_PIN, isOutboundActive ? LOW : HIGH);

  if (!isOutboundActive && !responderAlertActive && millis() > micMuteUntil && (millis() - lastResetTime > 3000)) {
    bool micActive = (digitalRead(SOUND_PIN) == LOW);
    if (soundDetected || micActive) {
      soundDetected = false;
      triggerSosOutbound("SCREAM");
      return;
    }
  }

  // 7. PERIODIC HEARTBEAT TELEMETRY (Every 5 seconds)
  if (millis() - lastHeartbeatTime > 5000) {
    lastHeartbeatTime = millis();
    String heartbeat = "{\"event\":\"HEARTBEAT\",\"connected\":" + String(deviceConnected ? "true" : "false") + ",\"outbound\":" + String(isOutboundActive ? "true" : "false") + "}";
    Serial.println(heartbeat);
  }

  delay(15);
}

// Process Commands from Phone App or Serial Mesh
void handleCommand(String cmd) {
  cmd.toUpperCase();
  if (cmd.startsWith("REMOTE_ALERT") || cmd.startsWith("INBOUND_SOS") || cmd == "SIREN_ON") {
    // Inbound alert from another node
    handleInboundSosAlert("INBOUND_" + String(millis()), "REMOTE_NODE", "MESH");
  } else if (cmd == "SIREN_OFF" || cmd == "RESET" || cmd == "DISMISS") {
    resetAlert();
  } else if (cmd == "PING") {
    String pong = "{\"event\":\"PONG\",\"connected\":" + String(deviceConnected ? "true" : "false") + ",\"outbound\":" + String(isOutboundActive ? "true" : "false") + "}";
    Serial.println(pong);
  }
}

// ================= 3. SENDER-SIDE STATE SEPARATION =================
// OUTBOUND: Initiated by user pressing the button or scream sensor.
// Silent on sender (NO continuous deterrent siren, NO self-trigger loop).
void triggerSosOutbound(String source) {
  isOutboundActive = true;
  soundDetected = false;

  // Short haptic confirmation beep (100ms) only, NO SIREN
  digitalWrite(BUZZER_PIN, HIGH);
  delay(80);
  digitalWrite(BUZZER_PIN, LOW);

  digitalWrite(GREEN_LED_PIN, LOW);
  digitalWrite(RED_LED_PIN, HIGH); // Steady red indicator

  char newPacketId[16];
  snprintf(newPacketId, sizeof(newPacketId), "%08X%04X", (uint32_t)millis(), esp_random() & 0xFFFF);
  registerPacketInDeduplicationCache(newPacketId);

  // Send JSON event over Serial/USB Bridge with origin_device_id
  String jsonPayload = "{\"event\":\"SOS_TRIGGERED\",\"source\":\"" + source + "\",\"packet_id\":\"" + String(newPacketId) + "\",\"origin_device_id\":\"" + localMacStr + "\",\"timestamp\":" + String(millis()) + "}";
  Serial.println(jsonPayload);

  // Send BLE Notification to Mobile App
  if (pAlertCharacteristic != NULL) {
    pAlertCharacteristic->setValue(jsonPayload.c_str());
    pAlertCharacteristic->notify();
  }

  renderOutboundScreen();
}

// INBOUND: Executed ONLY when remote alert packet arrives from a PEER node
void handleInboundSosAlert(String alertId, String originMac, String source) {
  // GUARD 1: Originator check - Drop if this node sent it
  if (originMac.length() > 0 && originMac == localMacStr) {
    return;
  }

  // GUARD 2: Multi-Hop Deduplication Ring Buffer
  if (isPacketInDeduplicationCache(alertId.c_str())) {
    return;
  }
  registerPacketInDeduplicationCache(alertId.c_str());

  // Trigger responder siren & strobe on this node
  responderAlertActive = true;
  alertSource = "REMOTE_MESH";
  alertStartTime = millis();
  digitalWrite(GREEN_LED_PIN, LOW);

  renderRemoteMeshScreen();
  Serial.println("{\"status\":\"RESPONDER_ALARM_ACTIVE\",\"alert_id\":\"" + alertId + "\"}");
}

void resetAlert() {
  isOutboundActive = false;
  responderAlertActive = false;
  alertSource = "NONE";
  lastResetTime = millis();
  micMuteUntil = millis() + 4000;
  soundDetected = false;

  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(GREEN_LED_PIN, HIGH);

  String resetPayload = "{\"event\":\"ALERT_RESET\",\"timestamp\":" + String(millis()) + "}";
  Serial.println(resetPayload);

  if (pAlertCharacteristic != NULL) {
    pAlertCharacteristic->setValue(resetPayload.c_str());
    pAlertCharacteristic->notify();
  }

  renderSafeScreen();
}

void soundSiren() {
  for (int hz = 1000; hz <= 2600; hz += 80) {
    tone(BUZZER_PIN, hz);
    digitalWrite(RED_LED_PIN, (hz % 160 == 0) ? HIGH : LOW);
    delay(4);
    if (!responderAlertActive) {
      noTone(BUZZER_PIN);
      return;
    }
  }
  for (int hz = 2600; hz >= 1000; hz -= 80) {
    tone(BUZZER_PIN, hz);
    digitalWrite(RED_LED_PIN, (hz % 160 == 0) ? HIGH : LOW);
    delay(4);
    if (!responderAlertActive) {
      noTone(BUZZER_PIN);
      return;
    }
  }
  noTone(BUZZER_PIN);
}

void renderSafeScreen() {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.print("RAKSHA NODE: SAFE");

  display.setCursor(0, 18);
  display.print("Status: ARMED");
  display.setCursor(0, 32);
  display.print("Link: ");
  display.print(deviceConnected ? "PHONE CONNECTED" : "OFFLINE MESH");

  display.setCursor(0, 48);
  display.print("MAC: ");
  display.print(localMacStr.substring(9));

  display.display();
}

void renderOutboundScreen() {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.print(">> SOS OUTBOUND <<");

  display.setTextSize(2);
  display.setCursor(14, 20);
  display.print("ACTIVE");

  display.setTextSize(1);
  display.setCursor(0, 44);
  display.print("Responders Alerted");
  display.setCursor(0, 56);
  display.print("Press button to cancel");

  display.display();
}

void renderRemoteMeshScreen() {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.print("!! DISTRESS ALERT !!");

  display.setTextSize(2);
  display.setCursor(8, 20);
  display.print("PEER SOS");

  display.setTextSize(1);
  display.setCursor(0, 46);
  display.print("Help needed nearby!");
  display.display();
}
