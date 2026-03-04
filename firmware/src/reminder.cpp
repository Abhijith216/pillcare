/* ================================================================
 *  reminder.cpp – Schedule evaluation & state transitions
 * ================================================================ */
#include "reminder.h"
#include "firebase_handler.h"
#include <time.h>

// ── Helpers ──────────────────────────────────────────────────────

/** Convert hour:minute to "minutes since midnight". */
static inline int toMinutes(int h, int m) { return h * 60 + m; }

/** Advance a single slot's state based on the current time. */
static void evaluateSlot(SlotState &state,
                         uint8_t schedH, uint8_t schedM,
                         int nowMin) {
    int schedMin  = toMinutes(schedH, schedM);
    int missMin   = schedMin + MISS_WINDOW_MINUTES;

    switch (state) {
        case SLOT_IDLE:
            if (nowMin >= schedMin && nowMin < missMin) {
                state = SLOT_PENDING;
                Serial.printf("[REM] Slot → PENDING (sched %02u:%02u, now %d min)\n",
                              schedH, schedM, nowMin);
            } else if (nowMin >= missMin) {
                state = SLOT_MISSED;
                Serial.printf("[REM] Slot → MISSED  (sched %02u:%02u, now %d min)\n",
                              schedH, schedM, nowMin);
            }
            break;

        case SLOT_PENDING:
            if (nowMin >= missMin) {
                state = SLOT_MISSED;
                Serial.printf("[REM] Slot PENDING → MISSED (sched %02u:%02u)\n",
                              schedH, schedM);
            }
            // TAKEN transition handled by markSlotTaken()
            break;

        case SLOT_TAKEN:
        case SLOT_MISSED:
            // Terminal for the day – only daily reset changes these
            break;
    }
}

// ── Public API ───────────────────────────────────────────────────

void checkReminders(DeviceState &ds, const Schedule &sched) {
    int nowMin = toMinutes(ds.currentHour, ds.currentMinute);

    evaluateSlot(ds.morning, sched.morningHour, sched.morningMinute, nowMin);
    evaluateSlot(ds.evening, sched.eveningHour, sched.eveningMinute, nowMin);
    evaluateSlot(ds.night,   sched.nightHour,   sched.nightMinute,   nowMin);
}

void checkDailyReset(DeviceState &ds) {
    // Reset at midnight (00:00).  Avoid re-triggering by checking seconds.
    static bool resetDoneToday = false;
    int nowMin = toMinutes(ds.currentHour, ds.currentMinute);

    if (nowMin == 0 && !resetDoneToday) {
        Serial.println(F("[REM] Midnight – resetting all slots"));
        ds.morning = SLOT_IDLE;
        ds.evening = SLOT_IDLE;
        ds.night   = SLOT_IDLE;
        resetAllStatusInFirebase();
        resetDoneToday = true;
    }
    if (nowMin > 0) {
        resetDoneToday = false;     // re-arm for next midnight
    }
}

bool markSlotTaken(DeviceState &ds, uint8_t slot) {
    SlotState *target  = nullptr;
    const char *name   = nullptr;

    switch (slot) {
        case LED_MORNING: target = &ds.morning; name = "morning"; break;
        case LED_EVENING: target = &ds.evening; name = "evening"; break;
        case LED_NIGHT:   target = &ds.night;   name = "night";   break;
        default: return false;
    }

    if (*target != SLOT_PENDING) return false;

    *target = SLOT_TAKEN;
    Serial.printf("[REM] %s → TAKEN\n", name);
    updateStatusToFirebase(name, true);
    return true;
}

bool anySlotPending(const DeviceState &ds) {
    return ds.morning == SLOT_PENDING ||
           ds.evening == SLOT_PENDING ||
           ds.night   == SLOT_PENDING;
}
