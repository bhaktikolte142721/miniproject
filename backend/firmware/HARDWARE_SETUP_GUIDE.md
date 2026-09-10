# 🛡️ SENTINEL-Ward: Final Hardware & Firmware Setup Guide

This guide provides the complete wiring diagrams, pinouts, firmware flashing instructions, and system integration details for the **SENTINEL-Ward Telemetry System**.

---

## 🏗️ Hardware Architecture & Component List

```
┌─────────────────────────────────────────────────────────────┐
│                 BEDSIDE SENSOR NODE                         │
│  • Microcontroller: Arduino Pro Mini (ATmega328P 3.3V/8MHz) │
│  • PPG Sensor:      MAX30102 (Heart Rate & SpO2) via I2C    │
│  • Temp Sensor:     MAX30205 (Clinical Body Temp) via I2C   │
│  • RF Transceiver:  nRF24L01 (PCB Traced Antenna) via SPI   │
└──────────────────────────────┬──────────────────────────────┘
                               │ 2.4 GHz RF Link (Pipes 0 to 5)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 MAIN RECEIVER HUB GATEWAY                   │
│  • MCU & Wi-Fi:     ESP32-WROOM-32                          │
│  • RF Transceiver:  nRF24L01 (Receives up to 6 Beds)        │
└──────────────────────────────┬──────────────────────────────┘
                               │ Local Wi-Fi (HTTP POST /api/telemetry/ingest)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 CENTRAL WARD MONITOR                        │
│  • Backend: Node.js + Express + Socket.IO (Port 3000)       │
│  • Frontend: Flutter Web / Mobile Nursing Console           │
└─────────────────────────────────────────────────────────────┘
```

---

## 📌 1. Bedside Node Wiring (Arduino Pro Mini)

### A. nRF24L01 (PCB Traced Antenna) to Arduino Pro Mini (SPI)
> [!CAUTION]
> **VCC MUST BE CONNECTED TO 3.3V!** Connecting nRF24L01 to 5V will permanently destroy the radio chip.
> **Pro-Tip:** Solder a $10\,\mu\text{F}$ electrolytic capacitor directly across the nRF24L01 `VCC` and `GND` pins to prevent current brownouts during RF transmission.

| nRF24L01 Pin | Arduino Pro Mini Pin | Description |
| :--- | :--- | :--- |
| **VCC** | **VCC (3.3V)** | Power Supply (3.3V only) |
| **GND** | **GND** | Ground |
| **CE** | **Pin 9** | Chip Enable |
| **CSN** | **Pin 10** | Chip Select Not |
| **SCK** | **Pin 13** | Hardware SPI Clock |
| **MOSI** | **Pin 11** | Hardware SPI Data In |
| **MISO** | **Pin 12** | Hardware SPI Data Out |
| **IRQ** | *Unconnected* | Optional Interrupt |

---

### B. MAX30102 (PPG Sensor) to Arduino Pro Mini (I2C)
| MAX30102 Pin | Arduino Pro Mini Pin | Description |
| :--- | :--- | :--- |
| **VIN / VCC** | **3.3V** | Power Supply |
| **GND** | **GND** | Ground |
| **SDA** | **Pin A4** | I2C Serial Data |
| **SCL** | **Pin A5** | I2C Serial Clock |
| **INT** | *Unconnected* | Interrupt (optional) |

---

### C. MAX30205 (Clinical Temperature Sensor) to Arduino Pro Mini (I2C)
> [!NOTE]
> The MAX30205 shares the same I2C bus (`A4`/`A5`) as the MAX30102 without conflict because their I2C addresses are distinct:
> - **MAX30102:** `0x57`
> - **MAX30205:** `0x48` (with address pins A0, A1, A2 tied to GND)

| MAX30205 Pin | Arduino Pro Mini Pin | Description |
| :--- | :--- | :--- |
| **VCC** | **3.3V** | Power Supply |
| **GND** | **GND** | Ground |
| **SDA** | **Pin A4** | I2C Serial Data (Shared with MAX30102) |
| **SCL** | **Pin A5** | I2C Serial Clock (Shared with MAX30102) |
| **A0, A1, A2** | **GND** | Sets I2C Address to `0x48` |
| **OS** | *Unconnected* | Over-temperature alert |

---

### D. Note on Battery & Charging Modules
As you noted, the battery (3.7V Li-Po/18650), TP4056 charging module, and boost/buck converter are **not yet connected**.
- **Firmware Behavior:** The firmware automatically reports a clean **`100%`** battery telemetry state to prevent false battery alarms.
- **Future Integration:** When you add the battery, connect a 1:1 voltage divider (two $100\,\text{k}\Omega$ resistors) from the battery positive terminal to **Pin A0** of the Pro Mini, and uncomment the ADC reading in `readBatteryStatus()`.

---

## 📌 2. Main Receiver Hub Wiring (ESP32-WROOM-32)

### nRF24L01 to ESP32-WROOM-32 (VSPI)
| nRF24L01 Pin | ESP32-WROOM-32 Pin | Description |
| :--- | :--- | :--- |
| **VCC** | **3V3 (3.3V)** | Power Supply |
| **GND** | **GND** | Ground |
| **CE** | **GPIO 4** | Chip Enable |
| **CSN** | **GPIO 5** | Chip Select Not |
| **SCK** | **GPIO 18** | VSPI Clock |
| **MOSI** | **GPIO 23** | VSPI Master Out |
| **MISO** | **GPIO 19** | VSPI Master In |

---

## 💻 3. Flashing Firmware via Arduino IDE

### Step A: Install Required Libraries in Arduino IDE
Open Arduino IDE $\to$ Go to **Tools** $\to$ **Manage Libraries...** and install:
1. **RF24** by *TMRh20*
2. **SparkFun MAX3010x Pulse and Proximity Sensor Library** by *SparkFun*
3. **Wire** and **SPI** (Included by default in Arduino IDE)

### Step B: Flash Bedside Node (`bedside_transmitter_node.ino`)
1. Connect your **FTDI / USB-to-UART programmer** to the Arduino Pro Mini.
2. In Arduino IDE $\to$ **Tools** $\to$ **Board**: Select `Arduino Pro or Pro Mini`.
3. In **Tools** $\to$ **Processor**: Select `ATmega328P (3.3V, 8 MHz)` (or 5V, 16MHz depending on your version).
4. Select your COM Port and click **Upload**.
   - *For each of your bedside units, simply change `#define BED_ID "bed_01"` to `"bed_02"`, `"bed_03"`, etc., and the corresponding pipe address!*

### Step C: Flash Central Hub (`esp32_gateway.ino`)
1. Connect ESP32-WROOM-32 via USB.
2. Open [`backend/firmware/esp32_gateway.ino`](./esp32_gateway.ino).
3. Put your local Wi-Fi SSID, Password, and your computer's IP address.
4. In Arduino IDE $\to$ **Tools** $\to$ **Board**: Select `ESP32 Dev Module`.
5. Click **Upload**.

---

## ❓ Frequently Asked Questions

### 1. Will the backend code change with these hardware changes?
**No breaking changes were required!** 
- The REST API endpoint (`POST /api/telemetry/ingest`) accepts `{ bedId, heartRate, spo2, temperature, rssi, batteryPercent }`. 
- The MAX30102 provides `heartRate` and `spo2`, the MAX30205 provides `temperature`, and the nRF24 transmits the payload.
- We have updated `server.js` to **dynamically support all 6 beds** (`bed_01` through `bed_06`) simultaneously!

### 2. How will a Nurse Register / Sign In?
- In clinical practice and in the SENTINEL-Ward system:
  1. **Shift Handover / Fast Switch:** A nurse taps the **Nurse Profile Card** or navigates to the **Shift Handover Screen**.
  2. **Registration & Shift Assignment:** The nurse enters her Name (e.g. *Sister Ananya Roy*), Nursing Council Registration Number / Staff ID (*RN #88192*), assigned Ward (*Ward 3B / ICU*), and Shift (*Day / Night*).
  3. **Audit Trail & Medico-legal Compliance:** Once logged in, every alarm clearance, patient admission, and medication check is cryptographically tagged with that nurse's identity.

### 3. Is it necessary to show the names of hardware components in the UI? Why is it shown?
- **For Academic Review & Final Project Evaluation:**
  - **Yes, it is highly advantageous!** Examiners and evaluators want visual confirmation that your system is a genuine Embedded IoT / Biomedical system, and not just a mockup dashboard. Showing "nRF24 2.4GHz RF Link (-58 dBm)" and "MAX30102 / MAX30205 Telemetry Node" clearly demonstrates that physical hardware nodes are active and communicating.
- **For Real Clinical Hospital Deployments:**
  - In a commercial hospital ICU (like Philips or GE Healthcare monitors), the semiconductor chip part numbers are hidden from daily clinical view and placed in a **"Biomedical Engineering / Diagnostics"** tab, while the nurses see intuitive labels: *"Bedside Telemetry Pack 1"*, *"Signal Strength: Excellent"*, and *"Battery: 100%"*.
