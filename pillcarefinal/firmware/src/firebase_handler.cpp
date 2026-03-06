/* ================================================================
 *  firebase_handler.cpp – Firebase RTDB read / write
 * ================================================================ */
#include "firebase_handler.h"

#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// ── Globals ──────────────────────────────────────────────────────
static FirebaseData   fbdo;
static FirebaseAuth   fbAuth;
static FirebaseConfig fbCfg;
static String         fbUID;
static bool           fbInitialised = false;

// ── Init ─────────────────────────────────────────────────────────

void initFirebase(const String &email, const String &password) {
    Serial.println(F("[FB] Initialising Firebase…"));

    fbCfg.api_key       = FIREBASE_API_KEY;
    fbCfg.database_url  = FIREBASE_DATABASE_URL;
    fbAuth.user.email    = email;
    fbAuth.user.password = password;

    // Token-status debug callback (prints to Serial automatically)
    fbCfg.token_status_callback = tokenStatusCallback;  // from TokenHelper.h
    fbCfg.max_token_generation_retry = 5;

    Firebase.begin(&fbCfg, &fbAuth);
    Firebase.reconnectWiFi(true);

    // ── Wait for authentication (with timeout) ──────────────────
    Serial.print(F("[FB] Authenticating"));
    unsigned long t0 = millis();
    while (!Firebase.ready() && millis() - t0 < FIREBASE_AUTH_TIMEOUT) {
        Serial.print('.');
        delay(300);
    }
    Serial.println();

    if (Firebase.ready()) {
        fbUID = fbAuth.token.uid.c_str();
        Serial.print(F("[FB] Authenticated – UID: "));
        Serial.println(fbUID);
        fbInitialised = true;
    } else {
        Serial.println(F("[FB] Authentication FAILED – will retry later"));
        fbInitialised = false;
    }
}

bool isFirebaseReady() {
    return fbInitialised && Firebase.ready();
}

String getFirebaseUID() {
    return fbUID;
}

void firebaseLoop() {
    // The library handles token refresh internally when Firebase.ready()
    // is called, but we can check explicitly:
    if (fbInitialised && Firebase.isTokenExpired()) {
        Firebase.refreshToken(&fbCfg);
        Serial.println(F("[FB] Token refreshed"));
    }
}

// ── Helpers ──────────────────────────────────────────────────────

static String basePath() {
    return String("/users/") + fbUID;
}

// ── Read schedule ────────────────────────────────────────────────

static bool parseTime(const String &timeStr, uint8_t &h, uint8_t &m) {
    // Expected format: "HH:MM"
    int colon = timeStr.indexOf(':');
    if (colon < 0) return false;
    h = (uint8_t)timeStr.substring(0, colon).toInt();
    m = (uint8_t)timeStr.substring(colon + 1).toInt();
    return (h < 24 && m < 60);
}

bool readScheduleFromFirebase(Schedule &sched) {
    if (!isFirebaseReady()) return false;

    String path = basePath() + "/schedule";
    Serial.print(F("[FB] Reading schedule from: "));
    Serial.println(path);

    bool ok = true;

    // Morning
    if (Firebase.RTDB.getString(&fbdo, path + "/morning")) {
        uint8_t h, m;
        if (parseTime(fbdo.stringData(), h, m)) {
            sched.morningHour   = h;
            sched.morningMinute = m;
        }
    } else { ok = false; Serial.println("[FB]  morning read err: " + fbdo.errorReason()); }

    // Evening
    if (Firebase.RTDB.getString(&fbdo, path + "/evening")) {
        uint8_t h, m;
        if (parseTime(fbdo.stringData(), h, m)) {
            sched.eveningHour   = h;
            sched.eveningMinute = m;
        }
    } else { ok = false; Serial.println("[FB]  evening read err: " + fbdo.errorReason()); }

    // Night
    if (Firebase.RTDB.getString(&fbdo, path + "/night")) {
        uint8_t h, m;
        if (parseTime(fbdo.stringData(), h, m)) {
            sched.nightHour   = h;
            sched.nightMinute = m;
        }
    } else { ok = false; Serial.println("[FB]  night read err: " + fbdo.errorReason()); }

    if (ok) {
        sched.valid = true;
        Serial.printf("[FB] Schedule: M=%02u:%02u  E=%02u:%02u  N=%02u:%02u\n",
                      sched.morningHour, sched.morningMinute,
                      sched.eveningHour, sched.eveningMinute,
                      sched.nightHour,   sched.nightMinute);
    }
    return ok;
}

// ── Write status ─────────────────────────────────────────────────

bool updateStatusToFirebase(const char *slot, bool taken) {
    if (!isFirebaseReady()) return false;

    String path = basePath() + "/status/" + slot;
    Serial.printf("[FB] Writing %s = %s\n", path.c_str(), taken ? "true" : "false");

    if (Firebase.RTDB.setBool(&fbdo, path, taken)) {
        return true;
    }
    Serial.println("[FB]  write err: " + fbdo.errorReason());
    return false;
}

bool resetAllStatusInFirebase() {
    if (!isFirebaseReady()) return false;

    Serial.println(F("[FB] Resetting daily status…"));
    bool ok = true;
    ok &= updateStatusToFirebase("morning", false);
    ok &= updateStatusToFirebase("evening", false);
    ok &= updateStatusToFirebase("night",   false);
    return ok;
}
