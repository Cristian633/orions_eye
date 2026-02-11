import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../domain/models/models.dart';
import '../providers/devices_provider.dart';
import '../providers/observations_provider.dart';

class GalleryScreen extends ConsumerWidget{
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final observations = ref.watch(observationProvider);
    final devices = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Galeria"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              //TODO: Mostrar filtos
            },
          ),
        ],
      ),
      body: observations.isEmpty
      ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.white70,
            ),
            SizedBox(height: 16),
            Text("No hay observaciones",
            style: TextStyle(
              color:  AppTheme.secondary,
              fontSize: 16,
            ),
            ),
          ],
        ),
      )

    : GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
       itemCount: observations.length,
              itemBuilder: (context, index) {
                final observation = observations[index];
                final device = devices. firstWhere(
                  (d) => d.id == observation.deviceId,
                  orElse: () => 
                  Device(
                    id: observation.deviceId,
                    name: 'Dispositivo desconocido',
                    isOnline: false,
                    status: 'Desconocido',
                    userId: '',
                    lastUpdate: DateTime.now()  
                  ),
                );
                return ObservationCard(
                  observation: observation,
                  deviceName: device.name,
                  onTap:(){
                    context.push('/observation/${observation.id}');
                  },
                );
              },
    ),
    );
  }
}

class ObservationCard extends StatelessWidget{
  final Observation observation;
  final String deviceName;
  final VoidCallback onTap;

  const ObservationCard({
    super.key,
    required this.observation,
    required this.deviceName,
    required this.onTap,
  });

  String _formatDate(DateTime date){
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0){
      return 'Hoy';
    }else if(difference.inDays == 1){
      return 'Ayer';
  }else if (difference.inDays < 7){
    return '${difference.inDays} dias';
  }else{
    return '${date.day}/${date.month}/${date.year}';
  }
}

@override
Widget build(BuildContext context){
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
          //imagen
          Expanded(
            flex: 3,
            child: Image.network(
              observation.thumbnailUrl ?? observation.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress){
                if(loadingProgress == null) return child;
                return Container(
                  color: AppTheme.background,
                  child: const Center(
                    child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                ),
            );
              },
              errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.background,
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          //informacion
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment:  CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //nombre del dispositivo
                   Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize:  14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     const SizedBox(height: 4),

                     //posicion (RA/DEC)
                     Text(
                      'RA: ${observation.position.rightAscension}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
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
                          size:  12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(observation.capturedAt),
                          style: const TextStyle(
                            fontSize:  11,
                            color:  Colors.white,
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
                
            
       