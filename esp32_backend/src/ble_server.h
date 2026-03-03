#ifndef BLE_SERVER_H
#define BLE_SERVER_H

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

class BLEServerManager {
private:
    BLEServer* pServer;
    BLEService* pService;
    BLECharacteristic* pCharSSID;
    BLECharacteristic* pCharPassword;
    BLECharacteristic* pCharStatus;
    
    bool deviceConnected;
    bool wifiCredentialsReceived;
    
    String receivedSSID;
    String receivedPassword;
    
    // Callbacks
    class ServerCallbacks;
    class CharacteristicCallbacks;

public:
    BLEServerManager();
    
    void begin(String deviceName);
    void loop();
    
    bool isDeviceConnected();
    bool hasWiFiCredentials();
    
    String getReceivedSSID();
    String getReceivedPassword();
    
    void notifyStatus(String status);
    void clearCredentials();
    
    friend class ServerCallbacks;
    friend class CharacteristicCallbacks;
};

#endif // BLE_SERVER_H