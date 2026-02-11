import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../data/services/api_service.dart';
import 'auth_provider.dart';

// Provider del servicio de API
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    getIdToken: () async {
      return await ref.read(authProvider.notifier).getIdToken() ?? '';
    },
  );
});

// Provider de dispositivos
class DevicesNotifier extends StateNotifier<List<Device>> {
  final ApiService _apiService;

  DevicesNotifier(this._apiService) : super([]) {
    loadDevices();
  }

  // Cargar dispositivos desde la API
  Future<void> loadDevices() async {
    try {
      final devices = await _apiService.getDevices();
      state = devices;
    } catch (e) {
      print('Error cargando dispositivos: $e');
      state = [];
    }
  }

  // Registrar nuevo dispositivo
  Future<bool> registerDevice({
    required String deviceId,
    required String name,
    String? model,
  }) async {
    try {
      final device = await _apiService.registerDevice(
        deviceId: deviceId,
        name: name,
        model: model,
      );
      
      state = [...state, device];
      return true;
    } catch (e) {
      print('Error registrando dispositivo: $e');
      return false;
    }
  }

  // Refrescar dispositivos
  Future<void> refresh() async {
    await loadDevices();
  }
}

final devicesProvider = StateNotifierProvider<DevicesNotifier, List<Device>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DevicesNotifier(apiService);
});

// Provider para buscar dispositivo por ID
final deviceByIdProvider = Provider.family<Device?, String>((ref, id) {
  final devices = ref.watch(devicesProvider);
  try {
    return devices.firstWhere((device) => device.id == id);
  } catch (e) {
    return null;
  }
});