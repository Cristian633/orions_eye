#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// CONFIGURACIÓN GENERAL
// ============================================================================

#define DEVICE_NAME_PREFIX "OrionsEye"
#define FIRMWARE_VERSION "1.0.0-MQTT"

// ============================================================================
// CONFIGURACIÓN BLUETOOTH BLE
// ============================================================================

// UUIDs para el servicio BLE (solo para pairing inicial)
#define BLE_SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define BLE_CHAR_SSID_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define BLE_CHAR_PASS_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define BLE_CHAR_STATUS_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26aa"

// ============================================================================
// CONFIGURACIÓN WiFi
// ============================================================================

// Opción A: WiFi hardcoded (para pruebas rápidas)
#define WIFI_SSID "TU_WIFI_AQUI"           // 
#define WIFI_PASSWORD "TU_PASSWORD_AQUI"   // 

// Opción B: Usar BLE para provisionar (comentar las líneas de arriba)
// #define USE_BLE_PROVISIONING

// ============================================================================
// CONFIGURACIÓN AWS IoT Core (MQTT)
// ============================================================================

#define AWS_IOT_ENDPOINT "a3kjpfhb0sgn22-ats.iot.us-east-2.amazonaws.com"  // 
#define AWS_IOT_PORT 8883

// Topics MQTT
#define MQTT_TOPIC_COMMAND "orionseye/%s/command"
#define MQTT_TOPIC_STATUS "orionseye/%s/status"
#define MQTT_TOPIC_REQUEST_UPLOAD "orionseye/%s/request-upload"
#define MQTT_TOPIC_UPLOAD_RESPONSE "orionseye/%s/upload-response"
#define MQTT_TOPIC_IMAGE_UPLOADED "orionseye/%s/image-uploaded"

// ============================================================================
// CERTIFICADOS AWS IoT Core
// ============================================================================

// Estos certificados se generan cuando registras el dispositivo
// Por ahora, usa certificados de prueba (los reemplazarás después)

// Root CA Certificate (Amazon Root CA 1)
const char AWS_CERT_CA[] PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj
ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM
9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw
IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6
VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L
93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm
jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA
A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI
U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs
N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv
o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU
5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy
rqXRfboQnoZsG4q5WTP468SQvvG5
-----END CERTIFICATE-----
)EOF";

// Device Certificate (se reemplazará después del registro)
const char AWS_CERT_CRT[] PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
REEMPLAZAR_CON_TU_CERTIFICADO
-----END CERTIFICATE-----
)EOF";

// Device Private Key (se reemplazará después del registro)
const char AWS_CERT_PRIVATE[] PROGMEM = R"KEY(
-----BEGIN RSA PRIVATE KEY-----
REEMPLAZAR_CON_TU_PRIVATE_KEY
-----END RSA PRIVATE KEY-----
)KEY";

// ============================================================================
// CONFIGURACIÓN ESP32-CAM (AI-THINKER)
// ============================================================================

#define CAMERA_MODEL_AI_THINKER

#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// LED integrado
#define LED_BUILTIN 33

// ============================================================================
// TIMEOUTS Y LÍMITES
// ============================================================================

#define WIFI_CONNECT_TIMEOUT 15000  // 15 segundos
#define MQTT_RECONNECT_DELAY 5000   // 5 segundos
#define CAPTURE_TIMEOUT 10000       // 10 segundos

#endif // CONFIG_H