/* ================================================================
 *  config.h – Master Configuration for Smart Pill Reminder
 *  All pin definitions, constants, EEPROM layout, enums, structs
 * ================================================================ */
#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// ────────────────────────────────────────────────────────────────
//  GPIO Pin Map  (ESP8266 NodeMCU)
// ────────────────────────────────────────────────────────────────

// I2C OLED (SSD1306)
#define PIN_SCL             D1   // GPIO5
#define PIN_SDA             D2   // GPIO4

// WS2812B LED Data (3 LEDs chained) – use 330 Ω series resistor
#define PIN_LED_DATA        D4   // GPIO2
#define NUM_LEDS            3

// IR Obstacle Sensors (LOW = pill present, HIGH = pill removed)
#define PIN_IR_MORNING      D5   // GPIO14
#define PIN_IR_EVENING      D6   // GPIO12
#define PIN_IR_NIGHT        D7   // GPIO13

// Active Buzzer (HIGH = ON)
#define PIN_BUZZER          D0   // GPIO16

// Lid Limit Switch (10 K pull-up to 3.3 V; LOW = lid closed)
#define PIN_LID_SWITCH      D3   // GPIO0

// ────────────────────────────────────────────────────────────────
//  LED Strip Indices
// ────────────────────────────────────────────────────────────────
#define LED_MORNING         0
#define LED_EVENING         1
#define LED_NIGHT           2

// ────────────────────────────────────────────────────────────────
//  Timing Constants (milliseconds unless noted)
// ────────────────────────────────────────────────────────────────
#define WIFI_CONNECT_TIMEOUT        10000   // 10 s
#define SCHEDULE_CHECK_INTERVAL     60000   // 60 s
#define FIREBASE_SYNC_INTERVAL      30000   // 30 s
#define DISPLAY_UPDATE_INTERVAL     1000    // 1 s
#define SENSOR_READ_INTERVAL        200     // 200 ms
#define BUZZER_BEEP_ON_MS           500     // buzzer ON duration
#define BUZZER_BEEP_OFF_MS          1500    // buzzer OFF duration
#define MISS_WINDOW_MINUTES         60      // minutes before "missed"
#define FIREBASE_AUTH_TIMEOUT       15000   // 15 s for auth

// ────────────────────────────────────────────────────────────────
//  NTP / Time-zone
// ────────────────────────────────────────────────────────────────
#define NTP_SERVER          "pool.ntp.org"
#define GMT_OFFSET_SEC      19800       // IST  UTC+5:30
#define DST_OFFSET_SEC      0

// ────────────────────────────────────────────────────────────────
//  Firebase
// ────────────────────────────────────────────────────────────────
#define FIREBASE_API_KEY        "AIzaSyBjhWgoRBpl0zDg6WbPQXopZAcyn2tByY0"
#define FIREBASE_DATABASE_URL   "https://pillcare-d4193-default-rtdb.firebaseio.com"

// ────────────────────────────────────────────────────────────────
//  Access-Point Mode
// ────────────────────────────────────────────────────────────────
#define AP_SSID             "PillCare_Setup"
#define AP_PASSWORD         "12345678"

// ────────────────────────────────────────────────────────────────
//  EEPROM Layout  (total: 512 bytes)
// ────────────────────────────────────────────────────────────────
#define EEPROM_SIZE                 512

// Magic bytes
#define EEPROM_MAGIC_WIFI           0xAB
#define EEPROM_MAGIC_SCHEDULE       0xCD
#define EEPROM_MAGIC_AUTH           0xEF

// Addresses
#define EEPROM_ADDR_MAGIC_WIFI      0       // 1 B
#define EEPROM_ADDR_SSID            1       // 33 B  (32 + NUL)
#define EEPROM_ADDR_PASS            34      // 65 B  (64 + NUL)
#define EEPROM_ADDR_MAGIC_SCHED     99      // 1 B
#define EEPROM_ADDR_MORN_H          100     // 1 B
#define EEPROM_ADDR_MORN_M          101     // 1 B
#define EEPROM_ADDR_EVE_H           102     // 1 B
#define EEPROM_ADDR_EVE_M           103     // 1 B
#define EEPROM_ADDR_NIGHT_H         104     // 1 B
#define EEPROM_ADDR_NIGHT_M         105     // 1 B
#define EEPROM_ADDR_MAGIC_AUTH_B    106     // 1 B
#define EEPROM_ADDR_EMAIL           107     // 65 B
#define EEPROM_ADDR_UPASS           172     // 65 B
//                                  237+    // reserved

// ────────────────────────────────────────────────────────────────
//  OLED Display
// ────────────────────────────────────────────────────────────────
#define SCREEN_WIDTH        128
#define SCREEN_HEIGHT       64
#define OLED_RESET          -1
#define OLED_I2C_ADDRESS    0x3C

// ────────────────────────────────────────────────────────────────
//  Enumerations & Structures
// ────────────────────────────────────────────────────────────────

/** State of one medicine slot */
enum SlotState : uint8_t {
    SLOT_IDLE    = 0,   // not yet time        – LED OFF
    SLOT_PENDING = 1,   // time to take pill    – LED GREEN + buzzer
    SLOT_TAKEN   = 2,   // pill taken           – LED BLUE
    SLOT_MISSED  = 3    // missed window        – LED RED
};

/** Daily schedule (hours & minutes) */
struct Schedule {
    uint8_t morningHour   = 8;
    uint8_t morningMinute = 0;
    uint8_t eveningHour   = 14;
    uint8_t eveningMinute = 0;
    uint8_t nightHour     = 21;
    uint8_t nightMinute   = 0;
    bool    valid         = false;
};

/** Run-time state shared across modules */
struct DeviceState {
    SlotState morning       = SLOT_IDLE;
    SlotState evening       = SLOT_IDLE;
    SlotState night         = SLOT_IDLE;
    bool wifiConnected      = false;
    bool firebaseConnected  = false;
    bool lidOpen            = false;
    bool ntpSynced          = false;
    int  currentHour        = 0;
    int  currentMinute      = 0;
    int  currentSecond      = 0;
};

#endif // CONFIG_H
