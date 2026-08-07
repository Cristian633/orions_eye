#include "mqtt_manager.h"
#include "../include/config.h"

MQTTManager* MQTTManager::instance = nullptr;

MQTTManager::MQTTManager() : mqttClient(wifiClient) {
    instance = this;
    isConnected = false;
    lastReconnectAttempt = 0;
    onCaptureCommand = nullptr;
    onUploadUrlReceived = nullptr;
}

void MQTTManager::begin(String deviceId) {
    this->deviceId = deviceId;
    
    // Configurar topics
    topicCommand = String(MQTT_TOPIC_COMMAND);
    topicCommand.replace("%s", deviceId);
    
    topicStatus = String(MQTT_TOPIC_STATUS);
    topicStatus.replace("%s", deviceId);
    
    topicRequestUpload = String(MQTT_TOPIC_REQUEST_UPLOAD);
    topicRequestUpload.replace("%s", deviceId);
    
    topicUploadResponse = String(MQTT_TOPIC_UPLOAD_RESPONSE);
    topicUploadResponse.replace("%s", deviceId);
    
    topicImageUploaded = String(MQTT_TOPIC_IMAGE_UPLOADED);
    topicImageUploaded.replace("%s", deviceId);
    
    Serial.println(" Configurando MQTT Manager...");
    Serial.println(" Topics:");
    Serial.println("  - Command: " + topicCommand);
    Serial.println("  - Status: " + topicStatus);
    Serial.println("  - Upload Response: " + topicUploadResponse);
    
    // Configurar certificados SSL
    wifiClient.setCACert(AWS_CERT_CA);
    wifiClient.setCertificate(AWS_CERT_CRT);
    wifiClient.setPrivateKey(AWS_CERT_PRIVATE);
    
    // Configurar servidor MQTT
    mqttClient.setServer(AWS_IOT_ENDPOINT, AWS_IOT_PORT);
    mqttClient.setCallback(staticMessageCallback);
    mqttClient.setKeepAlive(60);
    mqttClient.setSocketTimeout(30);
    
    Serial.println(" MQTT Manager configurado");
}

bool MQTTManager::connect() {
    if (mqttClient.connected()) {
        return true;
    }
    
    Serial.println("🔄 Conectando a AWS IoT Core...");
    Serial.print("📡 Endpoint: ");
    Serial.println(AWS_IOT_ENDPOINT);
    
    String clientId = "ESP32_" + deviceId;
    
    if (mqttClient.connect(clientId.c_str())) {
        Serial.println(" Conectado a AWS IoT Core!");
        
        isConnected = true;
        
        // Suscribirse a topics
        Serial.println("📥 Suscribiéndose a topics...");
        
        if (mqttClient.subscribe(topicCommand.c_str())) {
            Serial.println("  ✅ Suscrito a: " + topicCommand);
        }
        
        if (mqttClient.subscribe(topicUploadResponse.c_str())) {
            Serial.println("  ✅ Suscrito a: " + topicUploadResponse);
        }
        
        // Publicar estado online
        publishStatus("online");
        
        return true;
    } else {
        Serial.print("❌ Error conectando MQTT: ");
        Serial.println(mqttClient.state());
        
        switch (mqttClient.state()) {
            case -4: Serial.println("  → MQTT_CONNECTION_TIMEOUT"); break;
            case -3: Serial.println("  → MQTT_CONNECTION_LOST"); break;
            case -2: Serial.println("  → MQTT_CONNECT_FAILED"); break;
            case -1: Serial.println("  → MQTT_DISCONNECTED"); break;
            case  1: Serial.println("  → MQTT_CONNECT_BAD_PROTOCOL"); break;
            case  2: Serial.println("  → MQTT_CONNECT_BAD_CLIENT_ID"); break;
            case  3: Serial.println("  → MQTT_CONNECT_UNAVAILABLE"); break;
            case  4: Serial.println("  → MQTT_CONNECT_BAD_CREDENTIALS"); break;
            case  5: Serial.println("  → MQTT_CONNECT_UNAUTHORIZED"); break;
        }
        
        isConnected = false;
        return false;
    }
}

void MQTTManager::loop() {
    if (!mqttClient.connected()) {
        isConnected = false;
        
        unsigned long now = millis();
        if (now - lastReconnectAttempt > MQTT_RECONNECT_DELAY) {
            lastReconnectAttempt = now;
            Serial.println("🔄 Intentando reconectar MQTT...");
            connect();
        }
    } else {
        mqttClient.loop();
    }
}

void MQTTManager::disconnect() {
    publishStatus("offline");
    mqttClient.disconnect();
    isConnected = false;
}

void MQTTManager::publishStatus(String status) {
    if (!mqttClient.connected()) return;
    
    StaticJsonDocument<200> doc;
    doc["status"] = status;
    doc["deviceId"] = deviceId;
    doc["firmware"] = FIRMWARE_VERSION;
    doc["timestamp"] = millis();
    
    String payload;
    serializeJson(doc, payload);
    
    if (mqttClient.publish(topicStatus.c_str(), payload.c_str())) {
        Serial.println("📤 Status publicado: " + status);
    }
}

void MQTTManager::requestUploadUrl() {
    if (!mqttClient.connected()) {
        Serial.println("❌ No conectado a MQTT, no se puede solicitar URL");
        return;
    }
    
    Serial.println("📤 Solicitando presigned URL...");
    
    StaticJsonDocument<200> doc;
    doc["deviceId"] = deviceId;
    doc["contentType"] = "image/jpeg";
    doc["timestamp"] = millis();
    
    String payload;
    serializeJson(doc, payload);
    
    if (mqttClient.publish(topicRequestUpload.c_str(), payload.c_str())) {
        Serial.println("✅ Solicitud enviada");
    } else {
        Serial.println("❌ Error enviando solicitud");
    }
}

void MQTTManager::notifyImageUploaded(String s3Key) {
    if (!mqttClient.connected()) return;
    
    Serial.println("📤 Notificando imagen subida...");
    
    StaticJsonDocument<300> doc;
    doc["deviceId"] = deviceId;
    doc["s3Key"] = s3Key;
    doc["timestamp"] = millis();
    doc["status"] = "uploaded";
    
    String payload;
    serializeJson(doc, payload);
    
    if (mqttClient.publish(topicImageUploaded.c_str(), payload.c_str())) {
        Serial.println("✅ Notificación enviada");
    }
}

void MQTTManager::onCapture(void (*callback)()) {
    onCaptureCommand = callback;
}

void MQTTManager::onUploadUrl(void (*callback)(String, String)) {
    onUploadUrlReceived = callback;
}

bool MQTTManager::isConnectedToMQTT() {
    return isConnected && mqttClient.connected();
}

void MQTTManager::staticMessageCallback(char* topic, byte* payload, unsigned int length) {
    if (instance != nullptr) {
        instance->messageCallback(topic, payload, length);
    }
}

void MQTTManager::messageCallback(char* topic, byte* payload, unsigned int length) {
    Serial.println("\n📨 Mensaje MQTT recibido:");
    Serial.print("  Topic: ");
    Serial.println(topic);
    
    // Convertir payload a String
    String message;
    for (unsigned int i = 0; i < length; i++) {
        message += (char)payload[i];
    }
    
    Serial.print("  Payload: ");
    Serial.println(message);
    
    // Parsear JSON
    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, message);
    
    if (error) {
        Serial.print("❌ Error parseando JSON: ");
        Serial.println(error.c_str());
        return;
    }
    
    // Determinar qué hacer según el topic
    String topicStr = String(topic);
    
    if (topicStr == topicCommand) {
        // Comando recibido
        String command = doc["command"] | "";
        Serial.println("🎯 Comando: " + command);
        
        if (command == "capture" && onCaptureCommand != nullptr) {
            Serial.println("📸 Ejecutando captura...");
            onCaptureCommand();
        }
        
    } else if (topicStr == topicUploadResponse) {
        // URL presigned recibida
        String uploadUrl = doc["uploadUrl"] | "";
        String s3Key = doc["s3Key"] | "";
        
        Serial.println("🔗 URL recibida");
        Serial.println("  S3 Key: " + s3Key);
        
        if (uploadUrl.length() > 0 && onUploadUrlReceived != nullptr) {
            onUploadUrlReceived(uploadUrl, s3Key);
        }
    }
}