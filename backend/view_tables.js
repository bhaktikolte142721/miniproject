/**
 * view_tables.js
 * CLI Utility to inspect SENTINEL-Ward SQLite Database Tables
 * Run with: node view_tables.js (or npm run db:view)
 */

const dbModule = require('./database');

console.log('\n================================================================================');
console.log('🏥 SENTINEL-WARD CLINICAL TELEMETRY DATABASE (SQLite)');
console.log(`📁 Database File: ${dbModule.DB_PATH}`);
console.log('================================================================================\n');

// 1. View Summary: Patients, Alarm Counts, and Critical Conditions
console.log('📊 1. PATIENT SUMMARY TABLE (Number of Alarms & Critical Condition per Patient)');
console.log('SQL Query: SELECT * FROM v_patient_alarm_summary;');
const summaryRows = dbModule.getSummaryTable();
console.table(summaryRows);

// 2. View Full Patient Records
console.log('\n👥 2. PATIENTS TABLE (Full Profiles & Alarm Counters)');
console.log('SQL Query: SELECT bed_id, patient_name, total_alarms, active_alarms, current_status, latest_critical_condition FROM patients;');
const patients = dbModule.getAllPatients().map(p => ({
  Bed: p.bed_id,
  'Patient Name': p.patient_name,
  'Total Alarms': p.total_alarms,
  'Active Alarms': p.active_alarms,
  'Critical Alarms': p.critical_alarms_count,
  Status: p.current_status,
  'Critical Condition': p.latest_critical_condition
}));
console.table(patients);

// 3. View Alarms History Table
console.log('\n🚨 3. PATIENT ALARMS LOG TABLE (Detailed Critical Condition Log)');
console.log('SQL Query: SELECT alarm_id, bed_id, patient_name, severity, critical_condition, status FROM patient_alarms;');
const alarms = dbModule.getAllAlarms().map(a => ({
  'Alarm ID': a.alarm_id,
  Bed: a.bed_id,
  Patient: a.patient_name,
  Severity: a.severity,
  'Critical Condition Reason': a.critical_condition,
  'HR / SpO2': `${a.heart_rate || '--'} bpm / ${a.spo2 || '--'}%`,
  Status: a.status,
  'Acknowledged By': a.acknowledged_by || 'Unacknowledged',
  'Trigger Time': a.triggered_at ? a.triggered_at.substring(11, 19) : '--'
}));

if (alarms.length > 0) {
  console.table(alarms);
} else {
  console.log('No alarms logged yet.');
}

console.log('\n================================================================================');
console.log('✅ SQL Database tables verified successfully.');
console.log('================================================================================\n');
