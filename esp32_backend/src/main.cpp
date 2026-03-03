// ============================================================================
// ORION'S EYE - ESP32-CAM FIRMWARE
// Espectrometro astronómico con conectividad BLE + WiFi
// ============================================================================

#include <Arduino.h>
#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>    
#include <ble_server.h>
#include <camera_handler.h>
#include "../include/config.h"

// ============================================================================
// VARIABLES GLOBALES
// ============================================================================

BLEServerManager bleServer;
CameraHandler camera;
AsyncWebServer server(HTTP_PORT);

// Estados del sistema
enum SystemState {
    STATE_BLE_WAITING,      // Esperando conexión BLE
    STATE_WIFI_CONNECTING,  // Conectando a WiFi
    STATE_WIFI_CONNECTED,   // WiFi conectado, servidor HTTP activo
    STATE_ERROR             // Estado de error
};

SystemState currentState = STATE_BLE_WAITING;
String deviceName;
unsigned long stateStartTime = 0;

// ============================================================================
// FUNCIONES DE UTILIDAD
// ============================================================================

String getChipID() {
    uint64_t chipid = ESP.getEfuseMac();
    char chipidStr[13];
    sprintf(chipidStr, "%04X%08X", (uint16_t)(chipid >> 32), (uint32_t)chipid);
    return String(chipidStr).substring(8); // Últimos 4 caracteres
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
// FUNCIONES DE CONEXIÓN WiFi
// ============================================================================

bool connectToWiFi(String ssid, String password) {
    Serial.println("🌐 Conectando a WiFi: " + ssid);
    
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid.c_str(), password.c_str());
    
    unsigned long startTime = millis();
    
    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - startTime > WIFI_CONNECT_TIMEOUT) {
            Serial.println("❌ Timeout conectando a WiFi");
            return false;
        }
        delay(500);
        Serial.print(".");
    }
    
    Serial.println("\n✅ WiFi conectado!");
    Serial.print("📍 IP: ");
    Serial.println(WiFi.localIP());
    
    return true;
}

// ============================================================================
// ENDPOINTS HTTP DEL SERVIDOR WEB
// ============================================================================

void setupWebServer() {
    // Endpoint: Estado del dispositivo
    server.on("/status", HTTP_GET, [](AsyncWebServerRequest *request){
        DynamicJsonDocument doc(512);
        
        doc["status"] = "online";
        doc["deviceId"] = deviceName;
        doc["uptime"] = millis() / 1000;
        doc["freeHeap"] = ESP.getFreeHeap();
        doc["rssi"] = WiFi.RSSI();
        doc["ip"] = WiFi.localIP().toString();
        doc["firmware"] = FIRMWARE_VERSION;
        
        String response;
        serializeJson(doc, response);
        
        request->send(200, "application/json", response);
    });
    
    // Endpoint: Capturar imagen
    server.on("/capture", HTTP_GET, [](AsyncWebServerRequest *request){
        Serial.println("📸 Solicitud de captura recibida");
        
        if (!camera.isInitialized()) {
            request->send(500, "application/json", "{\"error\":\"Camera not initialized\"}");
            return;
        }
        
        camera_fb_t* fb = camera.captureImage();
        
        if (!fb) {
            request->send(500, "application/json", "{\"error\":\"Capture failed\"}");
            return;
        }
        
        // Enviar imagen JPEG usando send_P (para datos en RAM)
        AsyncWebServerResponse *response = request->beginResponse_P(
            200, 
            "image/jpeg", 
            fb->buf, 
            fb->len
        );
        
        response->addHeader("Content-Disposition", "inline; filename=capture.jpg");
        request->send(response);
        
        camera.releaseImage(fb);
        
        Serial.println("✅ Imagen enviada");
    });
    
    // Endpoint: Info del dispositivo
    server.on("/info", HTTP_GET, [](AsyncWebServerRequest *request){
        DynamicJsonDocument doc(512);
        
        doc["deviceName"] = deviceName;
        doc["chipModel"] = ESP.getChipModel();
        doc["chipCores"] = ESP.getChipCores();
        doc["cpuFreqMHz"] = ESP.getCpuFreqMHz();
        doc["flashSize"] = ESP.getFlashChipSize();
        doc["psramSize"] = ESP.getPsramSize();
        doc["firmware"] = FIRMWARE_VERSION;
        
        String response;
        serializeJson(doc, response);
        
        request->send(200, "application/json", response);
    });
    
    // Endpoint: Root
    server.on("/", HTTP_GET, [](AsyncWebServerRequest *request){
        String html = "<html><body>";
        html += "<h1>Orion's Eye ESP32-CAM</h1>";
        html += "<p>Device: " + deviceName + "</p>";
        html += "<p>Status: Online</p>";
        html += "<p>IP: " + WiFi.localIP().toString() + "</p>";
        html += "<p><a href='/status'>Status</a> | ";
        html += "<a href='/capture'>Capture</a> | ";
        html += "<a href='/info'>Info</a></p>";
        html += "</body></html>";
        
        request->send(200, "text/html", html);
    });
    
    // 404 Not Found
    server.onNotFound([](AsyncWebServerRequest *request){
        request->send(404, "application/json", "{\"error\":\"Not found\"}");
    });
    
    server.begin();
    Serial.println("✅ Servidor HTTP iniciado en puerto " + String(HTTP_PORT));
}

// ============================================================================
// SETUP
// ============================================================================

void setup() {
    // Inicializar Serial
    Serial.begin(115200);
    delay(100);
    
    Serial.println("\n\n");
    Serial.println("================================");
    Serial.println("  ORION'S EYE - ESP32-CAM");
    Serial.println("  Firmware v" + String(FIRMWARE_VERSION));
    Serial.println("================================");
    Serial.println();
    
    // LED de estado
    pinMode(LED_BUILTIN, OUTPUT);
    blinkLED(3, 100);
    
    // Generar nombre del dispositivo
    deviceName = String(DEVICE_NAME_PREFIX) + "-" + getChipID();
    Serial.println("📛 Device Name: " + deviceName);
    Serial.println("🔧 Chip ID: " + getChipID());
    Serial.println();
    
    // Inicializar cámara
    if (!camera.begin()) {
        Serial.println("❌ Error fatal: No se pudo inicializar la cámara");
        currentState = STATE_ERROR;
        return;
    }
    
    Serial.println();
    
    // Inicializar servidor BLE
    bleServer.begin(deviceName);
    currentState = STATE_BLE_WAITING;
    stateStartTime = millis();
    
    blinkLED(2, 300);
    
    Serial.println();
    Serial.println("✅ Sistema inicializado correctamente");
    Serial.println("🔍 Esperando conexión BLE desde la app...");
    Serial.println();
}

// ============================================================================
// LOOP PRINCIPAL
// ============================================================================

void loop() {
    // Manejar estados del sistema
    switch (currentState) {
        
        case STATE_BLE_WAITING: {
            // Esperar credenciales WiFi por BLE
            bleServer.loop();
            
            // Verificar si recibimos credenciales
            if (bleServer.hasWiFiCredentials()) {
                String ssid = bleServer.getReceivedSSID();
                String password = bleServer.getReceivedPassword();
                
                Serial.println("\n📥 Credenciales WiFi recibidas por BLE");
                Serial.println("🌐 Intentando conectar a: " + ssid);
                
                bleServer.notifyStatus("connecting");
                
                // Intentar conectar
                if (connectToWiFi(ssid, password)) {
                    bleServer.notifyStatus("connected:" + WiFi.localIP().toString());
                    
                    // Configurar servidor web
                    setupWebServer();
                    
                    currentState = STATE_WIFI_CONNECTED;
                    stateStartTime = millis();
                    
                    blinkLED(5, 100);
                    
                    Serial.println("\n🎉 Sistema completamente operativo!");
                    Serial.println("📡 BLE: Activo");
                    Serial.println("🌐 WiFi: Conectado");
                    Serial.println("🖥️  HTTP Server: http://" + WiFi.localIP().toString());
                    Serial.println();
                    
                } else {
                    bleServer.notifyStatus("failed");
                    Serial.println("❌ Error al conectar a WiFi");
                    Serial.println("🔄 Esperando nuevas credenciales...\n");
                    bleServer.clearCredentials();
                }
            }
            
            // LED heartbeat
            static unsigned long lastBlink = 0;
            static bool ledState = false;
            if (millis() - lastBlink > 2000) {
                ledState = !ledState;
                digitalWrite(LED_BUILTIN, ledState ? HIGH : LOW);
                lastBlink = millis();
            }
            
            break;
        }
        
        case STATE_WIFI_CONNECTED: {
            // Sistema operativo normal
            bleServer.loop();
            
            // Verificar conexión WiFi
            if (WiFi.status() != WL_CONNECTED) {
                Serial.println("⚠️  WiFi desconectado, reintentando...");
                currentState = STATE_BLE_WAITING;
                bleServer.clearCredentials();
            }
            
            // LED heartbeat lento
            static unsigned long lastBlink = 0;
            static bool ledState = false;
            if (millis() - lastBlink > 5000) {
                ledState = !ledState;
                digitalWrite(LED_BUILTIN, ledState ? HIGH : LOW);
                lastBlink = millis();
            }
            
            break;
        }
        
        case STATE_ERROR: {
            // Estado de error - parpadeo rápido
            blinkLED(1, 100);
            delay(500);
            break;
        }
    }
    
    delay(10);
}