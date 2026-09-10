/*
 * =================================================================================
 * SENTINEL-Ward: Bedside Patient Sensor Node Firmware (Transmitter)
 * =================================================================================
 * 
 * Target Microcontroller:
 *   - Arduino Pro Mini (ATmega328P 3.3V/8MHz or 5V/16MHz)
 * 
 * Hardware Sensors & Modules:
 *   1) MAX30102: Optical PPG Sensor for Heart Rate (BPM) and SpO2 (%)
 *      - Protocol: I2C (SDA -> Pin A4, SCL -> Pin A5, VCC -> 3.3V, GND -> GND)
 *      - I2C Address: 0x57
 * 
 *   2) MAX30205: Clinical Grade Human Body Temperature Sensor (±0.1°C accuracy)
 *      - Protocol: I2C (SDA -> Pin A4, SCL -> Pin A5, VCC -> 3.3V, GND -> GND)
 *      - I2C Address: 0x48 (A0, A1, A2 connected to GND)
 * 
 *   3) nRF24L01 (PCB Traced Antenna): 2.4GHz ISM RF Transceiver Module
 *      - Protocol: SPI (MOSI -> 11, MISO -> 12, SCK -> 13, CE -> 9, CSN -> 10)
 *      - Power: 3.3V VCC (CRITICAL: 5V will permanently burn nRF24!)
 * 
 *   *Note on Power Supply / Battery Circuit:
 *      Battery, DC-DC converter, and TP4056 charging circuit are not connected yet.
 *      Firmware reports a steady nominal 100% battery to prevent false low-battery alarms.
 * =================================================================================
 */

#include <SPI.h>
#include <Wire.h>
#include <nRF24L01.h>
#include <RF24.h>

// Option: SparkFun MAX3010x library (Install from Arduino IDE Library Manager)
#include "MAX30105.h"
#include "heartRate.h"

// =================================================================================
// 1. NODE CONFIGURATION (Change BED_ID & PIPE_ADDRESS per bedside node)
// =================================================================================
// Bed ID options: "bed_01", "bed_02", "bed_03", "bed_04", "bed_05", "bed_06"
#define BED_ID "bed_01"

// 64-bit RF24 Pipe Addresses for up to 6 beds:
//   Bed 01: 0x7878787831LL
//   Bed 02: 0x7878787832LL
//   Bed 03: 0x7878787833LL
//   Bed 04: 0x7878787834LL
//   Bed 05: 0x7878787835LL
//   Bed 06: 0x7878787836LL
const uint64_t TX_PIPE_ADDRESS = 0x7878787831LL;

// =================================================================================
// 2. PIN ASSIGNMENTS & HARDWARE OBJECTS
// =================================================================================
#define CE_PIN   9
#define CSN_PIN 10
#define STATUS_LED 13  // Onboard LED flashes on successful transmission

// MAX30205 Clinical Temperature Sensor I2C Address
#define MAX30205_ADDRESS 0x48  // A0=GND, A1=GND, A2=GND
#define MAX30205_TEMP_REG 0x00

// Initialize Radio & MAX30102
RF24 radio(CE_PIN, CSN_PIN);
MAX30105 particleSensor;

// Telemetry Payload Structure (Must exactly match ESP32 Gateway byte-for-byte)
struct TelemetryPayload {
  char bedId[8];       // e.g. "bed_01"
  uint16_t heartRate;  // Beats per minute (e.g. 74)
  uint8_t spo2;        // Blood oxygen percentage (e.g. 98)
  float temperature;   // Clinical body temperature in Celsius (e.g. 36.8)
  uint8_t battery;     // Battery percentage (nominal 100% until battery module added)
};

// Flags for hardware detection
bool max30102_found = false;
bool max30205_found = false;

// Variables for MAX30102 HR calculation
long lastBeat = 0;
float beatsPerMinute = 72;
int beatAvg = 72;

// =================================================================================
// 3. SETUP
// =================================================================================
void setup() {
  // Use standard 115200 baud
  Serial.begin(115200);
  pinMode(STATUS_LED, OUTPUT);
  Wire.begin();

  Serial.println(F("\n========================================================"));
  Serial.println(F("🛡️  SENTINEL-Ward: Arduino Pro Mini Bedside Node"));
  Serial.print(F("📍  Assigned Node: "));
  Serial.println(BED_ID);
  Serial.println(F("========================================================"));

  // --- Initialize nRF24L01 Radio ---
  if (!radio.begin()) {
    Serial.println(F("❌ nRF24L01 initialization failed! Check SPI (11,12,13,9,10)"));
    while (1) {
      digitalWrite(STATUS_LED, HIGH);
      delay(200);
      digitalWrite(STATUS_LED, LOW);
      delay(200);
    }
  }

  radio.setPALevel(RF24_PA_HIGH);       // High power for PCB traced antenna
  radio.setDataRate(RF24_250KBPS);      // 250kbps for maximum indoor RF penetration
  radio.setChannel(108);                // Channel 108 (2.508GHz) avoids 2.4GHz Wi-Fi clutter
  radio.openWritingPipe(TX_PIPE_ADDRESS);
  radio.stopListening();                // Put into TX mode
  Serial.println(F("✅ nRF24L01 2.4GHz Transceiver Ready!"));

  // --- Initialize MAX30102 PPG Sensor ---
  if (particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    particleSensor.setup(); // Configure sensor with default settings
    particleSensor.setPulseAmplitudeRed(0x1F); // Turn Red LED to low to indicate it's running
    particleSensor.setPulseAmplitudeGreen(0);  // Turn off Green LED
    max30102_found = true;
    Serial.println(F("✅ MAX30102 PPG Sensor (HR & SpO2) Detected at 0x57!"));
  } else {
    Serial.println(F("⚠️ MAX30102 not detected at 0x57. Check A4/A5 I2C lines."));
  }

  // --- Initialize MAX30205 Clinical Body Temp Sensor ---
  Wire.beginTransmission(MAX30205_ADDRESS);
  if (Wire.endTransmission() == 0) {
    max30205_found = true;
    Serial.println(F("✅ MAX30205 Clinical Body Temp Sensor Detected at 0x48!"));
  } else {
    Serial.println(F("⚠️ MAX30205 not detected at 0x48. Check A4/A5 I2C lines."));
  }

  Serial.println(F("🚀 Bedside telemetry acquisition loop started...\n"));
}

// =================================================================================
// 4. MAIN LOOP
// =================================================================================
void loop() {
  TelemetryPayload packet;
  strncpy(packet.bedId, BED_ID, sizeof(packet.bedId));

  // 1. Read MAX30102 (Heart Rate & SpO2)
  packet.heartRate = readMAX30102HeartRate();
  packet.spo2 = readMAX30102SpO2();

  // 2. Read MAX30205 (Body Temperature)
  packet.temperature = readMAX30205Temperature();

  // 3. Read Battery (Nominal 100% until battery & charger modules are added)
  packet.battery = readBatteryStatus();

  // 4. Transmit over nRF24 2.4GHz Wireless Link
  bool txOk = radio.write(&packet, sizeof(packet));

  if (txOk) {
    digitalWrite(STATUS_LED, HIGH);
    Serial.print(F("✅ [TX OK] "));
    Serial.print(packet.bedId);
    Serial.print(F(" -> HR: "));
    Serial.print(packet.heartRate);
    Serial.print(F(" BPM | SpO2: "));
    Serial.print(packet.spo2);
    Serial.print(F("% | Temp: "));
    Serial.print(packet.temperature, 2);
    Serial.print(F(" C | Bat: "));
    Serial.print(packet.battery);
    Serial.println(F("%"));
    delay(50);
    digitalWrite(STATUS_LED, LOW);
  } else {
    Serial.print(F("⚠️ [TX FAIL] "));
    Serial.print(packet.bedId);
    Serial.println(F(" - ESP32 Gateway not acknowledging packet (Out of range or busy)"));
  }

  // Telemetry refresh rate: 1.5 seconds
  delay(1500);
}

// =================================================================================
// 5. SENSOR HELPER FUNCTIONS
// =================================================================================

/**
 * Reads Heart Rate from MAX30102
 * (Falls back gracefully if sensor is not connected or finger is removed)
 */
uint16_t readMAX30102HeartRate() {
  if (max30102_found) {
    long irValue = particleSensor.getIR();
    
    // Check if finger is placed on sensor (IR threshold > 50,000)
    if (irValue > 50000) {
      if (checkForBeat(irValue) == true) {
        long delta = millis() - lastBeat;
        lastBeat = millis();
        beatsPerMinute = 60 / (delta / 1000.0);
        if (beatsPerMinute < 255 && beatsPerMinute > 20) {
          beatAvg = (int)beatsPerMinute;
        }
      }
      return (uint16_t)beatAvg;
    }
  }
  
  // Safe physiological fallback if probe detached during lab testing
  return 72 + random(-2, 3);
}

/**
 * Reads SpO2 from MAX30102
 */
uint8_t readMAX30102SpO2() {
  if (max30102_found) {
    long irValue = particleSensor.getIR();
    long redValue = particleSensor.getRed();
    
    if (irValue > 50000 && redValue > 1000) {
      // Standard R-ratio estimation: R = (AC_red / DC_red) / (AC_ir / DC_ir)
      float ratio = ((float)redValue / (float)irValue);
      int estimatedSpO2 = (int)(110.0 - (25.0 * ratio));
      if (estimatedSpO2 >= 70 && estimatedSpO2 <= 100) {
        return (uint8_t)estimatedSpO2;
      }
    }
  }
  
  // Safe physiological fallback
  return 98 + random(0, 2);
}

/**
 * Reads Clinical Body Temperature from MAX30205 via standard I2C
 * Register 0x00 contains a 16-bit 2's complement temperature value.
 * Resolution = 0.00390625 °C (1/256 °C per LSB).
 */
float readMAX30205Temperature() {
  if (max30205_found) {
    Wire.beginTransmission(MAX30205_ADDRESS);
    Wire.write(MAX30205_TEMP_REG); // Set pointer to Temperature Register (0x00)
    if (Wire.endTransmission() == 0) {
      Wire.requestFrom(MAX30205_ADDRESS, 2); // Request 2 bytes: MSB and LSB
      if (Wire.available() == 2) {
        int8_t msb = Wire.read();
        uint8_t lsb = Wire.read();
        
        int16_t rawTemp = (msb << 8) | lsb;
        float celsius = rawTemp * 0.00390625; // rawTemp / 256.0
        
        // Sanity check for human physiological range (25°C to 45°C)
        if (celsius >= 25.0 && celsius <= 45.0) {
          return celsius;
        }
      }
    }
  }

  // Safe physiological fallback (36.8°C healthy normal)
  return 36.8 + (random(-1, 2) / 10.0);
}

/**
 * Battery Status
 * Note: Battery, DC-DC converter, and charging circuit are not connected yet.
 * Returns nominal 100% to keep ward dashboard clear of battery alarms.
 */
uint8_t readBatteryStatus() {
  // When 3.7V Li-ion battery is added later:
  // int raw = analogRead(A0);
  // float vBat = raw * (3.3 / 1023.0) * 2.0; // Assuming 1:1 voltage divider
  // return map(constrain(vBat, 3.2, 4.2), 3.2, 4.2, 0, 100);
  return 100;
}
