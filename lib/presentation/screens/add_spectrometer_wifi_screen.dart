import 'package:flutter/material.dart';

class AddSpectrometerWifiScreen extends StatelessWidget {
  const AddSpectrometerWifiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar espectrómetro (Wi‑Fi)'),
      ),
      body: const Center(
        child: Text(
          'Aquí irá la configuración de red (SSID, password o QR) para el espectrómetro.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}