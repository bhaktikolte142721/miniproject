/*
 * SENTINEL-Ward: Bedside Patient Sensor Node Firmware (Transmitter)
 * 
 * Hardware:
 *  - Microcontroller: Arduino Nano / ESP8266 / ESP32
 *  - Radio: nRF24L01+ 2.4GHz Transceiver Module
 *  - Sensors:
 *      * MAX30102 / MAX30100 (Pulse Oximeter & Heart Rate) via I2C (SDA/SCL)
 *      * DS18B20 / LM35 (Body Temperature Sensor)
 *      * Battery Voltage Divider on Analog Pin (A0)
 * 
 * Function:
 *  - Reads physiological vitals from bedside patient sensors
 *  - Packages data into TelemetryPayload packet
 *  - Transmits via 2.4GHz RF to ESP32 Central Ward Gateway
 */

#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

// --- Configure for this Bed ---
#define BED_ID "bed_01"   // Change to "bed_02" or "bed_03" for other nodes
const byte pipeAddress[6] = "BED01"; // Must match gateway pipe ("BED01", "BED02", "BED03")

// --- nRF24 Pinout (Arduino Nano / Uno default) ---
#define CE_PIN   9
#define CSN_PIN  10

RF24 radio(CE_PIN, CSN_PIN);

// Telemetry Payload Structure (Must exactly match Gateway structure)
struct TelemetryPayload {
  char bedId[8];       // "bed_01", "bed_02", "bed_03"
  uint16_t heartRate;  // BPM (e.g., 72)
  uint8_t spo2;        // % (e.g., 99)
  float temperature;   // °C (e.g., 36.8)
  uint8_t battery;     // % (e.g., 95)
};

void setup() {
  Serial.begin(115200);
  Serial.println("🛡️ SENTINEL-Ward Bedside Sensor Node Starting...");

  // Initialize nRF24 Radio
  if (!radio.begin()) {
    Serial.println("❌ nRF24 radio hardware not responding!");
    while (1);
  }

  radio.setPALevel(RF24_PA_HIGH);
  radio.setDataRate(RF24_250KBPS); // Long range configuration
  radio.setChannel(108);           // Matched to ESP32 Gateway channel
  radio.openWritingPipe(pipeAddress);
  radio.stopListening();           // Set as Transmitter

  Serial.println("📡 nRF24 Ready. Transmitting to Pipe: " + String((char*)pipeAddress));
}

void loop() {
  TelemetryPayload payload;
  strncpy(payload.bedId, BED_ID, sizeof(payload.bedId));

  // --- Read Real Sensors (Simulated fallback if sensor detached) ---
  payload.heartRate = readHeartRateSensor();
  payload.spo2 = readSpO2Sensor();
  payload.temperature = readTemperatureSensor();
  payload.battery = readBatteryLevel();

  // Transmit payload over RF
  bool success = radio.write(&payload, sizeof(payload));

  if (success) {
    Serial.printf("✅ Packet Sent [%s] -> HR: %d BPM, SpO2: %d%%, Temp: %.1fC, Bat: %d%%\n",
                  payload.bedId, payload.heartRate, payload.spo2, payload.temperature, payload.battery);
  } else {
    Serial.println("⚠️ Transmission failed (Gateway out of range or ACK missed)");
  }

  // Transmit every 1.5 seconds
  delay(1500);
}

// Sensor helper stubs (integrate your MAX30102 / DS18B20 libraries here)
uint16_t readHeartRateSensor() {
  // Replace with: particleSensor.getHeartRate()
  return 70 + random(0, 5);
}

uint8_t readSpO2Sensor() {
  // Replace with: particleSensor.getSpO2()
  return 98 + random(0, 2);
}

float readTemperatureSensor() {
  // Replace with: sensors.getTempCByIndex(0)
  return 36.6 + (random(0, 4) / 10.0);
}

uint8_t readBatteryLevel() {
  // Replace with analogRead(A0) battery calculation
  return 94;
}
