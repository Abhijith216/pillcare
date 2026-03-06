# Smart Pill Reminder – ESP8266 Firmware

Complete PlatformIO firmware for the **PillCare** smart pill reminder hardware device.

---

## Required Libraries

| Library | Version | Purpose |
|---------|---------|---------|
| Firebase Arduino Client (mobizt) | ≥ 4.4.14 | Firebase RTDB read/write |
| Adafruit NeoPixel | ≥ 1.12.0 | WS2812B RGB LED control |
| Adafruit SSD1306 | ≥ 2.5.9 | OLED display driver |
| Adafruit GFX Library | ≥ 1.11.9 | Graphics primitives for OLED |
| Adafruit BusIO | ≥ 1.16.1 | I2C abstraction (SSD1306 dep) |

> All libraries are auto-installed by PlatformIO from `platformio.ini`.

---

## Hardware Wiring Diagram

```
ESP8266 NodeMCU
┌──────────────────────────────────┐
│                                  │
│  D1 (GPIO5)  ──────── OLED SCL  │
│  D2 (GPIO4)  ──────── OLED SDA  │
│                                  │
│  D4 (GPIO2)  ──330Ω── WS2812B DIN │
│                                  │
│  D5 (GPIO14) ──────── IR Morning OUT │
│  D6 (GPIO12) ──────── IR Evening OUT │
│  D7 (GPIO13) ──────── IR Night   OUT │
│                                  │
│  D0 (GPIO16) ──────── Buzzer (+) │
│                                  │
│  D3 (GPIO0)  ──────── Lid Switch │
│        │                         │
│       10K                        │
│        │                         │
│      3.3V                        │
│                                  │
│  5V  ──────── OLED VCC           │
│  5V  ──────── WS2812B VCC       │
│  5V  ──────── IR Sensors VCC     │
│  GND ──────── (all GND)         │
└──────────────────────────────────┘
```

### Detailed Connections

#### I2C OLED Display (SSD1306, 128×64)
| OLED Pin | ESP8266 Pin |
|----------|-------------|
| SCL | D1 (GPIO5) |
| SDA | D2 (GPIO4) |
| VCC | 3.3 V **or** 5 V |
| GND | GND |

#### WS2812B RGB LEDs (3 LEDs chained)
| LED Strip | ESP8266 Pin |
|-----------|-------------|
| DIN | D4 (GPIO2) via **330 Ω** resistor |
| VCC | **5 V** |
| GND | GND |

> **Important:** Place a **1000 µF electrolytic capacitor** across the 5 V and GND rails near the LED strip.

LED order on the strip:
- LED 0 → Morning
- LED 1 → Evening
- LED 2 → Night

#### IR Obstacle Sensors (×3)
| Sensor | ESP8266 Pin |
|--------|-------------|
| Morning OUT | D5 (GPIO14) |
| Evening OUT | D6 (GPIO12) |
| Night OUT | D7 (GPIO13) |
| VCC (all) | 5 V |
| GND (all) | GND |

> Sensor logic: **LOW** = pill present (obstacle), **HIGH** = pill removed (clear).

#### Active Buzzer
| Buzzer | ESP8266 Pin |
|--------|-------------|
| + | D0 (GPIO16) |
| − | GND |

#### Lid Limit Switch
| Switch | Connection |
|--------|------------|
| Terminal A | D3 (GPIO0) |
| Terminal B | GND |
| Pull-up | **10 kΩ** from D3 to **3.3 V** |

> Switch pressed (lid closed) = LOW; switch released (lid open) = HIGH.

---

## Firebase Setup

### 1. Enable Realtime Database

1. Open [Firebase Console](https://console.firebase.google.com/) → select your project (**pillcare-d4193**).
2. Go to **Build → Realtime Database → Create Database**.
3. Choose a region and start in **test mode** (or set rules below).
4. Copy the **Database URL** (e.g. `https://pillcare-d4193-default-rtdb.firebaseio.com`).

### 2. Get the Web API Key

1. In Firebase Console → **Project Settings** (gear icon).
2. Under **General → Web API Key**, copy the key.

### 3. Update Firmware Config

Open `src/config.h` and update:

```cpp
#define FIREBASE_API_KEY        "paste-your-web-api-key-here"
#define FIREBASE_DATABASE_URL   "https://pillcare-d4193-default-rtdb.firebaseio.com"
```

### 4. Database Structure

The firmware reads/writes to these paths:

```
users/
  <uid>/
    schedule/
      morning: "08:00"    ← written by Flutter app
      evening: "14:00"
      night:   "21:00"
    status/
      morning: false       ← written by ESP8266 (true = taken)
      evening: false
      night:   false
```

### 5. Security Rules (Recommended)

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read":  "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}
```

---

## How It Works – Complete Flow

### Boot Sequence

```
Power ON
  │
  ├─ Init EEPROM, OLED, LEDs, sensors, buzzer
  ├─ Load saved WiFi + auth creds from EEPROM
  ├─ Load cached schedule from EEPROM
  │
  ├─ WiFi credentials exist?
  │     ├─ YES → Try STA connection (10 s timeout)
  │     │    ├─ Connected → Sync NTP → Init Firebase → Read schedule from RTDB
  │     │    └─ Failed    → Enter AP mode
  │     └─ NO  → Enter AP mode
  │
  └─ AP Mode:
       SSID: PillCare_Setup / Password: 12345678
       Open http://192.168.4.1 → enter WiFi + Firebase creds
       → Saved to EEPROM → ESP restarts
```

### Main Loop (runs continuously)

| Task | Interval | Description |
|------|----------|-------------|
| Update clock | Every iteration | Read NTP-synced local time |
| WiFi watchdog | 30 s | Reconnect if STA dropped |
| Firebase sync | 30 s | Re-read schedule from RTDB; refresh auth token |
| Reminder check | 60 s | Compare schedule vs. time; advance slot states |
| Sensor poll | 200 ms | Read IR sensors + lid switch; detect pill removal |
| LED update | Every iteration | Set colours based on slot states |
| Buzzer pattern | Every iteration | Beep on/off when any slot is PENDING |
| Display refresh | 1 s | Render time, status, slot info on OLED |
| Daily reset | At 00:00 | Reset all slots to IDLE; clear Firebase status |

### LED Colour Codes

| Colour | Meaning |
|--------|---------|
| **Off** | Not yet time (IDLE) |
| **Green** | Time to take pill (PENDING) |
| **Blue** | Pill taken (TAKEN) |
| **Red** | Missed window (MISSED) |

### Pill Detection

1. Lid opened (limit switch HIGH)
2. IR sensor transitions from LOW → HIGH (pill removed)
3. If the slot is **PENDING** → marked **TAKEN**
4. Firebase `status/<slot>` set to `true`
5. LED turns **blue**, buzzer stops (if no other slots pending)

---

## Module Reference

| File | Functions |
|------|-----------|
| `storage.h/cpp` | `initStorage()`, `saveWiFiCredentials()`, `loadWiFiCredentials()`, `saveSchedule()`, `loadSchedule()`, `saveAuthCredentials()`, `loadAuthCredentials()`, `clearAllEEPROM()` |
| `wifi_manager.h/cpp` | `connectWiFi()`, `startAPMode()`, `handleWiFiReconnection()`, `isWiFiConnected()` |
| `firebase_handler.h/cpp` | `initFirebase()`, `isFirebaseReady()`, `readScheduleFromFirebase()`, `updateStatusToFirebase()`, `resetAllStatusInFirebase()`, `firebaseLoop()`, `getFirebaseUID()` |
| `hardware.h/cpp` | `initHardware()`, `readIRSensors()`, `isLidOpen()`, `setBuzzer()`, `setSlotLED()`, `updateAllLEDs()`, `handleBuzzerPattern()` |
| `display_manager.h/cpp` | `initDisplay()`, `displayStartup()`, `displayAPMode()`, `displayConnecting()`, `displayMain()`, `displayMessage()` |
| `reminder.h/cpp` | `checkReminders()`, `checkDailyReset()`, `markSlotTaken()`, `anySlotPending()` |

---

## Build & Flash (PlatformIO)

### Prerequisites

- [PlatformIO CLI](https://docs.platformio.org/en/latest/core/installation.html) or the PlatformIO VS Code extension.
- USB cable connected to NodeMCU.
- Correct COM port driver installed (CH340 or CP2102 depending on your board revision).

### Commands

```bash
# Navigate to firmware directory
cd firmware

# Build
pio run

# Upload to board
pio run --target upload

# Open serial monitor
pio device monitor

# Build + upload + monitor (all in one)
pio run --target upload && pio device monitor
```

If PlatformIO cannot auto-detect the COM port, specify it:

```bash
pio run --target upload --upload-port COM3
```

---

## Testing Steps

### 1. First-Boot (AP Mode)

1. Flash the firmware and open the serial monitor (115200 baud).
2. The OLED shows **"AP CONFIG MODE"** with SSID and IP.
3. On your phone, connect to WiFi **PillCare_Setup** (password: `12345678`).
4. Open a browser → navigate to **http://192.168.4.1**.
5. Enter your WiFi SSID, WiFi password, Firebase email, and Firebase password.
6. Press **Save & Connect**. The ESP restarts.

### 2. WiFi + Firebase Connection

1. After restart, the serial monitor shows WiFi connecting, NTP sync, and Firebase auth.
2. The OLED displays the main screen with clock and slot statuses.
3. Verify `[FB] Authenticated – UID: <your-uid>` appears in the serial log.

### 3. Schedule Reading

1. In Firebase RTDB Console, manually create:
   ```
   users/<your-uid>/schedule/morning  → "08:00"
   users/<your-uid>/schedule/evening  → "14:00"
   users/<your-uid>/schedule/night    → "21:00"
   ```
2. Within 30 seconds the ESP reads the schedule. Verify in serial log:
   ```
   [FB] Schedule: M=08:00  E=14:00  N=21:00
   ```

### 4. Reminder Trigger

1. Set a schedule time to 1–2 minutes in the future.
2. Wait for the reminder to trigger: LED turns **green**, buzzer beeps.
3. Open the lid and remove the pill (break the IR beam).
4. LED turns **blue**, buzzer stops, Firebase `status/<slot>` becomes `true`.

### 5. Missed Pill

1. Set a schedule time in the past (> 60 minutes ago).
2. The LED turns **red** (MISSED state).

### 6. Daily Reset

1. At midnight (00:00), all slot LEDs turn off and Firebase statuses reset to `false`.

### 7. Offline Operation

1. Disconnect the WiFi router.
2. The ESP continues using the locally-cached schedule.
3. Reminders, LEDs, and buzzer work normally.
4. When WiFi is restored, Firebase sync resumes automatically.

---

## Flutter App Integration

The Flutter app writes to **Firebase Realtime Database** (same paths the ESP reads):

```dart
// Write schedule
FirebaseDatabase.instance
  .ref('users/$uid/schedule')
  .set({
    'morning': '08:00',
    'evening': '14:00',
    'night':   '21:00',
  });

// Listen to status changes
FirebaseDatabase.instance
  .ref('users/$uid/status')
  .onValue
  .listen((event) {
    final data = event.snapshot.value as Map;
    // data['morning'], data['evening'], data['night'] → bool
  });
```

> **Note:** The existing Flutter app uses Cloud Firestore for medications. The hardware device uses **Realtime Database** for schedule and taken-status. You'll need to add the `firebase_database` package to your Flutter app and create a service that writes schedules to RTDB in addition to (or instead of) Firestore.

---

## Timezone

The default timezone is **IST (UTC+5:30)**. To change it, edit `src/config.h`:

```cpp
#define GMT_OFFSET_SEC   19800   // Change to your UTC offset in seconds
#define DST_OFFSET_SEC   0       // Daylight saving offset (if applicable)
```

Common offsets: UTC+0 = 0, UTC+1 = 3600, UTC-5 = -18000, UTC+5:30 = 19800.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| OLED blank | Check I2C wiring (SDA↔D2, SCL↔D1). Try address `0x3D` in `config.h`. |
| LEDs not lighting | Verify 5 V power, 330 Ω resistor on DIN, 1000 µF cap. |
| IR not detecting | Adjust sensor distance; check active-low/high logic in `hardware.cpp`. |
| Firebase auth fails | Verify API key in `config.h`; ensure Email/Password auth is enabled in Firebase Console. |
| Boot loop | GPIO0 (D3) must be HIGH on boot — ensure 10 kΩ pull-up is installed. |
| Clock wrong | Change `GMT_OFFSET_SEC` in `config.h` to match your timezone. |
| Can't find AP | Ensure no other WiFi creds are saved. Run `clearAllEEPROM()` once to reset. |
