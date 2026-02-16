import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orions_eye_app/data/services/esp32_service.dart';
import 'package:orions_eye_app/domain/models/wifi_network.dart';

// Provider del servicio
final esp32ServiceProvider = Provider<ESP32Service>((ref) {
  return ESP32Service();
});

// Estado de conexión
enum ESP32ConnectionState {
  disconnected,
  scanning,
  connected,
  provisioning,
  error,
}

// Estado del dispositivo
class ESP32DeviceState {
  final ESP32ConnectionState connectionState;
  final String? deviceId;
  final String? deviceIp;
  final List<WiFiNetwork> availableNetworks;
  final String? errorMessage;

  ESP32DeviceState({
    required this.connectionState,
    this.deviceId,
    this.deviceIp,
    this.availableNetworks = const [],
    this.errorMessage,
  });

  ESP32DeviceState copyWith({
    ESP32ConnectionState? connectionState,
    String? deviceId,
    String? deviceIp,
    List<WiFiNetwork>? availableNetworks,
    String? errorMessage,
  }) {
    return ESP32DeviceState(
      connectionState: connectionState ?? this.connectionState,
      deviceId: deviceId ?? this.deviceId,
      deviceIp: deviceIp ?? this.deviceIp,
      availableNetworks: availableNetworks ?? this.availableNetworks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Provider del estado
class ESP32StateNotifier extends StateNotifier<ESP32DeviceState> {
  final ESP32Service _service;

  ESP32StateNotifier(this._service)
      : super(ESP32DeviceState(
          connectionState: ESP32ConnectionState.disconnected,
        ));

  /// Verificar conectividad con ESP32
  Future<bool> checkConnection() async {
    state = state.copyWith(connectionState: ESP32ConnectionState.scanning);
    
    final isConnected = await _service.ping();
    
    if (isConnected) {
      final status = await _service.getDeviceStatus();
      state = state.copyWith(
        connectionState: ESP32ConnectionState.connected,
        deviceId: status['deviceId'],
      );
      return true;
    } else {
      state = state.copyWith(
        connectionState: ESP32ConnectionState.error,
        errorMessage: 'No se puede conectar al dispositivo',
      );
      return false;
    }
  }

  /// Escanear redes WiFi
  Future<void> scanWiFiNetworks() async {
    try {
      state = state.copyWith(connectionState: ESP32ConnectionState.scanning);
      
      final networks = await _service.scanWiFiNetworks();
      
      state = state.copyWith(
        connectionState: ESP32ConnectionState.connected,
        availableNetworks: networks,
      );
    } catch (e) {
      state = state.copyWith(
        connectionState: ESP32ConnectionState.error,
        errorMessage: 'Error escaneando redes: $e',
      );
    }
  }

  /// Provisionar WiFi
  Future<bool> provisionWiFi(String ssid, String password) async {
    try {
      state = state.copyWith(connectionState: ESP32ConnectionState.provisioning);
      
      final result = await _service.provisionWiFi(
        ssid: ssid,
        password: password,
      );

      if (result.success) {
        state = state.copyWith(
          connectionState: ESP32ConnectionState.connected,
          deviceIp: result.deviceIp,
        );
        return true;
      } else {
        state = state.copyWith(
          connectionState: ESP32ConnectionState.error,
          errorMessage: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        connectionState: ESP32ConnectionState.error,
        errorMessage: 'Error en provisionamiento: $e',
      );
      return false;
    }
  }

  void reset() {
    state = ESP32DeviceState(
      connectionState: ESP32ConnectionState.disconnected,
    );
  }
}

final esp32StateProvider = StateNotifierProvider<ESP32StateNotifier, ESP32DeviceState>((ref) {
  final service = ref.watch(esp32ServiceProvider);
  return ESP32StateNotifier(service);
});