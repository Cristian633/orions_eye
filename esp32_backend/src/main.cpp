// Minimal Arduino sketch entrypoints required by the Arduino core
#include <Arduino.h>

void setup() {
	// Inicialización mínima
	Serial.begin(115200);
	delay(100);
	Serial.println("ESP32 backend starting...");

	// TODO: inicializar subsistemas (WiFi, web server, AWS IoT, etc.)
}

void loop() {
	// Mantener el MCU vivo; la lógica principal puede ejecutarse aquí o en tareas
	delay(1000);
}

