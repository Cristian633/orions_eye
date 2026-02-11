import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../domain/models/models.dart';
import '../providers/devices_provider.dart';

class DeviceDetailScreen extends ConsumerWidget {
  final String deviceId;
  final String deviceName;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceByIdProvider(deviceId));

    // Si no se encuentra el dispositivo
    if (device == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Dispositivo no encontrado"),
        ),
        body: const Center(
          child: Text(
            "Este dispositivo no existe",
            style: TextStyle(
              color: Colors.white,
              fontSize:  16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        leading: IconButton(
          icon:  const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/dashboard');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado del dispositivo
            _buildStatusCard(device),
            const SizedBox(height: 16),
            
            // Controles de movimiento (solo si está online)
            if (device.isOnline) ...[
              const Text(
                "Controles de Movimiento",
                style:  TextStyle(
                  fontSize:  20,  
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildMovementControls(),
              const SizedBox(height: 24),
              
              // Botón de captura
              ElevatedButton. icon(
                onPressed: () {
                  // TODO:  Capturar imagen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Capturando imagen...")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  "Capturar Imagen",
                  style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  "Dispositivo desconectado",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Device device) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius:  BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: device.isOnline ? AppTheme.success : AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  device.status,
                  style: TextStyle(
                    color: device.isOnline ? AppTheme.success : AppTheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
                       _buildStatusRow("ID", device.id),
            if (device.position != null) ...[
              _buildStatusRow("RA", device.position!.rightAscension),
              _buildStatusRow("DEC", device.position!.declination),
              if (device.position!.altitude != null)
                _buildStatusRow("Altitud", "${device.position!.altitude!.toStringAsFixed(2)}°"),
              if (device.position!.azimuth != null)
                _buildStatusRow("Azimut", "${device.position!.azimuth!.toStringAsFixed(2)}°"),
            ],
            _buildStatusRow("Última actualización", _formatTimeSince(device.lastUpdate)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding:  const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:  [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementControls() {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Arriba
            _buildControlButton(Icons.arrow_upward, "Norte"),
            const SizedBox(height: 8),
            
            // Izquierda, Centro, Derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:  [
                _buildControlButton(Icons.arrow_back, "Oeste"),
                _buildControlButton(Icons.home, "Home"),
                _buildControlButton(Icons.arrow_forward, "Este"),
              ],
            ),
            const SizedBox(height:  8),
            
            // Abajo
            _buildControlButton(Icons.arrow_downward, "Sur"),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: Enviar comando de movimiento
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          child: Icon(icon, size:  28),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatTimeSince(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return "Hace ${difference.inDays} día${difference.inDays > 1 ? 's' :  ''}";
    } else if (difference.inHours > 0) {
      return "Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' :  ''}";
    } else if (difference.inMinutes > 0) {
      return "Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}";
    } else {
      return "Justo ahora";
    }
  }
}