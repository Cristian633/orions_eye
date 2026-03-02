#include "camera_handler.h"
#include "config.h"

#include "esp_camera.h"
#include "mbedtls/base64.h"

// ────────────────────────────────────────────────────────────────────────────
// Camera initialisation
// ────────────────────────────────────────────────────────────────────────────

bool cameraBegin() {
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer   = LEDC_TIMER_0;
    config.pin_d0       = Y2_GPIO_NUM;
    config.pin_d1       = Y3_GPIO_NUM;
    config.pin_d2       = Y4_GPIO_NUM;
    config.pin_d3       = Y5_GPIO_NUM;
    config.pin_d4       = Y6_GPIO_NUM;
    config.pin_d5       = Y7_GPIO_NUM;
    config.pin_d6       = Y8_GPIO_NUM;
    config.pin_d7       = Y9_GPIO_NUM;
    config.pin_xclk     = XCLK_GPIO_NUM;
    config.pin_pclk     = PCLK_GPIO_NUM;
    config.pin_vsync    = VSYNC_GPIO_NUM;
    config.pin_href     = HREF_GPIO_NUM;
    config.pin_sscb_sda = SIOD_GPIO_NUM;
    config.pin_sscb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn     = PWDN_GPIO_NUM;
    config.pin_reset    = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;
    config.pixel_format = PIXFORMAT_JPEG;

    if (psramFound()) {
        config.frame_size   = FRAMESIZE_UXGA;
        config.jpeg_quality = 10;
        config.fb_count     = 2;
    } else {
        config.frame_size   = FRAMESIZE_SVGA;
        config.jpeg_quality = 12;
        config.fb_count     = 1;
    }

    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("[Camera] Init failed: 0x%x\n", err);
        return false;
    }
    Serial.println("[Camera] Initialised OK");
    return true;
}

// ────────────────────────────────────────────────────────────────────────────
// Capture helpers
// ────────────────────────────────────────────────────────────────────────────

String cameraCaptureBase64() {
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("[Camera] Frame capture failed");
        return "";
    }

    // Calculate required Base64 output length.
    size_t encodedLen = 0;
    mbedtls_base64_encode(nullptr, 0, &encodedLen, fb->buf, fb->len);

    String result;
    result.reserve(encodedLen + 1);

    // Use a heap buffer because large JPEG frames (up to ~100 kB) would exceed
    // the stack. malloc/free is intentional here; no exceptions are thrown and
    // the only early-exit path (allocation failure) is handled explicitly.
    uint8_t *encoded = (uint8_t *)malloc(encodedLen + 1);
    if (encoded) {
        size_t written = 0;
        mbedtls_base64_encode(encoded, encodedLen + 1, &written, fb->buf, fb->len);
        encoded[written] = '\0';
        result = (char *)encoded;
        free(encoded);
    } else {
        Serial.println("[Camera] Base64 malloc failed");
    }

    esp_camera_fb_return(fb);
    return result;
}
