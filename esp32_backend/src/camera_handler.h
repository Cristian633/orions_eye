#ifndef CAMERA_HANDLER_H
#define CAMERA_HANDLER_H

#include <Arduino.h>
#include "esp_camera.h"

class CameraHandler {
private:
    bool initialized;
    
public:
    CameraHandler();
    
    bool begin();
    camera_fb_t* captureImage();
    void releaseImage(camera_fb_t* fb);
    
    bool isInitialized();
};

#endif // CAMERA_HANDLER_H