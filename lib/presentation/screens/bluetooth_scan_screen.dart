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
    // Mostrar diálogo de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Conectando por Bluetooth...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      print('🔵 Conectando a: ${device.name} (${device.id})');
      
      // Conectar por BLE
      final connection = _ble.connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 15),
      );

      await for (final state in connection) {
        print('🔵 Estado BLE: ${state.connectionState}');
        
        if (state.connectionState == DeviceConnectionState.connected) {
          print('✅ BLE Conectado exitosamente');
          
          if (mounted) {
            Navigator.pop(context); // Cerrar loading
            
            // Ir a WiFi Setup con la información del dispositivo
            context.push('/wifi-setup', extra: {
              'deviceId': device.id,
              'deviceName': device.name,
              'bleConnected': true,
            });
          }
          break;
        } else if (state.connectionState == DeviceConnectionState.disconnected) {
          print('❌ BLE Desconectado');
          if (mounted) {
            Navigator.pop(context); // Cerrar loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ No se pudo conectar al dispositivo'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
        }
      }
    } catch (e) {
      print('❌ Error BLE: $e');
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al conectar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _scanning
                              ? 'Buscando dispositivos...'
                              : 'No se encontraron dispositivos',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!_scanning)
                          ElevatedButton.icon(
                            onPressed: _startScan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Buscar de nuevo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth_connected,
                            color: AppTheme.secondary,
                            size: 32,
                          ),
                          title: Text(
                            device.name.isEmpty ? 'Dispositivo sin nombre' : device.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${device.id.substring(0, 8)}...',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Señal: ${device.rssi} dBm',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                          ),
                          onTap: () => _connectToDevice(device),
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