/*
  =================================================================================
  SENTINEL-Ward: Integrated ESP32 Gateway (nRF24 Receiver + Wi-Fi HTTP Dispatcher)
  =================================================================================

  Compatible with:
    - Transmitter: Arduino Pro Mini (Channel 76, 250kbps, ADDRESS "NODE1")
    - Packet Struct: SensorPacket (6 bytes: packetId, temperatureX10, heartRate, spo2)
    - Backend Server: Node.js Express on Port 3000 (POST /api/telemetry/ingest)

  Wiring (nRF24L01 -> ESP32):
    GND -> GND | VCC -> 3V3 (+10uF decoupling capacitor across VCC/GND)
    CE  -> GPIO 4  | CSN -> GPIO 5
    SCK -> GPIO 18 | MOSI -> GPIO 23 | MISO -> GPIO 19

  Libraries required in Arduino IDE:
    - "RF24" by TMRh20 (via Library Manager)
    - Built-in ESP32 core: WiFi.h, HTTPClient.h, SPI.h
  Board: ESP32 Dev Module
*/

#include <SPI.h>
#include <RF24.h>
#include <WiFi.h>
#include <HTTPClient.h>

// ====== 1. nRF24 CONFIGURATION (Matches Pro Mini Transmitter Exactly) ======
const byte ADDRESS[6]           = "NODE1";
const uint8_t CHANNEL           = 76;
const rf24_datarate_e DATA_RATE = RF24_250KBPS;

// Packet layout matching Pro Mini Transmitter (6 bytes, no padding)
struct SensorPacket {
  uint16_t packetId;
  int16_t  temperatureX10;   // e.g., 366 = 36.6 C
  uint8_t  heartRate;        // beats per minute
  uint8_t  spo2;             // blood oxygen percent
};

const uint8_t PIN_CE  = 4;
const uint8_t PIN_CSN = 5;
RF24 radio(PIN_CE, PIN_CSN);

// ====== 2. NETWORK & SERVER CONFIGURATION ======
// Replace with your local Wi-Fi network credentials
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Replace with your development computer's IPv4 address (found via 'ipconfig')
// Note: Do not use 'localhost' or '127.0.0.1' - use the local LAN IP (e.g., 192.168.1.142)
const char* SERVER_URL    = "http://192.168.1.142:3000/api/telemetry/ingest";

// Assigned Bed ID for this sensor node
const char* BED_ID        = "bed_01";

// State tracking
SensorPacket packet;
bool gotFirst = false;
uint16_t lastId = 0;
uint32_t receivedCount = 0, lostCount = 0;
unsigned long lastRxTime = 0;
unsigned long lastHttpSendTime = 0;
const unsigned long MIN_HTTP_INTERVAL_MS = 1000; // Rate limit HTTP dispatches to 1Hz

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println(F("\n========================================================"));
  Serial.println(F("🛡️ SENTINEL-Ward: ESP32 Central Telemetry Gateway"));
  Serial.println(F("========================================================"));

  // 1. Initialize Wi-Fi in Station Mode
  Serial.print(F("Connecting to Wi-Fi: "));
  Serial.println(WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 25) {
    delay(300);
    Serial.print(F("."));
    wifiAttempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(F("\n✅ Wi-Fi Connected!"));
    Serial.print(F("🌐 ESP32 IP Address: "));
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(F("\n⚠️ Wi-Fi connection timed out. Will retry in background loop."));
  }

  // 2. Initialize nRF24L01 Radio
  SPI.begin(18, 19, 23, PIN_CSN); // SCK, MISO, MOSI, SS

  if (!radio.begin() || !radio.isChipConnected()) {
    Serial.println(F("❌ nRF24L01 NOT detected! Check wiring, 3V3 power, and 10uF cap."));
    while (true) { delay(1000); }
  }

  radio.setChannel(CHANNEL);
  radio.setDataRate(DATA_RATE);
  radio.setPALevel(RF24_PA_LOW);
  radio.openReadingPipe(1, ADDRESS);
  radio.startListening();

  lastRxTime = millis();
  Serial.println(F("✅ nRF24L01 Radio Online (Channel 76, 250kbps, Pipe: NODE1)"));
  Serial.println(F("🚀 Listening for Pro Mini bedside sensor packets...\n"));
}

void loop() {
  // 1. Check for incoming radio packets from Pro Mini
  while (radio.available()) {
    radio.read(&packet, sizeof(packet));
    lastRxTime = millis();
    receivedCount++;

    if (gotFirst) {
      uint16_t gap = (uint16_t)(packet.packetId - lastId - 1);
      if (gap > 0 && gap < 1000) lostCount += gap;
    }
    gotFirst = true;
    lastId = packet.packetId;

    float temperatureC = packet.temperatureX10 / 10.0;

    Serial.printf("[RF RX] #%u | T=%.1f C | HR=%u bpm | SpO2=%u %% | Rx=%lu Lost=%lu\n",
                  packet.packetId,
                  temperatureC,
                  packet.heartRate,
                  packet.spo2,
                  (unsigned long)receivedCount, (unsigned long)lostCount);

    // 2. Forward telemetry to Node.js backend if Wi-Fi connected
    if (millis() - lastHttpSendTime >= MIN_HTTP_INTERVAL_MS) {
      lastHttpSendTime = millis();
      forwardTelemetryToBackend(packet, temperatureC);
    }
  }

  // 3. Keep Wi-Fi alive
  if (WiFi.status() != WL_CONNECTED) {
    WiFi.reconnect();
  }

  // 4. RF Link Liveness Check
  if (millis() - lastRxTime > 5000) {
    Serial.println(F("⚠️ No RF packet received for 5s. Check Pro Mini power & range."));
    lastRxTime = millis();
  }

  delay(5);
}

/**
 * Dispatches the received vitals packet to the Node.js Backend Server via HTTP POST
 */
void forwardTelemetryToBackend(SensorPacket p, float tempC) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println(F("  ⚠️ Cannot forward: Wi-Fi Disconnected"));
    return;
  }

  // Physiological validation: reject obviously corrupted RF packets
  if (p.heartRate < 25 || p.heartRate > 240 || p.spo2 > 100 || p.spo2 < 50 || tempC < 25.0 || tempC > 45.0) {
    Serial.printf("  ⚠️ Discarded physiologically invalid reading: HR=%u SpO2=%u T=%.1f\n", p.heartRate, p.spo2, tempC);
    return;
  }

  HTTPClient http;
  http.begin(SERVER_URL);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(1200); // 1.2s fast timeout to avoid blocking radio reception

  // Construct JSON payload conforming exactly to backend/server.js /api/telemetry/ingest
  String json = "{";
  json += "\"bedId\":\"" + String(BED_ID) + "\",";
  json += "\"heartRate\":" + String(p.heartRate) + ",";
  json += "\"spo2\":" + String(p.spo2) + ",";
  json += "\"temperature\":" + String(tempC, 1) + ",";
  json += "\"rssi\":-60,";
  json += "\"batteryPercent\":100";
  json += "}";

  int httpCode = http.POST(json);

  if (httpCode == HTTP_CODE_OK || httpCode == 201) {
    Serial.printf("  📤 Forwarded to Backend -> HTTP 200 OK (%s)\n", BED_ID);
  } else if (httpCode > 0) {
    Serial.printf("  ⚠️ Server returned HTTP code: %d\n", httpCode);
  } else {
    Serial.printf("  ⚠️ HTTP POST failed: %s\n", http.errorToString(httpCode).c_str());
  }

  http.end();
}
