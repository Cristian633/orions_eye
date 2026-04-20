import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';

class BluetoothScanScreen extends ConsumerStatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  ConsumerState<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends ConsumerState<BluetoothScanScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final List<DiscoveredDevice> _devices = [];
  final Map<String, DiscoveredDevice> _unique = {};
  StreamSubscription<DiscoveredDevice>? _scanSub;

  bool _scanning = false;

  // UUID del servicio BLE del ESP
  final Uuid _targetService = Uuid.parse('4fafc201-1fb5-459e-8fcc-c5c9c331914b');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSetupInstructions());
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;

    if (!scanGranted || !connectGranted) {
      throw Exception('Permisos BLE no concedidos');
    }
  }

  bool _isTarget(DiscoveredDevice d) {
    final n = d.name.toLowerCase().trim();

    final byName = n.contains('orion') || n.contains('spectrometer') || n.contains('esp32');
    final byService = d.serviceUuids.any(
      (u) => u.toString().toLowerCase() == _targetService.toString().toLowerCase(),
    );

    return byName || byService;
  }

  Future<void> _startScan() async {
    try {
      await _checkPermissions();
      await _scanSub?.cancel();

      setState(() {
        _devices.clear();
        _unique.clear();
        _scanning = true;
      });

      _scanSub = _ble
          .scanForDevices(
            withServices: const [],
            scanMode: ScanMode.lowLatency,
          )
          .listen(
        (device) {
          if (_isTarget(device)) {
            _unique[device.id] = device;
            if (mounted) {
              setState(() {
                _devices
                  ..clear()
                  ..addAll(_unique.values);
              });
            }
          }
        },
        onError: (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error escaneando BLE: $e')),
          );
        },
      );

      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) _stopScan();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error permisos BLE: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
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
      final connection = _ble.connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 15),
      );

      await for (final state in connection) {
        if (state.connectionState == DeviceConnectionState.connected) {
          if (!mounted) return;
          Navigator.pop(context);

          // userId desde SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('userId') ?? '';

          if (userId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se encontró userId en sesión. Inicia sesión nuevamente.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          context.push('/wifi-setup', extra: {
            'deviceId': device.id,
            'deviceName': device.name.isEmpty ? 'OrionSpectrometer' : device.name,
            'bleConnected': true,
            'userId': userId,
          });
          break;
        }

        if (state.connectionState == DeviceConnectionState.disconnected) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo conectar. Intenta de nuevo'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error BLE: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSetupInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.secondary),
            const SizedBox(width: 12),
            const Text('Configuración inicial'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(AppStrings.firstTimeSetup),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startScan();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
            child: const Text('Ya activé el HOTSPOT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar Espectrómetro'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.refresh),
            onPressed: _scanning ? _stopScan : _startScan,
            tooltip: _scanning ? 'Detener búsqueda' : 'Buscar de nuevo',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_scanning) LinearProgressIndicator(color: AppTheme.secondary),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.secondary.withOpacity(0.1),
            child: Text(
              _scanning
                  ? 'Buscando espectrómetro...'
                  : '${_devices.length} espectrómetros encontrados',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      _scanning ? 'Buscando...' : 'No se encontraron espectrómetros',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final d = _devices[index];
                      final name = d.name.isEmpty ? 'OrionSpectrometer' : d.name;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth, color: Colors.lightBlue),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            'RSSI: ${d.rssi} dBm\nID: ${d.id}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _connectToDevice(d),
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