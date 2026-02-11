import 'device.dart'; 

class Observation {
  final String id;
  final String deviceId;
  final String userId;
  final String imageUrl;
  final String? thumbnailUrl;
  final DevicePosition position;
  final DateTime capturedAt; 
  final ObservationMetadata? metadata;

  const Observation({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.position,
    required this.capturedAt,
    required this.metadata,
  });

  factory Observation.fromJson(Map<String, dynamic> json){
    return Observation(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      userId: json['userId'] as String,
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      position: DevicePosition.fromJson(json['position'] as Map<String, dynamic>),
      capturedAt: DateTime.parse( json['capturedAt'] as String),
      metadata: json['metadata'] != null
          ? ObservationMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'deviceId': deviceId,
      'userId': userId,
      'ImageUrl': imageUrl,
      'thumbailUrl': thumbnailUrl,
      'position': position.toJson(),
      'capturetedAt': capturedAt.toIso8601String(),
      'metadata': metadata?.toJson(),
    };
  }
}
class ObservationMetadata{
  final double? exposureTime; // Tiempo de exposición en segundos
  final int? iso;
  final String? filter; // Filtro usado (ej: "H-alpha", "RGB")
  final double? temperature; // Temperatura del sensor en °C

  const ObservationMetadata({
    this.exposureTime,
    this.iso,
    this.filter,
    this.temperature,
  });
  factory ObservationMetadata.fromJson(Map<String, dynamic> json){
    return ObservationMetadata(
      exposureTime: json['exposureTime'] as double?,
      iso: json['iso'] as int?,
      filter: json['filter'] as String?,
      temperature: json['temperature'] as double?,
    );
  }
  Map<String, dynamic> toJson(){
    return {
      'exposureTime': exposureTime,
      'iso': iso,
      'filter': filter,
      'temperature': temperature,
    };
  }
}