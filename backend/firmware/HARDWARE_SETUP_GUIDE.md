# 🔌 SENTINEL-Ward: Hardware-to-Backend Connection Guide

This guide explains how physical hardware (Bedside Sensors + ESP32 Gateway) connects to the Node.js backend and feeds live telemetry into the Flutter application.

---

## 🏗️ End-to-End Architecture

```
┌───────────────────────────────┐
│   Bedside Patient Node        │
│   (Bed 01 / Bed 02 / Bed 03)  │
│   • MAX30102 (HR + SpO2)      │
│   • DS18B20 (Body Temp)       │
│   • nRF24L01 (Transmitter)    │
│   [bedside_transmitter_node]  │
└──────────────┬────────────────┘
               │ 2.4 GHz Wireless RF (Pipes: BED01, BED02, BED03)
               ▼
┌───────────────────────────────┐
│   ESP32 Central Ward Gateway  │
│   • nRF24L01 (Receiver)       │
│   • Wi-Fi Transceiver         │
│   [esp32_gateway.ino]         │
└──────────────┬────────────────┘
               │ Local Wi-Fi (HTTP POST /api/telemetry/ingest)
               ▼
┌───────────────────────────────┐
│   Node.js Backend Server      │
│   • Express REST (Port 3000)  │
│   • Socket.IO WebSocket Engine│
│   [server.js]                 │
└──────────────┬────────────────┘
               │ WebSockets ('vitals_update', 'critical_alarm')
               ▼
┌───────────────────────────────┐
│   Flutter Healthcare App      │
│   (SENTINEL-Ward Mobile/Web)  │
└───────────────────────────────┘
```

---

## 📌 Step 1: ESP32 to nRF24L01+ Wiring Diagram

> [!CAUTION]
> **VCC MUST BE CONNECTED TO 3.3V, NOT 5V!**
> Connecting the nRF24L01 module directly to 5V will burn the RF radio chip. If you have an nRF24 socket adapter with an onboard AMS1117 3.3V regulator, you can supply 5V to the adapter.

| nRF24L01 Pin | ESP32 GPIO Pin | Function |
| :--- | :--- | :--- |
| **VCC** | **3V3 (3.3V)** | Power Supply |
| **GND** | **GND** | Ground |
| **CE** | **GPIO 4** | Chip Enable |
| **CSN** | **GPIO 5** | Chip Select Not |
| **SCK** | **GPIO 18** | SPI Clock (VSPI) |
| **MOSI** | **GPIO 23** | SPI Master Out Slave In |
| **MISO** | **GPIO 19** | SPI Master In Slave Out |

---

## 🌐 Step 2: Find Your Computer's Local IP Address

Your ESP32 and computer must be connected to the **same Wi-Fi router** (or mobile phone hotspot).

1. Open PowerShell / Command Prompt on your computer.
2. Run:
   ```powershell
   ipconfig
   ```
3. Look for **IPv4 Address** under your active Wi-Fi adapter (e.g., `192.168.1.142` or `192.168.43.50`).

---

## ⚙️ Step 3: Configure `esp32_gateway.ino`

Open [`backend/firmware/esp32_gateway.ino`](./esp32_gateway.ino) and update lines 18–25:

```cpp
// 1. Enter your Wi-Fi credentials
const char* ssid = "YOUR_WIFI_NAME";
const char* password = "YOUR_WIFI_PASSWORD";

// 2. Put your computer's IP address here (Port 3000)
const char* serverUrl = "http://192.168.1.142:3000/api/telemetry/ingest";
```

---

## 💻 Step 4: Flash Firmware via Arduino IDE

1. Open **Arduino IDE**.
2. Install ESP32 Board Support:
   - Go to `File` ➔ `Preferences` ➔ `Additional Board Manager URLs`:
     `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
   - In `Tools` ➔ `Board Manager`, install **esp32**.
3. Install the nRF24 Library:
   - In `Tools` ➔ `Manage Libraries`, search for **RF24** by **TMRh20** and click **Install**.
4. Open `esp32_gateway.ino`.
5. Connect your ESP32 board via USB.
6. Under `Tools` ➔ `Board`, select **ESP32 Dev Module**. Under `Port`, select your COM port.
7. Click **Upload** (Arrow icon).

---

## 🚀 Step 5: Start the Backend Server

In your computer terminal:
```bash
cd backend
npm start
```

You will see:
```
========================================================
🛡️  SENTINEL-Ward Telemetry Gateway Server Online!
📍  Port: 3000
🌐  REST Endpoints: http://localhost:3000/api/status
⚡  Socket.IO: Listening for 'vitals_update' & 'critical_alarm'
========================================================
```

---

## 📡 Step 6: Verify Live Ingestion

1. Open the Arduino IDE **Serial Monitor** at **115200 baud**.
2. You will see the ESP32 connect to Wi-Fi:
   ```
   ✅ WiFi Connected! IP: 192.168.1.189
   📡 nRF24 Listening on Pipes: BED01, BED02, BED03
   📥 Packet from Pipe 1 (bed_01): HR=74, SpO2=99%, Temp=36.8C, Bat=96%
   📤 Forwarded to Backend. Response: 200
   ```
3. Look at your Node.js backend console. You will see incoming live packets.
4. The Node.js server immediately broadcasts the vitals over **Socket.IO** to your **Flutter app**, updating the screen in real-time with zero delay!
