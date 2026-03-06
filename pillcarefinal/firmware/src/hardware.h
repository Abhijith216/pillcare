/* ================================================================
 *  hardware.h – WS2812B LEDs, IR sensors, buzzer, lid switch
 * ================================================================ */
#ifndef HARDWARE_H
#define HARDWARE_H

#include <Arduino.h>
#include "config.h"

/** Initialise all GPIO and the NeoPixel strip. */
void  initHardware();

/** Read all three IR sensors.
 *  true = pill ABSENT (removed), false = pill present. */
void  readIRSensors(bool &mornAbsent, bool &eveAbsent, bool &nightAbsent);

/** Returns true when the lid is open (limit switch released). */
bool  isLidOpen();

/** Direct buzzer control. */
void  setBuzzer(bool on);

/** Set one LED to a colour matching the slot state. */
void  setSlotLED(uint8_t index, SlotState state);

/** Update all three LEDs according to DeviceState. */
void  updateAllLEDs(const DeviceState &ds);

/** Non-blocking beep pattern – call every loop(). */
void  handleBuzzerPattern(const DeviceState &ds);

#endif // HARDWARE_H
