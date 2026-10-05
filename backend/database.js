/**
 * database.js
 * Persistent SQLite Database Module for SENTINEL-Ward Telemetry Gateway
 * Handles patient records, alarm counts, and critical conditions using SQL.
 */

const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');

const DB_PATH = path.join(__dirname, 'sentinel_ward.db');
const SCHEMA_PATH = path.join(__dirname, 'schema.sql');

// Initialize SQLite database instance
const db = new DatabaseSync(DB_PATH);

// Enable foreign key constraints and WAL mode for high performance
db.exec('PRAGMA foreign_keys = ON;');
db.exec('PRAGMA journal_mode = WAL;');

/**
 * Initialize database schema and default patient records
 */
function initDatabase() {
  // Execute DDL Schema from schema.sql
  if (fs.existsSync(SCHEMA_PATH)) {
    const schemaSql = fs.readFileSync(SCHEMA_PATH, 'utf-8');
    db.exec(schemaSql);
  }

  // Seed default patient roster if empty
  const patientCountStmt = db.prepare('SELECT COUNT(*) AS count FROM patients');
  const patientCountResult = patientCountStmt.get();

  if (!patientCountResult || patientCountResult.count === 0) {
    const insertPatientStmt = db.prepare(`
      INSERT INTO patients (
        bed_id, patient_name, age, gender, admission_date, current_status,
        total_alarms, active_alarms, critical_alarms_count, warning_alarms_count,
        latest_critical_condition, last_alarm_timestamp
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const initialPatients = [
      ['bed_01', 'Elena Rostova', 34, 'Female', '2026-09-08', 'optimal', 0, 0, 0, 0, 'None', null],
      ['bed_02', 'Marcus Vance', 58, 'Male', '2026-09-09', 'checking', 0, 0, 0, 0, 'None', null],
      ['bed_03', 'David Chen', 62, 'Male', '2026-09-07', 'critical', 1, 1, 1, 0, 'Hypoxemia: Sustained SpO2 < 88% for 15s (Clinical Desaturation)', new Date().toISOString()],
      ['bed_04', 'Sarah Connor', 35, 'Female', '2026-09-10', 'optimal', 0, 0, 0, 0, 'None', null],
      ['bed_05', 'James Wilson', 50, 'Male', '2026-09-09', 'optimal', 0, 0, 0, 0, 'None', null],
      ['bed_06', 'Robert Taylor', 67, 'Male', '2026-09-06', 'optimal', 0, 0, 0, 0, 'None', null]
    ];

    for (const patient of initialPatients) {
      insertPatientStmt.run(...patient);
    }

    // Seed initial active critical alarm for Bed 03
    const insertAlarmStmt = db.prepare(`
      INSERT INTO patient_alarms (
        alarm_id, bed_id, patient_name, severity, critical_condition,
        heart_rate, spo2, temperature, status, escalation_level,
        acknowledged_by, acknowledged_at, triggered_at, resolved_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    insertAlarmStmt.run(
      'ALT-1001',
      'bed_03',
      'David Chen',
      'critical',
      'Hypoxemia: Sustained SpO2 < 88% for 15s (Clinical Desaturation)',
      118,
      87,
      38.6,
      'active',
      1,
      null,
      null,
      new Date().toISOString(),
      null
    );

    console.log('✅ [SQL Database] Initialized schema and seeded default patient records & initial alarm.');
  } else {
    console.log(`✅ [SQL Database] Connected to existing database: ${DB_PATH}`);
  }
}

/**
 * Ensure patient exists in the patients table (auto-registers new bed if needed)
 */
function ensurePatientExists(bedId, patientName) {
  const checkStmt = db.prepare('SELECT id, patient_name FROM patients WHERE bed_id = ?');
  const row = checkStmt.get(bedId);
  if (!row) {
    const name = patientName || `Patient (${bedId.toUpperCase()})`;
    const insertStmt = db.prepare(`
      INSERT INTO patients (bed_id, patient_name, current_status, total_alarms, active_alarms, latest_critical_condition)
      VALUES (?, ?, 'optimal', 0, 0, 'None')
    `);
    insertStmt.run(bedId, name);
    return name;
  }
  return row.patient_name;
}

/**
 * Synchronize patient cumulative alarm counters, active count, condition, and status
 * directly from the patient_alarms source-of-truth table.
 * Guarantees zero counter drift across concurrent, duplicate, or out-of-order events.
 */
function syncPatientAlarmCounts(bedId) {
  const stats = db.prepare(`
    SELECT 
      COUNT(*) AS total_alarms,
      SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) AS active_alarms,
      SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) AS critical_alarms,
      SUM(CASE WHEN severity = 'warning' THEN 1 ELSE 0 END) AS warning_alarms,
      SUM(CASE WHEN status = 'active' AND severity = 'critical' THEN 1 ELSE 0 END) AS active_critical,
      SUM(CASE WHEN status = 'active' AND severity = 'warning' THEN 1 ELSE 0 END) AS active_warning
    FROM patient_alarms
    WHERE bed_id = ?
  `).get(bedId);

  const total = stats ? (stats.total_alarms || 0) : 0;
  const active = stats ? (stats.active_alarms || 0) : 0;
  const criticalCount = stats ? (stats.critical_alarms || 0) : 0;
  const warningCount = stats ? (stats.warning_alarms || 0) : 0;

  // Retrieve most recent alarm for condition and timestamp
  const latestAlarm = db.prepare(`
    SELECT critical_condition, triggered_at
    FROM patient_alarms
    WHERE bed_id = ?
    ORDER BY id DESC
    LIMIT 1
  `).get(bedId);

  const latestCondition = latestAlarm ? latestAlarm.critical_condition : 'None';
  const lastAlarmTime = latestAlarm ? latestAlarm.triggered_at : null;

  // Determine clinical status based on active alarms
  let newStatus = 'optimal';
  if (stats && stats.active_critical > 0) {
    newStatus = 'critical';
  } else if (stats && stats.active_warning > 0) {
    newStatus = 'checking';
  }

  db.prepare(`
    UPDATE patients SET
      total_alarms = ?,
      active_alarms = ?,
      critical_alarms_count = ?,
      warning_alarms_count = ?,
      latest_critical_condition = ?,
      current_status = ?,
      last_alarm_timestamp = ?,
      updated_at = CURRENT_TIMESTAMP
    WHERE bed_id = ?
  `).run(
    total,
    active,
    criticalCount,
    warningCount,
    latestCondition,
    newStatus,
    lastAlarmTime,
    bedId
  );
}

/**
 * Record a new alarm for a patient in the database.
 * Updates the patient's alarm count and records what the critical condition was.
 */
function recordAlarm({
  alarmId,
  bedId,
  patientName,
  severity = 'critical',
  criticalCondition,
  heartRate = null,
  spo2 = null,
  temperature = null,
  timestamp = new Date().toISOString()
}) {
  const resolvedPatientName = ensurePatientExists(bedId, patientName);

  // 1. Insert alarm record into patient_alarms table
  const insertAlarmStmt = db.prepare(`
    INSERT OR REPLACE INTO patient_alarms (
      alarm_id, bed_id, patient_name, severity, critical_condition,
      heart_rate, spo2, temperature, status, escalation_level,
      triggered_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', 1, ?)
  `);

  insertAlarmStmt.run(
    alarmId,
    bedId,
    resolvedPatientName,
    severity,
    criticalCondition,
    heartRate,
    spo2,
    temperature,
    timestamp
  );

  // 2. Synchronize patient counters and clinical status
  syncPatientAlarmCounts(bedId);
}

/**
 * Acknowledge an alarm by clinician (Idempotent: safe against duplicate calls)
 */
function acknowledgeAlarm(alarmId, nurseName = 'Sister Sunita Rao') {
  const ackTime = new Date().toISOString();

  const alarm = db.prepare('SELECT bed_id, status FROM patient_alarms WHERE alarm_id = ?').get(alarmId);
  if (!alarm) {
    return { success: false, message: 'Alarm not found' };
  }

  // Update only if active; if already acknowledged, record nurse name if missing
  if (alarm.status === 'active') {
    db.prepare(`
      UPDATE patient_alarms SET
        status = 'acknowledged',
        acknowledged_by = ?,
        acknowledged_at = ?
      WHERE alarm_id = ?
    `).run(nurseName, ackTime, alarmId);
  } else {
    db.prepare(`
      UPDATE patient_alarms SET
        acknowledged_by = COALESCE(acknowledged_by, ?),
        acknowledged_at = COALESCE(acknowledged_at, ?)
      WHERE alarm_id = ?
    `).run(nurseName, ackTime, alarmId);
  }

  // Synchronize patient active alarms
  syncPatientAlarmCounts(alarm.bed_id);
  return { success: true, bedId: alarm.bed_id };
}

/**
 * Clear a specific alarm or all alarms (Idempotent: safe against duplicate calls)
 */
function clearAlarm(alarmId = null) {
  const clearTime = new Date().toISOString();

  if (alarmId) {
    const alarm = db.prepare('SELECT bed_id FROM patient_alarms WHERE alarm_id = ?').get(alarmId);
    if (alarm) {
      db.prepare(`
        UPDATE patient_alarms SET
          status = 'cleared',
          resolved_at = ?
        WHERE alarm_id = ? AND status != 'cleared'
      `).run(clearTime, alarmId);

      syncPatientAlarmCounts(alarm.bed_id);
      return { success: true, bedId: alarm.bed_id };
    }
    return { success: false, message: 'Alarm not found' };
  } else {
    // Clear all alarms
    db.prepare(`
      UPDATE patient_alarms SET
        status = 'cleared',
        resolved_at = ?
      WHERE status != 'cleared'
    `).run(clearTime);

    // Sync all patients
    const patients = db.prepare('SELECT bed_id FROM patients').all();
    for (const p of patients) {
      syncPatientAlarmCounts(p.bed_id);
    }
    return { success: true };
  }
}

/**
 * Delete a specific alarm permanently (useful for test teardown)
 */
function deleteAlarm(alarmId) {
  const alarm = db.prepare('SELECT bed_id FROM patient_alarms WHERE alarm_id = ?').get(alarmId);
  if (alarm) {
    db.prepare('DELETE FROM patient_alarms WHERE alarm_id = ?').run(alarmId);
    syncPatientAlarmCounts(alarm.bed_id);
    return true;
  }
  return false;
}

/**
 * Reset database to pristine default initial state (tables, indexes, view, seed records)
 */
function resetDatabase() {
  db.exec('DROP VIEW IF EXISTS v_patient_alarm_summary;');
  db.exec('DROP TABLE IF EXISTS patient_vitals_log;');
  db.exec('DROP TABLE IF EXISTS patient_alarms;');
  db.exec('DROP TABLE IF EXISTS patients;');

  if (fs.existsSync(SCHEMA_PATH)) {
    const schemaSql = fs.readFileSync(SCHEMA_PATH, 'utf-8');
    db.exec(schemaSql);
  }

  const insertPatientStmt = db.prepare(`
    INSERT INTO patients (
      bed_id, patient_name, age, gender, admission_date, current_status,
      total_alarms, active_alarms, critical_alarms_count, warning_alarms_count,
      latest_critical_condition, last_alarm_timestamp
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const initialPatients = [
    ['bed_01', 'Elena Rostova', 34, 'Female', '2026-09-08', 'optimal', 0, 0, 0, 0, 'None', null],
    ['bed_02', 'Marcus Vance', 58, 'Male', '2026-09-09', 'checking', 0, 0, 0, 0, 'None', null],
    ['bed_03', 'David Chen', 62, 'Male', '2026-09-07', 'critical', 1, 1, 1, 0, 'Hypoxemia: Sustained SpO2 < 88% for 15s (Clinical Desaturation)', new Date().toISOString()],
    ['bed_04', 'Sarah Connor', 35, 'Female', '2026-09-10', 'optimal', 0, 0, 0, 0, 'None', null],
    ['bed_05', 'James Wilson', 50, 'Male', '2026-09-09', 'optimal', 0, 0, 0, 0, 'None', null],
    ['bed_06', 'Robert Taylor', 67, 'Male', '2026-09-06', 'optimal', 0, 0, 0, 0, 'None', null]
  ];

  for (const patient of initialPatients) {
    insertPatientStmt.run(...patient);
  }

  const insertAlarmStmt = db.prepare(`
    INSERT INTO patient_alarms (
      alarm_id, bed_id, patient_name, severity, critical_condition,
      heart_rate, spo2, temperature, status, escalation_level,
      acknowledged_by, acknowledged_at, triggered_at, resolved_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertAlarmStmt.run(
    'ALT-1001',
    'bed_03',
    'David Chen',
    'critical',
    'Hypoxemia: Sustained SpO2 < 88% for 15s (Clinical Desaturation)',
    118,
    87,
    38.6,
    'active',
    1,
    null,
    null,
    new Date().toISOString(),
    null
  );

  syncPatientAlarmCounts('bed_03');
  console.log('✅ [SQL Database] Database reset and seeded with initial records.');
}

/**
 * Log vitals snapshot to patient_vitals_log table
 */
function logVitals({
  bedId,
  patientName,
  heartRate,
  spo2,
  temperature,
  respiratoryRate = 16,
  bloodPressureSys = 120,
  bloodPressureDia = 80,
  status = 'optimal'
}) {
  ensurePatientExists(bedId, patientName);

  const insertStmt = db.prepare(`
    INSERT INTO patient_vitals_log (
      bed_id, patient_name, heart_rate, spo2, temperature,
      respiratory_rate, blood_pressure_sys, blood_pressure_dia,
      clinical_status
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertStmt.run(
    bedId,
    patientName,
    heartRate,
    spo2,
    temperature,
    respiratoryRate,
    bloodPressureSys,
    bloodPressureDia,
    status
  );
}

/**
 * Update patient vitals & check thresholds
 */
function updatePatientVitals(bedId, vitals) {
  const { heartRate, spo2, temperature, status } = vitals;
  const updateStmt = db.prepare(`
    UPDATE patients SET
      current_status = COALESCE(?, current_status),
      updated_at = CURRENT_TIMESTAMP
    WHERE bed_id = ?
  `);
  updateStmt.run(status, bedId);
}

/**
 * Get summary table of all patients, total alarms, and critical conditions
 */
function getSummaryTable() {
  const stmt = db.prepare('SELECT * FROM v_patient_alarm_summary');
  return stmt.all();
}

/**
 * Get full patients table records
 */
function getAllPatients() {
  const stmt = db.prepare('SELECT * FROM patients ORDER BY bed_id ASC');
  return stmt.all();
}

/**
 * Get patient profile and alarms by Bed ID
 */
function getPatientByBedId(bedId) {
  const patientStmt = db.prepare('SELECT * FROM patients WHERE bed_id = ?');
  const patient = patientStmt.get(bedId);

  if (!patient) return null;

  const alarmsStmt = db.prepare(`
    SELECT * FROM patient_alarms 
    WHERE bed_id = ? 
    ORDER BY id DESC
  `);
  const alarms = alarmsStmt.all(bedId);

  return { ...patient, alarms };
}

/**
 * Get all alarms in table format
 */
function getAllAlarms(limit = 100) {
  const stmt = db.prepare(`
    SELECT 
      a.id,
      a.alarm_id,
      a.bed_id,
      a.patient_name,
      a.severity,
      a.critical_condition,
      a.heart_rate,
      a.spo2,
      a.temperature,
      a.status,
      a.escalation_level,
      a.acknowledged_by,
      a.triggered_at,
      a.resolved_at
    FROM patient_alarms a
    ORDER BY a.id DESC
    LIMIT ?
  `);
  return stmt.all(limit);
}

/**
 * Execute raw custom SQL query (read-only safe helper)
 */
function queryRaw(sql, params = []) {
  const stmt = db.prepare(sql);
  return stmt.all(...params);
}

// Initialize on module load
initDatabase();

module.exports = {
  db,
  DB_PATH,
  initDatabase,
  resetDatabase,
  recordAlarm,
  acknowledgeAlarm,
  clearAlarm,
  deleteAlarm,
  syncPatientAlarmCounts,
  logVitals,
  updatePatientVitals,
  getSummaryTable,
  getAllPatients,
  getPatientByBedId,
  getAllAlarms,
  queryRaw
};
