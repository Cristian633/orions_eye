import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../data/services/api_service.dart';
import 'auth_provider.dart';

// Provider del servicio de API
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    getIdToken: () async => await ref.read(authProvider.notifier).getIdToken(),
  );
});

// Provider de dispositivos
class DevicesNotifier extends StateNotifier<List<Device>> {
  final ApiService _apiService;

  DevicesNotifier(this._apiService) : super([]) {
    loadDevices();
  }

  Future<void> loadDevices() async {
    try {
      final devices = await _apiService.getDevices();
      state = devices;
    } catch (e) {
      print('Error cargando dispositivos: $e');
      state = [];
    }
  }

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

      final idx = state.indexWhere((d) => d.id == device.id);
      if (idx >= 0) {
        final copy = [...state];
        copy[idx] = device;
        state = copy;
      } else {
        state = [...state, device];
      }
      return true;
    } catch (e) {
      print('Error registrando dispositivo: $e');
      return false;
    }
  }

  Future<void> refresh() async => loadDevices();

  /// Polling hasta que el device aparezca en /devices
  Future<Device> waitUntilDeviceOnline(
    String deviceId, {
    Duration timeout = const Duration(seconds: 45),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final start = DateTime.now();

    while (true) {
      await refresh();

      final match = state.where((d) => d.id == deviceId).toList();
      if (match.isNotEmpty) return match.first;

      if (DateTime.now().difference(start) > timeout) {
        throw Exception('Timeout esperando el dispositivo en backend.');
      }

      await Future.delayed(interval);
    }
  }
}

final devicesProvider =
    StateNotifierProvider<DevicesNotifier, List<Device>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DevicesNotifier(apiService);
});

final deviceByIdProvider = Provider.family<Device?, String>((ref, id) {
  final devices = ref.watch(devicesProvider);
  try {
    return devices.firstWhere((d) => d.id == id);
  } catch (_) {
    return null;
  }
});