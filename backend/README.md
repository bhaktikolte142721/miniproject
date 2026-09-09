# ⚡ SENTINEL-Ward Telemetry Gateway Backend

Production-grade Node.js + Express + Socket.IO real-time telemetry gateway server for the **SENTINEL-Ward** acute care hospital monitoring system.

---

## 🚀 Quick Start

```bash
cd backend
npm install
npm start
```

The server starts on port `3000`:
- **REST Endpoints**: `http://localhost:3000/api/status`
- **Socket.IO Server**: `ws://localhost:3000` (Listening for `vitals_update`, `node_status`, `critical_alarm`)

---

## 📡 REST API Specifications

### 1. Gateway Status
`GET /api/status`
```json
{
  "status": "online",
  "gatewayId": "ESP32-WARD-3B-GW",
  "firmwareVersion": "v2.4.1-nRF24",
  "ipAddress": "192.168.1.142",
  "activeNodes": 3,
  "uptimeFormatted": "14h 32m",
  "activeAlarmsCount": 1
}
```

### 2. Multi-Patient Bed Vitals
`GET /api/beds`
Returns live telemetry for Bed 01, Bed 02, and Bed 03.

### 3. ESP32 Hardware Telemetry Ingestion
`POST /api/telemetry/ingest`
Payload:
```json
{
  "bedId": "bed_01",
  "heartRate": 74,
  "spo2": 99,
  "temperature": 36.8,
  "rssi": -58,
  "batteryPercent": 96
}
```
*Broadcasts immediately to all connected Flutter mobile & nurse console clients via WebSocket.*

### 4. Alarm Acknowledgment
`POST /api/alarms/acknowledge`
Payload:
```json
{
  "alarmId": "ALT-1001",
  "nurseName": "Nurse Sarah Jenkins, RN"
}
```

---

## 🔌 ESP32 Gateway Hardware Firmware

The complete C++ Arduino firmware sketch for the ESP32 microcontroller with nRF24L01 radio receiver is located at:
[`backend/firmware/esp32_gateway.ino`](./firmware/esp32_gateway.ino)
