/* ================================================================
 *  main.cpp – Smart Pill Reminder  (ESP8266 / NodeMCU)
 *  ────────────────────────────────────────────────────────────────
 *  Entry-point: setup() → loop()
 *
 *  Modules:
 *    config.h           Pin definitions, constants, structs
 *    storage.h/cpp      EEPROM persistence
 *    wifi_manager.h/cpp WiFi STA + AP config portal
 *    firebase_handler.h/cpp  Firebase RTDB read / write
 *    hardware.h/cpp     LEDs, IR sensors, buzzer, lid switch
 *    display_manager.h/cpp   SSD1306 OLED display
 *    reminder.h/cpp     Reminder state machine
 * ================================================================ */

#include <Arduino.h>
#include <time.h>
#include <ESP8266WiFi.h>

#include "config.h"
#include "storage.h"
#include "wifi_manager.h"
#include "firebase_handler.h"
#include "hardware.h"
#include "display_manager.h"
#include "reminder.h"

// ── Global state ─────────────────────────────────────────────────
static DeviceState state;
static Schedule    schedule;

// Saved credentials (kept in RAM after loading from EEPROM)
static String wifiSSID;
static String wifiPass;
static String authEmail;
static String authPass;

// IR edge-detection previous readings
static bool prevIR_M = false;
static bool prevIR_E = false;
static bool prevIR_N = false;

// Timing trackers
static unsigned long lastScheduleCheck  = 0;
static unsigned long lastFirebaseSync   = 0;
static unsigned long lastDisplayUpdate  = 0;
static unsigned long lastSensorRead     = 0;
static unsigned long lastWifiRetry      = 0;

// ── NTP helper ───────────────────────────────────────────────────

static void syncNTP() {
    Serial.println(F("[NTP] Syncing time…"));
    configTime(GMT_OFFSET_SEC, DST_OFFSET_SEC, NTP_SERVER);

    // Wait (up to 10 s) until NTP delivers a sensible time
    time_t now = 0;
    int tries  = 0;
    while (now < 100000 && tries < 20) {
        delay(500);
        time(&now);
        tries++;
    }

    if (now > 100000) {
        struct tm *ti = localtime(&now);
        Serial.printf("[NTP] Time: %02d:%02d:%02d\n",
                      ti->tm_hour, ti->tm_min, ti->tm_sec);
        state.ntpSynced = true;
    } else {
        Serial.println(F("[NTP] Sync FAILED – using compile time"));
    }
}

static void updateCurrentTime() {
    time_t now;
    time(&now);
    struct tm *ti = localtime(&now);
    state.currentHour   = ti->tm_hour;
    state.currentMinute = ti->tm_min;
    state.currentSecond = ti->tm_sec;
}

// ─────────────────────────────────────────────────────────────────
//  SETUP
// ─────────────────────────────────────────────────────────────────

void setup() {
    Serial.begin(115200);
    Serial.println();
    Serial.println(F("╔══════════════════════════════════════╗"));
    Serial.println(F("║   Smart Pill Reminder – PillCare     ║"));
    Serial.println(F("║   ESP8266 Firmware v1.0               ║"));
    Serial.println(F("╚══════════════════════════════════════╝"));

    // 1. Persistent storage
    initStorage();

    // 2. OLED display
    initDisplay();
    displayStartup();

    // 3. LEDs, sensors, buzzer
    initHardware();

    delay(1500);

    // 4. Load saved WiFi + auth credentials
    bool haveWifi = loadWiFiCredentials(wifiSSID, wifiPass);
    bool haveAuth = loadAuthCredentials(authEmail, authPass);

    // 5. Load locally-cached schedule (used as fallback)
    loadSchedule(schedule);

    // 6. Attempt WiFi connection
    if (haveWifi) {
        displayConnecting();
        if (connectWiFi(wifiSSID, wifiPass)) {
            state.wifiConnected = true;

            // 7. Sync NTP
            syncNTP();

            // 8. Firebase authentication
            if (haveAuth) {
                displayMessage("  PillCare", "Connecting to", "Firebase...");
                initFirebase(authEmail, authPass);
                state.firebaseConnected = isFirebaseReady();

                // 9. Pull latest schedule from cloud
                if (state.firebaseConnected) {
                    if (readScheduleFromFirebase(schedule)) {
                        saveSchedule(schedule);     // persist locally
                    }
                }
            } else {
                Serial.println(F("[MAIN] No auth credentials – skipping Firebase"));
            }
        } else {
            // WiFi failed → fall into AP mode
            haveWifi = false;
        }
    }

    // 10. If no WiFi or connection failed → AP config portal
    if (!haveWifi) {
        displayAPMode();
        startAPMode();      // blocks & restarts ESP after config
        // (execution never continues past this point)
    }

    // 11. Ready
    Serial.println(F("[MAIN] ✓ System running"));
    displayMessage("  PillCare", "System ready!", "");
    delay(1000);
}

// ─────────────────────────────────────────────────────────────────
//  LOOP
// ─────────────────────────────────────────────────────────────────

void loop() {
    unsigned long now = millis();

    // ── Always update time ───────────────────────────────────────
    updateCurrentTime();

    // ── WiFi watchdog (retry every 30 s) ─────────────────────────
    if (now - lastWifiRetry > FIREBASE_SYNC_INTERVAL) {
        lastWifiRetry = now;
        handleWiFiReconnection(wifiSSID, wifiPass, state.wifiConnected);
    }

    // ── Firebase keep-alive & schedule sync ──────────────────────
    if (state.wifiConnected) {
        firebaseLoop();     // handle token refresh

        if (now - lastFirebaseSync > FIREBASE_SYNC_INTERVAL) {
            lastFirebaseSync = now;

            if (isFirebaseReady()) {
                state.firebaseConnected = true;

                // Re-read schedule from cloud (in case the Flutter app changed it)
                Schedule tmp = schedule;
                if (readScheduleFromFirebase(tmp)) {
                    // Only save if something changed
                    if (tmp.morningHour   != schedule.morningHour   ||
                        tmp.morningMinute != schedule.morningMinute ||
                        tmp.eveningHour   != schedule.eveningHour   ||
                        tmp.eveningMinute != schedule.eveningMinute ||
                        tmp.nightHour     != schedule.nightHour     ||
                        tmp.nightMinute   != schedule.nightMinute) {
                        schedule = tmp;
                        saveSchedule(schedule);
                        Serial.println(F("[MAIN] Schedule updated from Firebase"));
                    }
                }
            } else {
                state.firebaseConnected = false;
                // Attempt re-init if auth was previously successful
                if (authEmail.length() > 0) {
                    Serial.println(F("[MAIN] Firebase lost – re-initialising…"));
                    initFirebase(authEmail, authPass);
                }
            }
        }
    } else {
        state.firebaseConnected = false;
    }

    // ── Reminder evaluation (every 60 s) ─────────────────────────
    if (now - lastScheduleCheck > SCHEDULE_CHECK_INTERVAL) {
        lastScheduleCheck = now;
        if (schedule.valid || schedule.morningHour != 0) {  // use schedule if available
            checkReminders(state, schedule);
        }
    }

    // ── Sensor polling (every 200 ms) ────────────────────────────
    if (now - lastSensorRead > SENSOR_READ_INTERVAL) {
        lastSensorRead = now;

        state.lidOpen = isLidOpen();

        if (state.lidOpen) {
            bool irM, irE, irN;
            readIRSensors(irM, irE, irN);

            // Edge detection: pill was present (false) → now absent (true)
            if (irM && !prevIR_M)  markSlotTaken(state, LED_MORNING);
            if (irE && !prevIR_E)  markSlotTaken(state, LED_EVENING);
            if (irN && !prevIR_N)  markSlotTaken(state, LED_NIGHT);

            prevIR_M = irM;
            prevIR_E = irE;
            prevIR_N = irN;
        }
    }

    // ── LED update ───────────────────────────────────────────────
    updateAllLEDs(state);

    // ── Buzzer pattern ───────────────────────────────────────────
    handleBuzzerPattern(state);

    // ── Display refresh (every 1 s) ──────────────────────────────
    if (now - lastDisplayUpdate > DISPLAY_UPDATE_INTERVAL) {
        lastDisplayUpdate = now;
        displayMain(state, schedule);
    }

    // ── Daily midnight reset ─────────────────────────────────────
    checkDailyReset(state);

    // ── Yield to ESP8266 background tasks (WiFi, TCP) ────────────
    yield();
}
