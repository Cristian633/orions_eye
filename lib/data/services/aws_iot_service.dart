import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../../config/aws_config.dart';

class AWSIoTService {
  final Dio _dio;
  final Logger _logger = Logger();

  AWSIoTService()
      : _dio = Dio(BaseOptions(
          baseUrl: AwsConfig.apiEndpoint,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

  /// Registrar dispositivo en AWS IoT Core
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String userId,
    required String deviceName,
  }) async {
    try {
      _logger.i('Registrando dispositivo en AWS IoT: $deviceId');

      final response = await _dio.post(
        '/devices/register',
        data: {
          'deviceId': deviceId,
          'userId': userId,
          'deviceName': deviceName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _logger.i('Dispositivo registrado exitosamente');
      return response.data;
    } catch (e) {
      _logger.e('Error registrando dispositivo: $e');
      rethrow;
    }
  }

  /// Obtener certificados del dispositivo
  Future<DeviceCertificates> getDeviceCertificates(String deviceId) async {
    try {
      _logger.i('Obteniendo certificados para: $deviceId');

      final response = await _dio.get('/devices/$deviceId/certificates');

      return DeviceCertificates.fromJson(response.data);
    } catch (e) {
      _logger.e('Error obteniendo certificados: $e');
      rethrow;
    }
  }

  /// Enviar comando al dispositivo vía IoT Core
  Future<void> sendCommand({
    required String deviceId,
    required String command,
    Map<String, dynamic>? payload,
  }) async {
    try {
      _logger.i('Enviando comando "$command" a $deviceId');

      await _dio.post(
        '/devices/$deviceId/command',
        data: {
          'command': command,
          'payload': payload ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _logger.i('Comando enviado exitosamente');
    } catch (e) {
      _logger.e('Error enviando comando: $e');
      rethrow;
    }
  }

  /// Obtener estado del dispositivo desde IoT Shadow
  Future<Map<String, dynamic>> getDeviceShadow(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId/shadow');
      return response.data['state']['reported'] ?? {};
    } catch (e) {
      _logger.e('Error obteniendo shadow: $e');
      rethrow;
    }
  }

  /// Actualizar configuración del dispositivo
  Future<void> updateDeviceConfig({
    required String deviceId,
    required Map<String, dynamic> config,
  }) async {
    try {
      await _dio.patch(
        '/devices/$deviceId/config',
        data: config,
      );
      _logger.i('Configuración actualizada');
    } catch (e) {
      _logger.e('Error actualizando configuración: $e');
      rethrow;
    }
  }

  /// Eliminar dispositivo
  Future<void> deleteDevice(String deviceId) async {
    try {
      await _dio.delete('/devices/$deviceId');
      _logger.i('Dispositivo eliminado: $deviceId');
    } catch (e) {
      _logger.e('Error eliminando dispositivo: $e');
      rethrow;
    }
  }
}

/// Modelo de certificados del dispositivo
class DeviceCertificates {
  final String certificatePem;
  final String privateKey;
  final String publicKey;
  final String certificateArn;

  DeviceCertificates({
    required this.certificatePem,
    required this.privateKey,
    required this.publicKey,
    required this.certificateArn,
  });

  factory DeviceCertificates.fromJson(Map<String, dynamic> json) {
    return DeviceCertificates(
      certificatePem: json['certificatePem'] ?? '',
      privateKey: json['privateKey'] ?? '',
      publicKey: json['publicKey'] ?? '',
      certificateArn: json['certificateArn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'certificatePem': certificatePem,
      'privateKey': privateKey,
      'publicKey': publicKey,
      'certificateArn': certificateArn,
    };
  }
}