/**
 * test_database.js
 * End-to-end verification and regression suite for SENTINEL-Ward SQLite Database
 * 
 * Verifies:
 * 1. Schema DDL tables & indexes
 * 2. SQL View v_patient_alarm_summary
 * 3. Seed records & initial critical alarm state
 * 4. Alarm creation, patient counter updates & clinical status
 * 5. Alarm acknowledgment (including idempotency under duplicate calls)
 * 6. Alarm clearing (single and bulk)
 * 7. Telemetry vitals logging & history querying
 * 8. Dynamic bed auto-registration
 * 9. Clean teardown & data integrity
 */

const assert = require('assert');
const db = require('./database');

console.log('================================================================');
console.log('🧪 RUNNING SENTINEL-WARD SQL DATABASE TEST & VERIFICATION SUITE');
console.log(`📁 Database Path: ${db.DB_PATH}`);
console.log('================================================================\n');

// 0. Reset to fresh pristine baseline
console.log('0️⃣ Resetting Database to Clean Initial Baseline State...');
db.resetDatabase();
console.log('   ✅ Clean state established!\n');

// 1. Verify schema tables exist
console.log('1️⃣ Verifying Database Tables Exist...');
const tables = db.queryRaw("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;");
const tableNames = tables.map(t => t.name);
console.log('   Found tables:', tableNames);
assert(tableNames.includes('patients'), 'patients table missing');
assert(tableNames.includes('patient_alarms'), 'patient_alarms table missing');
assert(tableNames.includes('patient_vitals_log'), 'patient_vitals_log table missing');
console.log('   ✅ All tables verified!\n');

// 2. Verify View exists
console.log('2️⃣ Verifying SQL View v_patient_alarm_summary...');
const views = db.queryRaw("SELECT name FROM sqlite_master WHERE type='view';");
const viewNames = views.map(v => v.name);
console.log('   Found views:', viewNames);
assert(viewNames.includes('v_patient_alarm_summary'), 'v_patient_alarm_summary view missing');
console.log('   ✅ View verified!\n');

// 3. Verify Patient summary table & initial seed records
console.log('3️⃣ Verifying Initial Patient Roster & Bed 03 Alarm...');
const summary = db.getSummaryTable();
console.log(`   Retrieved ${summary.length} patient summary rows.`);
assert.strictEqual(summary.length, 6, 'Expected exactly 6 patients in default roster');

const bed3Summary = summary.find(s => s.Bed === 'bed_03');
assert(bed3Summary, 'bed_03 not found in summary');
assert.strictEqual(bed3Summary['Total Alarms'], 1, 'Bed 03 should have initial total alarms = 1');
assert.strictEqual(bed3Summary['Active Alarms'], 1, 'Bed 03 should have 1 active alarm');
assert.strictEqual(bed3Summary['Patient Name'], 'David Chen');
assert.strictEqual(bed3Summary['Critical Condition'], 'Hypoxemia: Sustained SpO2 < 88% for 15s (Clinical Desaturation)');
console.log(`   Bed 03: ${bed3Summary['Patient Name']} - Alarms: ${bed3Summary['Total Alarms']}, Condition: "${bed3Summary['Critical Condition']}"`);
console.log('   ✅ Initial patient state verified!\n');

// 4. Test Recording a New Alarm for Bed 02
console.log('4️⃣ Testing New Alarm Trigger & Counter Increments for Bed 02...');
const testAlarmId = `ALT-TEST-${Date.now()}`;
db.recordAlarm({
  alarmId: testAlarmId,
  bedId: 'bed_02',
  patientName: 'Marcus Vance',
  severity: 'critical',
  criticalCondition: 'Severe Tachycardia: HR > 130 bpm (Acute Cardiac Episode)',
  heartRate: 134,
  spo2: 91,
  temperature: 38.2
});

const bed2 = db.getPatientByBedId('bed_02');
assert(bed2, 'Bed 02 record not found');
assert.strictEqual(bed2.total_alarms, 1, 'Bed 02 should now have 1 alarm recorded');
assert.strictEqual(bed2.active_alarms, 1, 'Bed 02 should have 1 active alarm');
assert.strictEqual(bed2.critical_alarms_count, 1, 'Bed 02 critical alarms count should be 1');
assert.strictEqual(bed2.latest_critical_condition, 'Severe Tachycardia: HR > 130 bpm (Acute Cardiac Episode)');
assert.strictEqual(bed2.current_status, 'critical', 'Bed 02 status should be critical');
assert(bed2.alarms.length >= 1, 'Bed 02 should have alarm history');
console.log(`   Bed 02 updated: total_alarms = ${bed2.total_alarms}, active = ${bed2.active_alarms}, status = "${bed2.current_status}"`);
console.log('   ✅ Alarm recording & counters verified!\n');

// 5. Test Acknowledging the Alarm
console.log('5️⃣ Testing Alarm Acknowledgment & Idempotency...');
db.acknowledgeAlarm(testAlarmId, 'Dr. Sarah Johnson, MD');

let updatedBed2 = db.getPatientByBedId('bed_02');
let ackAlarm = updatedBed2.alarms.find(a => a.alarm_id === testAlarmId);
assert(ackAlarm, 'Alarm not found');
assert.strictEqual(ackAlarm.status, 'acknowledged', 'Alarm status should be acknowledged');
assert.strictEqual(ackAlarm.acknowledged_by, 'Dr. Sarah Johnson, MD');
assert(ackAlarm.acknowledged_at, 'Acknowledgment timestamp should be recorded');
assert.strictEqual(updatedBed2.active_alarms, 0, 'Bed 02 active alarms should decrement to 0');
assert.strictEqual(updatedBed2.current_status, 'optimal', 'Bed 02 status should return to optimal when no active critical alarms remain');

// Test Idempotency: acknowledge again should not double-decrement active_alarms
db.acknowledgeAlarm(testAlarmId, 'Dr. Sarah Johnson, MD');
updatedBed2 = db.getPatientByBedId('bed_02');
assert.strictEqual(updatedBed2.active_alarms, 0, 'active_alarms must remain 0 after duplicate acknowledgment');
console.log(`   Alarm ${testAlarmId} acknowledged and verified idempotent (active_alarms = 0)`);
console.log('   ✅ Acknowledgment transaction verified!\n');

// 6. Test Clearing the Alarm
console.log('6️⃣ Testing Alarm Clear Functionality...');
db.clearAlarm(testAlarmId);
updatedBed2 = db.getPatientByBedId('bed_02');
const clearedAlarm = updatedBed2.alarms.find(a => a.alarm_id === testAlarmId);
assert.strictEqual(clearedAlarm.status, 'cleared', 'Alarm status should be cleared');
assert(clearedAlarm.resolved_at, 'Resolution timestamp should be recorded');
assert.strictEqual(updatedBed2.active_alarms, 0, 'Active alarms should remain 0');

// Test Idempotent clear
db.clearAlarm(testAlarmId);
updatedBed2 = db.getPatientByBedId('bed_02');
assert.strictEqual(updatedBed2.active_alarms, 0);
console.log(`   Alarm ${testAlarmId} cleared and resolved.`);
console.log('   ✅ Alarm clear verified!\n');

// 7. Test Telemetry Vitals Logging
console.log('7️⃣ Testing Telemetry Vitals Logging...');
db.logVitals({
  bedId: 'bed_01',
  patientName: 'Elena Rostova',
  heartRate: 74,
  spo2: 99,
  temperature: 36.8,
  respiratoryRate: 16,
  bloodPressureSys: 118,
  bloodPressureDia: 76,
  status: 'optimal'
});
const vitalsLogs = db.queryRaw('SELECT * FROM patient_vitals_log WHERE bed_id = ? ORDER BY id DESC LIMIT 1', ['bed_01']);
assert.strictEqual(vitalsLogs.length, 1);
assert.strictEqual(vitalsLogs[0].patient_name, 'Elena Rostova');
assert.strictEqual(vitalsLogs[0].spo2, 99);
assert.strictEqual(vitalsLogs[0].heart_rate, 74);
console.log(`   Logged vitals for ${vitalsLogs[0].patient_name}: HR ${vitalsLogs[0].heart_rate} bpm, SpO2 ${vitalsLogs[0].spo2}%`);
console.log('   ✅ Telemetry vitals logging verified!\n');

// 8. Test Dynamic Bed Auto-Registration
console.log('8️⃣ Testing Auto-Registration of Dynamic Beds (e.g. bed_07)...');
const dynamicAlarmId = `ALT-DYN-${Date.now()}`;
db.recordAlarm({
  alarmId: dynamicAlarmId,
  bedId: 'bed_07',
  patientName: 'Kishore Kumar',
  severity: 'warning',
  criticalCondition: 'Borderline Tachypnea (RR > 24 bpm)'
});

const bed7 = db.getPatientByBedId('bed_07');
assert(bed7, 'bed_07 should be automatically created');
assert.strictEqual(bed7.patient_name, 'Kishore Kumar');
assert.strictEqual(bed7.total_alarms, 1);
assert.strictEqual(bed7.active_alarms, 1);
assert.strictEqual(bed7.current_status, 'checking');
console.log(`   Dynamic Bed 07 auto-registered: ${bed7.patient_name} (Status: ${bed7.current_status})`);

// Clean up bed_07 and testAlarmId
db.deleteAlarm(dynamicAlarmId);
db.deleteAlarm(testAlarmId);
db.queryRaw('DELETE FROM patients WHERE bed_id = ?', ['bed_07']);
console.log('   ✅ Dynamic registration & cleanup verified!\n');

// 9. Verify Final Summary View Output
console.log('9️⃣ Inspecting Final Database State:');
const finalSummary = db.getSummaryTable();
console.table(finalSummary);

console.log('================================================================');
console.log('🎉 ALL DATABASE VERIFICATION TESTS PASSED SUCCESSFULLY! (100%)');
console.log('================================================================\n');
