#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <Arduino.h>
#include <WiFi.h>

class WiFiManager {
public:
    WiFiManager();
    bool connectToWiFi(String ssid, String password, unsigned long timeout = 10000);
    bool isConnected();
    String getLocalIP();
    int getRSSI();
};

#endif // WIFI_MANAGER_H