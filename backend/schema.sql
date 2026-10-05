-- =====================================================================
-- SENTINEL-Ward Clinical Telemetry SQL Database Schema
-- Multi-Patient Vitals, Alarms, and Critical Condition Records
-- =====================================================================

-- Enforce Foreign Key integrity
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- Table 1: patients
-- Holds patient profiles, cumulative alarm statistics, and condition
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bed_id TEXT UNIQUE NOT NULL,                          -- e.g., 'bed_01', 'bed_02'
    patient_name TEXT NOT NULL,                           -- e.g., 'Priya Sharma'
    age INTEGER DEFAULT 45,
    gender TEXT DEFAULT 'Unspecified',
    admission_date TEXT,
    current_status TEXT DEFAULT 'optimal',                -- 'optimal', 'checking', 'critical'
    total_alarms INTEGER DEFAULT 0,                       -- Total number of alarms for this patient
    active_alarms INTEGER DEFAULT 0,                      -- Currently unacknowledged/active alarms
    critical_alarms_count INTEGER DEFAULT 0,              -- Count of critical-severity alarms
    warning_alarms_count INTEGER DEFAULT 0,               -- Count of warning-severity alarms
    latest_critical_condition TEXT DEFAULT 'None',        -- Description of the critical condition
    last_alarm_timestamp TEXT,                            -- Timestamp of latest alarm
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast lookup by bed_id
CREATE INDEX IF NOT EXISTS idx_patients_bed_id ON patients(bed_id);

-- ---------------------------------------------------------------------
-- Table 2: patient_alarms
-- Detailed history of alarm incidents in table format for each patient
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patient_alarms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    alarm_id TEXT UNIQUE NOT NULL,                        -- e.g., 'ALT-1001'
    bed_id TEXT NOT NULL,                                 -- Foreign Key referencing patients
    patient_name TEXT NOT NULL,
    severity TEXT NOT NULL,                               -- 'critical', 'warning', 'advisory'
    critical_condition TEXT NOT NULL,                     -- Explanation of what was the critical condition
    heart_rate REAL,                                      -- Patient HR at alarm trigger
    spo2 REAL,                                            -- Patient SpO2 at alarm trigger
    temperature REAL,                                     -- Patient Temperature at alarm trigger
    status TEXT DEFAULT 'active',                         -- 'active', 'acknowledged', 'cleared'
    escalation_level INTEGER DEFAULT 1,                   -- 1: Bedside Nurse, 2: Supervisor, 3: Rapid Response
    acknowledged_by TEXT,                                 -- Nurse or clinician who acknowledged
    acknowledged_at TEXT,
    triggered_at TEXT NOT NULL,
    resolved_at TEXT,
    FOREIGN KEY (bed_id) REFERENCES patients(bed_id) ON DELETE CASCADE
);

-- Index for quick lookups and joins on bed_id
CREATE INDEX IF NOT EXISTS idx_alarms_bed_id ON patient_alarms(bed_id);
CREATE INDEX IF NOT EXISTS idx_alarms_severity ON patient_alarms(severity);
CREATE INDEX IF NOT EXISTS idx_alarms_status ON patient_alarms(status);

-- ---------------------------------------------------------------------
-- Table 3: patient_vitals_log
-- Telemetry log capturing vital snapshots over time for each patient
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patient_vitals_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bed_id TEXT NOT NULL,
    patient_name TEXT NOT NULL,
    heart_rate REAL,
    spo2 REAL,
    temperature REAL,
    respiratory_rate REAL,
    blood_pressure_sys INTEGER,
    blood_pressure_dia INTEGER,
    clinical_status TEXT,
    logged_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bed_id) REFERENCES patients(bed_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_vitals_bed_id ON patient_vitals_log(bed_id);

-- ---------------------------------------------------------------------
-- View: v_patient_alarm_summary
-- Presents summary data in table format showing each patient,
-- their total number of alarms, and their critical condition.
-- ---------------------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_patient_alarm_summary AS
SELECT 
    p.bed_id AS Bed,
    p.patient_name AS "Patient Name",
    p.total_alarms AS "Total Alarms",
    p.active_alarms AS "Active Alarms",
    p.latest_critical_condition AS "Critical Condition",
    p.current_status AS "Clinical Status",
    p.last_alarm_timestamp AS "Last Alarm Timestamp"
FROM patients p
ORDER BY p.bed_id ASC;
