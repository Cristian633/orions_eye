import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleScanner {
  BleScanner({FlutterReactiveBle? ble}) : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;

  // ESP32 actual
  static const String targetName = 'OrionSpectrometer';

  // UUIDs del firmware
  static final Uuid targetServiceUuid =
      Uuid.parse('4fafc201-1fb5-459e-8fcc-c5c9c331914b');
  static final Uuid ssidCharUuid =
      Uuid.parse('beb5483e-36e1-4688-b7f5-ea07361b26a8');
  static final Uuid passCharUuid =
      Uuid.parse('beb5483e-36e1-4688-b7f5-ea07361b26a9');

  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;

  final Map<String, DiscoveredDevice> _found = {};
  StreamSubscription<DiscoveredDevice>? _scanSub;

  Future<void> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // compat Android
    ].request();

    final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;

    if (!scanGranted || !connectGranted) {
      throw Exception('Permisos BLE no concedidos');
    }
  }

  bool _matches(DiscoveredDevice d) {
    final name = d.name.trim();
    final normalized = name.toLowerCase();

    // Fallback por nombre (tu caso real)
    if (normalized == targetName.toLowerCase() ||
        normalized.contains('orion') ||
        normalized.contains('spectrometer') ||
        normalized.contains('esp32')) {
      return true;
    }

    // Match por service UUID (ideal)
    for (final u in d.serviceUuids) {
      if (u.toString().toLowerCase() ==
          targetServiceUuid.toString().toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 12)}) async {
    await requestPermissions();

    _found.clear();
    await stopScan();

    // Escaneo sin filtro (más robusto en Android)
    _scanSub = _ble
        .scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency)
        .listen(
      (device) {
        // DEBUG logs
        print(
          'BLE => name:${device.name} id:${device.id} rssi:${device.rssi} services:${device.serviceUuids}',
        );

        if (_matches(device)) {
          _found[device.id] = device;
          _devicesController.add(_found.values.toList());
        }
      },
      onError: (e) {
        print('BLE scan error: $e');
      },
    );

    // Auto-stop
    Future.delayed(timeout, () async {
      await stopScan();
    });
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
  }

  Future<Stream<ConnectionStateUpdate>> connect(String deviceId) async {
    return _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 15),
    );
  }

  Future<void> sendWifiCredentials({
    required String deviceId,
    required String ssid,
    required String password,
  }) async {
    final services = await _ble.discoverServices(deviceId);

    DiscoveredCharacteristic? ssidChar;
    DiscoveredCharacteristic? passChar;

    for (final s in services) {
      if (s.serviceId.toString().toLowerCase() ==
          targetServiceUuid.toString().toLowerCase()) {
        for (final c in s.characteristics) {
          final cu = c.characteristicId.toString().toLowerCase();
          if (cu == ssidCharUuid.toString().toLowerCase()) ssidChar = c;
          if (cu == passCharUuid.toString().toLowerCase()) passChar = c;
        }
      }
    }

    if (ssidChar == null || passChar == null) {
      throw Exception('No se encontraron características SSID/PASS');
    }

    await _ble.writeCharacteristicWithResponse(
      QualifiedCharacteristic(
        serviceId: targetServiceUuid,
        characteristicId: ssidCharUuid,
        deviceId: deviceId,
      ),
      value: ssid.codeUnits,
    );

    await Future.delayed(const Duration(milliseconds: 200));

    await _ble.writeCharacteristicWithResponse(
      QualifiedCharacteristic(
        serviceId: targetServiceUuid,
        characteristicId: passCharUuid,
        deviceId: deviceId,
      ),
      value: password.codeUnits,
    );
  }

  Future<void> dispose() async {
    await stopScan();
    await _devicesController.close();
  }
}