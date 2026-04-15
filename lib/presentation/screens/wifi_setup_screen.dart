import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../providers/devices_provider.dart';

enum _SetupStep { idle, sendingWifi, connecting, done }

class WiFiSetupScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> deviceExtra;

  const WiFiSetupScreen({
    super.key,
    required this.deviceExtra,
  });

  @override
  ConsumerState<WiFiSetupScreen> createState() => _WiFiSetupScreenState();
}

class _WiFiSetupScreenState extends ConsumerState<WiFiSetupScreen> {
  final _ble = FlutterReactiveBle();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  _SetupStep _step = _SetupStep.idle;
  String _statusText = '';

  final serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final ssidCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  final passCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a9");
  final statusCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26aa");

  bool get _isLoading => _step != _SetupStep.idle;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendWiFiCredentials() async {
    if (_ssidController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('❌ Por favor ingresa el SSID')));
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('❌ Por favor ingresa la contraseña')));
      return;
    }

    final deviceId = widget.deviceExtra['deviceId'] as String;
    final deviceName = (widget.deviceExtra['deviceName'] as String?) ?? 'Espectrómetro';

    try {
      setState(() {
        _step = _SetupStep.sendingWifi;
        _statusText = 'Enviando WiFi al espectrómetro...';
      });

      await _ble.writeCharacteristicWithResponse(
        QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: ssidCharUuid,
          deviceId: deviceId,
        ),
        value: utf8.encode(_ssidController.text),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      await _ble.writeCharacteristicWithResponse(
        QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: passCharUuid,
          deviceId: deviceId,
        ),
        value: utf8.encode(_passwordController.text),
      );

      setState(() {
        _step = _SetupStep.connecting;
        _statusText = 'Conectando a internet y registrando en la nube... (30–45s)';
      });

      // Registrar dispositivo en backend usando ApiService (Cognito)
      final ok = await ref.read(devicesProvider.notifier).registerDevice(
            deviceId: deviceId,
            name: deviceName,
          );

      if (!ok) {
        throw Exception('No se pudo registrar el dispositivo en el backend.');
      }

      // Esperar a que aparezca en /devices
      await ref.read(devicesProvider.notifier).waitUntilDeviceOnline(deviceId);

      if (!mounted) return;

      setState(() {
        _step = _SetupStep.done;
        _statusText = '✅ Listo. El espectrómetro ya está configurado.';
      });

      // Pantalla de éxito (ya existe en tu router)
      context.go('/device-setup-success', extra: {
        'deviceId': deviceId,
        'deviceName': deviceName,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _SetupStep.idle;
        _statusText = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = (widget.deviceExtra['deviceName'] as String?) ?? 'Dispositivo';

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Internet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.router, color: AppTheme.secondary, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Conectado por Bluetooth',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(deviceName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.bluetooth_connected, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('WiFi / Hotspot',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'En el campo usa el Hotspot de tu teléfono (datos móviles).',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _ssidController,
              enabled: !_isLoading,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'SSID',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.wifi, color: Colors.white70),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70),
                  onPressed: _isLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            if (_step == _SetupStep.sendingWifi || _step == _SetupStep.connecting)
              Card(
                color: AppTheme.surface.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_statusText, style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _sendWiFiCredentials,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_isLoading ? 'Procesando...' : 'Enviar y conectar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}