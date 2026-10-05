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

## 🗄️ SQL Patient & Alarm Database (SQLite)

Persistent relational database storing patient data, cumulative alarm statistics, and historical critical conditions in table format (`backend/sentinel_ward.db`).

### SQL Schema Overview

1. **`patients` Table**:
   - `bed_id` (TEXT UNIQUE): Bed Identifier (`bed_01` to `bed_06`)
   - `patient_name` (TEXT): Patient full name
   - `total_alarms` (INTEGER): Total count of alarms triggered for this patient
   - `active_alarms` (INTEGER): Currently unacknowledged active alarms
   - `latest_critical_condition` (TEXT): Description of what was the critical condition
   - `current_status` (TEXT): Clinical threshold status (`optimal`, `checking`, `critical`)
   - `last_alarm_timestamp` (TEXT): ISO timestamp of the latest alert

2. **`patient_alarms` Table**:
   - `alarm_id` (TEXT UNIQUE): Incident ID (e.g., `ALT-1001`)
   - `bed_id` (TEXT): Foreign key referencing `patients(bed_id)`
   - `severity` (TEXT): `critical` or `warning`
   - `critical_condition` (TEXT): Specific reason/condition (e.g., `Sustained SpO2 < 88% for 15s (Clinical Desaturation)`)
   - `heart_rate`, `spo2`, `temperature`: Vitals captured at alarm trigger time
   - `status` (TEXT): `active`, `acknowledged`, `cleared`
   - `acknowledged_by` (TEXT): Nurse or physician who acknowledged

3. **`v_patient_alarm_summary` View**:
   Pre-aggregated SQL view presenting data in table format for each patient.

### View Database Tables in Console
```bash
npm run db:view
```

### SQL REST Endpoints
- `GET /api/db/summary` - Returns tabular summary of all patients, number of alarms, and critical conditions.
- `GET /api/db/patients` - Returns complete patient table records.
- `GET /api/db/patient/:bedId` - Returns profile and all alarm history for a specific patient.
- `GET /api/db/alarms` - Returns all alarm event records.
- `GET /api/db/table-view` - Visual HTML table format view for browser inspection.

---

## 🔌 ESP32 Gateway Hardware Firmware

The complete C++ Arduino firmware sketch for the ESP32 microcontroller with nRF24L01 radio receiver is located at:
[`backend/firmware/esp32_gateway.ino`](./firmware/esp32_gateway.ino)
