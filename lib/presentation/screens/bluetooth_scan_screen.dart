import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class BluetoothScanScreen extends ConsumerStatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  ConsumerState<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends ConsumerState<BluetoothScanScreen> {
  final _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devices = [];
  bool _scanning = false;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // Mostrar instrucciones primero
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSetupInstructions();
    });
  }

  void _showSetupInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.secondary),
            SizedBox(width: 12),
            Text('Configuración inicial'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.firstTimeSetup,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.secondary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.router, color: AppTheme.secondary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Activar HOTSPOT ahora:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Android: Ajustes → Conexiones → Zona WiFi\n'
                      '• iOS: Ajustes → Compartir Internet',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startScan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
            ),
            child: Text('Ya activé el HOTSPOT'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPermissions() async {
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
      _showInstructions = false;
    });

    _ble.scanForDevices(withServices: []).listen((device) {
      if (device.name.contains('OrionsEye') || device.name.contains('ESP32')) {
        if (!_devices.any((d) => d.id == device.id)) {
          setState(() => _devices.add(device));
        }
      }
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  void _stopScan() {
    setState(() => _scanning = false);
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Conectando por Bluetooth...'),
                SizedBox(height: 8),
                Text(
                  'Espera unos segundos',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      print(' Conectando a: ${device.name} (${device.id})');
      
      final connection = _ble.connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 15),
      );

      await for (final state in connection) {
        print(' Estado BLE: ${state.connectionState}');
        
        if (state.connectionState == DeviceConnectionState.connected) {
          print(' BLE Conectado exitosamente');
          
          if (mounted) {
            Navigator.pop(context);
            
            // Ir a WiFi Setup
            context.push('/wifi-setup', extra: {
              'deviceId': device.id,
              'deviceName': device.name,
              'bleConnected': true,
            });
          }
          break;
        } else if (state.connectionState == DeviceConnectionState.disconnected) {
          print(' BLE Desconectado');
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(' No se pudo conectar. Intenta de nuevo'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Reintentar',
                  textColor: Colors.white,
                  onPressed: () => _connectToDevice(device),
                ),
              ),
            );
          }
          break;
        }
      }
    } catch (e) {
      print(' Error BLE: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error: Asegúrate de estar cerca del espectrómetro'),
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
        title: const Text('Conectar Espectrómetro'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.refresh),
            onPressed: _scanning ? _stopScan : _startScan,
            tooltip: _scanning ? 'Detener búsqueda' : 'Buscar de nuevo',
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showSetupInstructions,
            tooltip: 'Ver instrucciones',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_scanning)
            LinearProgressIndicator(color: AppTheme.secondary),
          
          // Banner de instrucciones
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: AppTheme.secondary.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.router, color: AppTheme.secondary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scanning 
                          ? 'Buscando espectrómetro...'
                          : '${_devices.length} espectrómetros encontrados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '📱 Asegúrate de tener el HOTSPOT activado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _scanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                          size: 100,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 24),
                        Text(
                          _scanning
                              ? 'Buscando espectrómetros...'
                              : 'No se encontraron espectrómetros',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Verifica que:\n'
                            '• El espectrómetro esté encendido\n'
                            '• Estés cerca del dispositivo (< 5 metros)\n'
                            '• El Bluetooth esté activado',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 32),
                        if (!_scanning)
                          ElevatedButton.icon(
                            onPressed: _startScan,
                            icon: Icon(Icons.refresh),
                            label: Text('Buscar de nuevo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.radar,
                              color: AppTheme.secondary,
                              size: 32,
                            ),
                          ),
                          title: Text(
                            device.name.isEmpty ? 'Espectrómetro' : device.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.signal_cellular_alt, size: 16, color: Colors.white70),
                                  SizedBox(width: 4),
                                  Text(
                                    'Señal: ${device.rssi} dBm',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ID: ${device.id.substring(0, 8)}...',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _connectToDevice(device),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                            ),
                            child: Text('Conectar'),
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