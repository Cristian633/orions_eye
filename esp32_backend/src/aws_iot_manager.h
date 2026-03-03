#ifndef AWS_IOT_MANAGER_H
#define AWS_IOT_MANAGER_H

#include <Arduino.h>
#include <HTTPClient.h>

class AWSIoTManager {
private:
    String endpoint;
    
public:
    AWSIoTManager(String awsEndpoint);
    bool sendImage(uint8_t* imageData, size_t imageSize);
    bool sendData(String jsonData);
};

#endif // AWS_IOT_MANAGER_H