class ApiConstants {

  static const String baseUrl = 'https://wovr1gy45g.execute-api.us-east-2.amazonaws.com/Prod';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class AppStrings {
  static const String firstTimeSetup =
      'Para conectar Orion\'s Eye por primera vez, sigue estos pasos:\n\n'
      '1. Enciende el dispositivo ESP32-CAM.\n'
      '2. Activa el Hotspot de tu teléfono con los datos de configuración.\n'
      '3. Vuelve aquí y pulsa "Buscar dispositivos" para iniciar el emparejamiento.';
}