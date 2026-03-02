#include "wifi_manager.h"
#include "config.h"

#include <WiFi.h>

// ────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ────────────────────────────────────────────────────────────────────────────

static String buildApSsid() {
    uint64_t chipId = ESP.getEfuseMac();
    char suffix[5];
    snprintf(suffix, sizeof(suffix), "%04X", (uint16_t)(chipId & 0xFFFF));
    return String("OrionsEye-") + suffix;
}

// ────────────────────────────────────────────────────────────────────────────
// Public API
// ────────────────────────────────────────────────────────────────────────────

void wifiManagerBegin() {
    // Start in AP+STA dual mode so the AP stays up even after STA connects.
    WiFi.mode(WIFI_AP_STA);

    String apSsid = buildApSsid();
    IPAddress apIp, apGateway, apSubnet;
    apIp.fromString(AP_IP);
    apGateway.fromString(AP_IP);
    apSubnet.fromString("255.255.255.0");

    WiFi.softAPConfig(apIp, apGateway, apSubnet);
    WiFi.softAP(apSsid.c_str(), AP_PASSWORD, AP_CHANNEL, 0, AP_MAX_CONN);

    Serial.print("[WiFi] AP started: ");
    Serial.print(apSsid);
    Serial.print("  IP: ");
    Serial.println(WiFi.softAPIP());
}

String wifiScan() {
    int n = WiFi.scanNetworks(/*async=*/false, /*show_hidden=*/false);
    String json = "{\"networks\":[";
    for (int i = 0; i < n; i++) {
        if (i > 0) json += ",";
        String enc;
        switch (WiFi.encryptionType(i)) {
            case WIFI_AUTH_OPEN:          enc = "Open";  break;
            case WIFI_AUTH_WEP:           enc = "WEP";   break;
            case WIFI_AUTH_WPA_PSK:       enc = "WPA";   break;
            case WIFI_AUTH_WPA2_PSK:      enc = "WPA2";  break;
            case WIFI_AUTH_WPA_WPA2_PSK:  enc = "WPA/WPA2"; break;
            default:                      enc = "Unknown"; break;
        }
        json += "{\"ssid\":\"" + WiFi.SSID(i) + "\","
                "\"rssi\":"    + WiFi.RSSI(i)  + ","
                "\"encryption\":\"" + enc + "\","
                "\"channel\":" + WiFi.channel(i) + "}";
    }
    WiFi.scanDelete();
    json += "]}";
    return json;
}

bool wifiConnect(const String &ssid, const String &password, String &assignedIp) {
    WiFi.begin(ssid.c_str(), password.c_str());

    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - start > WIFI_CONNECT_TIMEOUT_MS) {
            Serial.println("[WiFi] STA connect timeout");
            return false;
        }
        delay(200);
    }

    assignedIp = WiFi.localIP().toString();
    Serial.print("[WiFi] Connected. IP: ");
    Serial.println(assignedIp);
    return true;
}
