import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';

class BluetoothScanScreen extends ConsumerStatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  ConsumerState<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends ConsumerState<BluetoothScanScreen> {
  final _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _startScan(); // Auto-iniciar escaneo
  }

  Future<void> _checkPermissions() async {
    // Android 12+ necesita múltiples permisos
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void _startScan() {
    setState(() {
      _devices.clear();
      _scanning = true;
    });

    _ble.scanForDevices(withServices: []).listen((device) {
      // Filtrar solo dispositivos "OrionsEye"
      if (device.name.contains('OrionsEye') || device.name.contains('ESP32')) {
        if (!_devices.any((d) => d.id == device.id)) {
          setState(() => _devices.add(device));
        }
      }
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  void _stopScan() {
    setState(() => _scanning = false);
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    // TODO: Implementar conexión BLE real
    // Por ahora, redirigir a WiFi setup
    if (mounted) {
      context.push('/wifi-setup', extra: {
        'deviceId': device.id,
        'deviceName': device.name,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Orion\'s Eye'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.refresh),
            onPressed: _scanning ? _stopScan : _startScan,
          )
        ],
      ),
      body: Column(
        children: [
          if (_scanning)
            const LinearProgressIndicator(),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _scanning ? Icons.bluetooth_searching : Icons.bluetooth,
                      color: AppTheme.secondary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _scanning
                            ? 'Buscando dispositivos...'
                            : '${_devices.length} dispositivos encontrados',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _scanning
                              ? 'Buscando...'
                              : 'No se encontraron dispositivos',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                        if (!_scanning) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _startScan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Volver a buscar'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _devices.length,
                    itemBuilder: (context, i) {
                      final device = _devices[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.radar,
                            color: AppTheme.secondary,
                            size: 32,
                          ),
                          title: Text(
                            device.name.isNotEmpty ? device.name : 'Dispositivo sin nombre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${device.id}\nSeñal: ${device.rssi} dBm',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _connectToDevice(device),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                            ),
                            child: const Text('Conectar'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}