import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../data/services/device_service.dart';

// Provider del servicio de dispositivos
final deviceServiceProvider = Provider((ref) => DeviceService());

// Provider que maneja la lista de observaciones
final observationProvider = StateNotifierProvider<ObservationNotifier, List<Observation>>((ref) {
  return ObservationNotifier();
});

// Notifier que maneja el estado y las acciones de las observaciones
class ObservationNotifier extends StateNotifier<List<Observation>> {
  ObservationNotifier() : super(_initialObservations);

  // Datos temporales (después vendrán del backend)
  static final _initialObservations = [
    Observation(
      id: 'obs-1',
      deviceId: 'device-1',
      userId: 'user-1',
      imageUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=800',
      thumbnailUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=400',
      position: const DevicePosition(
        rightAscension: '12h 34m 56s',
        declination: '+45° 23\' 56"',
        altitude: 45.5,
        azimuth: 120.0,
      ),
      capturedAt: DateTime.now().subtract(const Duration(hours: 2)),
      metadata: const ObservationMetadata(
        exposureTime: 30.0,
        iso: 800,
        filter: 'h-alpha',
        temperature: -10.5,
      ),
    ),
    Observation(
      id: 'obs-2',
      deviceId: 'device-1',
      userId: 'user-1',
      imageUrl: 'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=800',
      thumbnailUrl: 'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=400',
      position: const DevicePosition(
        rightAscension: '5h 35m 17s',
        declination: '-5° 23\' 28"',
        altitude: 60.2,
        azimuth: 180.5,
      ),
      capturedAt: DateTime.now().subtract(const Duration(days: 1)),
      metadata: const ObservationMetadata(
        exposureTime: 60.0,
        iso: 1600,
        filter: 'RGB',
        temperature: -12.0,
      ),
    ),
    Observation(
      id: 'obs-3',
      deviceId: 'device-2',
      userId: 'user-1',
      imageUrl: 'https://images.unsplash.com/photo-1502134249126-9f3755a50d78?w=800',
      thumbnailUrl: 'https://images.unsplash.com/photo-1502134249126-9f3755a50d78?w=400',
      position: const DevicePosition(
        rightAscension: '18h 36m 56s',
        declination: '+38° 47\' 01"',
        altitude: 75.0,
        azimuth: 90.0,
      ),
      capturedAt: DateTime.now().subtract(const Duration(days: 3)),
      metadata: const ObservationMetadata(
        exposureTime: 120.0,
        iso: 3200,
        filter: 'OIII',
        temperature: -15.2,
      ),
    ),
    Observation(
      id: 'obs-4',
      deviceId: 'device-1',
      userId: 'user-1',
      imageUrl: 'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=800',
      thumbnailUrl: 'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=400',
      position: const DevicePosition(
        rightAscension: '20h 41m 25s',
        declination: '+45° 16\' 49"',
        altitude: 50.3,
        azimuth: 200.0,
      ),
      capturedAt: DateTime.now().subtract(const Duration(days: 5)),
      metadata: const ObservationMetadata(
        exposureTime: 90.0,
        iso: 1600,
        filter: 'Luminance',
        temperature: -8.5,
      ),
    ),
    Observation(
      id: 'obs-5',
      deviceId: 'device-3',
      userId: 'user-1',
      imageUrl: 'https://images.unsplash.com/photo-1464802686167-b939a6910659?w=800',
      thumbnailUrl: 'https://images.unsplash.com/photo-1464802686167-b939a6910659?w=400',
      position: const DevicePosition(
        rightAscension: '6h 45m 08s',
        declination: '-16° 42\' 58"',
        altitude: 35.8,
        azimuth: 150.0,
      ),
      capturedAt: DateTime.now().subtract(const Duration(days: 7)),
      metadata: const ObservationMetadata(
        exposureTime: 45.0,
        iso: 800,
        filter: 'RGB',
        temperature: -9.0,
      ),
    ),
    Observation(
      id: 'obs-6',
      deviceId: 'device-1',
      userId: 'user-1',
      imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
      thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400',
      position: const DevicePosition(
        rightAscension: '1h 33m 50s',
        declination: '+30° 39\' 36"',
        altitude: 42.0,
        azimuth: 270.0,
      ),
      capturedAt: DateTime.now().subtract(const Duration(days: 10)),
      metadata: const ObservationMetadata(
        exposureTime: 180.0,
        iso: 3200,
        filter: 'H-alpha',
        temperature: -18.0,
      ),
    ),
  ];

  // Método para agregar una nueva observación
  void addObservation(Observation observation) {
    state = [observation, ...state]; // Agregar al inicio
  }

  // Método para eliminar una observación
  void removeObservation(String observationId) {
    state = state.where((obs) => obs.id != observationId).toList();
  }

  // Método para obtener las observaciones de un dispositivo específico
  List<Observation> getObservationsByDevice(String deviceId) {
    return state.where((obs) => obs.deviceId == deviceId).toList();
  }

  // ✨ NUEVO: Método para refrescar desde el backend
  Future<void> refreshObservations(String userId) async {
    try {
      print('🔄 Refrescando observaciones desde backend...');
      
      final deviceService = DeviceService();
      final data = await deviceService.getObservations(userId);
      
      if (data.isNotEmpty) {
        // Parsear observaciones del backend
        final backendObservations = data.map((json) {
          try {
            return Observation(
              id: json['observationId'] ?? json['id'] ?? '',
              deviceId: json['deviceId'] ?? '',
              userId: json['userId'] ?? userId,
              imageUrl: json['imageUrl'] ?? '',
              thumbnailUrl: json['thumbnailUrl'] ?? json['imageUrl'] ?? '',
              capturedAt: DateTime.tryParse(json['timestamp'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
              position: DevicePosition(
                rightAscension: json['position']?['ra'] ?? '00h 00m 00s',
                declination: json['position']?['dec'] ?? '+00° 00\' 00"',
                altitude: json['position']?['altitude']?.toDouble(),
                azimuth: json['position']?['azimuth']?.toDouble(),
              ),
              metadata: json['metadata'] != null
                  ? ObservationMetadata(
                      exposureTime: json['metadata']['exposureTime']?.toDouble(),
                      iso: json['metadata']['iso'],
                      filter: json['metadata']['filter'],
                      temperature: json['metadata']['temperature']?.toDouble(),
                    )
                  : null,
            );
          } catch (e) {
            print('⚠️ Error parseando observación: $e');
            return null;
          }
        }).whereType<Observation>().toList();

        // Combinar con observaciones locales (mock)
        // Puedes decidir si quieres solo backend o combinar:
        
        // Opción 1: Solo backend
        // state = backendObservations;
        
        // Opción 2: Combinar (backend + mock sin duplicados)
        final allObservations = [...backendObservations];
        for (var mockObs in _initialObservations) {
          if (!allObservations.any((obs) => obs.id == mockObs.id)) {
            allObservations.add(mockObs);
          }
        }
        state = allObservations;
        
        print('✅ ${backendObservations.length} observaciones cargadas desde backend');
      } else {
        print('ℹ️ No hay observaciones en el backend, usando datos mock');
        state = _initialObservations;
      }
    } catch (e) {
      print('❌ Error refrescando observaciones: $e');
      // Mantener observaciones actuales en caso de error
    }
  }

  // ✨ NUEVO: Cargar observaciones desde backend (reemplaza todas)
  Future<void> loadFromBackend(String userId) async {
    try {
      final deviceService = DeviceService();
      final data = await deviceService.getObservations(userId);
      
      final observations = data.map((json) {
        try {
          return Observation(
            id: json['observationId'] ?? json['id'] ?? '',
            deviceId: json['deviceId'] ?? '',
            userId: json['userId'] ?? userId,
            imageUrl: json['imageUrl'] ?? '',
            thumbnailUrl: json['thumbnailUrl'] ?? json['imageUrl'] ?? '',
            capturedAt: DateTime.tryParse(json['timestamp'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
            position: DevicePosition(
              rightAscension: json['position']?['ra'] ?? '00h 00m 00s',
              declination: json['position']?['dec'] ?? '+00° 00\' 00"',
              altitude: json['position']?['altitude']?.toDouble(),
              azimuth: json['position']?['azimuth']?.toDouble(),
            ),
            metadata: json['metadata'] != null
                ? ObservationMetadata(
                    exposureTime: json['metadata']['exposureTime']?.toDouble(),
                    iso: json['metadata']['iso'],
                    filter: json['metadata']['filter'],
                    temperature: json['metadata']['temperature']?.toDouble(),
                  )
                : null,
          );
        } catch (e) {
          return null;
        }
      }).whereType<Observation>().toList();

      if (observations.isNotEmpty) {
        state = observations;
      }
    } catch (e) {
      print('Error cargando observaciones: $e');
    }
  }
}

// Provider derivado: observación específica por ID
final observationByIdProvider = Provider.family<Observation?, String>((ref, observationId) {
  final observations = ref.watch(observationProvider);
  try {
    return observations.firstWhere((obs) => obs.id == observationId);
  } catch (e) {
    return null;
  }
});

// ✨ NUEVO: Provider para cargar observaciones del backend
final observationsFromBackendProvider = FutureProvider.family<List<Observation>, String>((ref, userId) async {
  final deviceService = ref.read(deviceServiceProvider);
  
  try {
    final data = await deviceService.getObservations(userId);
    
    return data.map((json) {
      try {
        return Observation(
          id: json['observationId'] ?? json['id'] ?? '',
          deviceId: json['deviceId'] ?? '',
          userId: json['userId'] ?? userId,
          imageUrl: json['imageUrl'] ?? '',
          thumbnailUrl: json['thumbnailUrl'] ?? json['imageUrl'] ?? '',
          capturedAt: DateTime.tryParse(json['timestamp'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
          position: DevicePosition(
            rightAscension: json['position']?['ra'] ?? '00h 00m 00s',
            declination: json['position']?['dec'] ?? '+00° 00\' 00"',
            altitude: json['position']?['altitude']?.toDouble(),
            azimuth: json['position']?['azimuth']?.toDouble(),
          ),
          metadata: json['metadata'] != null
              ? ObservationMetadata(
                  exposureTime: json['metadata']['exposureTime']?.toDouble(),
                  iso: json['metadata']['iso'],
                  filter: json['metadata']['filter'],
                  temperature: json['metadata']['temperature']?.toDouble(),
                )
              : null,
        );
      } catch (e) {
        print('Error parseando observación: $e');
        return null;
      }
    }).whereType<Observation>().toList();
  } catch (e) {
    print('Error cargando observaciones del backend: $e');
    return [];
  }
});

// ✨ NUEVO: Provider para auto-refresh cada 30 segundos
final autoRefreshObservationsProvider = StreamProvider.family<int, String>((ref, userId) {
  return Stream.periodic(const Duration(seconds: 30), (count) {
    // Refrescar observaciones cada 30 segundos
    ref.read(observationProvider.notifier).refreshObservations(userId);
    return count;
  });
});