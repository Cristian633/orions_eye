#ifndef WEB_SERVER_H
#define WEB_SERVER_H

#include <Arduino.h>
#include <ESPAsyncWebServer.h>

class WebServerManager {
private:
    AsyncWebServer* server;
    
public:
    WebServerManager(int port = 80);
    void begin();
    void setupRoutes();
};

#endif // WEB_SERVER_H