import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class FieldModeTipsScreen extends StatelessWidget {
  const FieldModeTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Campo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.terrain, color: AppTheme.secondary, size: 42),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Para usar Orion’s Eye en el campo necesitas internet. '
                        'La forma más fácil es usando el hotspot de tu teléfono.',
                        style: TextStyle(color: Colors.white70, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _Step(
              number: '1',
              title: 'Activa Hotspot',
              subtitle: 'Comparte internet desde tu teléfono (datos móviles).',
              icon: Icons.router,
            ),
            _Step(
              number: '2',
              title: 'Pon nombre y contraseña',
              subtitle: 'Usa un nombre fácil y una contraseña que recuerdes.',
              icon: Icons.lock_outline,
            ),
            _Step(
              number: '3',
              title: 'Enciende el espectrómetro',
              subtitle: 'Mantén el dispositivo cerca (< 5m).',
              icon: Icons.power_settings_new,
            ),
            _Step(
              number: '4',
              title: 'Conecta por Bluetooth',
              subtitle: 'Luego le enviaremos el WiFi (tu hotspot) al dispositivo.',
              icon: Icons.bluetooth,
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.push('/bluetooth-scan'),
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Continuar a Bluetooth'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: ~1MB por captura (aprox).',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary.withOpacity(0.15),
          child: Text(
            number,
            style: const TextStyle(
              color: AppTheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.secondary, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}