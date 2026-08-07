import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/device_service.dart';

class WifiSetupScreen extends StatefulWidget {
  final String deviceId;
  final String? deviceName;
  final bool bleConnected;
  final String userId;

  const WifiSetupScreen({
    super.key,
    required this.deviceId,
    this.deviceName,
    this.bleConnected = false,
    required this.userId,
  });

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _ble = FlutterReactiveBle();
  final _deviceService = DeviceService();

  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _connected = false;
  String _status = "Listo para configurar WiFi";

  final Uuid serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid ssidUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  final Uuid passUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a9");

  @override
  void initState() {
    super.initState();
    _connected = widget.bleConnected;
  }

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureConnected() async {
    if (_connected) return;

    setState(() => _status = "Conectando BLE...");
    await for (final update in _ble.connectToDevice(
      id: widget.deviceId,
      connectionTimeout: const Duration(seconds: 15),
    )) {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connected = true;
        setState(() => _status = "BLE conectado");
        break;
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        throw Exception("No se pudo conectar por BLE");
      }
    }
  }

  Future<void> _sendCredentialsAndRegister() async {
    final ssid = _ssidCtrl.text.trim();
    final pass = _passCtrl.text;

    if (ssid.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa SSID y contraseña")),
      );
      return;
    }

    if (widget.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontró userId para registrar dispositivo")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _ensureConnected().timeout(const Duration(seconds: 15));

      setState(() => _status = "Descubriendo servicios...");
      final services = await _ble
          .discoverServices(widget.deviceId)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException("discoverServices timeout (10s)");
      });
      
      bool foundService = false;
      bool foundSsid = false;
      bool foundPass = false;

      for (final s in services) {
        if (s.serviceId.toString().toLowerCase() == serviceUuid.toString().toLowerCase()) {
          foundService = true;
          for (final c in s.characteristics) {
            final id = c.characteristicId.toString().toLowerCase();
            if (id == ssidUuid.toString().toLowerCase()) foundSsid = true;
            if (id == passUuid.toString().toLowerCase()) foundPass = true;
          }
        }
      }

      if (!foundService || !foundSsid || !foundPass) {
        throw Exception("No se encontraron UUIDs BLE esperados");
      }

      setState(() => _status = "Enviando SSID...");
      await _ble
          .writeCharacteristicWithResponse(
            QualifiedCharacteristic(
              serviceId: serviceUuid,
              characteristicId: ssidUuid,
              deviceId: widget.deviceId,
            ),
            value: ssid.codeUnits,
          )
          .timeout(const Duration(seconds: 8));

      await Future.delayed(const Duration(milliseconds: 250));

      setState(() => _status = "Enviando contraseña...");
      await _ble
          .writeCharacteristicWithResponse(
            QualifiedCharacteristic(
              serviceId: serviceUuid,
              characteristicId: passUuid,
              deviceId: widget.deviceId,
            ),
            value: pass.codeUnits,
          )
          .timeout(const Duration(seconds: 8));

      setState(() => _status = "Credenciales enviadas ✅ Registrando dispositivo...");

      final result = await _deviceService
          .registerDevice(
            deviceId: widget.deviceId,
            userId: widget.userId,
            deviceName: widget.deviceName ?? 'OrionSpectrometer',
          )
          .timeout(const Duration(seconds: 12));

      debugPrint("REGISTER OK: $result");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dispositivo agregado a Mis dispositivos ✅")),
      );

      context.go('/dashboard');
    } on TimeoutException catch (e) {
      if (!mounted) return;
      setState(() => _status = "Timeout: ${e.message ?? 'operación tardó demasiado'}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Timeout: ${e.message ?? 'operación tardó demasiado'}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = "Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceLabel = (widget.deviceName != null && widget.deviceName!.isNotEmpty)
        ? widget.deviceName!
        : widget.deviceId;

    return Scaffold(
      appBar: AppBar(title: const Text("Configurar WiFi")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Dispositivo: $deviceLabel"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ssidCtrl,
              decoration: const InputDecoration(
                labelText: "SSID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_status),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendCredentialsAndRegister,
                child: Text(_loading ? 'Procesando...' : 'Enviar y Registrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}