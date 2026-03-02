#pragma once

#include <Arduino.h>

// Capture one frame and send it directly to the AWS backend.
// Returns true on success.
bool cameraCaptureAndUpload();