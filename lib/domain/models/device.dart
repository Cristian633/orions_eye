class Device {
  final String id;
  final String name;
  final bool isOnline;
  final String status;
  final DevicePosition? position;
  final DateTime lastUpdate;
  final String userId;

  const Device({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.status,
    this.position,
    required this.lastUpdate,
    required this.userId,
  });
  //crear Device  desde JSON (Cuando llegue del Backend)
  factory Device.fromJson(Map<String, dynamic> json){
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      isOnline: json['isOnline'] as bool,
      status: json['status'] as String,
      position: json['position'] != null
          ? DevicePosition.fromJson(json['position'] as Map<String, dynamic>)
          : null,
          lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'] as String)
          : DateTime.now(),
      userId: json['userId'] as String,
     
    );
  }
    // Convertir Device a JSON (para enviar al backend)
    Map<String, dynamic> toJson(){
      return {
        'id': id,
        'name': name,
        'isOnline': isOnline,
        'status': status,
        'position': position?.toJson(),
        'lastUpdate': lastUpdate.toIso8601String(),
        'userId': userId,
      };
    }
     // Copiar el objeto con algunos campos modificados 
     Device copyWith({
      String? id,
      String? name,
      bool? isOnline,
      String? status,
      DevicePosition? position,
      DateTime? lastUpdate,
      String? userId,
     }){
      return Device(
        id: id ?? this.id,
        name: name ?? this.name,
        isOnline: isOnline ?? this.isOnline,
        status: status ?? this.status,
        position: position ?? this.position,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        userId: userId ?? this.userId,
      );
     }
}
class DevicePosition {
  final String rightAscension; // RA:  12h 34m 56s
  final String declination;    // DEC: +12° 34' 56"
  final double? altitude;       // Altitud en grados
  final double? azimuth;        // Azimut en grados

  const DevicePosition({
    required this.rightAscension,
    required this.declination,
    required this.altitude,
    required this.azimuth,
  });

  factory DevicePosition.fromJson(Map<String, dynamic> json){
    return DevicePosition(
      rightAscension: json['rightAscension'] as String,
      declination: json['declination'] as String,
      altitude: json['altitude'] as double?,
      azimuth: json['azimuth'] as double?,
    );

  }
  Map<String, dynamic> toJson() {
    return {
      'rightAscension': rightAscension,
      'declination':  declination,
      'altitude':  altitude,
      'azimuth': azimuth,
    };
  }
}

