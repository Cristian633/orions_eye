import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/aws_config.dart';
import '../../domain/models/models.dart';

class ApiService {
  final Future<String?> Function() getIdToken;
  ApiService({required this.getIdToken});

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

  Device _safeDeviceFromAny(Map<String, dynamic> raw) {
    final normalized = <String, dynamic>{
      ...raw,
      // Normalizar claves comunes backend -> app
      'id': raw['id'] ?? raw['deviceId'] ?? raw['device_id'] ?? '',
      'name': raw['name'] ?? raw['deviceName'] ?? raw['device_name'] ?? 'Dispositivo',
      'model': raw['model'],
      'isOnline': raw['isOnline'] ?? raw['online'] ?? (raw['status'] == 'online'),
      'lastSeen': raw['lastSeen'] ?? raw['updatedAt'] ?? raw['createdAt'],
    };

    return Device.fromJson(normalized);
  }

  // GET /devices
  Future<List<Device>> getDevices() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AwsConfig.apiEndpoint}/devices');

    print('===API GET DEVICES START===');
    print('API ENDPOINT: ${AwsConfig.apiEndpoint}');
    print('GET URL: $url');

    final response = await http.get(url, headers: headers);

    print('GET /devices Status: ${response.statusCode}');
    print('GET /devices Body: ${response.body}');

    if (response.statusCode != 200) {
      print('===API GET DEVICES END (ERROR)===');
      throw Exception(
        'Error al obtener dispositivos: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      print('Parsed devices count: 0 (body vacío)');
      print('===API GET DEVICES END===');
      return [];
    }

    final data = json.decode(response.body);

    List<dynamic> devicesJson = [];
    if (data is List) {
      devicesJson = data;
    } else if (data is Map<String, dynamic>) {
      devicesJson = (data['devices'] as List?) ??
          (data['items'] as List?) ??
          (data['data'] as List?) ??
          [];
    }

    final devices = devicesJson
        .whereType<Map>()
        .map((e) => _safeDeviceFromAny(Map<String, dynamic>.from(e)))
        .toList();

    print('Parsed devices count: ${devices.length}');
    print('===API GET DEVICES END===');

    return devices;
  }

  // POST /devices/register
  Future<Device> registerDevice({
    required String deviceId,
    required String name,
    String? model,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AwsConfig.apiEndpoint}/devices/register');

    final body = json.encode({
      'deviceId': deviceId,
      'deviceName': name,
      'model': model ?? 'ESP32-CAM',
    });

    print('===API REGISTER START===');
    print('POST URL: $url');
    print('POST /devices/register Body: $body');

    final response = await http.post(url, headers: headers, body: body);

    print('POST /devices/register Status: ${response.statusCode}');
    print('POST /devices/register Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.trim().isEmpty) {
        print('===API REGISTER END (empty body)===');
        return Device.fromJson({
          'id': deviceId,
          'name': name,
          'model': model ?? 'ESP32-CAM',
          'isOnline': false,
          'lastSeen': null,
        });
      }

      final data = json.decode(response.body);

      Map<String, dynamic> raw;
      if (data is Map<String, dynamic> && data['device'] is Map<String, dynamic>) {
        raw = Map<String, dynamic>.from(data['device']);
      } else if (data is Map<String, dynamic>) {
        raw = data;
      } else {
        raw = {};
      }

      raw['deviceId'] = raw['deviceId'] ?? deviceId;
      raw['deviceName'] = raw['deviceName'] ?? name;
      raw['model'] = raw['model'] ?? model ?? 'ESP32-CAM';

      print('===API REGISTER END (success)===');
      return _safeDeviceFromAny(raw);
    }

    print('===API REGISTER END (ERROR)===');
    throw Exception(
      'Error al registrar dispositivo: ${response.statusCode} ${response.body}',
    );
  }

  // GET /observations
  Future<List<Observation>> getObservations() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AwsConfig.apiEndpoint}/observations');

    print('===API GET OBS START===');
    print('GET URL: $url');

    final response = await http.get(url, headers: headers);

    print('GET /observations Status: ${response.statusCode}');
    print('GET /observations Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> observationsJson = data['observations'] ?? [];
      print('===API GET OBS END (success)===');
      return observationsJson.map((json) => Observation.fromJson(json)).toList();
    }

    print('===API GET OBS END (ERROR)===');
    throw Exception(
      'Error al obtener observaciones: ${response.statusCode} ${response.body}',
    );
  }
}
