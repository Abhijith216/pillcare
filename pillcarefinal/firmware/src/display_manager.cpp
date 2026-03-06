/* ================================================================
 *  display_manager.cpp – SSD1306 OLED 128×64 renderers
 * ================================================================ */
#include "display_manager.h"

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

static Adafruit_SSD1306 oled(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
static bool oledOk = false;

// ── Helpers ──────────────────────────────────────────────────────

static const char *stateTag(SlotState s) {
    switch (s) {
        case SLOT_PENDING: return "TAKE";
        case SLOT_TAKEN:   return "DONE";
        case SLOT_MISSED:  return "MISS";
        default:           return "----";
    }
}

static void header(const char *title) {
    oled.clearDisplay();
    oled.setTextSize(1);
    oled.setTextColor(SSD1306_WHITE);
    oled.setCursor(0, 0);
    oled.println(title);
    oled.drawLine(0, 10, 127, 10, SSD1306_WHITE);
}

// ── Public API ───────────────────────────────────────────────────

bool initDisplay() {
    Wire.begin(PIN_SDA, PIN_SCL);
    if (!oled.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDRESS)) {
        Serial.println(F("[OLED] SSD1306 init FAILED"));
        return false;
    }
    oled.clearDisplay();
    oled.display();
    oledOk = true;
    Serial.println(F("[OLED] Display initialised"));
    return true;
}

void displayStartup() {
    if (!oledOk) return;
    oled.clearDisplay();
    oled.setTextSize(2);
    oled.setTextColor(SSD1306_WHITE);
    oled.setCursor(10, 8);
    oled.println(F("PillCare"));
    oled.setTextSize(1);
    oled.setCursor(16, 36);
    oled.println(F("Smart Pill Reminder"));
    oled.setCursor(30, 52);
    oled.println(F("Booting..."));
    oled.display();
}

void displayAPMode() {
    if (!oledOk) return;
    header("  AP CONFIG MODE");
    oled.setCursor(0, 16);
    oled.println(F("Connect to WiFi:"));
    oled.println();
    oled.print(F("SSID: "));  oled.println(F(AP_SSID));
    oled.print(F("Pass: "));  oled.println(F(AP_PASSWORD));
    oled.println();
    oled.println(F("Open 192.168.4.1"));
    oled.println(F("in your browser"));
    oled.display();
}

void displayConnecting() {
    if (!oledOk) return;
    header("    PillCare");
    oled.setCursor(0, 20);
    oled.println(F("Connecting to WiFi"));
    oled.println(F("Please wait..."));
    oled.display();
}

void displayMain(const DeviceState &ds, const Schedule &sched) {
    if (!oledOk) return;

    oled.clearDisplay();
    oled.setTextSize(1);
    oled.setTextColor(SSD1306_WHITE);

    // ── Row 0: Title + clock ────────────────────────────────────
    oled.setCursor(0, 0);
    oled.print(F("PillCare"));
    // Right-align time
    char timeBuf[9];
    snprintf(timeBuf, sizeof(timeBuf), "%02d:%02d:%02d",
             ds.currentHour, ds.currentMinute, ds.currentSecond);
    oled.setCursor(SCREEN_WIDTH - 48, 0);
    oled.print(timeBuf);

    oled.drawLine(0, 10, 127, 10, SSD1306_WHITE);

    // ── Row 1: Connection status ────────────────────────────────
    oled.setCursor(0, 13);
    oled.print(F("WiFi:"));
    oled.print(ds.wifiConnected ? F("OK") : F("--"));
    oled.print(F("  FB:"));
    oled.print(ds.firebaseConnected ? F("OK") : F("--"));
    oled.print(F("  Lid:"));
    oled.print(ds.lidOpen ? F("Open") : F("Shut"));

    oled.drawLine(0, 23, 127, 23, SSD1306_WHITE);

    // ── Rows 2-4: Slot info ─────────────────────────────────────
    char line[22];

    // Morning
    snprintf(line, sizeof(line), "M %02u:%02u  [%s]",
             sched.morningHour, sched.morningMinute, stateTag(ds.morning));
    oled.setCursor(0, 26);
    oled.println(line);

    // Evening
    snprintf(line, sizeof(line), "E %02u:%02u  [%s]",
             sched.eveningHour, sched.eveningMinute, stateTag(ds.evening));
    oled.setCursor(0, 38);
    oled.println(line);

    // Night
    snprintf(line, sizeof(line), "N %02u:%02u  [%s]",
             sched.nightHour, sched.nightMinute, stateTag(ds.night));
    oled.setCursor(0, 50);
    oled.println(line);

    oled.display();
}

void displayMessage(const char *l1, const char *l2, const char *l3) {
    if (!oledOk) return;
    header(l1);
    oled.setCursor(0, 20);
    oled.println(l2);
    oled.setCursor(0, 36);
    oled.println(l3);
    oled.display();
}
