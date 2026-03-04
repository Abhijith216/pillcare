/* ================================================================
 *  display_manager.h – SSD1306 OLED 128×64 I2C display
 * ================================================================ */
#ifndef DISPLAY_MANAGER_H
#define DISPLAY_MANAGER_H

#include <Arduino.h>
#include "config.h"

/** Initialise I2C and the SSD1306 display. */
bool  initDisplay();

/** Startup splash screen. */
void  displayStartup();

/** AP-mode information screen. */
void  displayAPMode();

/** "Connecting to WiFi…" screen. */
void  displayConnecting();

/** Main status screen (time, WiFi/FB status, slot states). */
void  displayMain(const DeviceState &ds, const Schedule &sched);

/** Arbitrary 3-line message (title, line2, line3). */
void  displayMessage(const char *l1, const char *l2, const char *l3);

#endif // DISPLAY_MANAGER_H
