const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const path = require('path');
const db = require('./database');

const app = express();
app.use(cors());
app.use(express.json());

// Serve static assets and project files
app.use(express.static(path.join(__dirname, '..')));
app.use('/assets', express.static(path.join(__dirname, '..', 'assets')));
app.use('/preview', express.static(path.join(__dirname, '..', 'preview')));

// Root route loads the 3D Interactive Medical Dashboard
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'preview', 'index.html'));
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 3000;
const START_TIME = Date.now();

// Clinical Telemetry State (Supports up to 6 Bedside Nodes)
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
  },
  bed_04: {
    bedId: 'bed_04',
    patientName: 'Sarah Connor',
    heartRate: 76,
    spo2: 98,
    temperature: 36.9,
    respiratoryRate: 18,
    bloodPressureSys: 122,
    bloodPressureDia: 80,
    status: 'optimal',
    timestamp: new Date().toISOString()
  },
  bed_05: {
    bedId: 'bed_05',
    patientName: 'James Wilson',
    heartRate: 82,
    spo2: 97,
    temperature: 37.1,
    respiratoryRate: 17,
    bloodPressureSys: 126,
    bloodPressureDia: 82,
    status: 'optimal',
    timestamp: new Date().toISOString()
  },
  bed_06: {
    bedId: 'bed_06',
    patientName: 'Robert Taylor',
    heartRate: 70,
    spo2: 99,
    temperature: 36.7,
    respiratoryRate: 15,
    bloodPressureSys: 116,
    bloodPressureDia: 74,
    status: 'optimal',
    timestamp: new Date().toISOString()
  }
};

const nodeHealthState = {
  bed_01: { bedId: 'bed_01', rssi: -58, batteryPercent: 100, isOnline: true },
  bed_02: { bedId: 'bed_02', rssi: -64, batteryPercent: 100, isOnline: true },
  bed_03: { bedId: 'bed_03', rssi: -72, batteryPercent: 100, isOnline: true },
  bed_04: { bedId: 'bed_04', rssi: -61, batteryPercent: 100, isOnline: true },
  bed_05: { bedId: 'bed_05', rssi: -66, batteryPercent: 100, isOnline: true },
  bed_06: { bedId: 'bed_06', rssi: -59, batteryPercent: 100, isOnline: true }
};

// Load active alarms from SQLite database on startup
function loadActiveAlarmsFromDb() {
  try {
    const dbAlarms = db.queryRaw("SELECT * FROM patient_alarms WHERE status = 'active' ORDER BY id ASC");
    if (dbAlarms && dbAlarms.length > 0) {
      return dbAlarms.map(a => ({
        id: a.alarm_id,
        bedId: a.bed_id,
        patientName: a.patient_name,
        severity: a.severity,
        triggerReason: a.critical_condition,
        timestamp: a.triggered_at,
        secondsRemaining: 60,
        isAcknowledged: false,
        acknowledgedBy: a.acknowledged_by,
        escalationLevel: a.escalation_level || 1
      }));
    }
  } catch (err) {
    console.warn('⚠️ [SQL] Could not load active alarms:', err.message);
  }
  return [];
}

let activeAlarms = loadActiveAlarmsFromDb();
let resolvedAlarmsCount = 1;
try {
  const dbResolved = db.queryRaw("SELECT COUNT(*) AS count FROM patient_alarms WHERE status IN ('acknowledged', 'cleared', 'resolved')");
  if (dbResolved && dbResolved[0] && dbResolved[0].count > 0) {
    resolvedAlarmsCount = dbResolved[0].count;
  }
} catch (e) {}

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
    resolvedAlarmsCount,
    database: {
      engine: 'SQLite (node:sqlite)',
      file: 'sentinel_ward.db',
      status: 'connected',
      tables: ['patients', 'patient_alarms', 'patient_vitals_log'],
      summaryView: 'v_patient_alarm_summary'
    },
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
  if (!bedId) {
    return res.status(400).json({ error: 'Missing bedId' });
  }

  // Auto-initialize bed state if not already existing (up to 6 beds or dynamic)
  if (!telemetryState[bedId]) {
    telemetryState[bedId] = {
      bedId,
      patientName: `Patient (${bedId.toUpperCase()})`,
      heartRate: heartRate || 75,
      spo2: spo2 || 98,
      temperature: temperature || 37.0,
      respiratoryRate: 16,
      bloodPressureSys: 120,
      bloodPressureDia: 80,
      status: 'optimal',
      timestamp: new Date().toISOString()
    };
    nodeHealthState[bedId] = {
      bedId,
      rssi: rssi || -60,
      batteryPercent: batteryPercent !== undefined ? batteryPercent : 100,
      isOnline: true
    };
  }

  // Update Telemetry
  if (heartRate !== undefined) telemetryState[bedId].heartRate = heartRate;
  if (spo2 !== undefined) telemetryState[bedId].spo2 = spo2;
  if (temperature !== undefined) telemetryState[bedId].temperature = temperature;
  telemetryState[bedId].timestamp = new Date().toISOString();

  // Evaluate clinical status
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
  nodeHealthState[bedId].isOnline = true;

  // Persist telemetry into SQL database (patients & patient_vitals_log tables)
  try {
    db.logVitals({
      bedId,
      patientName: telemetryState[bedId].patientName,
      heartRate: telemetryState[bedId].heartRate,
      spo2: telemetryState[bedId].spo2,
      temperature: telemetryState[bedId].temperature,
      respiratoryRate: telemetryState[bedId].respiratoryRate,
      bloodPressureSys: telemetryState[bedId].bloodPressureSys,
      bloodPressureDia: telemetryState[bedId].bloodPressureDia,
      status: telemetryState[bedId].status
    });
    db.updatePatientVitals(bedId, {
      heartRate: telemetryState[bedId].heartRate,
      spo2: telemetryState[bedId].spo2,
      temperature: telemetryState[bedId].temperature,
      status: telemetryState[bedId].status
    });
  } catch (dbErr) {
    console.error('⚠️ [SQL Log Error]', dbErr.message);
  }

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

  // Update telemetry status for bed
  if (telemetryState[newAlarm.bedId]) {
    telemetryState[newAlarm.bedId].status = severity === 'critical' ? 'critical' : 'checking';
    io.emit('vitals_update', telemetryState);
  }

  // Persist alarm into SQL database in table format and increment patient total alarms
  try {
    db.recordAlarm({
      alarmId: newAlarm.id,
      bedId: newAlarm.bedId,
      patientName: newAlarm.patientName,
      severity: newAlarm.severity,
      criticalCondition: newAlarm.triggerReason,
      heartRate: telemetryState[newAlarm.bedId]?.heartRate,
      spo2: telemetryState[newAlarm.bedId]?.spo2,
      temperature: telemetryState[newAlarm.bedId]?.temperature,
      timestamp: newAlarm.timestamp
    });
    console.log(`💾 [SQL Database] Stored alarm ${newAlarm.id} for ${newAlarm.patientName} (${newAlarm.bedId}). Condition: ${newAlarm.triggerReason}`);
  } catch (dbErr) {
    console.error('⚠️ [SQL Alarm Save Error]', dbErr.message);
  }

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
  const alarmId = req.body.alarmId || req.body.alarm_id;
  const nurseName = req.body.nurseName || req.body.nurse || 'Nurse Sarah Jenkins';
  if (!alarmId) {
    return res.status(400).json({ error: 'Missing alarmId' });
  }

  const alarm = activeAlarms.find(a => a.id === alarmId);
  if (alarm && !alarm.isAcknowledged) {
    alarm.isAcknowledged = true;
    alarm.acknowledgedBy = nurseName;
    resolvedAlarmsCount++;
  }

  // Update SQL database status
  try {
    db.acknowledgeAlarm(alarmId, nurseName);
  } catch (dbErr) {
    console.error('⚠️ [SQL Alarm Ack Error]', dbErr.message);
  }

  auditTrail.unshift({
    timestamp: new Date().toISOString(),
    action: 'ALARM_ACKNOWLEDGED',
    details: `Alarm ${alarmId} acknowledged and handled by ${nurseName}. Audio alarm silenced.`
  });

  console.log(`🔕 [Alarm Handled] ${alarmId} acknowledged by ${nurseName}. Total resolved: ${resolvedAlarmsCount}`);
  io.emit('alarm_acknowledged', { alarmId, nurseName, resolvedAlarmsCount });
  io.emit('alarm_stats', { resolvedAlarmsCount, activeAlarmsCount: activeAlarms.filter(a => !a.isAcknowledged).length });
  io.emit('critical_alarm', activeAlarms);

  res.json({ success: true, alarm, resolvedAlarmsCount });
});

// 5b. Clear / Silence Alarm
app.post('/api/alarms/clear', (req, res) => {
  const alarmId = req.body?.alarmId || req.body?.alarm_id;
  if (alarmId) {
    const alarm = activeAlarms.find(a => a.id === alarmId);
    if (alarm && !alarm.isAcknowledged) {
      resolvedAlarmsCount++;
    }
    activeAlarms = activeAlarms.filter(a => a.id !== alarmId);
    try {
      db.clearAlarm(alarmId);
    } catch (dbErr) {
      console.error('⚠️ [SQL Alarm Clear Error]', dbErr.message);
    }
    if (alarm && telemetryState[alarm.bedId]) {
      telemetryState[alarm.bedId].status = 'optimal';
      io.emit('vitals_update', telemetryState);
    }
  } else {
    const unack = activeAlarms.filter(a => !a.isAcknowledged).length;
    resolvedAlarmsCount += unack;
    activeAlarms = [];
    try {
      db.clearAlarm(null);
    } catch (dbErr) {
      console.error('⚠️ [SQL Alarm Clear Error]', dbErr.message);
    }
    Object.keys(telemetryState).forEach(bed => {
      telemetryState[bed].status = 'optimal';
    });
    io.emit('vitals_update', telemetryState);
  }

  auditTrail.unshift({
    timestamp: new Date().toISOString(),
    action: 'ALARM_CLEARED',
    details: `Alarm ${alarmId || 'ALL'} cleared and resolved by clinician.`
  });

  console.log(`🔕 [Alarm Cleared] Alarm ${alarmId || 'ALL'} cleared. Total resolved: ${resolvedAlarmsCount}`);
  io.emit('alarm_cleared', { alarmId: alarmId || 'ALL', resolvedAlarmsCount });
  io.emit('alarm_stats', { resolvedAlarmsCount, activeAlarmsCount: activeAlarms.length });
  io.emit('critical_alarm', activeAlarms);
  res.json({ success: true, activeAlarms, resolvedAlarmsCount });
});

// 5c. Alarm Statistics (for live appreciation and reporting)
app.get('/api/alarms/stats', (req, res) => {
  res.json({
    resolvedAlarmsCount,
    activeAlarmsCount: activeAlarms.filter(a => !a.isAcknowledged).length,
    auditTrailCount: auditTrail.length,
    timestamp: new Date().toISOString()
  });
});

// 6. Audit Trail
app.get('/api/audit', (req, res) => {
  res.json(auditTrail);
});

// --- SQL Database Query Endpoints ---

// 7. Get summary table of all patients, number of alarms, and critical condition
app.get('/api/db/summary', (req, res) => {
  try {
    const summary = db.getSummaryTable();
    res.json({
      success: true,
      count: summary.length,
      table: summary
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 8. Get full patient roster table from database
app.get('/api/db/patients', (req, res) => {
  try {
    const patients = db.getAllPatients();
    res.json({
      success: true,
      count: patients.length,
      patients
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 9. Get specific patient with full history of alarms and critical conditions
app.get('/api/db/patient/:bedId', (req, res) => {
  try {
    const patientData = db.getPatientByBedId(req.params.bedId);
    if (!patientData) {
      return res.status(404).json({ error: 'Patient or Bed not found' });
    }
    res.json({
      success: true,
      patient: patientData
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 10. Get all recorded alarms in table format
app.get('/api/db/alarms', (req, res) => {
  try {
    const limit = parseInt(req.query.limit, 10) || 100;
    const alarms = db.getAllAlarms(limit);
    res.json({
      success: true,
      count: alarms.length,
      alarms
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 10d. Get recent patient vitals telemetry records in table format
app.get('/api/db/vitals', (req, res) => {
  try {
    const limit = parseInt(req.query.limit, 10) || 100;
    const vitals = db.getRecentVitals(limit);
    res.json({
      success: true,
      count: vitals.length,
      vitals
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 10c. Reset SQL Database to pristine seed state
app.post('/api/db/reset', (req, res) => {
  try {
    db.resetDatabase();
    activeAlarms = loadActiveAlarmsFromDb();
    resolvedAlarmsCount = 0;
    io.emit('critical_alarm', activeAlarms);
    io.emit('alarm_stats', { resolvedAlarmsCount: 0, activeAlarmsCount: activeAlarms.length });
    res.json({ success: true, message: 'Database reset to clean initial state' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 10b. Export Patient Report as CSV File (Excel / Google Sheets compatible)
app.get('/api/db/export/csv', (req, res) => {
  try {
    const summary = db.getSummaryTable();
    const headers = ['Bed', 'Patient Name', 'Total Alarms', 'Active Alarms', 'Critical Condition', 'Clinical Status', 'Last Alarm Time'];
    const rows = summary.map(r => [
      `"${r.Bed}"`,
      `"${r['Patient Name']}"`,
      r['Total Alarms'],
      r['Active Alarms'],
      `"${(r['Critical Condition'] || 'None').replace(/"/g, '""')}"`,
      `"${r['Clinical Status']}"`,
      `"${r['Last Alarm Timestamp'] || ''}"`
    ].join(','));

    const csvContent = [headers.join(','), ...rows].join('\r\n');

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="patient_alarm_report.csv"');
    res.status(200).send(csvContent);
  } catch (err) {
    res.status(500).send('Error generating CSV report: ' + err.message);
  }
});

// 11. HTML Table View for browser inspection & reporting
app.get('/api/db/table-view', (req, res) => {
  try {
    const summary = db.getSummaryTable();
    const alarms = db.getAllAlarms();

    const summaryRows = summary.map(r => `
      <tr>
        <td><strong>${r.Bed}</strong></td>
        <td>${r['Patient Name']}</td>
        <td style="text-align:center; font-weight:bold; color:${r['Total Alarms'] > 0 ? '#d32f2f' : '#2e7d32'}">${r['Total Alarms']}</td>
        <td style="text-align:center;">${r['Active Alarms']}</td>
        <td><span class="badge ${r['Clinical Status']}">${r['Clinical Status']}</span></td>
        <td>${r['Critical Condition'] || 'None'}</td>
        <td>${r['Last Alarm Timestamp'] || '--'}</td>
      </tr>
    `).join('');

    const alarmRows = alarms.map(a => `
      <tr>
        <td><code>${a.alarm_id}</code></td>
        <td><strong>${a.bed_id}</strong></td>
        <td>${a.patient_name}</td>
        <td><span class="badge ${a.severity}">${a.severity}</span></td>
        <td>${a.critical_condition}</td>
        <td>${a.heart_rate || '--'} bpm / ${a.spo2 || '--'}%</td>
        <td><span class="badge ${a.status}">${a.status}</span></td>
        <td>${a.acknowledged_by || '<em>Unacknowledged</em>'}</td>
        <td>${a.triggered_at ? a.triggered_at.replace('T', ' ').substring(0, 19) : '--'}</td>
      </tr>
    `).join('');

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>SENTINEL-Ward SQL Database Tables</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f4f7f9; color: #333; padding: 28px; line-height: 1.5; }
    .header-bar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; margin-bottom: 24px; }
    h1 { color: #00838f; margin: 0 0 4px 0; font-size: 26px; }
    p.subtitle { color: #666; margin: 0; font-size: 14px; }
    .actions { display: flex; gap: 10px; }
    .btn { background: #00838f; color: white; border: none; padding: 10px 18px; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; box-shadow: 0 2px 6px rgba(0,131,143,0.3); transition: background 0.2s; }
    .btn:hover { background: #00695c; }
    .btn.secondary { background: #475569; box-shadow: 0 2px 6px rgba(71,85,105,0.3); }
    .btn.secondary:hover { background: #334155; }
    .card { background: white; border-radius: 12px; box-shadow: 0 4px 16px rgba(0,0,0,0.06); padding: 24px; margin-bottom: 28px; border: 1px solid #e0f2f1; }
    h2 { margin-top: 0; font-size: 18px; color: #1e293b; }
    table { width: 100%; border-collapse: collapse; margin-top: 14px; }
    th, td { text-align: left; padding: 12px 14px; border-bottom: 1px solid #edf2f4; font-size: 14px; }
    th { background: #f8fafc; color: #475569; font-weight: 600; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px; }
    tr:hover { background: #f8fafc; }
    .badge { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; text-transform: uppercase; }
    .badge.critical { background: #ffebee; color: #c62828; }
    .badge.checking { background: #fff8e1; color: #f57f17; }
    .badge.optimal { background: #e8f5e9; color: #2e7d32; }
    .badge.active { background: #ffebee; color: #c62828; }
    .badge.acknowledged { background: #e0f2fe; color: #0284c7; }
    .badge.cleared { background: #f1f5f9; color: #64748b; }
    code { background: #f1f5f9; padding: 2px 6px; border-radius: 4px; font-size: 13px; font-family: monospace; }
    @media print {
      body { background: white; padding: 0; }
      .actions, .btn { display: none; }
      .card { box-shadow: none; border: 1px solid #ccc; break-inside: avoid; }
    }
  </style>
</head>
<body>
  <div class="header-bar">
    <div>
      <h1>🏥 SENTINEL-Ward Patient Database Tables</h1>
      <p class="subtitle">Persistent SQLite Database (<code>backend/sentinel_ward.db</code>) • Real-Time SQL View</p>
    </div>
    <div class="actions">
      <a href="/api/db/export/csv" class="btn" download>📥 Download CSV Report</a>
      <button onclick="window.print()" class="btn secondary">🖨️ Print / Save PDF</button>
    </div>
  </div>

  <div class="card">
    <h2>📊 Patient Alarms Summary (Table Format)</h2>
    <p>Saved in table format for each patient, displaying total number of alarms and critical conditions.</p>
    <table>
      <thead>
        <tr>
          <th>Bed</th>
          <th>Patient Name</th>
          <th style="text-align:center;">Total Alarms</th>
          <th style="text-align:center;">Active Alarms</th>
          <th>Status</th>
          <th>Critical Condition</th>
          <th>Last Alarm Time</th>
        </tr>
      </thead>
      <tbody>
        ${summaryRows}
      </tbody>
    </table>
  </div>

  <div class="card">
    <h2>🚨 Patient Alarms History Log (Table Format)</h2>
    <p>Chronological history of all critical condition events for each patient.</p>
    <table>
      <thead>
        <tr>
          <th>Alarm ID</th>
          <th>Bed</th>
          <th>Patient</th>
          <th>Severity</th>
          <th>Critical Condition Reason</th>
          <th>Vitals (HR / SpO2)</th>
          <th>Status</th>
          <th>Handled By</th>
          <th>Triggered At</th>
        </tr>
      </thead>
      <tbody>
        ${alarmRows.length > 0 ? alarmRows : '<tr><td colspan="9" style="text-align:center; color:#888;">No alarms recorded yet.</td></tr>'}
      </tbody>
    </table>
  </div>
</body>
</html>`;

    res.send(html);
  } catch (err) {
    res.status(500).send('Error rendering table view: ' + err.message);
  }
});

// --- Socket.IO Real-Time Engine ---

io.on('connection', (socket) => {
  console.log(`🟢 [Socket.IO] New client connected: ${socket.id}`);

  // Send current state upon connection
  socket.emit('vitals_update', telemetryState);
  socket.emit('node_status', nodeHealthState);
  socket.emit('critical_alarm', activeAlarms);
  socket.emit('alarm_stats', {
    resolvedAlarmsCount,
    activeAlarmsCount: activeAlarms.filter(a => !a.isAcknowledged).length
  });

  // Client acknowledges alarm
  socket.on('acknowledge_alarm', (data) => {
    const alarm_id = data?.alarm_id || data?.alarmId;
    const nurse = data?.nurse || data?.nurseName || 'Nurse Sarah Jenkins';
    if (!alarm_id) return;

    const alarm = activeAlarms.find(a => a.id === alarm_id);
    if (alarm && !alarm.isAcknowledged) {
      alarm.isAcknowledged = true;
      alarm.acknowledgedBy = nurse;
      resolvedAlarmsCount++;
    }
    try {
      db.acknowledgeAlarm(alarm_id, nurse);
    } catch (dbErr) {
      console.error('⚠️ [Socket SQL Ack Error]', dbErr.message);
    }
    console.log(`✅ [Alarm Ack] ${alarm_id} acknowledged by ${nurse}. Total resolved: ${resolvedAlarmsCount}`);
    io.emit('alarm_acknowledged', { alarmId: alarm_id, nurseName: nurse, resolvedAlarmsCount });
    io.emit('alarm_stats', { resolvedAlarmsCount, activeAlarmsCount: activeAlarms.filter(a => !a.isAcknowledged).length });
    io.emit('critical_alarm', activeAlarms);
  });

  // Client clears alarm
  socket.on('clear_alarm', (data) => {
    const alarm_id = data?.alarm_id || data?.alarmId;
    if (alarm_id) {
      const alarm = activeAlarms.find(a => a.id === alarm_id);
      if (alarm && !alarm.isAcknowledged) {
        resolvedAlarmsCount++;
      }
      activeAlarms = activeAlarms.filter(a => a.id !== alarm_id);
      try {
        db.clearAlarm(alarm_id);
      } catch (dbErr) {
        console.error('⚠️ [Socket SQL Clear Error]', dbErr.message);
      }
      if (alarm && telemetryState[alarm.bedId]) {
        telemetryState[alarm.bedId].status = 'optimal';
        io.emit('vitals_update', telemetryState);
      }
    } else {
      resolvedAlarmsCount += activeAlarms.filter(a => !a.isAcknowledged).length;
      activeAlarms = [];
      try {
        db.clearAlarm(null);
      } catch (dbErr) {
        console.error('⚠️ [Socket SQL Clear Error]', dbErr.message);
      }
      Object.keys(telemetryState).forEach(bed => {
        telemetryState[bed].status = 'optimal';
      });
      io.emit('vitals_update', telemetryState);
    }
    console.log(`🔕 [Socket.IO] Alarm ${alarm_id || 'ALL'} cleared. Total resolved: ${resolvedAlarmsCount}`);
    io.emit('alarm_cleared', { alarmId: alarm_id || 'ALL', resolvedAlarmsCount });
    io.emit('alarm_stats', { resolvedAlarmsCount, activeAlarmsCount: activeAlarms.length });
    io.emit('critical_alarm', activeAlarms);
  });

  socket.on('disconnect', () => {
    console.log(`🔴 [Socket.IO] Client disconnected: ${socket.id}`);
  });
});

// --- Simulation Ticker (Simulates ESP32 Gateway Telemetry Broadcasts) ---

let dbVitalsLogCounter = 0;

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

  // Periodically log telemetry snapshot to SQLite database
  dbVitalsLogCounter++;
  if (dbVitalsLogCounter % 3 === 0) {
    ['bed_01', 'bed_02', 'bed_03'].forEach(bedId => {
      const b = telemetryState[bedId];
      if (b) {
        try {
          db.logVitals({
            bedId,
            patientName: b.patientName,
            heartRate: b.heartRate,
            spo2: b.spo2,
            temperature: b.temperature,
            respiratoryRate: b.respiratoryRate || 16,
            bloodPressureSys: b.bloodPressureSys || 120,
            bloodPressureDia: b.bloodPressureDia || 80,
            status: b.status
          });
          db.updatePatientVitals(bedId, {
            heartRate: b.heartRate,
            spo2: b.spo2,
            temperature: b.temperature,
            status: b.status
          });
        } catch (dbErr) {
          // ignore duplicate ticks
        }
      }
    });
  }

  // Broadcast to all connected Flutter apps
  io.emit('vitals_update', telemetryState);
}, 1500);

// Auto-escalation countdown ticker
setInterval(() => {
  let changed = false;
  activeAlarms.forEach((alarm) => {
    // Only tick down if unacknowledged
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
          // Emit critical alarm only when a new escalation occurs!
          io.emit('critical_alarm', activeAlarms);
        }
      }
    }
  });

  // Emit timer tick so frontend countdown updates smoothly without triggering sound
  const hasUnack = activeAlarms.some(a => !a.isAcknowledged);
  if (changed && hasUnack) {
    io.emit('alarm_tick', activeAlarms);
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
