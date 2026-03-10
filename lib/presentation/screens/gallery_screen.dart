import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../domain/models/models.dart';
import '../providers/devices_provider.dart';
import '../providers/observations_provider.dart';
import '../providers/auth_provider.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Refrescar observaciones al abrir la galería
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshObservations();
    });
  }

  Future<void> _refreshObservations() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final user = ref.read(authProvider);
      if (user != null) {
        await ref.read(observationProvider.notifier).refreshObservations(user.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Observaciones actualizadas'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error actualizando: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final observations = ref.watch(observationProvider);
    final devices = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Galería"),
        actions: [
          // Botón de refresh
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshObservations,
            tooltip: 'Actualizar observaciones',
          ),
          
          // Botón de filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppTheme.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Función de filtros próximamente',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshObservations,
        color: AppTheme.secondary,
        backgroundColor: AppTheme.surface,
        child: observations.isEmpty
            ? _buildEmptyState(context)
            : _buildGrid(observations, devices),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 100,
                color: Colors.white30,
              ),
              const SizedBox(height: 24),
              const Text(
                "No hay observaciones",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Captura tu primera imagen del cosmos",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/dashboard');
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ir al Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _refreshObservations,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Observation> observations, List<Device> devices) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: observations.length,
      itemBuilder: (context, index) {
        final observation = observations[index];
        final device = devices.firstWhere(
          (d) => d.id == observation.deviceId,
          orElse: () => Device(
            id: observation.deviceId,
            name: 'Dispositivo desconocido',
            isOnline: false,
            status: 'Desconocido',
            userId: '',
            lastUpdate: DateTime.now(),
          ),
        );
        
        return ObservationCard(
          observation: observation,
          deviceName: device.name,
          onTap: () {
            context.push('/observation/${observation.id}');
          },
        );
      },
    );
  }
}

class ObservationCard extends StatelessWidget {
  final Observation observation;
  final String deviceName;
  final VoidCallback onTap;

  const ObservationCard({
    super.key,
    required this.observation,
    required this.deviceName,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    observation.thumbnailUrl ?? observation.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppTheme.background,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2.0,
                            color: AppTheme.secondary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.background,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error cargando imagen',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Badge de nuevo (opcional)
                  if (DateTime.now().difference(observation.capturedAt).inHours < 24)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NUEVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Información
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nombre del dispositivo
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Posición (RA/DEC)
                    Text(
                      'RA: ${observation.position.rightAscension}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),

                    // Fecha
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(observation.capturedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
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
      ),
    );
  }
}