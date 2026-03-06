/* ================================================================
 *  firebase_handler.h – Firebase Realtime Database integration
 * ================================================================ */
#ifndef FIREBASE_HANDLER_H
#define FIREBASE_HANDLER_H

#include <Arduino.h>
#include "config.h"

/** Initialise Firebase with email/password auth.
 *  Call after WiFi is connected. */
void  initFirebase(const String &email, const String &password);

/** True once the auth token is valid and RTDB is reachable. */
bool  isFirebaseReady();

/** Read schedule from RTDB → populate sched.  Returns true on success. */
bool  readScheduleFromFirebase(Schedule &sched);

/** Write a single slot status (true = taken) to RTDB. */
bool  updateStatusToFirebase(const char *slot, bool taken);

/** Reset all three slot statuses to false in RTDB. */
bool  resetAllStatusInFirebase();

/** Call periodically to keep tokens alive. */
void  firebaseLoop();

/** Get the authenticated UID (empty if not yet authed). */
String getFirebaseUID();

#endif // FIREBASE_HANDLER_H
