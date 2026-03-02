#pragma once

// ─── AWS Backend ────────────────────────────────────────────────────────────
#define AWS_IOT_ENDPOINT "https://c4cp36ywm6.execute-api.us-east-2.amazonaws.com/Prod"
#define AWS_CAPTURE_PATH "/capture"

// ─── Access Point ────────────────────────────────────────────────────────────
#define AP_PASSWORD      "orionseye2024"
#define AP_IP            "192.168.4.1"
#define AP_CHANNEL       1
#define AP_MAX_CONN      4

// ─── Network timeouts ────────────────────────────────────────────────────────
#define WIFI_CONNECT_TIMEOUT_MS  10000
#define HTTP_TIMEOUT_MS          15000

// ─── Serial ──────────────────────────────────────────────────────────────────
#define SERIAL_BAUD 115200

// ─── Status LED (GPIO 33 on AI-THINKER board, active-low) ───────────────────
#define LED_GPIO_NUM 33

// ─── ESP32-CAM AI-THINKER pin mapping ────────────────────────────────────────
#define PWDN_GPIO_NUM    32
#define RESET_GPIO_NUM   -1
#define XCLK_GPIO_NUM     0
#define SIOD_GPIO_NUM    26
#define SIOC_GPIO_NUM    27
#define Y9_GPIO_NUM      35
#define Y8_GPIO_NUM      34
#define Y7_GPIO_NUM      39
#define Y6_GPIO_NUM      36
#define Y5_GPIO_NUM      21
#define Y4_GPIO_NUM      19
#define Y3_GPIO_NUM      18
#define Y2_GPIO_NUM       5
#define VSYNC_GPIO_NUM   25
#define HREF_GPIO_NUM    23
#define PCLK_GPIO_NUM    22