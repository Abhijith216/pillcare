/* ================================================================
 *  wifi_manager.h – WiFi station + AP fallback with config portal
 * ================================================================ */
#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <Arduino.h>
#include "config.h"

/** Attempt STA connection with saved credentials (blocking, with timeout). */
bool  connectWiFi(const String &ssid, const String &password);

/** Start soft-AP + captive config portal.
 *  Blocks until the user submits credentials, then restarts the ESP. */
void  startAPMode();

/** Call from loop() – reconnects STA if it dropped. */
void  handleWiFiReconnection(const String &ssid, const String &password,
                             bool &wifiConnected);

/** True when STA is associated and has an IP. */
bool  isWiFiConnected();

#endif // WIFI_MANAGER_H
