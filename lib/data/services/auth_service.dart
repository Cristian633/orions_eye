import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class DeviceService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Priorizar ID token (muchos authorizers de API Gateway/Cognito esperan este)
    final token = prefs.getString('idToken') ??
        prefs.getString('accessToken') ??
        prefs.getString('token') ??
        '';

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Debug útil (puedes quitar luego)
    print('idToken exists: ${(prefs.getString('idToken') ?? '').isNotEmpty}');
    print('accessToken exists: ${(prefs.getString('accessToken') ?? '').isNotEmpty}');
    print('using token prefix: ${token.isNotEmpty ? token.substring(0, 20) : 'EMPTY'}');

    return headers;
  }

  /// Registra un nuevo dispositivo
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String userId,
    required String deviceName,
  }) async {
    try {
      final headers = await _authHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/devices/register'),
        headers: headers,
        body: jsonEncode({
          'deviceId': deviceId,
          'userId': userId,
          'deviceName': deviceName,
        }),
      );

      print('REGISTER status: ${response.statusCode}');
      print('REGISTER body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado (401). Inicia sesión nuevamente.');
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
      final headers = await _authHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/devices/$deviceId/command'),
        headers: headers,
        body: jsonEncode({
          'command': 'capture',
          'payload': {},
        }),
      );

      print('CAPTURE status: ${response.statusCode}');
      print('CAPTURE body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error enviando comando de captura: $e');
      return false;
    }
  }

  /// Obtiene el estado del dispositivo
  Future<Map<String, dynamic>?> getDeviceStatus(String deviceId) async {
    try {
      final headers = await _authHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId/status'),
        headers: headers,
      );

      print('STATUS status: ${response.statusCode}');
      print('STATUS body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
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
      final headers = await _authHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/observations?userId=$userId'),
        headers: headers,
      );

      print('OBS status: ${response.statusCode}');
      print('OBS body: ${response.body}');

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