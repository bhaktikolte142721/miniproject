# 🛡️ SENTINEL-Ward: Multi-Patient Vitals Telemetry System

> Production-grade Flutter healthcare application engineered for acute care multi-patient vitals telemetry across Bed 01, Bed 02, and Bed 03 via an ESP32 Ward Gateway and nRF24 wireless sensor nodes.

Strictly modeled after the **3D Claymorphic Medical UI Design System** with soft dual lighting shadows, rounded containers (`BorderRadius.circular(24)`), satin frosted pearl surfaces, and glossy 3D vital monitoring assets.

---

## 🎨 3D Claymorphic Design System

| Element | Specification | Visual Role |
| :--- | :--- | :--- |
| **Surgical Canvas** | `#F5F9FA` ➔ `#EDF4F6` | Soft gradient background preventing clinical eye fatigue |
| **Primary Accent** | Mint `#00BFA5` & Medical Teal `#00838F` | Active actions, high contrast telemetry labels, status indicators |
| **Frosted Pearl Cards** | Pure White `#FFFFFF` with `#E0F2F1` Border | Tactile floating 3D containers with subtle inner borders |
| **Alert Coral** | `#FF5252` (Critical) • `#FFB300` (Warning) • `#00C853` (Stable) | Tri-state clinical threshold classification |
| **Lighting Vectors** | `Offset(0, 10)` blur 20 + Specular `Offset(-4, -4)` blur 10 | Dual-directional claymorphic depth |

---

## 📱 6 Core Screen Modules

1. **Onboarding / Welcome Screen** (`lib/views/onboarding/onboarding_screen.dart`):
   - Soft cyan glow backdrop with floating micro-particles.
   - Hero centerpiece: Glossy 3D beating clay heart with glowing pulse ring & medical shield (`assets/images/vital_heart_3d.png`).
   - Tactile pill action button with circular forward arrow.
2. **Shift Handover & Ward Home** (`lib/views/handover/shift_handover_screen.dart`):
   - Nurse Sarah greeting, status indicator, notification bell with alarm badge.
   - Teal gradient Hero Card featuring live ESP32 gateway telemetry and 3D vital monitor (`assets/images/vital_monitor_3d.png`).
   - 4 Claymorphic quick actions: Book Rounds, Ward Grid, Alarms Feed, Node Diagnostics.
   - Circular Ward Stability Health Score gauge (96% Optimal).
3. **Multi-Patient Grid Dashboard** (`lib/views/ward_grid/multi_patient_grid_screen.dart`):
   - Live telemetry cards for Bed 01 (Elena Rostova), Bed 02 (Marcus Vance), and Bed 03 (David Chen).
   - 3D vital thumbnails (`vital_heart_3d.png`, `pulse_oximeter_3d.png`, `vital_monitor_3d.png`).
   - Real-time numerical telemetry triplet: Heart Rate (BPM), SpO2 (%), Temperature (°C).
   - nRF24 wireless RSSI signal strength 4-bar indicator (-58 dBm) & battery level pill (96%).
4. **Shift Rounds & Handover Schedule** (`lib/views/handover/schedule_handover_screen.dart`):
   - Interactive calendar selector with active day pill.
   - Shift rounds time slot pills (08:00 AM, 10:00 AM, 12:00 PM, etc.).
   - Attending triage physician profile card (Dr. Sarah Johnson, MD • 4.9 rating).
5. **Detailed Patient Monitoring & Diagnostics** (`lib/views/patient_detail/patient_monitoring_screen.dart`):
   - Subtabs: Overview, Live ECG Waveform, 15m Trends.
   - Centerpiece 3D organ asset with animated rhythm sweep.
   - Real-time `EcgSweepView` custom painter rendering P-Q-R-S-T cardiac waves at 50mm/s.
   - 15-minute physiological historical trend charts using `fl_chart`.
   - Direct Call Nurse Station intercom FAB and Acknowledge Alarm actions.
6. **Alert Escalation Feed & Console Settings** (`lib/views/alerts/alerts_feed_screen.dart`):
   - Active alarm incident cards with severity badges.
   - Real-time 60-second countdown auto-escalation progress bar to Ward Supervisor.
   - 3-tier escalation tracker: L1 Bedside Nurse ➔ L2 Ward Supervisor ➔ L3 Rapid Response (Code Blue).
   - Station settings: ESP32 Gateway config, nRF24 node diagnostics, audible buzzer toggle.

---

## 🔊 Clinical Alarm Sound System (IEC 60601-1-8)

Compliant with clinical telemetry alarm guidelines (`lib/core/utils/audio_alert_service.dart`):
- **Critical High-Priority Alarm**: Repeating urgent 3-pulse triplet burst (B5 987Hz, B5 987Hz, E6 1318Hz).
- **Warning Medium-Priority Alarm**: Two-tone descending chime (E5 659Hz ➔ C5 523Hz).
- **R-Wave Pulse Tick**: 45ms blip on cardiac peak detection.
- **Global Station Mute**: Instant override toggle with audible state persistence.

---

## 🚀 Running the Project

### Prerequisites
- Flutter SDK (v3.16.0 or higher)
- Dart SDK (v3.2.0 or higher)

### Setup & Run
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run unit & simulation tests
flutter test

# 3. Launch on Chrome / Android / Desktop
flutter run -d chrome
# or
flutter run -d windows
```
