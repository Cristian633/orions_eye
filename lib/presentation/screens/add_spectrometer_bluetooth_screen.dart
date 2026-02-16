import 'package:flutter/material.dart';

class AddSpectrometerBluetoothScreen extends StatelessWidget {
  const AddSpectrometerBluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar espectrómetro (Bluetooth)'),
      ),
      body: const Center(
        child: Text(
          'Aquí irá el flujo para escanear y vincular el espectrómetro por Bluetooth.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}