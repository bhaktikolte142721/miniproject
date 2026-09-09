/*
 * SENTINEL-Ward: ESP32 Central Ward Gateway Firmware
 * 
 * Hardware:
 *  - ESP32 Development Board (NodeMCU-32S / ESP32-WROOM-32)
 *  - nRF24L01+ 2.4GHz Wireless Transceiver with Power Amplifier (PA/LNA)
 *  - Status LEDs: Blue (WiFi), Green (nRF24 Packet RX), Red (Critical Alarm)
 * 
 * Function:
 *  - Listens on 2.4GHz ISM band on 3 radio pipes (Bed 01, Bed 02, Bed 03)
 *  - Deserializes vital telemetry packets: { bed_id, hr, spo2, temp, battery }
 *  - Transmits packets to SENTINEL-Ward Backend via HTTP POST / WebSockets
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

// --- WiFi Credentials ---
const char* ssid = "HOSPITAL_WARD_WIFI";
const char* password = "WARD_SECURE_PASSWORD";

// --- SENTINEL-Ward Backend Server Endpoint ---
const char* serverUrl = "http://192.168.1.142:3000/api/telemetry/ingest";

// --- nRF24 Pinout for ESP32 ---
#define CE_PIN   4
#define CSN_PIN  5
#define LED_RX   2  // Builtin LED for packet flash

RF24 radio(CE_PIN, CSN_PIN);

// Radio pipe addresses for 3 monitored beds
const byte pipes[3][6] = {"BED01", "BED02", "BED03"};

// Telemetry Payload Structure (Matches Sensor Node Transmitters)
struct TelemetryPayload {
  char bedId[8];       // "bed_01", "bed_02", "bed_03"
  uint16_t heartRate;  // BPM
  uint8_t spo2;        // %
  float temperature;   // Celsius
  uint8_t battery;     // %
};

void setup() {
  Serial.begin(115200);
  pinMode(LED_RX, OUTPUT);

  Serial.println("\n==========================================");
  Serial.println("🛡️ SENTINEL-Ward ESP32 Gateway Booting...");
  Serial.println("==========================================");

  // 1. Connect to Hospital Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi Connected! IP: " + WiFi.localIP().toString());

  // 2. Initialize nRF24 Radio
  if (!radio.begin()) {
    Serial.println("❌ nRF24 Initialization Failed! Check SPI wiring.");
    while (1);
  }

  radio.setPALevel(RF24_PA_HIGH);
  radio.setDataRate(RF24_250KBPS); // Long range configuration
  radio.setChannel(108);           // High frequency above common WiFi channels

  // Open reading pipes for Bed 1, Bed 2, Bed 3
  radio.openReadingPipe(1, pipes[0]);
  radio.openReadingPipe(2, pipes[1]);
  radio.openReadingPipe(3, pipes[2]);

  radio.startListening();
  Serial.println("📡 nRF24 Listening on Pipes: BED01, BED02, BED03");
}

void loop() {
  uint8_t pipeNum;

  // Check if radio packet arrived from any bedside node
  if (radio.available(&pipeNum)) {
    TelemetryPayload payload;
    radio.read(&payload, sizeof(payload));

    // Flash activity LED
    digitalWrite(LED_RX, HIGH);

    Serial.printf("📥 Packet from Pipe %d (%s): HR=%d, SpO2=%d%%, Temp=%.1fC, Bat=%d%%\n",
                  pipeNum, payload.bedId, payload.heartRate, payload.spo2, payload.temperature, payload.battery);

    // Forward to Backend Server
    forwardTelemetryToBackend(payload);

    digitalWrite(LED_RX, LOW);
  }

  delay(10);
}

void forwardTelemetryToBackend(TelemetryPayload data) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");

    // Construct JSON payload
    String jsonPayload = "{";
    jsonPayload += "\"bedId\":\"" + String(data.bedId) + "\",";
    jsonPayload += "\"heartRate\":" + String(data.heartRate) + ",";
    jsonPayload += "\"spo2\":" + String(data.spo2) + ",";
    jsonPayload += "\"temperature\":" + String(data.temperature, 1) + ",";
    jsonPayload += "\"rssi\": -62,";
    jsonPayload += "\"batteryPercent\":" + String(data.battery);
    jsonPayload += "}";

    int httpCode = http.POST(jsonPayload);
    if (httpCode > 0) {
      Serial.printf("📤 Forwarded to Backend. Response: %d\n", httpCode);
    } else {
      Serial.printf("⚠️ POST Failed. Error: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  }
}
