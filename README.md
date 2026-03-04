# PillCare – Smart Pill Reminder System

**A complete IoT medication management system** combining a Flutter mobile app with an ESP8266-powered smart pill dispenser. Patients and caregivers can track medications, monitor adherence in real-time, and receive hardware-triggered reminders — all synced through Firebase.

---

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Firebase Setup](#firebase-setup)
  - [Flutter App Setup](#flutter-app-setup)
  - [ESP8266 Firmware Setup](#esp8266-firmware-setup)
- [Hardware Wiring](#hardware-wiring)
- [How It Works](#how-it-works)
- [Environment Variables](#environment-variables)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

PillCare bridges the gap between medication management software and physical pill dispensing hardware. The system consists of two major components:

| Component | Description |
|-----------|-------------|
| **Flutter App** | Cross-platform mobile app for patients and caregivers to manage medications, schedules, adherence tracking, AI health assistant, and real-time alerts |
| **ESP8266 Firmware** | Smart pill dispenser firmware that controls LEDs, OLED display, IR sensors, buzzer, and lid switch — syncing schedules and status with Firebase in real time |

---

## System Architecture

```
┌─────────────────────┐        ┌──────────────────┐        ┌─────────────────────┐
│    Flutter App       │        │   Firebase Cloud  │        │  ESP8266 Hardware    │
│  (Android / iOS)     │◄──────►│                  │◄──────►│  (Smart Dispenser)   │
│                      │        │  ┌──────────────┐│        │                      │
│  • Patient Portal    │        │  │  Firestore   ││        │  • OLED Display      │
│  • Caregiver Portal  │        │  │  (App Data)  ││        │  • WS2812B LEDs      │
│  • AI Chat (Groq)    │        │  ├──────────────┤│        │  • IR Sensors (x3)   │
│  • Medication CRUD   │        │  │  Realtime DB ││        │  • Buzzer            │
│  • Schedule View     │        │  │  (Hardware)  ││        │  • Lid Switch        │
│  • Adherence Charts  │        │  ├──────────────┤│        │  • WiFi (AP + STA)   │
│  • Push Alerts       │        │  │  Firebase    ││        │                      │
│                      │        │  │  Auth        ││        │  Reads schedule from │
│                      │        │  └──────────────┘│        │  RTDB, writes pill   │
│                      │        │                  │        │  taken/missed status │
└─────────────────────┘        └──────────────────┘        └─────────────────────┘
```

- **Flutter App ↔ Firestore**: Medications, user profiles, caregiver links, history
- **ESP8266 ↔ Realtime Database**: Pill schedules (read), dispense status (write)
- **Firebase Auth**: Shared authentication — the hardware logs in with the patient's credentials to access their schedule

---

## Features

### Mobile App (Flutter)

- **Patient Dashboard** – Daily adherence ring, medication list, quick actions
- **Medication Management** – Add/edit/delete medications with dosage, schedule, color-coded icons
- **Interactive Schedule** – Monthly calendar with vertical timeline and animated refill counter
- **Caregiver Portal** – Link patients via QR code, monitor adherence, manage multiple patients
- **AI Health Assistant** – Powered by Groq (LLaMA 3.3 70B) for medication Q&A with streaming responses
- **Smart Alerts** – Missed dose notifications, refill warnings, caregiver messages
- **Medication History** – Detailed adherence history with trend visualization
- **Profile & Settings** – BMI calculator, notification preferences, smart dispenser pairing, theme toggle
- **Secure Auth** – Firebase Authentication with role-based access (patient/caregiver)
- **Glassmorphic UI** – Premium design with backdrop blur, animations, and smooth transitions

### Hardware (ESP8266 Smart Dispenser)

- **3-Slot Pill Compartments** – Morning, Evening, Night with individual IR sensors
- **Visual Reminders** – WS2812B RGB LEDs per slot (green = pending, blue = taken, red = missed)
- **Audio Alerts** – Active buzzer with escalating reminder patterns
- **OLED Display** – 128×64 SSD1306 showing time, WiFi status, next medication, slot states
- **Lid Detection** – Limit switch tracks when the dispenser is opened
- **WiFi Configuration** – AP mode with captive portal for first-time setup (no hardcoded credentials)
- **Firebase Sync** – Authenticates as the patient, reads schedule, writes pill taken/missed events
- **NTP Time Sync** – Automatic time synchronization for accurate scheduling
- **EEPROM Persistence** – Stores WiFi credentials and schedule across power cycles
- **Midnight Auto-Reset** – Automatically resets all slots for the new day

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile App | Flutter 3.x / Dart |
| State Management | ChangeNotifier + ListenableBuilder (Singleton pattern) |
| Backend | Firebase (Auth + Cloud Firestore + Realtime Database) |
| AI Service | Groq API (LLaMA 3.3 70B Versatile) |
| Hardware MCU | ESP8266 (NodeMCU v2) |
| Firmware Build | PlatformIO (Arduino framework) |
| Display | SSD1306 OLED 128×64 (I2C) |
| LEDs | WS2812B NeoPixel (×3) |
| Sensors | IR Obstacle Sensors (×3) + Limit Switch |
| QR Linking | qr_flutter + mobile_scanner |

---

## Project Structure

```
pillCare/
│
├── lib/                              # Flutter App Source
│   ├── main.dart                     # App entry point, Firebase init, auth gate
│   ├── firebase_options.dart         # Firebase configuration (auto-generated)
│   │
│   ├── models/
│   │   ├── medication.dart           # Medication data model + presets
│   │   └── patient_info.dart         # Patient model for caregiver portal
│   │
│   ├── screens/
│   │   ├── home_screen.dart          # Main screen with bottom navigation
│   │   ├── home_content.dart         # Dashboard (adherence ring, med list)
│   │   ├── schedule_screen.dart      # Calendar + medication timeline
│   │   ├── history_screen.dart       # Adherence history viewer
│   │   ├── alerts_screen.dart        # Notification center
│   │   ├── profile_screen.dart       # User profile + QR code + settings
│   │   ├── login_screen.dart         # Email/password login
│   │   ├── signup_screen.dart        # Registration with role selection
│   │   ├── forgot_password_screen.dart # Password reset flow
│   │   ├── ai_chat_screen.dart       # AI health assistant chat
│   │   ├── all_medications_screen.dart # Full medication list
│   │   ├── add_medication_sheet.dart  # Bottom sheet for adding medications
│   │   ├── patient_chat_screen.dart   # Patient-caregiver messaging
│   │   ├── ai_health_insights_card.dart # AI insights widget
│   │   ├── daily_adherence_card.dart  # Circular progress widget
│   │   ├── refill_counter_widget.dart # Animated refill tracker
│   │   │
│   │   ├── caregiver/                # Caregiver Portal
│   │   │   ├── caregiver_home.dart   # Caregiver main screen + tabs
│   │   │   ├── overview_tab.dart     # Dashboard overview
│   │   │   ├── patients_tab.dart     # Linked patients list
│   │   │   ├── patient_detail_screen.dart # Individual patient view
│   │   │   ├── alerts_tab.dart       # Caregiver alerts
│   │   │   ├── analytics_tab.dart    # Adherence analytics
│   │   │   ├── caregiver_profile_tab.dart # Caregiver profile
│   │   │   └── chat_screen.dart      # Chat with patient
│   │   │
│   │   ├── settings/                 # Settings Sub-pages
│   │   │   ├── notifications_page.dart
│   │   │   ├── medication_schedule_page.dart
│   │   │   ├── smart_dispenser_page.dart
│   │   │   ├── privacy_security_page.dart
│   │   │   ├── help_support_page.dart
│   │   │   └── about_page.dart
│   │   │
│   │   └── components/
│   │       └── history_components.dart # Reusable history widgets
│   │
│   └── services/
│       ├── auth_service.dart          # Firebase Auth wrapper (sign in/up/out)
│       ├── firestore_service.dart     # Firestore CRUD for medications
│       ├── medication_store.dart      # Singleton state (ChangeNotifier)
│       ├── caregiver_store.dart       # Caregiver state + linked patients
│       ├── ai_service.dart            # Groq API streaming client
│       ├── history_store.dart         # Medication history state
│       ├── patient_alerts_store.dart  # Patient alerts state
│       ├── theme_provider.dart        # Light/dark theme management
│       └── firebase_setup_test.dart   # Firebase connection test utility
│
├── firmware/                          # ESP8266 Firmware (PlatformIO)
│   ├── platformio.ini                 # Build config, dependencies
│   ├── README.md                      # Firmware-specific documentation
│   └── src/
│       ├── main.cpp                   # Entry point (setup + loop)
│       ├── config.h                   # Pin definitions, constants, structs
│       ├── wifi_manager.h/.cpp        # WiFi STA + AP captive portal
│       ├── firebase_handler.h/.cpp    # Firebase RTDB auth + sync
│       ├── hardware.h/.cpp            # LEDs, IR sensors, buzzer, lid switch
│       ├── display_manager.h/.cpp     # OLED display rendering
│       ├── storage.h/.cpp             # EEPROM persistence
│       └── reminder.h/.cpp            # Reminder state machine
│
├── android/                           # Android platform files
├── ios/                               # iOS platform files
├── assets/                            # App assets
├── pubspec.yaml                       # Flutter dependencies
├── .env                               # Environment variables (not committed)
└── README.md                          # This file
```

---

## Getting Started

### Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | ≥ 3.0 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Android Studio / VS Code | Latest | IDE with Flutter plugin |
| PlatformIO | ≥ 6.0 | [platformio.org](https://platformio.org/install) |
| Git | Latest | [git-scm.com](https://git-scm.com/) |
| Firebase CLI | Latest | `npm install -g firebase-tools` |

### Firebase Setup

1. **Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com/)

2. **Enable Authentication**:
   - Go to **Authentication → Sign-in method**
   - Enable **Email/Password** provider

3. **Create Cloud Firestore** database:
   - Go to **Firestore Database → Create Database**
   - Start in **test mode** (or configure rules for production)

4. **Create Realtime Database** (for ESP8266):
   - Go to **Realtime Database → Create Database**
   - Choose your region
   - Set rules:
     ```json
     {
       "rules": {
         "users": {
           "$uid": {
             ".read": "$uid === auth.uid",
             ".write": "$uid === auth.uid"
           }
         }
       }
     }
     ```

5. **Register your Flutter app**:
   - Add an Android app with your package name
   - Download `google-services.json` to `android/app/`
   - Run: `flutterfire configure`

6. **Get your Web API Key**:
   - Go to **Project Settings → General**
   - Copy the **Web API Key** (needed for ESP8266 firmware)

### Flutter App Setup

```bash
# 1. Clone the repository
git clone https://github.com/Am4l-babu/pillCare.git
cd pillCare

# 2. Install dependencies
flutter pub get

# 3. Create .env file in root
cat > .env << EOF
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_bucket
EOF

# 4. Run on connected device
flutter run

# 5. Build release APK
flutter build apk --release
```

### ESP8266 Firmware Setup

```bash
# 1. Navigate to firmware directory
cd firmware

# 2. Update Firebase credentials in src/config.h
#    - Set FIREBASE_API_KEY to your Web API Key
#    - Set FIREBASE_DB_URL to your Realtime Database URL

# 3. Build the firmware
pio run

# 4. Flash to ESP8266 (auto-detects COM port)
pio run --target upload

# 5. First-time WiFi setup:
#    - ESP8266 creates AP: "PillCare-Setup"
#    - Connect to it from your phone
#    - Browse to 192.168.4.1
#    - Enter your WiFi credentials + Firebase login (patient email/password)
#    - Device reboots and connects automatically
```

---

## Hardware Wiring

### Components Required

| Component | Quantity | Purpose |
|-----------|----------|---------|
| ESP8266 NodeMCU v2 | 1 | Main microcontroller |
| SSD1306 OLED 128×64 | 1 | Status display |
| WS2812B LED Strip | 3 LEDs | Slot indicators |
| IR Obstacle Sensor | 3 | Pill detection per slot |
| Active Buzzer | 1 | Audio reminders |
| Limit Switch | 1 | Lid open/close detection |
| 330Ω Resistor | 1 | LED data line protection |
| 10kΩ Resistor | 1 | Lid switch pull-up |
| 1000µF Capacitor | 1 | LED power smoothing |

### Wiring Diagram

```
ESP8266 NodeMCU
┌──────────────────────────────────┐
│                                  │
│  D1 (GPIO5)  ──────── OLED SCL  │
│  D2 (GPIO4)  ──────── OLED SDA  │
│                                  │
│  D4 (GPIO2)  ──330Ω── WS2812B   │
│                                  │
│  D5 (GPIO14) ──── IR Morning    │
│  D6 (GPIO12) ──── IR Evening    │
│  D7 (GPIO13) ──── IR Night      │
│                                  │
│  D0 (GPIO16) ──── Buzzer (+)    │
│                                  │
│  D3 (GPIO0) ───┬── Lid Switch   │
│                10kΩ              │
│                3.3V              │
│                                  │
│  5V ──── OLED, LEDs, IR VCC     │
│  GND ─── All GND                │
└──────────────────────────────────┘
```

### Pin Mapping Reference

| ESP8266 Pin | GPIO | Connected To |
|-------------|------|-------------|
| D0 | GPIO16 | Active Buzzer (+) |
| D1 | GPIO5 | OLED SCL (I2C Clock) |
| D2 | GPIO4 | OLED SDA (I2C Data) |
| D3 | GPIO0 | Lid Limit Switch |
| D4 | GPIO2 | WS2812B LED Data In |
| D5 | GPIO14 | IR Sensor – Morning Slot |
| D6 | GPIO12 | IR Sensor – Evening Slot |
| D7 | GPIO13 | IR Sensor – Night Slot |

---

## How It Works

### User Flow

```
1. Sign Up → Patient or Caregiver role selection
          │
2. Add Medications → Name, dosage, time (Morning/Evening/Night)
          │
3. Pair Hardware → ESP8266 reads schedule from Firebase RTDB
          │
4. Daily Reminders → Buzzer sounds + LED flashes at scheduled time
          │
5. Take Pill → IR sensor detects removal → Firebase → App updates
          │
6. Missed Dose → After timeout → Red LED → Caregiver notified
          │
7. Caregiver View → Real-time adherence dashboard + alerts
```

### Reminder State Machine (ESP8266)

```
    ┌─────────┐
    │  IDLE   │ ← Not yet time for this slot
    └────┬────┘
         │ (scheduled time reached)
    ┌────▼────┐
    │ PENDING │ → LED flashes green, buzzer beeps
    └────┬────┘
         │
    ┌────┴────┐
    │         │
┌───▼──┐  ┌──▼───┐
│ TAKEN │  │MISSED│ ← After 30-minute window
│(blue) │  │(red) │
└──────┘  └──────┘
    │         │
    └────┬────┘
         │ (midnight)
    ┌────▼────┐
    │  RESET  │ → All slots back to IDLE
    └─────────┘
```

### Data Flow

```
Patient adds medication in Flutter app
        │
        ▼
Cloud Firestore (medications collection)
        │
        ▼ (Cloud Function or app writes to RTDB)
Realtime Database: /users/{uid}/schedule
        │
        ▼
ESP8266 reads schedule every 60 seconds
        │
        ▼
At scheduled time → Buzzer + LED + OLED display
        │
        ▼ (IR sensor detects pill removal)
ESP8266 writes to /users/{uid}/status
        │
        ▼
Flutter app reads status → Updates adherence percentage
```

---

## Environment Variables

### Flutter App (`.env` file in project root)

```env
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
GROQ_API_KEY=your_groq_api_key          # For AI Health Assistant
```

### ESP8266 Firmware (`firmware/src/config.h`)

```cpp
#define FIREBASE_API_KEY   "your_web_api_key"
#define FIREBASE_DB_URL    "https://your-project.firebaseio.com"
```

> **Security Note:** Never commit API keys to version control. Use environment variables or a secrets manager for production.

---

## App Screens

| Screen | Description |
|--------|-------------|
| **Login / Sign Up** | Email/password auth with role selection (Patient or Caregiver) |
| **Home Dashboard** | Daily adherence ring, today's medications, AI insights card |
| **Schedule** | Monthly calendar, medication timeline, animated refill counter |
| **History** | Adherence trend visualization with filterable events |
| **Alerts** | Missed doses, delayed doses, refill warnings, caregiver messages |
| **AI Chat** | Conversational health assistant (Groq LLaMA 3.3 70B) with streaming |
| **Profile** | QR code for caregiver linking, BMI calculator, settings |
| **Caregiver Home** | Overview, patients list, alerts, analytics, chat |
| **Smart Dispenser** | Hardware pairing and status page |

---

## Caregiver-Patient Linking

1. **Patient** opens Profile → QR Code is displayed (contains their UID)
2. **Caregiver** scans the QR code from their Patients tab
3. A Firestore document link is created between the two accounts
4. Caregiver can now view the patient's medications, adherence, and hardware status in real-time

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -m 'Add my feature'`
4. Push to branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## License

This project is open-source and available under the [MIT License](LICENSE).

---

<p align="center">
  <strong>Built with Flutter + Firebase + ESP8266</strong><br>
  PillCare – Because every dose matters.
</p>
