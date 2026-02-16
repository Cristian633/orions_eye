import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/aws_iot_service.dart';
import 'auth_provider.dart';

final awsIoTServiceProvider = Provider<AWSIoTService>((ref) {
  return AWSIoTService();
});

/// Estado de registro en AWS IoT
enum IoTRegistrationState {
  idle,
  registering,
  registered,
  error,
}

class IoTRegistrationStatus {
  final IoTRegistrationState state;
  final String? deviceId;
  final String? errorMessage;
  final DeviceCertificates? certificates;

  IoTRegistrationStatus({
    required this.state,
    this.deviceId,
    this.errorMessage,
    this.certificates,
  });

  IoTRegistrationStatus copyWith({
    IoTRegistrationState? state,
    String? deviceId,
    String? errorMessage,
    DeviceCertificates? certificates,
  }) {
    return IoTRegistrationStatus(
      state: state ?? this.state,
      deviceId: deviceId ?? this.deviceId,
      errorMessage: errorMessage ?? this.errorMessage,
      certificates: certificates ?? this.certificates,
    );
  }
}

class IoTRegistrationNotifier extends StateNotifier<IoTRegistrationStatus> {
  final AWSIoTService _iotService;
  final String? _userId;

  IoTRegistrationNotifier(this._iotService, this._userId)
      : super(IoTRegistrationStatus(state: IoTRegistrationState.idle));

  /// Registrar dispositivo en AWS IoT Core
  Future<bool> registerDevice({
    required String deviceId,
    required String deviceName,
  }) async {
    if (_userId == null) {
      state = state.copyWith(
        state: IoTRegistrationState.error,
        errorMessage: 'Usuario no autenticado',
      );
      return false;
    }

    try {
      state = state.copyWith(state: IoTRegistrationState.registering);

      // Registrar dispositivo
      final response = await _iotService.registerDevice(
        deviceId: deviceId,
        userId: _userId!,
        deviceName: deviceName,
      );

      // Obtener certificados
      final certificates = await _iotService.getDeviceCertificates(deviceId);

      state = state.copyWith(
        state: IoTRegistrationState.registered,
        deviceId: deviceId,
        certificates: certificates,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        state: IoTRegistrationState.error,
        errorMessage: 'Error registrando dispositivo: $e',
      );
      return false;
    }
  }

  /// Enviar comando al dispositivo
  Future<void> sendCommand({
    required String deviceId,
    required String command,
    Map<String, dynamic>? payload,
  }) async {
    await _iotService.sendCommand(
      deviceId: deviceId,
      command: command,
      payload: payload,
    );
  }

  /// Obtener estado del dispositivo
  Future<Map<String, dynamic>> getDeviceState(String deviceId) async {
    return await _iotService.getDeviceShadow(deviceId);
  }

  void reset() {
    state = IoTRegistrationStatus(state: IoTRegistrationState.idle);
  }
}

final iotRegistrationProvider =
    StateNotifierProvider<IoTRegistrationNotifier, IoTRegistrationStatus>((ref) {
  final iotService = ref.watch(awsIoTServiceProvider);
  final userId = ref.watch(authProvider)?.id;
  return IoTRegistrationNotifier(iotService, userId);
});