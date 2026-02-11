import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';

//provider que maneja la lista de observaciones
final observationProvider = StateNotifierProvider<ObservationNotifier, List<Observation>>((ref) {
  return ObservationNotifier();
});

//notifier que maneja el estaado y las acciones de las observaciones
class ObservationNotifier extends StateNotifier<List<Observation>>{
  ObservationNotifier() : super(_initialObservations);

  //datos temporales (despues vendran del backend)
  static final _initialObservations = [
    Observation(
      id: 'obs-1',
      deviceId: 'device-1',
      userId: 'user-1',
      imageUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=800',
      thumbnailUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=400',
      position: const DevicePosition(
        rightAscension: '12h 34m 56s',
        declination: '+45° 23\' 56s',
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
      deviceId:  'device-1',
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
      thumbnailUrl: 'https://images.unsplash.com/photo-1502134249126-9f3755a50d78? w=400',
      position:  const DevicePosition(
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
      imageUrl:  'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=800',
      thumbnailUrl: 'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a? w=400',
      position:  const DevicePosition(
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
      imageUrl:  'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
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
  //metodo para agregar una nueva obsevacion
  void addObservation(Observation observation){
    state = [observation, ...state];//agregar al inicion
  }
  //metodo para eliminar una observacion
  void removeObservation(String observationId){
    state = state.where((obs) => obs.id != observationId).toList();

  }
  //metodo para obtener las observaciones de un dispositivo especifico
  List<Observation> getObservationsByDevice(String deviceId){
    return state.where((obs) => obs.deviceId == deviceId).toList();
  }
  //metodo para refrescar desde el backend (placeholder)
  Future<void> refreshObservations() async{
    //TODO: LLamar al backend para obtener observaciones actualizadas
    await Future.delayed(const Duration(seconds: 1));
    //state = observaciones delBckend

  }
}
//provider derivado: observacion espicifico por ID
final observationByIdProvider = Provider.family<Observation?, String>((ref, observationId){
final observations = ref.watch(observationProvider);
try{
return observations.firstWhere((obs) => obs.id == observationId);  
}catch(e){
  return null;
}
});

