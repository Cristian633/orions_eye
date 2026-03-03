#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// CONFIGURACIÓN GENERAL
// ============================================================================

#define DEVICE_NAME_PREFIX "OrionsEye"
#define FIRMWARE_VERSION "1.0.0-BLE"

// ============================================================================
// CONFIGURACIÓN BLUETOOTH BLE
// ============================================================================

// UUIDs para el servicio BLE (deben coincidir con la app Flutter)
#define BLE_SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define BLE_CHAR_SSID_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define BLE_CHAR_PASS_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define BLE_CHAR_STATUS_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26aa"

// ============================================================================
// CONFIGURACIÓN WiFi ACCESS POINT
// ============================================================================

#define AP_SSID_PREFIX "OrionsEye"
#define AP_PASSWORD "orionseye2024"
#define AP_CHANNEL 1
#define AP_MAX_CONNECTIONS 4

// IP del Access Point
#define AP_IP IPAddress(192, 168, 4, 1)
#define AP_GATEWAY IPAddress(192, 168, 4, 1)
#define AP_SUBNET IPAddress(255, 255, 255, 0)

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
// CONFIGURACIÓN AWS BACKEND
// ============================================================================

#define AWS_IOT_ENDPOINT "https://c4cp36ywm6.execute-api.us-east-2.amazonaws.com/Prod"
#define AWS_TIMEOUT 10000

// ============================================================================
// CONFIGURACIÓN HTTP SERVER
// ============================================================================

#define HTTP_PORT 80

// ============================================================================
// TIMEOUTS Y LÍMITES
// ============================================================================

#define WIFI_CONNECT_TIMEOUT 10000  // 10 segundos
#define BLE_TIMEOUT 30000            // 30 segundos
#define CAPTURE_TIMEOUT 5000         // 5 segundos

#endif // CONFIG_H