#include "aws_iot_manager.h"
#include "camera_handler.h"
#include "config.h"

#include <HTTPClient.h>
#include <WiFiClientSecure.h>

bool cameraCaptureAndUpload() {
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("[AWS] Frame capture failed – cannot upload");
        return false;
    }

    WiFiClientSecure client;
    // NOTE: setInsecure() skips certificate verification. For production,
    // replace this with client.setCACert(rootCaPem) to prevent MITM attacks.
    client.setInsecure();

    HTTPClient http;
    String url = String(AWS_IOT_ENDPOINT) + AWS_CAPTURE_PATH;
    http.begin(client, url);
    http.addHeader("Content-Type", "image/jpeg");
    http.setTimeout(HTTP_TIMEOUT_MS);

    int code = http.POST(fb->buf, fb->len);
    esp_camera_fb_return(fb);

    if (code > 0) {
        Serial.printf("[AWS] Upload response: %d\n", code);
        http.end();
        return (code >= 200 && code < 300);
    }

    Serial.printf("[AWS] Upload error: %s\n", http.errorToString(code).c_str());
    http.end();
    return false;
}
