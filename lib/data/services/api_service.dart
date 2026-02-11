import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/aws_config.dart';
import '../../domain/models/models.dart';

class ApiService {
  final Future<String?> Function() getIdToken;
  ApiService({required this.getIdToken});

  // Headers comunes con autorización
  Future<Map<String, String>> _getHeaders() async {
    final token = await getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token ?? '',
    };
  }
  // GET /devices - Obtener dispositivos del usuario
  Future<List<Device>> getDevices() async {
    try
    {
      final headers = await _getHeaders();
      final url = Uri.parse('${AwsConfig.apiEndpoint}/devices');

      print('GET $url');
      final response = await http.get(url, headers: headers);

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200){
        final data = json.decode(response.body);
        final List<dynamic> devicesJson = data['devices'] ??[];

        return devicesJson.map((json) => Device.fromJson(json)).toList();
      }else{
        throw Exception('Error al obtener dispositivos: ${response.statusCode}');
      }
    } catch (e){
      print('Error en getDevices: $e');
      rethrow;
    }
  }
    // POST /devices - Registrar nuevo dispositivo
    Future<Device> registerDevice({
    required String deviceId,
    required String name,
    String? model,
  }) async {
    try {
       final headers = await _getHeaders();
      final url = Uri.parse('${AwsConfig.apiEndpoint}/devices');
      final body = json.encode({
        'deviceId': deviceId,
        'name': name,
        'model': model ?? 'ESP32-CAM',
      });

       print('POST $url');
      print('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Device.fromJson(data['device']);
      } else {
        throw Exception('Error al registrar dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en registerDevice: $e');
      throw Exception('Error de conexión: $e');
    }
  }
  // GET /devices/{id} - Obtener dispositivo por ID
  Future<Device> getDeviceById(String deviceId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AwsConfig.apiEndpoint}/devices/$deviceId');

      print('GET $url');

      final response = await http.get(url, headers: headers);

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Device.fromJson(data['device']);
      } else {
        throw Exception('Error al obtener dispositivo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getDeviceById: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // GET /observations - Obtener observaciones del usuario
  Future<List<Observation>> getObservations() async {
    try {
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
      } else {
        throw Exception('Error al obtener observaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getObservations: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}
