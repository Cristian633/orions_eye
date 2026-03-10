#include "camera_handler.h"
#include "../include/config.h"

CameraHandler::CameraHandler() {
    initialized = false;
}

bool CameraHandler::begin() {
    Serial.println("📷 Iniciando cámara ESP32-CAM...");
    
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer = LEDC_TIMER_0;
    config.pin_d0 = Y2_GPIO_NUM;
    config.pin_d1 = Y3_GPIO_NUM;
    config.pin_d2 = Y4_GPIO_NUM;
    config.pin_d3 = Y5_GPIO_NUM;
    config.pin_d4 = Y6_GPIO_NUM;
    config.pin_d5 = Y7_GPIO_NUM;
    config.pin_d6 = Y8_GPIO_NUM;
    config.pin_d7 = Y9_GPIO_NUM;
    config.pin_xclk = XCLK_GPIO_NUM;
    config.pin_pclk = PCLK_GPIO_NUM;
    config.pin_vsync = VSYNC_GPIO_NUM;
    config.pin_href = HREF_GPIO_NUM;
    config.pin_sccb_sda = SIOD_GPIO_NUM;
    config.pin_sccb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn = PWDN_GPIO_NUM;
    config.pin_reset = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;
    config.pixel_format = PIXFORMAT_JPEG;
    
    // Configuración de calidad según PSRAM
    if (psramFound()) {
        config.frame_size = FRAMESIZE_UXGA;  // 1600x1200
        config.jpeg_quality = 10;
        config.fb_count = 2;
        Serial.println("✅ PSRAM encontrado - Alta calidad");
    } else {
        config.frame_size = FRAMESIZE_SVGA;  // 800x600
        config.jpeg_quality = 12;
        config.fb_count = 1;
        Serial.println("⚠️  PSRAM no encontrado - Calidad media");
    }
    
    // Inicializar cámara
    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("❌ Error al inicializar cámara: 0x%x\n", err);
        initialized = false;
        return false;
    }
    
    // Ajustes de sensor
    sensor_t* s = esp_camera_sensor_get();
    if (s) {
        s->set_brightness(s, 0);     // -2 to 2
        s->set_contrast(s, 0);       // -2 to 2
        s->set_saturation(s, 0);     // -2 to 2
        s->set_special_effect(s, 0); // 0 to 6 (0 - No Effect)
        s->set_whitebal(s, 1);       // 0 = disable , 1 = enable
        s->set_awb_gain(s, 1);       // 0 = disable , 1 = enable
        s->set_wb_mode(s, 0);        // 0 to 4
        s->set_exposure_ctrl(s, 1);  // 0 = disable , 1 = enable
        s->set_aec2(s, 0);           // 0 = disable , 1 = enable
        s->set_gain_ctrl(s, 1);      // 0 = disable , 1 = enable
        s->set_agc_gain(s, 0);       // 0 to 30
        s->set_gainceiling(s, (gainceiling_t)0);  // 0 to 6
        s->set_bpc(s, 0);            // 0 = disable , 1 = enable
        s->set_wpc(s, 1);            // 0 = disable , 1 = enable
        s->set_raw_gma(s, 1);        // 0 = disable , 1 = enable
        s->set_lenc(s, 1);           // 0 = disable , 1 = enable
        s->set_hmirror(s, 0);        // 0 = disable , 1 = enable
        s->set_vflip(s, 0);          // 0 = disable , 1 = enable
        s->set_dcw(s, 1);            // 0 = disable , 1 = enable
        s->set_colorbar(s, 0);       // 0 = disable , 1 = enable
    }
    
    initialized = true;
    Serial.println("✅ Cámara inicializada correctamente");
    return true;
}

camera_fb_t* CameraHandler::captureImage() {
    if (!initialized) {
        Serial.println("❌ Cámara no inicializada");
        return nullptr;
    }
    
    Serial.println("📸 Capturando imagen...");
    camera_fb_t* fb = esp_camera_fb_get();
    
    if (!fb) {
        Serial.println("❌ Error al capturar imagen");
        return nullptr;
    }
    
    Serial.printf("✅ Imagen capturada: %dx%d, %d bytes\n", 
                  fb->width, fb->height, fb->len);
    
    return fb;
}

void CameraHandler::releaseImage(camera_fb_t* fb) {
    if (fb) {
        esp_camera_fb_return(fb);
    }
}

bool CameraHandler::isInitialized() {
    return initialized;
}