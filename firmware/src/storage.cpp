/* ================================================================
 *  storage.cpp – EEPROM persistence implementation
 * ================================================================ */
#include "storage.h"
#include <EEPROM.h>

// ── Helpers ──────────────────────────────────────────────────────

static void writeStringEE(int addr, const String &str, int maxLen) {
    int len = str.length();
    if (len > maxLen - 1) len = maxLen - 1;
    for (int i = 0; i < len; i++) {
        EEPROM.write(addr + i, (uint8_t)str[i]);
    }
    EEPROM.write(addr + len, 0);           // NUL terminator
}

static String readStringEE(int addr, int maxLen) {
    String result;
    result.reserve(maxLen);
    for (int i = 0; i < maxLen; i++) {
        char c = (char)EEPROM.read(addr + i);
        if (c == '\0') break;
        result += c;
    }
    return result;
}

// ── Public API ───────────────────────────────────────────────────

void initStorage() {
    EEPROM.begin(EEPROM_SIZE);
    Serial.println(F("[STORAGE] EEPROM initialised"));
}

// ── WiFi credentials ────────────────────────────────────────────

void saveWiFiCredentials(const String &ssid, const String &password) {
    EEPROM.write(EEPROM_ADDR_MAGIC_WIFI, EEPROM_MAGIC_WIFI);
    writeStringEE(EEPROM_ADDR_SSID, ssid, 33);
    writeStringEE(EEPROM_ADDR_PASS, password, 65);
    EEPROM.commit();
    Serial.println(F("[STORAGE] WiFi credentials saved"));
}

bool loadWiFiCredentials(String &ssid, String &password) {
    if (EEPROM.read(EEPROM_ADDR_MAGIC_WIFI) != EEPROM_MAGIC_WIFI) {
        Serial.println(F("[STORAGE] No saved WiFi credentials"));
        return false;
    }
    ssid     = readStringEE(EEPROM_ADDR_SSID, 33);
    password = readStringEE(EEPROM_ADDR_PASS, 65);
    Serial.print(F("[STORAGE] WiFi loaded – SSID: "));
    Serial.println(ssid);
    return true;
}

// ── Schedule ────────────────────────────────────────────────────

void saveSchedule(const Schedule &sched) {
    EEPROM.write(EEPROM_ADDR_MAGIC_SCHED, EEPROM_MAGIC_SCHEDULE);
    EEPROM.write(EEPROM_ADDR_MORN_H,  sched.morningHour);
    EEPROM.write(EEPROM_ADDR_MORN_M,  sched.morningMinute);
    EEPROM.write(EEPROM_ADDR_EVE_H,   sched.eveningHour);
    EEPROM.write(EEPROM_ADDR_EVE_M,   sched.eveningMinute);
    EEPROM.write(EEPROM_ADDR_NIGHT_H, sched.nightHour);
    EEPROM.write(EEPROM_ADDR_NIGHT_M, sched.nightMinute);
    EEPROM.commit();
    Serial.printf("[STORAGE] Schedule saved – M=%02u:%02u  E=%02u:%02u  N=%02u:%02u\n",
                  sched.morningHour, sched.morningMinute,
                  sched.eveningHour, sched.eveningMinute,
                  sched.nightHour,   sched.nightMinute);
}

bool loadSchedule(Schedule &sched) {
    if (EEPROM.read(EEPROM_ADDR_MAGIC_SCHED) != EEPROM_MAGIC_SCHEDULE) {
        Serial.println(F("[STORAGE] No saved schedule – using defaults"));
        return false;
    }
    sched.morningHour   = EEPROM.read(EEPROM_ADDR_MORN_H);
    sched.morningMinute = EEPROM.read(EEPROM_ADDR_MORN_M);
    sched.eveningHour   = EEPROM.read(EEPROM_ADDR_EVE_H);
    sched.eveningMinute = EEPROM.read(EEPROM_ADDR_EVE_M);
    sched.nightHour     = EEPROM.read(EEPROM_ADDR_NIGHT_H);
    sched.nightMinute   = EEPROM.read(EEPROM_ADDR_NIGHT_M);
    sched.valid = true;
    Serial.printf("[STORAGE] Schedule loaded – M=%02u:%02u  E=%02u:%02u  N=%02u:%02u\n",
                  sched.morningHour, sched.morningMinute,
                  sched.eveningHour, sched.eveningMinute,
                  sched.nightHour,   sched.nightMinute);
    return true;
}

// ── Firebase auth credentials ───────────────────────────────────

void saveAuthCredentials(const String &email, const String &password) {
    EEPROM.write(EEPROM_ADDR_MAGIC_AUTH_B, EEPROM_MAGIC_AUTH);
    writeStringEE(EEPROM_ADDR_EMAIL, email, 65);
    writeStringEE(EEPROM_ADDR_UPASS, password, 65);
    EEPROM.commit();
    Serial.println(F("[STORAGE] Auth credentials saved"));
}

bool loadAuthCredentials(String &email, String &password) {
    if (EEPROM.read(EEPROM_ADDR_MAGIC_AUTH_B) != EEPROM_MAGIC_AUTH) {
        Serial.println(F("[STORAGE] No saved auth credentials"));
        return false;
    }
    email    = readStringEE(EEPROM_ADDR_EMAIL, 65);
    password = readStringEE(EEPROM_ADDR_UPASS, 65);
    Serial.print(F("[STORAGE] Auth loaded – email: "));
    Serial.println(email);
    return true;
}

// ── Erase ───────────────────────────────────────────────────────

void clearAllEEPROM() {
    for (int i = 0; i < EEPROM_SIZE; i++) EEPROM.write(i, 0);
    EEPROM.commit();
    Serial.println(F("[STORAGE] EEPROM cleared"));
}
