import 'package:flutter/material.dart';

class WifiSetupScreen extends StatefulWidget {
  final String? deviceId;
  final Object? deviceExtra;
  const WifiSetupScreen({super.key, this.deviceId, this.deviceExtra});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    debugPrint('WifiSetup deviceId: ${widget.deviceId}');
    debugPrint('WifiSetup extra: ${widget.deviceExtra}');
  }

  Future<void> _provisionWifi() async {
    setState(() => _sending = true);
    // TODO: implementar envío de credenciales (SoftAP o BLE)
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _sending = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulación de provisionado enviada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar Wi‑Fi${widget.deviceId != null ? ' • ${widget.deviceId}' : ''}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _ssidController, decoration: const InputDecoration(labelText: 'SSID')),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sending ? null : _provisionWifi,
              child: _sending
                  ? const CircularProgressIndicator()
                  : const Text('Enviar credenciales al dispositivo'),
            ),
          ],
        ),
      ),
    );
  }
}