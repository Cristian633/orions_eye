#pragma once

#include <Arduino.h>

// Initialise Access Point (AP) and optionally connect as Station (STA).
void wifiManagerBegin();

// Scan for nearby networks. Returns a JSON string.
String wifiScan();

// Attempt to connect to the given SSID / password.
// Returns true on success; assigns the obtained IP to `assignedIp`.
bool wifiConnect(const String &ssid, const String &password, String &assignedIp);