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

  factory Device.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['deviceId'] ?? '').toString();
    final name = (json['name'] ?? json['deviceName'] ?? 'Dispositivo').toString();

    final dynamic onlineRaw = json['isOnline'] ?? json['online'] ?? json['status'];
    final bool isOnline = onlineRaw == true ||
        onlineRaw == 'true' ||
        onlineRaw == 'online' ||
        onlineRaw == 'connected';

    final status = (json['status'] ??
            (isOnline ? 'online' : 'registered'))
        .toString();

    final lastUpdateRaw =
        (json['lastUpdate'] ?? json['updatedAt'] ?? json['createdAt'])?.toString();

    DateTime lastUpdate;
    try {
      lastUpdate = lastUpdateRaw != null && lastUpdateRaw.isNotEmpty
          ? DateTime.parse(lastUpdateRaw)
          : DateTime.now();
    } catch (_) {
      lastUpdate = DateTime.now();
    }

    final userId = (json['userId'] ?? json['ownerId'] ?? '').toString();

    return Device(
      id: id,
      name: name,
      isOnline: isOnline,
      status: status,
      position: json['position'] != null
          ? DevicePosition.fromJson(Map<String, dynamic>.from(json['position']))
          : null,
      lastUpdate: lastUpdate,
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() {
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

  Device copyWith({
    String? id,
    String? name,
    bool? isOnline,
    String? status,
    DevicePosition? position,
    DateTime? lastUpdate,
    String? userId,
  }) {
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
  final String rightAscension;
  final String declination;
  final double? altitude;
  final double? azimuth;

  const DevicePosition({
    required this.rightAscension,
    required this.declination,
    required this.altitude,
    required this.azimuth,
  });

  factory DevicePosition.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return DevicePosition(
      rightAscension: (json['rightAscension'] ?? '').toString(),
      declination: (json['declination'] ?? '').toString(),
      altitude: toDouble(json['altitude']),
      azimuth: toDouble(json['azimuth']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rightAscension': rightAscension,
      'declination': declination,
      'altitude': altitude,
      'azimuth': azimuth,
    };
  }
}