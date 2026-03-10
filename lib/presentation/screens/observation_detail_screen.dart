import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../providers/observations_provider.dart';
import '../providers/devices_provider.dart';

class ObservationDetailScreen extends ConsumerWidget {
  final String observationId;

  const ObservationDetailScreen({
    super.key,
    required this.observationId
  });

  // ============================================================================
  // FUNCIÓN DE DESCARGA
  // ============================================================================
  Future<void> _downloadImage(String imageUrl, BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descargando imagen...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Descargar imagen
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        // Obtener directorio de documentos (más compatible multiplataforma)
        final directory = Platform.isAndroid
            ? await getExternalStorageDirectory()
            : await getApplicationDocumentsDirectory();
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${directory!.path}/orionseye_$timestamp.jpg';
        
        // Guardar archivo
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Imagen guardada exitosamente'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Ver ruta',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Ubicación'),
                      content: Text(filePath),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Error al descargar: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // FUNCIÓN DE COMPARTIR
  // ============================================================================
  Future<void> _shareImage(String imageUrl, BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparando para compartir...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Descargar imagen temporalmente
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${directory.path}/share_orionseye_$timestamp.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Compartir
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Captura de Orion\'s Eye - Espectrómetro Astronómico',
          subject: 'Observación astronómica',
        );
      } else {
        throw Exception('Error al descargar: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final observation = ref.watch(observationByIdProvider(observationId));
  
    if(observation == null){
      return Scaffold(
        appBar: AppBar(
          title: const Text("Observación no encontrada"),
        ),
        body: const Center(
          child: Text(
            "Esta observación no existe",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    final device = ref.watch(deviceByIdProvider(observation.deviceId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen de fondo
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            // BOTONES AGREGADOS EN EL APPBAR
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Compartir',
                onPressed: () => _shareImage(observation.imageUrl, context),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Descargar',
                onPressed: () => _downloadImage(observation.imageUrl, context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                observation.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress){
                  if(loadingProgress == null) return child;
                  return Container(
                    color: AppTheme.background,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },   
                errorBuilder: (context, error, stackTrace){
                  return Container(
                    color: AppTheme.background,
                    child: const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          // contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // informacion del dispositivo
                  _buildSection(
                    title: "Dispositivo",
                    child: _buildInfoRow("Nombre", device?.name ?? "Desconocido"),
                  ),
                  const SizedBox(height: 16),
                  // informacion de la observacion
                  _buildSection(
                    title: "Posición",
                    child: Column(
                      children: [
                        _buildInfoRow("Ascensión Recta", observation.position.rightAscension),
                        _buildInfoRow("Declinación", observation.position.declination),
                        if (observation.position.altitude != null)
                          _buildInfoRow("Altitud", "${observation.position.altitude!.toStringAsFixed(2)}°"),
                        if (observation.position.azimuth != null)
                          _buildInfoRow("Azimut", "${observation.position.azimuth!.toStringAsFixed(2)}°"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // metadata de captura
                  if(observation.metadata != null) ...[
                    _buildSection(
                      title: "Datos de Captura",
                      child: Column(
                        children: [
                          if (observation.metadata!.exposureTime != null)
                            _buildInfoRow("Exposición", "${observation.metadata!.exposureTime}s"),
                          if (observation.metadata!.iso != null)
                            _buildInfoRow("ISO", "${observation.metadata!.iso}"),
                          if (observation.metadata!.filter != null)
                            _buildInfoRow("Filtro", observation.metadata!.filter!),
                          if (observation.metadata!.temperature != null)
                            _buildInfoRow("Temperatura", "${observation.metadata!.temperature}°C"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // fecha de captura
                  _buildSection(
                    title: "Fecha de Captura",
                    child: _buildInfoRow(
                      "Capturado",
                      "${observation.capturedAt.day}/${observation.capturedAt.month}/${observation.capturedAt.year} "
                      "${observation.capturedAt.hour.toString().padLeft(2, '0')}:${observation.capturedAt.minute.toString().padLeft(2, '0')}",
                    ),
                  ),
                  const SizedBox(height: 32),

                  //  BOTONES ACTUALIZADOS CON FUNCIONALIDAD REAL
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareImage(observation.imageUrl, context),
                          icon: const Icon(Icons.share),
                          label: const Text("Compartir"),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadImage(observation.imageUrl, context),
                          icon: const Icon(Icons.download),
                          label: const Text("Descargar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}