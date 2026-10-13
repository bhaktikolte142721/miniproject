/*
  RECEIVER - ESP32 + nRF24L01
  Prints every dummy vitals packet (temperature, heart rate, SpO2) sent by the Pro Mini.

  Wiring (nRF24L01 -> ESP32):
    GND -> GND | VCC -> 3V3 (+10uF cap across VCC/GND)
    CE  -> GPIO4  | CSN -> GPIO5
    SCK -> GPIO18 | MOSI -> GPIO23 | MISO -> GPIO19

  Library needed: "RF24" by TMRh20 (Library Manager)
  Board: ESP32 Dev Module | Serial Monitor: 115200 baud
*/

#include <SPI.h>
#include <RF24.h>

// ====== THESE THREE MUST BE IDENTICAL ON THE TRANSMITTER ======
const byte ADDRESS[6]           = "NODE1";
const uint8_t CHANNEL           = 76;
const rf24_datarate_e DATA_RATE = RF24_250KBPS;   // if clone modules fail, use RF24_1MBPS on both
// ==============================================================

// Packet layout must match the transmitter exactly (6 bytes, no padding)
struct SensorPacket {
  uint16_t packetId;
  int16_t  temperatureX10;   // 366 = 36.6 C
  uint8_t  heartRate;        // beats per minute
  uint8_t  spo2;             // blood oxygen, percent
};

const uint8_t PIN_CE  = 4;
const uint8_t PIN_CSN = 5;
RF24 radio(PIN_CE, PIN_CSN);

SensorPacket packet;
bool gotFirst = false;
uint16_t lastId = 0;
uint32_t received = 0, lost = 0;
unsigned long lastRxTime = 0;

void setup() {
  Serial.begin(9600);
  delay(500);
  Serial.println("\nESP32 receiver starting...");

  SPI.begin(18, 19, 23, PIN_CSN);        // SCK, MISO, MOSI, SS

  if (!radio.begin() || !radio.isChipConnected()) {
    Serial.println("nRF24L01 NOT detected. Check wiring, 3V3 power and capacitor.");
    while (true) { delay(1000); }
  }

  radio.setChannel(CHANNEL);
  radio.setDataRate(DATA_RATE);
  radio.setPALevel(RF24_PA_LOW);
  radio.openReadingPipe(1, ADDRESS);
  radio.startListening();                // receiver mode

  lastRxTime = millis();
  Serial.println("Radio OK. Waiting for packets...");
}

void loop() {
  while (radio.available()) {
    radio.read(&packet, sizeof(packet));
    lastRxTime = millis();
    received++;

    if (gotFirst) {
      uint16_t gap = (uint16_t)(packet.packetId - lastId - 1);   // handles rollover
      if (gap > 0 && gap < 1000) lost += gap;
    }
    gotFirst = true;
    lastId = packet.packetId;

    Serial.printf("#%u  T=%.1f C  HR=%u bpm  SpO2=%u %%  | received=%lu lost=%lu\n",
                  packet.packetId,
                  packet.temperatureX10 / 10.0,
                  packet.heartRate,
                  packet.spo2,
                  (unsigned long)received, (unsigned long)lost);
  }

  if (millis() - lastRxTime > 5000) {
    Serial.println("No packet for 5 s. Check transmitter, address, channel, data rate.");
    lastRxTime = millis();
  }
}
