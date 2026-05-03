import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class DeviceService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    // API Gateway + Cognito suele validar mejor idToken para authorizer de usuario
    final idToken = prefs.getString('idToken') ?? '';
    final accessToken = prefs.getString('accessToken') ?? '';
    final fallbackToken = prefs.getString('token') ?? '';

    final token = idToken.isNotEmpty
        ? idToken
        : (accessToken.isNotEmpty ? accessToken : fallbackToken);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Debug útil
    print('AUTH idToken exists: ${idToken.isNotEmpty}');
    print('AUTH accessToken exists: ${accessToken.isNotEmpty}');
    print('AUTH fallback token exists: ${fallbackToken.isNotEmpty}');
    print('AUTH token prefix: ${token.isNotEmpty ? token.substring(0, 20) : 'EMPTY'}');

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
      final uri = Uri.parse('$baseUrl/devices/register');

      final payload = {
        'deviceId': deviceId,
        'userId': userId,
        'deviceName': deviceName,
      };

      print('REGISTER url: $uri');
      print('REGISTER payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      print('REGISTER status: ${response.statusCode}');
      print('REGISTER body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.trim().isEmpty) {
          return {
            'success': true,
            'message': 'Registrado (sin body)',
          };
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        throw Exception(
          'No autorizado (401). Inicia sesión nuevamente. Body: ${response.body}',
        );
      }

      throw Exception(
        'Error registrando dispositivo: ${response.statusCode} | body: ${response.body}',
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Envía comando de captura al dispositivo
  Future<bool> captureImage(String deviceId) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$baseUrl/devices/$deviceId/command');

      final payload = {
        'command': 'capture',
        'payload': <String, dynamic>{},
      };

      print('CAPTURE url: $uri');
      print('CAPTURE payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

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
      final uri = Uri.parse('$baseUrl/devices/$deviceId/status');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      print('STATUS url: $uri');
      print('STATUS status: ${response.statusCode}');
      print('STATUS body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) return <String, dynamic>{};
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
      final uri = Uri.parse('$baseUrl/observations?userId=$userId');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      print('OBS url: $uri');
      print('OBS status: ${response.statusCode}');
      print('OBS body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) return [];
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return (data['observations'] as List?) ?? [];
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error obteniendo observaciones: $e');
      return [];
    }
  }
}