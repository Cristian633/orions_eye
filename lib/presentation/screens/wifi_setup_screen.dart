import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../config/theme.dart';
import '../../data/services/device_service.dart';
import '../providers/auth_provider.dart';

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
  final _deviceService = DeviceService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  // UUIDs del ESP32
  final serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final ssidCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  final passCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a9");
  final statusCharUuid = Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26aa");

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendWiFiCredentials() async {
    if (_ssidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Por favor ingresa el SSID')),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Por favor ingresa la contraseña')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deviceId = widget.deviceExtra['deviceId'] as String;
      
      print('📤 Enviando SSID: ${_ssidController.text}');
      
      // Enviar SSID
      await _ble.writeCharacteristicWithResponse(
        QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: ssidCharUuid,
          deviceId: deviceId,
        ),
        value: utf8.encode(_ssidController.text),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      print('📤 Enviando Password');
      
      // Enviar Password
      await _ble.writeCharacteristicWithResponse(
        QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: passCharUuid,
          deviceId: deviceId,
        ),
        value: utf8.encode(_passwordController.text),
      );

      print('✅ Credenciales enviadas, esperando confirmación...');

      // Esperar a que el ESP32 se conecte
      await Future.delayed(const Duration(seconds: 5));

      // Registrar dispositivo en el backend
      try {
        final user = ref.read(authProvider);
        final deviceName = widget.deviceExtra['deviceName'] as String;
        
        if (user != null) {
          await _deviceService.registerDevice(
            deviceId: deviceId,
            userId: user.id,
            deviceName: deviceName,
          );
          
          print('✅ Dispositivo registrado en backend');
        }
      } catch (e) {
        print('⚠️ Error registrando dispositivo: $e');
        // No es crítico, continuar
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dispositivo configurado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Volver al dashboard
        context.go('/dashboard');
      }

    } catch (e) {
      print('❌ Error enviando credenciales: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.deviceExtra['deviceName'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar WiFi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del dispositivo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.router,
                      color: AppTheme.secondary,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dispositivo conectado',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deviceName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.bluetooth_connected,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Ingresa las credenciales WiFi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'El dispositivo se conectará a tu red WiFi para enviar las capturas.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Campo SSID
            TextField(
              controller: _ssidController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre de la red (SSID)',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.wifi, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.secondary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Campo Password
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.secondary),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón enviar
            ElevatedButton(
              onPressed: _isLoading ? null : _sendWiFiCredentials,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar Credenciales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Información adicional
            Card(
              color: AppTheme.surface.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Información',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Asegúrate de estar cerca del dispositivo\n'
                      '• La red debe ser de 2.4 GHz (no 5 GHz)\n'
                      '• El proceso puede tomar hasta 30 segundos\n'
                      '• El dispositivo se reiniciará automáticamente',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}