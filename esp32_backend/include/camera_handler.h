#pragma once

#include <Arduino.h>

// Initialise the OV2640 camera with the AI-THINKER pin configuration.
// Returns true on success.
bool cameraBegin();

// Capture one frame and return it encoded as a Base64 string.
// Returns an empty string on failure.
String cameraCaptureBase64();
