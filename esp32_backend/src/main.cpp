// Minimal Arduino sketch entrypoints required by the Arduino core
#include <Arduino.h>
#include <ESPAsyncWebServer.h>

#include "config.h"
#include "wifi_manager.h"
#include "camera_handler.h"
#include "web_server.h"

// ────────────────────────────────────────────────────────────────────────────
// Globals
// ────────────────────────────────────────────────────────────────────────────

static AsyncWebServer webServer(80);

// ────────────────────────────────────────────────────────────────────────────
// setup / loop
// ────────────────────────────────────────────────────────────────────────────

void setup() {
    Serial.begin(SERIAL_BAUD);
    delay(100);
    Serial.println("\n[Main] Orion's Eye ESP32 starting...");

    // Status LED (active-low on AI-THINKER board).
    pinMode(LED_GPIO_NUM, OUTPUT);
    digitalWrite(LED_GPIO_NUM, HIGH);  // off

    // 1. WiFi – start Access Point (and enter AP+STA mode).
    wifiManagerBegin();

    // 2. Camera.
    if (!cameraBegin()) {
        Serial.println("[Main] WARNING: camera initialisation failed");
    }

    // 3. HTTP web server.
    setupWebServer(webServer);

    // Brief LED blink to signal ready.
    digitalWrite(LED_GPIO_NUM, LOW);
    delay(200);
    digitalWrite(LED_GPIO_NUM, HIGH);

    Serial.println("[Main] Setup complete");
}

void loop() {
    // ESPAsyncWebServer runs in its own task; nothing needed here.
    delay(1000);
}

