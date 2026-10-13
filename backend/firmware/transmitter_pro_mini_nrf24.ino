/*
  TRANSMITTER - Arduino Pro Mini + nRF24L01
  Sends a dummy vitals packet (temperature, heart rate, SpO2) once per second.

  Wiring (nRF24L01 -> Pro Mini):
    GND -> GND | VCC -> 3.3V (+10uF cap across VCC/GND)
    CE  -> D9  | CSN -> D10
    SCK -> D13 | MOSI -> D11 | MISO -> D12

  Library needed: "RF24" by TMRh20 (Library Manager)
  Board: Arduino Pro or Pro Mini (pick the processor matching your board)
*/

#include <SPI.h>
#include <RF24.h>

// ====== THESE THREE MUST BE IDENTICAL ON THE RECEIVER ======
const byte ADDRESS[6]           = "NODE1";
const uint8_t CHANNEL           = 76;
const rf24_datarate_e DATA_RATE = RF24_250KBPS;   // if clone modules fail, use RF24_1MBPS on both
// ===========================================================

// Packet layout must match the receiver exactly (6 bytes, no padding)
struct SensorPacket {
  uint16_t packetId;
  int16_t  temperatureX10;   // 366 = 36.6 C
  uint8_t  heartRate;        // beats per minute
  uint8_t  spo2;             // blood oxygen, percent
};

RF24 radio(9, 10);           // CE, CSN
SensorPacket packet;
unsigned long lastSend = 0;
const unsigned long SEND_INTERVAL_MS = 1000;

void setup() {
  Serial.begin(9600);
  Serial.println(F("Pro Mini transmitter starting..."));

  if (!radio.begin() || !radio.isChipConnected()) {
    Serial.println(F("nRF24L01 NOT detected. Check wiring, 3.3V power and capacitor."));
    while (true) { delay(1000); }
  }

  radio.setChannel(CHANNEL);
  radio.setDataRate(DATA_RATE);
  radio.setPALevel(RF24_PA_LOW);
  radio.setRetries(5, 15);               // wait 1.5 ms, retry up to 15 times
  radio.openWritingPipe(ADDRESS);
  radio.stopListening();                 // transmitter mode

  randomSeed(analogRead(A0));
  packet.packetId = 0;
  Serial.println(F("Radio OK. Sending..."));
}

void loop() {
  if (millis() - lastSend < SEND_INTERVAL_MS) return;
  lastSend = millis();

  // ---- dummy sensor data ----
  float t = packet.packetId * 0.2;
  packet.temperatureX10 = 365 + (int16_t)(8.0 * sin(t));      // swings 35.7 to 37.3 C
  packet.heartRate      = 72 + (int8_t)(10.0 * sin(t * 0.7)) + random(-2, 3);   // ~60 to 84 bpm
  packet.spo2           = 97 + random(-1, 2);                 // 96 to 98 %

  bool ok = radio.write(&packet, sizeof(packet));             // true = receiver ACKed

  Serial.print(F("#"));        Serial.print(packet.packetId);
  Serial.print(F("  T="));     Serial.print(packet.temperatureX10 / 10.0, 1);
  Serial.print(F("C  HR="));   Serial.print(packet.heartRate);
  Serial.print(F("bpm  SpO2=")); Serial.print(packet.spo2);
  Serial.print(F("%"));
  Serial.println(ok ? F("  -> delivered") : F("  -> NO ACK"));

  packet.packetId++;
}
