import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:orions_eye_app/domain/models/wifi_network.dart';

class ESP32Service {
  final Dio _dio;
  final Logger _logger = Logger();
  
  // IP del ESP32 en modo Access Point
  static const String ESP32_AP_IP = '192.168.4.1';
  
  ESP32Service() : _dio = Dio(BaseOptions(
    baseUrl: 'http://$ESP32_AP_IP',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Obtener estado del dispositivo
  Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final response = await _dio.get('/status');
      _logger.i('Estado del dispositivo: ${response.data}');
      return response.data;
    } catch (e) {
      _logger.e('Error obteniendo estado: $e');
      rethrow;
    }
  }

  /// Escanear redes WiFi disponibles
  Future<List<WiFiNetwork>> scanWiFiNetworks() async {
    try {
      final response = await _dio.get('/wifi-scan');
      _logger.i('Redes encontradas: ${response.data['networks'].length}');
      
      final networks = (response.data['networks'] as List)
          .map((network) => WiFiNetwork.fromJson(network))
          .toList();
      
      return networks;
    } catch (e) {
      _logger.e('Error escaneando WiFi: $e');
      rethrow;
    }
  }

  /// Enviar credenciales WiFi al ESP32
  Future<ProvisionResult> provisionWiFi({
    required String ssid,
    required String password,
  }) async {
    try {
      _logger.i('Enviando credenciales WiFi: $ssid');
      
      final response = await _dio.post(
        '/provision',
        data: {
          'ssid': ssid,
          'password': password,
        },
      );

      _logger.i('Respuesta de provisionamiento: ${response.data}');
      
      return ProvisionResult(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? 'Sin respuesta',
        deviceIp: response.data['ip'],
      );
    } catch (e) {
      _logger.e('Error en provisionamiento: $e');
      return ProvisionResult(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  /// Verificar conectividad con el ESP32
  Future<bool> ping() async {
    try {
      final response = await _dio.get('/status');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Modelo de red WiFi
// WiFiNetwork model moved to domain models

/// Resultado del provisionamiento
class ProvisionResult {
  final bool success;
  final String message;
  final String? deviceIp;

  ProvisionResult({
    required this.success,
    required this.message,
    this.deviceIp,
  });
}