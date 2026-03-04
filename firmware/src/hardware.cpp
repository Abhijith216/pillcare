/* ================================================================
 *  hardware.cpp – LED strip, IR sensors, buzzer, lid switch
 * ================================================================ */
#include "hardware.h"
#include <Adafruit_NeoPixel.h>

// ── NeoPixel strip ───────────────────────────────────────────────
static Adafruit_NeoPixel strip(NUM_LEDS, PIN_LED_DATA, NEO_GRB + NEO_KHZ800);

// ── Buzzer pattern state ─────────────────────────────────────────
static unsigned long buzzerToggleTime = 0;
static bool          buzzerIsOn       = false;

// ── Colour definitions ───────────────────────────────────────────
static const uint32_t COL_OFF   = 0x000000;
static const uint32_t COL_GREEN = 0x00FF00;   // PENDING  – time to take
static const uint32_t COL_BLUE  = 0x0000FF;   // TAKEN
static const uint32_t COL_RED   = 0xFF0000;   // MISSED

// ── Init ─────────────────────────────────────────────────────────

void initHardware() {
    // IR sensors – most modules drive HIGH when no obstacle
    pinMode(PIN_IR_MORNING, INPUT);
    pinMode(PIN_IR_EVENING, INPUT);
    pinMode(PIN_IR_NIGHT,   INPUT);

    // Buzzer
    pinMode(PIN_BUZZER, OUTPUT);
    digitalWrite(PIN_BUZZER, LOW);

    // Lid switch (external 10K pull-up, active LOW when pressed/lid closed)
    pinMode(PIN_LID_SWITCH, INPUT);

    // NeoPixel
    strip.begin();
    strip.setBrightness(60);
    strip.clear();
    strip.show();

    Serial.println(F("[HW] Hardware initialised"));
}

// ── IR Sensors ───────────────────────────────────────────────────

void readIRSensors(bool &mornAbsent, bool &eveAbsent, bool &nightAbsent) {
    // Common modules: LOW = object detected (pill present)
    //                 HIGH = no object     (pill removed / absent)
    mornAbsent  = (digitalRead(PIN_IR_MORNING) == HIGH);
    eveAbsent   = (digitalRead(PIN_IR_EVENING) == HIGH);
    nightAbsent = (digitalRead(PIN_IR_NIGHT)   == HIGH);
}

// ── Lid switch ───────────────────────────────────────────────────

bool isLidOpen() {
    // With 10K pull-up: switch released (lid open) = HIGH
    //                   switch pressed  (lid closed)= LOW
    return digitalRead(PIN_LID_SWITCH) == HIGH;
}

// ── Buzzer ───────────────────────────────────────────────────────

void setBuzzer(bool on) {
    digitalWrite(PIN_BUZZER, on ? HIGH : LOW);
}

void handleBuzzerPattern(const DeviceState &ds) {
    // Buzzer beeps only when at least one slot is PENDING
    bool anyPending = (ds.morning == SLOT_PENDING ||
                       ds.evening == SLOT_PENDING ||
                       ds.night   == SLOT_PENDING);

    if (!anyPending) {
        setBuzzer(false);
        buzzerIsOn = false;
        return;
    }

    unsigned long now = millis();
    if (buzzerIsOn) {
        if (now - buzzerToggleTime >= BUZZER_BEEP_ON_MS) {
            setBuzzer(false);
            buzzerIsOn = false;
            buzzerToggleTime = now;
        }
    } else {
        if (now - buzzerToggleTime >= BUZZER_BEEP_OFF_MS) {
            setBuzzer(true);
            buzzerIsOn = true;
            buzzerToggleTime = now;
        }
    }
}

// ── LEDs ─────────────────────────────────────────────────────────

void setSlotLED(uint8_t index, SlotState state) {
    uint32_t col;
    switch (state) {
        case SLOT_PENDING: col = COL_GREEN; break;
        case SLOT_TAKEN:   col = COL_BLUE;  break;
        case SLOT_MISSED:  col = COL_RED;   break;
        default:           col = COL_OFF;   break;
    }
    strip.setPixelColor(index, col);
}

void updateAllLEDs(const DeviceState &ds) {
    setSlotLED(LED_MORNING, ds.morning);
    setSlotLED(LED_EVENING, ds.evening);
    setSlotLED(LED_NIGHT,   ds.night);
    strip.show();
}
