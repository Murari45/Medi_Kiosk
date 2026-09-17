# AyuDwar — Multilingual Voice-Enabled Clinical Pre-Intake & Triage Platform

> **Smart India Hackathon (SIH 2026) Official Submission**  
> *A 100% Offline-First, Self-Contained, Voice-Guided Clinical Triage & OPD Pre-Intake Kiosk for Elderly and Multilingual Patients*

---

## 🌟 Executive Summary

**AyuDwar** bridges the critical communication and triage gap in high-volume Indian hospital Out-Patient Departments (OPDs). Designed specifically for low-literacy and elderly patients, the kiosk provides real-time voice-guided clinical pre-intake across **5 Indic languages**, calculates algorithmic triage priority (**P1 Urgent, P2 Moderate, P3 Routine**), structures dual clinical protocols (**Allopathy SOCRATES** and **AYUSH Dashavidha Pariksha**), and delivers a **3-Tier AI Consultation Summary** (100% Certain, Not Sure, Unclear) directly into the doctor's consultation terminal with instant PDF prescription generation.

The application operates **100% locally with SQLite** (`sqflite` + `sqflite_common_ffi`), requiring zero external cloud dependencies for full functional execution, and features built-in **simulated ABHA/ABDM** integration.

---

## 🎯 6 Fully Functional Core Pages

| Page | Screen Name | Key Functionalities |
|---|---|---|
| **Page 1** | **Language Selection Screen** | Supports English, Hindi (हिंदी), Tamil (தமிழ்), Telugu (తెలుగు), Bengali (বাংলা); Speaks *"Hello! Welcome to AyuDwar"* aloud; Interactive speaker buttons for every language; Animated pointer indicator; Smooth `GoRouter` transition. |
| **Page 2** | **Role & Auth Screen** | 3 User Roles (Patient, Doctor, Admin); ABHA ID (`patient_XXXX@abdm`) & phone sign-in; Working speech synthesis on buttons; In-app registration with Aadhaar/Mobile, saving directly to SQLite; Secure JWT session persistence. |
| **Page 3** | **Patient Dashboard** | Left sidebar navigation (Dashboard, Profile, Previous Summaries, Upload Docs, Upcoming Visits, Logout); Big action cards for **Allopathy** and **AYUSH** intake; Scanned docs list; Real-time editable health profile (blood type, allergies) saved to SQLite; Synchronized pointer + voice guidance. |
| **Page 4** | **Clinical Intake Screen** | **Allopathy SOCRATES** (Site, Onset, Character, Radiation, Associated, Timing, Exacerbating, Severity 1-10) & **AYUSH Dashavidha Pariksha** (Prakriti, Vikriti, Sara, Samhanana, Pramana, Satmya, Satva, Ahara Shakti, Vyayama Shakti, Vaya); Voiced questions (`flutter_tts`); Real-time microphone listening (`speech_to_text`) with live audio waveform; Repeat fallback *"I didn't quite catch that, could you please repeat?"*; Hesitation/uncertainty detection; Instant token generation (e.g. `TK-P1-042`) and auto-logout kiosk cleanup. |
| **Page 5** | **Doctor Dashboard** | Left sidebar (Queue, Schedule, History, Archives, Logout); Live prioritized patient queue sorted by P1 (Urgent Top), P2 (Moderate Middle), and P3 (Routine Bottom); Token badges, wait times, and symptom indicators fetched directly from SQLite; Direct navigation to Page 6 on patient tap. |
| **Page 6** | **Consultation & AI Summary** | **3-Tier AI Summary**: 🟢 **100% CERTAIN** (Verified facts), 🟡 **NOT SURE** (Patient hesitated), 🔴 **UNCLEAR** (Doctor clarification required); AI Voice Read-Aloud; Doctor speech modification; Hands-free **Voice Prescription dictation** with Medical NER (drug, dose, frequency, duration); Printable compliant PDF generation via `printing`. |

---

## 🏗️ 11-Module Clean Architecture Structure

```
lib/
├── main.dart                          # App Entrypoint, SQLite FFI, GetIt DI
└── src/
    ├── app/                           # App configuration, Theme, DI, GoRouter
    ├── database/                      # Module 9: Database Module
    │   ├── app_database.dart          # SQLite Engine & Cross-Platform schema
    │   ├── seed_data.dart             # Seed data with realistic Indian profiles
    │   └── daos/                      # UserDao, ClinicalSessionDao, PrescriptionDao, etc.
    ├── features/
    │   ├── auth/                      # Module 1: Auth Module
    │   ├── patient_dashboard/         # Module 2: Patient Module
    │   ├── clinical_intake/           # Module 3: Clinical Intake Module
    │   │   └── domain/                # SOCRATES, Dashavidha, & Triage Algorithms
    │   ├── doctor_dashboard/          # Module 4: Doctor Module
    │   ├── admin_panel/               # Module 5: Admin Module (fl_chart Analytics)
    │   ├── document_scanning/         # Module 6: Document & On-Device OCR Module
    │   ├── prescription/              # Module 7: Prescription & PDF Module
    │   └── summary/                   # Module 8: AI Consultation Summary Module
    ├── voice/                         # Module 10: Voice Module
    │   ├── services/                  # TTSService, STTService, BhashiniService
    │   └── widgets/                   # VoicePointerOverlay, AudioWaveformVisualizer
    └── shared/                        # Module 11: Shared Module
        ├── constants/                 # AppColors, 5-Language AppStrings dictionary
        ├── models/                    # Domain Data Entities
        └── services/                  # SecureStorage, MedicalNER, NotificationService
```

---

## 🚀 Quick Start & Running Locally

### Prerequisites
- Flutter SDK (`^3.12.2` or later)
- macOS, Windows, Linux, iOS, Android, or Web

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Tests
```bash
flutter test
```

### 3. Run the Application
```bash
# Run on macOS Desktop
flutter run -d macos

# Run on Chrome Web
flutter run -d chrome
```

---

## 🔑 Demo Credentials (Pre-Seeded in Local SQLite)

| Role | Username / ABHA ID | Password | Access Area |
|---|---|---|---|
| **Patient** | `patient_1024@abdm` *(or `9876543210`)* | `patient123` | Patient Portal, Allopathy/AYUSH Intake, Document Scanner |
| **Doctor** | `dr_sharma@abdm` | `doctor123` | Doctor Queue, Consultation Suite, 3-Tier Summary, Voice Rx |
| **Admin** | `admin_kiosk@abdm` | `admin123` | Analytics Charts, User CRUD, Audit Trail, ABDM Settings |

---

## 🔒 Security & DPDP Compliance
- **Zero Cloud Leakage**: Clinical sessions, OCR transcripts, and voice logs are processed and stored locally in encrypted SQLite.
- **Role-Based Access Control (RBAC)**: Distinct permissions for Patient, Doctor, and Administrator.
- **Kiosk Privacy Auto-Reset**: Token screen auto-logs out and clears in-memory state after a countdown.
