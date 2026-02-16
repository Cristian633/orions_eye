class WiFiNetwork {
  final String ssid;
  final int rssi;
  final bool isSecured;

  WiFiNetwork({
    required this.ssid,
    required this.rssi,
    required this.isSecured,
  });

  factory WiFiNetwork.fromJson(Map<String, dynamic> json) {
    return WiFiNetwork(
      ssid: json['ssid'] ?? '',
      rssi: json['rssi'] ?? -100,
      isSecured: json['encryption'] != 'open',
    );
  }

  int get signalLevel {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }
}
