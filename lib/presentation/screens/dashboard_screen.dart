import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../domain/models/models.dart';
import '../../data/services/device_service.dart';
import '../providers/devices_provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _deviceService = DeviceService();

  Future<void> _captureImage(String deviceId) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Enviando comando de captura...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Enviar comando de captura
      final success = await _deviceService.captureImage(deviceId);

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 Captura iniciada! El ESP32 está procesando...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Mostrar diálogo informativo
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Captura en proceso'),
              content: const Text(
                '⏳ El ESP32 está capturando y subiendo la imagen a S3.\n\n'
                '📸 Esto puede tomar 10-30 segundos.\n\n'
                '💡 Revisa la Galería en unos momentos.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Ir a galería
                    context.push('/gallery');
                  },
                  child: const Text('Ir a Galería'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error enviando comando de captura'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
    final devices = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Orion's Eye"),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: "Galería",
            onPressed: () {
              context.push('/gallery');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: "Cerrar sesión",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Cerrar sesión"),
                  content: const Text("¿Estás seguro que deseas cerrar sesión?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                      child: const Text(
                        "Cerrar sesión",
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: AppTheme.background,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.radar,
                      size: 48,
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Orion's Eye",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer(
                      builder: (context, ref, child) {
                        final user = ref.watch(authProvider);
                        return Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: AppTheme.secondary),
                title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/dashboard');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.secondary),
                title: const Text('Galería', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/gallery');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppTheme.secondary),
                title: const Text('Perfil', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
              const Divider(color: Colors.white),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.white),
                title: const Text('Configuración', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Función próximamente")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.white),
                title: const Text('Ayuda', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Función próximamente")),
                  );
                },
              ),
              const Divider(color: Colors.white),
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.error),
                title: const Text('Cerrar Sesión', style: TextStyle(color: AppTheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text("Cerrar sesión"),
                      content: const Text("¿Estás seguro que deseas cerrar sesión?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            ref.read(authProvider.notifier).logout();
                            context.go('/login');
                          },
                          child: const Text(
                            "Cerrar sesión",
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mis Dispositivos",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.radar_outlined,
                            size: 80,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No tienes dispositivos conectados",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push('/bluetooth-scan');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Dispositivo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return DeviceCard(
                          device: device,
                          onTap: () {
                            context.push('/device/${device.id}?name=${device.name}');
                          },
                          onCapture: () => _captureImage(device.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppTheme.background,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Agregar espectrómetro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/bluetooth-scan');
                      },
                      label: const Text('Conectar por Bluetooth'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    OutlinedButton.icon(
                      icon: const Icon(Icons.wifi),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Conecta por Bluetooth primero para configurar WiFi'),
                          ),
                        );
                      },
                      label: const Text(
                        'Conectar por Wi‑Fi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  final VoidCallback onCapture;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.radar,
                    size: 40,
                    color: device.isOnline ? AppTheme.success : Colors.white54,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: device.isOnline ? AppTheme.success : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              device.status,
                              style: TextStyle(
                                color: device.isOnline ? AppTheme.success : Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                    size: 16,
                  ),
                ],
              ),
              
              if (device.isOnline) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                
                // Botón de captura
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCapture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capturar Imagen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}