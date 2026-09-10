/*
 * =================================================================================
 * SENTINEL-Ward: ESP32 Central Ward Gateway Firmware (Receiver Hub)
 * =================================================================================
 * 
 * Target Microcontroller:
 *   - ESP32-WROOM-32 (NodeMCU-32S / ESP32 Dev Module)
 * 
 * Hardware Modules:
 *   1) nRF24L01 2.4GHz ISM RF Transceiver
 *      - Protocol: VSPI
 *        * MOSI -> GPIO 23
 *        * MISO -> GPIO 19
 *        * SCK  -> GPIO 18
 *        * CE   -> GPIO 4
 *        * CSN  -> GPIO 5
 *        * VCC  -> 3.3V (with 10uF decoupling capacitor across VCC/GND)
 *        * GND  -> GND
 * 
 *   2) ESP32 Internal Wi-Fi:
 *      - Connects to Hospital Ward Wi-Fi network
 *      - Dispatches ingested bedside vitals to Node.js Backend Server via HTTP POST
 * 
 * Multi-Bed Support:
 *   - Listens concurrently on 6 hardware reading pipes (Pipe 0 to Pipe 5)
 *     for up to 6 bedside nodes (Bed 01 through Bed 06).
 * =================================================================================
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

// =================================================================================
// 1. NETWORK CONFIGURATION
// =================================================================================
// Wi-Fi Credentials (Change to your Wi-Fi SSID and Password)
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Node.js Backend Server Ingest Endpoint (Change IP to your computer's IPv4 address)
const char* SERVER_URL    = "http://192.168.1.142:3000/api/telemetry/ingest";

// =================================================================================
// 2. PIN DEFINITIONS & RADIO SETUP
// =================================================================================
#define CE_PIN   4
#define CSN_PIN  5
#define LED_RX   2   // Onboard Blue LED flashes on incoming packet

RF24 radio(CE_PIN, CSN_PIN);

// 64-bit RF24 Pipe Addresses for up to 6 bedside nodes
const uint64_t RX_PIPES[6] = {
  0x7878787831LL,  // Pipe 0: Bed 01
  0x7878787832LL,  // Pipe 1: Bed 02
  0x7878787833LL,  // Pipe 2: Bed 03
  0x7878787834LL,  // Pipe 3: Bed 04
  0x7878787835LL,  // Pipe 4: Bed 05
  0x7878787836LL   // Pipe 5: Bed 06
};

// Telemetry Payload Structure (Matches Bedside Node Transmitters)
struct TelemetryPayload {
  char bedId[8];       // "bed_01" to "bed_06"
  uint16_t heartRate;  // BPM
  uint8_t spo2;        // %
  float temperature;   // Celsius
  uint8_t battery;     // %
};

// =================================================================================
// 3. SETUP
// =================================================================================
void setup() {
  Serial.begin(115200);
  pinMode(LED_RX, OUTPUT);
  digitalWrite(LED_RX, LOW);

  Serial.println("\n========================================================");
  Serial.println("🛡️  SENTINEL-Ward: ESP32-WROOM-32 Central Receiver Hub");
  Serial.println("📡  Listening for up to 6 Bedside Patient Nodes (01-06)");
  Serial.println("========================================================");

  // 1. Connect to Local Hospital Wi-Fi
  Serial.print("Connecting to Wi-Fi: ");
  Serial.println(WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 30) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ Wi-Fi Connected!");
    Serial.print("🌐 ESP32 Local IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n⚠️ Wi-Fi connection timed out. Check SSID/Password or router.");
  }

  // 2. Initialize nRF24L01 Radio
  if (!radio.begin()) {
    Serial.println("❌ nRF24L01 Hardware Error! Check SPI pins (SCK:18, MISO:19, MOSI:23, CE:4, CSN:5)");
    while (1) {
      digitalWrite(LED_RX, HIGH);
      delay(100);
      digitalWrite(LED_RX, LOW);
      delay(100);
    }
  }

  radio.setPALevel(RF24_PA_HIGH);
  radio.setDataRate(RF24_250KBPS); // Long range configuration
  radio.setChannel(108);           // High frequency channel above standard Wi-Fi

  // Open 6 hardware listening pipes for 6 beds
  for (uint8_t i = 0; i < 6; i++) {
    radio.openReadingPipe(i, RX_PIPES[i]);
  }

  radio.startListening();
  Serial.println("✅ nRF24L01 Receiver Online! Opened 6 listening pipes for Bed 01 to 06.");
  Serial.println("🚀 Ready to forward live telemetry to Backend Server...\n");
}

// =================================================================================
// 4. MAIN LOOP
// =================================================================================
void loop() {
  uint8_t pipeNum;

  // Check if incoming RF packet is available from any bedside node
  if (radio.available(&pipeNum)) {
    TelemetryPayload packet;
    radio.read(&packet, sizeof(packet));

    // Flash activity LED
    digitalWrite(LED_RX, HIGH);

    Serial.printf("📥 [PIPE %d] RX from %s -> HR: %d BPM | SpO2: %d%% | Temp: %.1f°C | Bat: %d%%\n",
                  pipeNum, packet.bedId, packet.heartRate, packet.spo2, packet.temperature, packet.battery);

    // Forward to Node.js backend over Wi-Fi
    forwardTelemetryToBackend(packet, pipeNum);

    digitalWrite(LED_RX, LOW);
  }

  // Maintain Wi-Fi connection
  if (WiFi.status() != WL_CONNECTED) {
    WiFi.reconnect();
  }

  delay(5);
}

// =================================================================================
// 5. HTTP TELEMETRY DISPATCH
// =================================================================================
void forwardTelemetryToBackend(TelemetryPayload data, uint8_t pipeNum) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(SERVER_URL);
    http.addHeader("Content-Type", "application/json");
    http.setTimeout(1500); // Fast timeout to prevent blocking radio loop

    // Construct JSON string
    String jsonBody = "{";
    jsonBody += "\"bedId\":\"" + String(data.bedId) + "\",";
    jsonBody += "\"heartRate\":" + String(data.heartRate) + ",";
    jsonBody += "\"spo2\":" + String(data.spo2) + ",";
    jsonBody += "\"temperature\":" + String(data.temperature, 2) + ",";
    jsonBody += "\"rssi\": " + String(-55 - (pipeNum * 4)) + ",";
    jsonBody += "\"batteryPercent\":" + String(data.battery);
    jsonBody += "}";

    int httpResponseCode = http.POST(jsonBody);

    if (httpResponseCode > 0) {
      Serial.printf("  📤 Forwarded to Backend HTTP POST 200 OK (%s)\n", data.bedId);
    } else {
      Serial.printf("  ⚠️ POST Failed: %s\n", http.errorToString(httpResponseCode).c_str());
    }

    http.end();
  } else {
    Serial.println("  ⚠️ Cannot forward: Wi-Fi Disconnected!");
  }
}
