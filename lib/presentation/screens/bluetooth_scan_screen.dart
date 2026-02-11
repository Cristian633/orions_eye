import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  final List<ScanResult> _devices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Android 12+ needs BLUETOOTH_SCAN, BLUETOOTH_CONNECT; for location use ACCESS_FINE_LOCATION
    final status = await Permission.location.request();
    if (!status.isGranted) {
      // show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesitamos permisos para Bluetooth')));
      }
    }
  }

  void _startScan() async {
    setState(() {
      _devices.clear();
      _scanning = true;
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (!_devices.any((d) => d.device.remoteId == result.device.remoteId)) {
          setState(() => _devices.add(result));
        }
      }
    });
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() => _scanning = false);
      }
    });
  }

  void _stopScan() => FlutterBluePlus.stopScan();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar dispositivos Bluetooth'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.search),
            onPressed: _scanning ? _stopScan : _startScan,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, i) {
          final r = _devices[i];
          return ListTile(
            title: Text(r.device.name.isNotEmpty ? r.device.name : r.device.id.id),
            subtitle: Text('RSSI: ${r.rssi}'),
            trailing: ElevatedButton(
              child: const Text('Conectar'),
              onPressed: () {
                // navegar a screen de detalle / pairing
              },
            ),
          );
        },
      ),
    );
  }
}