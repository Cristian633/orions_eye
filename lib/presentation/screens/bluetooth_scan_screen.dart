import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  final _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.location.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitamos permisos para Bluetooth')),
      );
    }
  }

  void _startScan() {
    setState(() {
      _devices.clear();
      _scanning = true;
    });

    _ble.scanForDevices(withServices: []).listen((device) {
      if (!_devices.any((d) => d.id == device.id)) {
        setState(() => _devices.add(device));
      }
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar dispositivos Bluetooth'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.search),
            onPressed: _scanning ? null : _startScan,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, i) {
          final device = _devices[i];
          return ListTile(
            title: Text(device.name.isNotEmpty ? device.name : device.id),
            subtitle: Text('RSSI: ${device.rssi}'),
            trailing: ElevatedButton(
              child: const Text('Conectar'),
              onPressed: () {
                // TODO: Conectar al dispositivo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Conectando a ${device.name}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}