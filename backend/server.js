const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 3000;
const START_TIME = Date.now();

// Clinical Telemetry State
const telemetryState = {
  bed_01: {
    bedId: 'bed_01',
    patientName: 'Elena Rostova',
    heartRate: 72,
    spo2: 99,
    temperature: 36.8,
    respiratoryRate: 16,
    bloodPressureSys: 118,
    bloodPressureDia: 76,
    status: 'optimal',
    timestamp: new Date().toISOString()
  },
  bed_02: {
    bedId: 'bed_02',
    patientName: 'Marcus Vance',
    heartRate: 88,
    spo2: 94,
    temperature: 37.6,
    respiratoryRate: 20,
    bloodPressureSys: 132,
    bloodPressureDia: 84,
    status: 'checking',
    timestamp: new Date().toISOString()
  },
  bed_03: {
    bedId: 'bed_03',
    patientName: 'David Chen',
    heartRate: 118,
    spo2: 87,
    temperature: 38.6,
    respiratoryRate: 26,
    bloodPressureSys: 94,
    bloodPressureDia: 60,
    status: 'critical',
    timestamp: new Date().toISOString()
  }
};

const nodeHealthState = {
  bed_01: { bedId: 'bed_01', rssi: -58, batteryPercent: 96, isOnline: true },
  bed_02: { bedId: 'bed_02', rssi: -64, batteryPercent: 88, isOnline: true },
  bed_03: { bedId: 'bed_03', rssi: -78, batteryPercent: 74, isOnline: true }
};

let activeAlarms = [
  {
    id: 'ALT-1001',
    bedId: 'bed_03',
    patientName: 'David Chen',
    severity: 'critical',
    triggerReason: 'Sustained SpO2 < 88% for 15s (Clinical Desaturation)',
    timestamp: new Date().toISOString(),
    secondsRemaining: 58,
    isAcknowledged: false,
    acknowledgedBy: null,
    escalationLevel: 1
  }
];

const auditTrail = [
  {
    timestamp: new Date().toISOString(),
    action: 'WARD_GATEWAY_INITIALIZED',
    details: 'ESP32 Gateway online on Ward 3B network. 3 nRF24 nodes bound.'
  }
];

// --- REST Endpoints ---

// 1. Gateway Status
app.get('/api/status', (req, res) => {
  const uptimeSeconds = Math.floor((Date.now() - START_TIME) / 1000);
  res.json({
    status: 'online',
    gatewayId: 'ESP32-WARD-3B-GW',
    firmwareVersion: 'v2.4.1-nRF24',
    ipAddress: '192.168.1.142',
    activeNodes: Object.keys(nodeHealthState).length,
    uptimeSeconds,
    uptimeFormatted: `${Math.floor(uptimeSeconds / 3600)}h ${Math.floor((uptimeSeconds % 3600) / 60)}m`,
    activeAlarmsCount: activeAlarms.filter(a => !a.isAcknowledged).length,
    timestamp: new Date().toISOString()
  });
});

// 2. Current Vitals for all beds
app.get('/api/beds', (req, res) => {
  res.json({
    telemetry: telemetryState,
    nodeHealth: nodeHealthState,
    timestamp: new Date().toISOString()
  });
});

// 3. Ingest Hardware Telemetry from ESP32 Microcontroller
app.post('/api/telemetry/ingest', (req, res) => {
  const { bedId, heartRate, spo2, temperature, rssi, batteryPercent } = req.body;
  if (!bedId || !telemetryState[bedId]) {
    return res.status(400).json({ error: 'Invalid bedId' });
  }

  // Update Telemetry
  if (heartRate !== undefined) telemetryState[bedId].heartRate = heartRate;
  if (spo2 !== undefined) telemetryState[bedId].spo2 = spo2;
  if (temperature !== undefined) telemetryState[bedId].temperature = temperature;
  telemetryState[bedId].timestamp = new Date().toISOString();

  // Evaluate status
  if (telemetryState[bedId].spo2 < 90 || telemetryState[bedId].heartRate > 120) {
    telemetryState[bedId].status = 'critical';
  } else if (telemetryState[bedId].spo2 < 94 || telemetryState[bedId].heartRate > 100) {
    telemetryState[bedId].status = 'checking';
  } else {
    telemetryState[bedId].status = 'optimal';
  }

  // Update Node radio metrics
  if (rssi !== undefined) nodeHealthState[bedId].rssi = rssi;
  if (batteryPercent !== undefined) nodeHealthState[bedId].batteryPercent = batteryPercent;

  // Broadcast instantly to all connected mobile & console clients
  io.emit('vitals_update', telemetryState);
  io.emit('node_status', nodeHealthState);

  res.json({ success: true, updated: telemetryState[bedId] });
});

// 4. Trigger Clinical Alarm
app.post('/api/alarms/trigger', (req, res) => {
  const { bedId, triggerReason, severity = 'critical' } = req.body;
  const newAlarm = {
    id: `ALT-${Date.now()}`,
    bedId: bedId || 'bed_03',
    patientName: telemetryState[bedId]?.patientName || 'Unknown Patient',
    severity,
    triggerReason: triggerReason || 'Physiological threshold violated',
    timestamp: new Date().toISOString(),
    secondsRemaining: 60,
    isAcknowledged: false,
    acknowledgedBy: null,
    escalationLevel: 1
  };

  activeAlarms.unshift(newAlarm);
  io.emit('critical_alarm', activeAlarms);

  auditTrail.unshift({
    timestamp: new Date().toISOString(),
    action: 'ALARM_TRIGGERED',
    details: `${severity.toUpperCase()} on ${bedId}: ${triggerReason}`
  });

  res.json({ success: true, alarm: newAlarm });
});

// 5. Acknowledge Alarm
app.post('/api/alarms/acknowledge', (req, res) => {
  const { alarmId, nurseName = 'Nurse Sarah' } = req.body;
  const alarm = activeAlarms.find(a => a.id === alarmId);
  if (!alarm) {
    return res.status(404).json({ error: 'Alarm not found' });
  }

  alarm.isAcknowledged = true;
  alarm.acknowledgedBy = nurseName;

  io.emit('critical_alarm', activeAlarms);

  auditTrail.unshift({
    timestamp: new Date().toISOString(),
    action: 'ALARM_ACKNOWLEDGED',
    details: `Alarm ${alarmId} acknowledged by ${nurseName}`
  });

  res.json({ success: true, alarm });
});

// 6. Audit Trail
app.get('/api/audit', (req, res) => {
  res.json(auditTrail);
});

// --- Socket.IO Real-Time Engine ---

io.on('connection', (socket) => {
  console.log(`🟢 [Socket.IO] New client connected: ${socket.id}`);

  // Send current state upon connection
  socket.emit('vitals_update', telemetryState);
  socket.emit('node_status', nodeHealthState);
  socket.emit('critical_alarm', activeAlarms);

  // Client acknowledges alarm
  socket.on('acknowledge_alarm', (data) => {
    const { alarm_id, nurse } = data;
    const alarm = activeAlarms.find(a => a.id === alarm_id);
    if (alarm) {
      alarm.isAcknowledged = true;
      alarm.acknowledgedBy = nurse || 'Nurse Sarah';
      console.log(`✅ [Alarm Ack] ${alarm_id} acknowledged by ${alarm.acknowledgedBy}`);
      io.emit('critical_alarm', activeAlarms);
    }
  });

  socket.on('disconnect', () => {
    console.log(`🔴 [Socket.IO] Client disconnected: ${socket.id}`);
  });
});

// --- Simulation Ticker (Simulates ESP32 Gateway Telemetry Broadcasts) ---

setInterval(() => {
  // Fluctuate Bed 1 (Elena - Stable)
  telemetryState.bed_01.heartRate = 70 + Math.floor(Math.random() * 5);
  telemetryState.bed_01.spo2 = 98 + Math.floor(Math.random() * 2);

  // Fluctuate Bed 2 (Marcus - Checking)
  telemetryState.bed_02.heartRate = 86 + Math.floor(Math.random() * 6);
  telemetryState.bed_02.spo2 = 93 + Math.floor(Math.random() * 3);

  // Fluctuate Bed 3 (David - Critical)
  telemetryState.bed_03.heartRate = 115 + Math.floor(Math.random() * 8);
  telemetryState.bed_03.spo2 = 86 + Math.floor(Math.random() * 4);

  // Broadcast to all connected Flutter apps
  io.emit('vitals_update', telemetryState);
}, 1500);

// Auto-escalation countdown ticker
setInterval(() => {
  let changed = false;
  activeAlarms.forEach((alarm) => {
    if (!alarm.isAcknowledged) {
      if (alarm.secondsRemaining > 0) {
        alarm.secondsRemaining--;
        changed = true;
      } else {
        // Auto-escalate (L1 -> L2 Supervisor, L2 -> L3 Code Blue)
        if (alarm.escalationLevel < 3) {
          alarm.escalationLevel++;
          alarm.secondsRemaining = 60;
          changed = true;
          console.log(`🚨 [Auto-Escalation] Alert ${alarm.id} escalated to Level ${alarm.escalationLevel}`);
        }
      }
    }
  });

  if (changed) {
    io.emit('critical_alarm', activeAlarms);
  }
}, 1000);

// Start server
server.listen(PORT, () => {
  console.log(`\n========================================================`);
  console.log(`🛡️  SENTINEL-Ward Telemetry Gateway Server Online!`);
  console.log(`📍  Port: ${PORT}`);
  console.log(`🌐  REST Endpoints: http://localhost:${PORT}/api/status`);
  console.log(`⚡  Socket.IO: Listening for 'vitals_update' & 'critical_alarm'`);
  console.log(`========================================================\n`);
});
