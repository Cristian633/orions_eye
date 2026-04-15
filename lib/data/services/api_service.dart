import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/aws_config.dart';
import '../../domain/models/models.dart';

class ApiService {
  final Future<String?> Function() getIdToken;
  ApiService({required this.getIdToken});

  // Headers comunes con autorización (Cognito Authorizer)
  Future<Map<String, String>> _getHeaders() async {
  final token = await getIdToken();

  if (token == null || token.isEmpty) {
    throw Exception('No hay token de sesión. Inicia sesión nuevamente.');
  }

  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

  // GET /devices - Obtener dispositivos del usuario
  Future<List<Device>> getDevices() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AwsConfig.apiEndpoint}/devices');

    print('GET $url');
    final response = await http.get(url, headers: headers);

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> devicesJson = data['devices'] ?? [];
      return devicesJson.map((json) => Device.fromJson(json)).toList();
    }

    throw Exception('Error al obtener dispositivos: ${response.statusCode} ${response.body}');
  }

  //  POST /devices/register - Registrar nuevo dispositivo (SEGÚN TU SAM)
  Future<Device> registerDevice({
    required String deviceId,
    required String name,
    String? model,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AwsConfig.apiEndpoint}/devices/register');

    final body = json.encode({
      'deviceId': deviceId,
      'deviceName': name, // en tu SAM se usa "deviceName" típicamente
      'model': model ?? 'ESP32-CAM',
    });

    print('POST $url');
    print('Body: $body');

    final response = await http.post(url, headers: headers, body: body);

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    // muchas lambdas devuelven 200, no 201. Aceptamos ambos.
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      // tu lambda puede devolver { device: {...} } o el device directo
      final deviceJson = (data is Map && data['device'] != null) ? data['device'] : data;
      return Device.fromJson(deviceJson);
    }

    throw Exception('Error al registrar dispositivo: ${response.statusCode} ${response.body}');
  }

  // GET /observations - Obtener observaciones del usuario
  Future<List<Observation>> getObservations() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AwsConfig.apiEndpoint}/observations');

    print('🌐 GET $url');
    final response = await http.get(url, headers: headers);

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> observationsJson = data['observations'] ?? [];
      return observationsJson.map((json) => Observation.fromJson(json)).toList();
    }

    throw Exception('Error al obtener observaciones: ${response.statusCode} ${response.body}');
  }
}