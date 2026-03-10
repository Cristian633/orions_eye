import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';

class DeviceService {
  final String baseUrl = ApiConstants.baseUrl;

  /// Registra un nuevo dispositivo
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String userId,
    required String deviceName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devices/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deviceId': deviceId,
          'userId': userId,
          'deviceName': deviceName,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error registrando dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Envía comando de captura al dispositivo
  Future<bool> captureImage(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devices/$deviceId/command'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'command': 'capture',
          'payload': {},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error enviando comando de captura: $e');
      return false;
    }
  }

  /// Obtiene el estado del dispositivo
  Future<Map<String, dynamic>?> getDeviceStatus(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId/status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error obteniendo estado: $e');
      return null;
    }
  }

  /// Obtiene observaciones del dispositivo
  Future<List<dynamic>> getObservations(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/observations?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['observations'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error obteniendo observaciones: $e');
      return [];
    }
  }
}