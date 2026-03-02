#include "web_server.h"
#include "wifi_manager.h"
#include "camera_handler.h"
#include "aws_iot_manager.h"
#include "config.h"

#include <ArduinoJson.h>
#include <WiFi.h>

// ────────────────────────────────────────────────────────────────────────────
// CORS helper
// ────────────────────────────────────────────────────────────────────────────

static void addCorsHeaders(AsyncWebServerResponse *response) {
    response->addHeader("Access-Control-Allow-Origin",  "*");
    response->addHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
    response->addHeader("Access-Control-Allow-Headers", "Content-Type");
}

// ────────────────────────────────────────────────────────────────────────────
// Endpoint handlers
// ────────────────────────────────────────────────────────────────────────────

static void handleStatus(AsyncWebServerRequest *request) {
    uint64_t chipId = ESP.getEfuseMac();
    char deviceId[20];
    snprintf(deviceId, sizeof(deviceId), "ESP32_%06X", (uint32_t)(chipId & 0xFFFFFF));

    StaticJsonDocument<256> doc;
    doc["status"]   = "online";
    doc["deviceId"] = deviceId;
    doc["uptime"]   = millis() / 1000;
    doc["freeHeap"] = ESP.getFreeHeap();
    doc["rssi"]     = WiFi.RSSI();
    doc["ip"]       = (WiFi.status() == WL_CONNECTED)
                          ? WiFi.localIP().toString()
                          : WiFi.softAPIP().toString();

    String body;
    serializeJson(doc, body);
    auto *response = request->beginResponse(200, "application/json", body);
    addCorsHeaders(response);
    request->send(response);
}

static void handleWifiScan(AsyncWebServerRequest *request) {
    String body = wifiScan();
    auto *response = request->beginResponse(200, "application/json", body);
    addCorsHeaders(response);
    request->send(response);
}

static void handleProvision(AsyncWebServerRequest *request, uint8_t *data,
                             size_t len, size_t /*index*/, size_t /*total*/) {
    StaticJsonDocument<256> reqDoc;
    DeserializationError err = deserializeJson(reqDoc, data, len);

    StaticJsonDocument<256> resDoc;
    uint64_t chipId = ESP.getEfuseMac();
    char deviceId[20];
    snprintf(deviceId, sizeof(deviceId), "ESP32_%06X", (uint32_t)(chipId & 0xFFFFFF));
    resDoc["deviceId"] = deviceId;

    if (err || !reqDoc.containsKey("ssid") || !reqDoc.containsKey("password")) {
        resDoc["success"] = false;
        resDoc["message"] = "JSON invalido o campos faltantes";
        String body;
        serializeJson(resDoc, body);
        auto *response = request->beginResponse(400, "application/json", body);
        addCorsHeaders(response);
        request->send(response);
        return;
    }

    String ssid     = reqDoc["ssid"].as<String>();
    String password = reqDoc["password"].as<String>();
    String assignedIp;
    bool connected  = wifiConnect(ssid, password, assignedIp);

    resDoc["success"] = connected;
    resDoc["message"] = connected ? "Conectado exitosamente" : "No se pudo conectar";
    resDoc["ip"]      = assignedIp;

    String body;
    serializeJson(resDoc, body);
    auto *response = request->beginResponse(connected ? 200 : 503,
                                            "application/json", body);
    addCorsHeaders(response);
    request->send(response);
}

static void handleCapture(AsyncWebServerRequest *request) {
    String b64 = cameraCaptureBase64();
    if (b64.isEmpty()) {
        StaticJsonDocument<64> doc;
        doc["error"] = "Fallo al capturar imagen";
        String body;
        serializeJson(doc, body);
        auto *response = request->beginResponse(500, "application/json", body);
        addCorsHeaders(response);
        request->send(response);
        return;
    }

    // The image data is too large for a JSON document; stream it manually.
    String body = "{\"image\":\"" + b64 + "\"}";
    auto *response = request->beginResponse(200, "application/json", body);
    addCorsHeaders(response);
    request->send(response);
}

static void handleInfo(AsyncWebServerRequest *request) {
    uint64_t chipId = ESP.getEfuseMac();
    char deviceId[20];
    snprintf(deviceId, sizeof(deviceId), "ESP32_%06X", (uint32_t)(chipId & 0xFFFFFF));

    StaticJsonDocument<256> doc;
    doc["firmwareVersion"] = "1.0.0";
    doc["deviceId"]        = deviceId;
    doc["chipModel"]       = ESP.getChipModel();
    doc["cpuFreqMHz"]      = ESP.getCpuFreqMHz();
    doc["flashSizeMB"]     = ESP.getFlashChipSize() / (1024 * 1024);
    doc["freeHeap"]        = ESP.getFreeHeap();
    doc["psramSize"]       = ESP.getPsramSize();

    String body;
    serializeJson(doc, body);
    auto *response = request->beginResponse(200, "application/json", body);
    addCorsHeaders(response);
    request->send(response);
}

// ────────────────────────────────────────────────────────────────────────────
// Server setup
// ────────────────────────────────────────────────────────────────────────────

void setupWebServer(AsyncWebServer &server) {
    // Handle pre-flight CORS requests.
    server.onNotFound([](AsyncWebServerRequest *request) {
        if (request->method() == HTTP_OPTIONS) {
            auto *response = request->beginResponse(204);
            addCorsHeaders(response);
            request->send(response);
        } else {
            request->send(404, "application/json", "{\"error\":\"Not found\"}");
        }
    });

    server.on("/status",    HTTP_GET,  handleStatus);
    server.on("/wifi-scan", HTTP_GET,  handleWifiScan);
    server.on("/capture",   HTTP_GET,  handleCapture);
    server.on("/info",      HTTP_GET,  handleInfo);

    // POST /provision needs a body handler.
    server.on("/provision", HTTP_POST,
        [](AsyncWebServerRequest *request) { /* body arrives via onBody */ },
        nullptr,
        handleProvision);

    server.begin();
    Serial.println("[WebServer] Listening on port 80");
}
