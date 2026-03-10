#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

class MQTTManager {
private:
    WiFiClientSecure wifiClient;
    PubSubClient mqttClient;
    String deviceId;
    String topicCommand;
    String topicStatus;
    String topicRequestUpload;
    String topicUploadResponse;
    String topicImageUploaded;
    
    void (*onCaptureCommand)();
    void (*onUploadUrlReceived)(String uploadUrl, String s3Key);
    
    bool isConnected;
    unsigned long lastReconnectAttempt;

public:
    MQTTManager();
    
    void begin(String deviceId);
    void loop();
    
    bool connect();
    void disconnect();
    
    void publishStatus(String status);
    void requestUploadUrl();
    void notifyImageUploaded(String s3Key);
    
    void onCapture(void (*callback)());
    void onUploadUrl(void (*callback)(String, String));
    
    bool isConnectedToMQTT();
    
private:
    void setupCallbacks();
    void messageCallback(char* topic, byte* payload, unsigned int length);
    static void staticMessageCallback(char* topic, byte* payload, unsigned int length);
    static MQTTManager* instance;
};

#endif // MQTT_MANAGER_H