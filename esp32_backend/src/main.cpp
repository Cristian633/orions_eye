// ============================================================================
// ORION'S EYE - ESP32-CAM FIRMWARE CON AWS IoT Core
// Espectrómetro astronómico con MQTT + S3
// ============================================================================

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "ble_server.h"
#include "camera_handler.h"
#include "mqtt_manager.h"
#include "../include/config.h"

// ============================================================================
// VARIABLES GLOBALES
// ============================================================================

BLEServerManager bleServer;
CameraHandler camera;
MQTTManager mqttManager;

String deviceName;
String deviceId;

bool wifiConnected = false;
bool mqttConnected = false;
bool captureRequested = false;

String pendingUploadUrl;
String pendingS3Key;

// ============================================================================
// FUNCIONES DE UTILIDAD
// ============================================================================

String getChipID() {
    uint64_t chipid = ESP.getEfuseMac();
    char chipidStr[13];
    sprintf(chipidStr, "%04X%08X", (uint16_t)(chipid >> 32), (uint32_t)chipid);
    return String(chipidStr).substring(8);
}

void blinkLED(int times, int delayMs = 200) {
    for (int i = 0; i < times; i++) {
        digitalWrite(LED_BUILTIN, HIGH);
        delay(delayMs);
        digitalWrite(LED_BUILTIN, LOW);
        delay(delayMs);
    }
}

// ============================================================================
// CONEXIÓN WiFi
// ============================================================================

bool connectToWiFi() {
    Serial.println("Conectando a WiFi...");
    Serial.print("  SSID: ");
    Serial.println(WIFI_SSID);
    
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    unsigned long startTime = millis();
    
    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - startTime > WIFI_CONNECT_TIMEOUT) {
            Serial.println(" Timeout conectando a WiFi");
            return false;
        }
        delay(500);
        Serial.print(".");
    }
    
    Serial.println("\n WiFi conectado!");
    Serial.print(" IP: ");
    Serial.println(WiFi.localIP());
    Serial.print(" RSSI: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    
    wifiConnected = true;
    return true;
}

// ============================================================================
// SUBIR IMAGEN A S3
// ============================================================================

bool uploadImageToS3(String uploadUrl, camera_fb_t* fb) {
    if (!fb || !fb->buf || fb->len == 0) {
        Serial.println(" Imagen inválida");
        return false;
    }
    
    Serial.println("  Subiendo imagen a S3...");
    Serial.print("  Tamaño: ");
    Serial.print(fb->len);
    Serial.println(" bytes");
    
    HTTPClient http;
    http.begin(uploadUrl);
    http.addHeader("Content-Type", "image/jpeg");
    http.setTimeout(30000); // 30 segundos
    
    int httpCode = http.PUT(fb->buf, fb->len);
    
    Serial.print("  HTTP Code: ");
    Serial.println(httpCode);
    
    if (httpCode == 200 || httpCode == 204) {
        Serial.println(" Imagen subida exitosamente!");
        http.end();
        return true;
    } else {
        Serial.print(" Error subiendo imagen: ");
        Serial.println(httpCode);
        
        if (httpCode > 0) {
            String response = http.getString();
            Serial.println("  Response: " + response);
        }
        
        http.end();
        return false;
    }
}

// ============================================================================
// PROCESO COMPLETO DE CAPTURA
// ============================================================================

void handleCaptureCommand() {
    Serial.println("\n ========================================");
    Serial.println(" INICIANDO PROCESO DE CAPTURA");
    Serial.println(" ========================================\n");
    
    blinkLED(2, 100);
    
    // 1. Solicitar URL presigned
    Serial.println("PASO 1: Solicitando presigned URL...");
    mqttManager.requestUploadUrl();
    
    // Esperar respuesta (se manejará en el callback)
    captureRequested = true;
}

void handleUploadUrl(String uploadUrl, String s3Key) {
    Serial.println("\nURL PRESIGNED RECIBIDA");
    Serial.println("  S3 Key: " + s3Key);
    
    pendingUploadUrl = uploadUrl;
    pendingS3Key = s3Key;
    
    // 2. Capturar imagen
    Serial.println("\nPASO 2: Capturando imagen...");
    
    camera_fb_t* fb = camera.captureImage();
    
    if (!fb) {
        Serial.println(" Error capturando imagen");
        captureRequested = false;
        return;
    }
    
    Serial.println("Imagen capturada!");
    Serial.printf("  Tamaño: %dx%d\n", fb->width, fb->height);
    Serial.printf("  Bytes: %d\n", fb->len);
    
    // 3. Subir a S3
    Serial.println("\n  PASO 3: Subiendo a S3...");
    
    bool uploaded = uploadImageToS3(pendingUploadUrl, fb);
    
    // Liberar memoria
    camera.releaseImage(fb);
    
    if (uploaded) {
        // 4. Notificar que la imagen fue subida
        Serial.println("\n PASO 4: Notificando backend...");
        mqttManager.notifyImageUploaded(pendingS3Key);
        
        Serial.println("\n ========================================");
        Serial.println("CAPTURA COMPLETADA EXITOSAMENTE");
        Serial.println(" ========================================\n");
        
        blinkLED(5, 100);
    } else {
        Serial.println("\n ========================================");
        Serial.println(" ERROR EN LA CAPTURA");
        Serial.println(" ========================================\n");
        
        blinkLED(10, 50);
    }
    
    captureRequested = false;
}

// ============================================================================
// SETUP
// ============================================================================

void setup() {
    // Inicializar Serial
    Serial.begin(115200);
    delay(100);
    
    Serial.println("\n\n");
    Serial.println("🎯 ========================================");
    Serial.println("  ORION'S EYE - ESP32-CAM");
    Serial.println("  Firmware v" + String(FIRMWARE_VERSION));
    Serial.println("  Con AWS IoT Core + S3");
    Serial.println("🎯 ========================================");
    Serial.println();
    
    // LED de estado
    pinMode(LED_BUILTIN, OUTPUT);
    blinkLED(3, 100);
    
    // Generar Device ID
    deviceId = getChipID();
    deviceName = String(DEVICE_NAME_PREFIX) + "-" + deviceId;
    
    Serial.println(" Device Name: " + deviceName);
    Serial.println("Device ID: " + deviceId);
    Serial.println();
    
    // Inicializar cámara
    if (!camera.begin()) {
        Serial.println(" Error fatal: No se pudo inicializar la cámara");
        while(1) {
            blinkLED(1, 100);
            delay(1000);
        }
    }
    
    Serial.println();
    
    // Conectar a WiFi
    if (!connectToWiFi()) {
        Serial.println(" Error fatal: No se pudo conectar a WiFi");
        
        #ifdef USE_BLE_PROVISIONING
        Serial.println(" Iniciando modo BLE para provisioning...");
        bleServer.begin(deviceName);
        #else
        while(1) {
            blinkLED(2, 200);
            delay(2000);
        }
        #endif
    }
    
    Serial.println();
    
    // Inicializar MQTT Manager
    mqttManager.begin(deviceId);
    
    // Configurar callbacks
    mqttManager.onCapture(handleCaptureCommand);
    mqttManager.onUploadUrl(handleUploadUrl);
    
    // Conectar a MQTT
    if (mqttManager.connect()) {
        mqttConnected = true;
        Serial.println(" Sistema completamente operativo!");
    } else {
        Serial.println("  Sistema iniciado pero MQTT desconectado");
        Serial.println("  Se intentará reconectar automáticamente...");
    }
    
    Serial.println();
    Serial.println(" ========================================");
    Serial.println(" LISTO PARA RECIBIR COMANDOS");
    Serial.println(" ========================================");
    Serial.println();
    
    blinkLED(5, 100);
}

// ============================================================================
// LOOP PRINCIPAL
// ============================================================================

void loop() {
    // Mantener conexión MQTT
    mqttManager.loop();
    
    // LED heartbeat
    static unsigned long lastHeartbeat = 0;
    if (millis() - lastHeartbeat > 5000) {
        lastHeartbeat = millis();
        
        if (mqttManager.isConnectedToMQTT()) {
            // Parpadeo rápido: conectado
            digitalWrite(LED_BUILTIN, HIGH);
            delay(50);
            digitalWrite(LED_BUILTIN, LOW);
        } else {
            // Parpadeo lento: desconectado
            digitalWrite(LED_BUILTIN, HIGH);
            delay(200);
            digitalWrite(LED_BUILTIN, LOW);
        }
    }
    
    delay(10);
}