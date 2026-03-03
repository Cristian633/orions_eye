#include "ble_server.h"
#include "../include/config.h"

// ============================================================================
// CALLBACKS DEL SERVIDOR BLE
// ============================================================================

class BLEServerManager::ServerCallbacks : public BLEServerCallbacks {
private:
    BLEServerManager* parent;
    
public:
    ServerCallbacks(BLEServerManager* p) : parent(p) {}
    
    void onConnect(BLEServer* pServer) {
        parent->deviceConnected = true;
        Serial.println("📱 Cliente BLE conectado");
    }
    
    void onDisconnect(BLEServer* pServer) {
        parent->deviceConnected = false;
        Serial.println("📱 Cliente BLE desconectado");
        
        // Reiniciar advertising
        delay(500);
        pServer->startAdvertising();
        Serial.println("🔄 BLE Advertising reiniciado");
    }
};

// ============================================================================
// CALLBACKS DE LAS CARACTERÍSTICAS
// ============================================================================

class BLEServerManager::CharacteristicCallbacks : public BLECharacteristicCallbacks {
private:
    BLEServerManager* parent;
    String* targetString;
    String name;
    
public:
    CharacteristicCallbacks(BLEServerManager* p, String* target, String n) 
        : parent(p), targetString(target), name(n) {}
    
    void onWrite(BLECharacteristic* pCharacteristic) {
        std::string value = pCharacteristic->getValue();
        
        if (value.length() > 0) {
            *targetString = String(value.c_str());
            Serial.print("📥 Recibido " + name + ": ");
            Serial.println(*targetString);
            
            // Si tenemos ambas credenciales
            if (parent->receivedSSID.length() > 0 && 
                parent->receivedPassword.length() > 0) {
                parent->wifiCredentialsReceived = true;
                Serial.println("✅ Credenciales WiFi completas recibidas");
            }
        }
    }
};

// ============================================================================
// IMPLEMENTACIÓN DE BLEServerManager
// ============================================================================

BLEServerManager::BLEServerManager() {
    pServer = nullptr;
    pService = nullptr;
    pCharSSID = nullptr;
    pCharPassword = nullptr;
    pCharStatus = nullptr;
    deviceConnected = false;
    wifiCredentialsReceived = false;
}

void BLEServerManager::begin(String deviceName) {
    Serial.println("🔵 Iniciando servidor BLE...");
    
    // Inicializar BLE
    BLEDevice::init(deviceName.c_str());
    
    // Crear servidor BLE
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks(this));
    
    // Crear servicio
    pService = pServer->createService(BLE_SERVICE_UUID);
    
    // Característica para SSID
    pCharSSID = pService->createCharacteristic(
        BLE_CHAR_SSID_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    pCharSSID->setCallbacks(new CharacteristicCallbacks(this, &receivedSSID, "SSID"));
    
    // Característica para Password
    pCharPassword = pService->createCharacteristic(
        BLE_CHAR_PASS_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    pCharPassword->setCallbacks(new CharacteristicCallbacks(this, &receivedPassword, "Password"));
    
    // Característica para Status (notificaciones)
    pCharStatus = pService->createCharacteristic(
        BLE_CHAR_STATUS_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pCharStatus->addDescriptor(new BLE2902());
    
    // Iniciar servicio
    pService->start();
    
    // Configurar advertising
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(BLE_SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    
    // Iniciar advertising
    BLEDevice::startAdvertising();
    
    Serial.println("✅ Servidor BLE iniciado: " + deviceName);
    Serial.println("🔍 Esperando conexión BLE...");
}

void BLEServerManager::loop() {
    // Por ahora no hay nada que hacer aquí
    // Los callbacks manejan todo
}

bool BLEServerManager::isDeviceConnected() {
    return deviceConnected;
}

bool BLEServerManager::hasWiFiCredentials() {
    return wifiCredentialsReceived;
}

String BLEServerManager::getReceivedSSID() {
    return receivedSSID;
}

String BLEServerManager::getReceivedPassword() {
    return receivedPassword;
}

void BLEServerManager::notifyStatus(String status) {
    if (pCharStatus && deviceConnected) {
        pCharStatus->setValue(status.c_str());
        pCharStatus->notify();
        Serial.println("📤 Status notificado: " + status);
    }
}

void BLEServerManager::clearCredentials() {
    receivedSSID = "";
    receivedPassword = "";
    wifiCredentialsReceived = false;
}