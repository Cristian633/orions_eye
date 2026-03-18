import 'dart:convert';
import '../services/api_client.dart';

class ObservationService {
  final ApiClient api;

  ObservationService({required this.api});

  Future<List<dynamic>> getObservations() async {
    final res = await api.get('/observations');
    if (res.statusCode != 200) {
      throw Exception('getObservations failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    return (data['observations'] ?? []) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getObservationDetail(String observationId) async {
    final res = await api.get('/observations/$observationId');
    if (res.statusCode != 200) {
      throw Exception('getObservationDetail failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}