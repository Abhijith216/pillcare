/* ================================================================
 *  reminder.h – Reminder state machine & daily-reset logic
 * ================================================================ */
#ifndef REMINDER_H
#define REMINDER_H

#include <Arduino.h>
#include "config.h"

/** Evaluate schedule against current time and advance slot states.
 *  Call every SCHEDULE_CHECK_INTERVAL ms. */
void checkReminders(DeviceState &ds, const Schedule &sched);

/** Check if midnight has passed and reset slots + Firebase status. */
void checkDailyReset(DeviceState &ds);

/** Mark a slot as TAKEN (only if currently PENDING).
 *  Returns true if the state was changed. */
bool markSlotTaken(DeviceState &ds, uint8_t slot);

/** Returns true if any slot is PENDING (needs buzzer). */
bool anySlotPending(const DeviceState &ds);

#endif // REMINDER_H
