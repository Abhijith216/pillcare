/* ================================================================
 *  wifi_manager.cpp – WiFi station + AP config portal
 * ================================================================ */
#include "wifi_manager.h"
#include "storage.h"
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>

// ── Forward declarations ─────────────────────────────────────────
static void handleRoot();
static void handleSave();

// ── Globals ──────────────────────────────────────────────────────
static ESP8266WebServer webServer(80);
static volatile bool    apDone = false;

// ── HTML config page (stored in flash via PROGMEM) ──────────────
static const char CONFIG_PAGE[] PROGMEM = R"rawliteral(
<!DOCTYPE html><html><head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width,initial-scale=1'>
<title>PillCare Setup</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Arial,Helvetica,sans-serif;background:#1a1a2e;color:#e0e0e0;
     display:flex;justify-content:center;align-items:center;min-height:100vh}
.card{background:#16213e;border-radius:15px;padding:30px;width:340px;
      box-shadow:0 8px 32px rgba(0,0,0,.35)}
h2{text-align:center;color:#4fc3f7;margin-bottom:22px}
.icon{text-align:center;font-size:48px;margin-bottom:8px}
.section{border-top:1px solid #0f3460;margin-top:18px;padding-top:14px}
.stitle{color:#4fc3f7;font-size:12px;text-transform:uppercase;letter-spacing:1px;margin-bottom:6px}
label{display:block;margin:10px 0 4px;color:#90caf9;font-size:13px}
input{width:100%;padding:10px;border:1px solid #0f3460;border-radius:8px;
      background:#0f3460;color:#fff;font-size:14px}
input:focus{outline:none;border-color:#4fc3f7}
button{width:100%;padding:13px;background:#4fc3f7;color:#1a1a2e;border:none;
       border-radius:8px;font-size:16px;font-weight:bold;cursor:pointer;margin-top:24px}
button:hover{background:#81d4fa}
.note{font-size:11px;color:#777;text-align:center;margin-top:14px}
</style></head><body>
<div class='card'>
  <div class='icon'>&#x1F48A;</div>
  <h2>PillCare Setup</h2>
  <form action='/save' method='POST'>
    <div class='stitle'>WiFi Configuration</div>
    <label>WiFi SSID</label>
    <input type='text'     name='ssid'     required placeholder='Your WiFi name'>
    <label>WiFi Password</label>
    <input type='password'  name='wifipass' required placeholder='WiFi password'>
    <div class='section'>
      <div class='stitle'>Firebase Account</div>
      <label>Email</label>
      <input type='email'    name='email'   required placeholder='you@example.com'>
      <label>Password</label>
      <input type='password'  name='fbpass'  required placeholder='Account password'>
    </div>
    <button type='submit'>Save &amp; Connect</button>
    <p class='note'>Device will restart after saving.</p>
  </form>
</div></body></html>
)rawliteral";

// Success page shown after save
static const char SUCCESS_PAGE[] PROGMEM = R"rawliteral(
<!DOCTYPE html><html><head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width,initial-scale=1'>
<title>PillCare</title>
<style>
body{font-family:Arial;background:#1a1a2e;color:#e0e0e0;display:flex;
     justify-content:center;align-items:center;min-height:100vh}
.card{background:#16213e;border-radius:15px;padding:40px;width:340px;text-align:center;
      box-shadow:0 8px 32px rgba(0,0,0,.35)}
h2{color:#4fc3f7}
p{margin-top:16px;color:#90caf9}
</style></head><body>
<div class='card'>
  <h2>&#x2705; Saved!</h2>
  <p>Credentials stored.<br>Device will restart now&hellip;</p>
</div></body></html>
)rawliteral";

// ── STA connection ───────────────────────────────────────────────

bool connectWiFi(const String &ssid, const String &password) {
    Serial.print(F("[WIFI] Connecting to: "));
    Serial.println(ssid);

    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid.c_str(), password.c_str());

    unsigned long t0 = millis();
    while (WiFi.status() != WL_CONNECTED &&
           millis() - t0 < WIFI_CONNECT_TIMEOUT) {
        delay(500);
        Serial.print('.');
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
        Serial.print(F("[WIFI] Connected – IP: "));
        Serial.println(WiFi.localIP());
        return true;
    }
    Serial.println(F("[WIFI] Connection FAILED"));
    return false;
}

// ── AP mode + captive portal ─────────────────────────────────────

void startAPMode() {
    Serial.println(F("[WIFI] Starting AP mode…"));

    WiFi.mode(WIFI_AP);
    WiFi.softAPConfig(IPAddress(192, 168, 4, 1),
                      IPAddress(192, 168, 4, 1),
                      IPAddress(255, 255, 255, 0));
    WiFi.softAP(AP_SSID, AP_PASSWORD);

    Serial.print(F("[WIFI] AP SSID : "));  Serial.println(F(AP_SSID));
    Serial.print(F("[WIFI] AP Pass : "));  Serial.println(F(AP_PASSWORD));
    Serial.print(F("[WIFI] AP IP   : "));  Serial.println(WiFi.softAPIP());

    webServer.on("/",     HTTP_GET,  handleRoot);
    webServer.on("/save", HTTP_POST, handleSave);
    webServer.begin();

    Serial.println(F("[WIFI] Config portal running – waiting for user…"));

    apDone = false;
    while (!apDone) {
        webServer.handleClient();
        delay(10);
    }

    // After save the ESP restarts – execution never reaches here normally
    delay(500);
}

// ── Web handlers ─────────────────────────────────────────────────

static void handleRoot() {
    webServer.send_P(200, "text/html", CONFIG_PAGE);
}

static void handleSave() {
    String ssid     = webServer.arg("ssid");
    String wifiPass = webServer.arg("wifipass");
    String email    = webServer.arg("email");
    String fbPass   = webServer.arg("fbpass");

    Serial.println(F("[WIFI] Received config:"));
    Serial.println("  SSID  = " + ssid);
    Serial.println("  Email = " + email);

    saveWiFiCredentials(ssid, wifiPass);
    saveAuthCredentials(email, fbPass);

    webServer.send_P(200, "text/html", SUCCESS_PAGE);

    delay(2000);                       // let the browser render the page
    Serial.println(F("[WIFI] Restarting…"));
    ESP.restart();
}

// ── Reconnection helper (non-blocking) ───────────────────────────

void handleWiFiReconnection(const String &ssid, const String &password,
                            bool &wifiConnected) {
    if (WiFi.status() == WL_CONNECTED) {
        wifiConnected = true;
        return;
    }
    wifiConnected = false;
    Serial.println(F("[WIFI] Disconnected – attempting reconnect…"));
    WiFi.begin(ssid.c_str(), password.c_str());
    // Non-blocking: result checked next cycle
}

bool isWiFiConnected() {
    return WiFi.status() == WL_CONNECTED;
}
