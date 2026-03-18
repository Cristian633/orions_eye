import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final Future<String?> Function() getIdToken;

  ApiClient({
    required this.baseUrl,
    required this.getIdToken,
  });

  Future<Map<String, String>> _headers({bool jsonBody = true}) async {
    final token = await getIdToken();
    final headers = <String, String>{};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(jsonBody: false),
    );
  }

  Future<http.Response> post(String path, {Object? body}) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }
}