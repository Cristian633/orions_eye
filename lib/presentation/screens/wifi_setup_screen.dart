import 'package:flutter/material.dart';

class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _sending = false;

  Future<void> _provisionWifi() async {
    setState(() => _sending = true);
    // TODO: implement provisioning logic depending on device:
    // - SoftAP: Connect to device AP, call its HTTP endpoint with SSID/password.
    // - BLE provisioning: connect via BLE and send SSID/password characteristics.
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _sending = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulación de provisionado enviada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Wi‑Fi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _ssidController, decoration: const InputDecoration(labelText: 'SSID')),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sending ? null : _provisionWifi,
              child: _sending ? const CircularProgressIndicator() : const Text('Enviar credenciales al dispositivo'),
            ),
          ],
        ),
      ),
    );
  }
}