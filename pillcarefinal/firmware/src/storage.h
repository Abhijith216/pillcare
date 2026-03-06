/* ================================================================
 *  storage.h – EEPROM persistence for WiFi, schedule & auth creds
 * ================================================================ */
#ifndef STORAGE_H
#define STORAGE_H

#include <Arduino.h>
#include "config.h"

void  initStorage();
void  saveWiFiCredentials(const String &ssid, const String &password);
bool  loadWiFiCredentials(String &ssid, String &password);
void  saveSchedule(const Schedule &sched);
bool  loadSchedule(Schedule &sched);
void  saveAuthCredentials(const String &email, const String &password);
bool  loadAuthCredentials(String &email, String &password);
void  clearAllEEPROM();

#endif // STORAGE_H
