import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../domain/models/models.dart';
import '../providers/devices_provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  ? const Center(
                      child: Text(
                        "No tienes dispositivos",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
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
                    
                    // ✅ BOTÓN BLUETOOTH CON RUTA CORRECTA
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
                        context.push('/bluetooth-scan');  // ✅ CORREGIDO
                      },
                      label: const Text('Conectar por Bluetooth'),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // ✅ BOTÓN WIFI CON RUTA CORRECTA
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
                        context.push('/wifi-setup');  // ✅ CORREGIDO
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

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          Icons.radar,
          size: 40,
          color: device.isOnline ? AppTheme.success : Colors.white,
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          device.status,
          style: TextStyle(
            color: device.isOnline ? AppTheme.success : Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
        ),
        onTap: onTap,
      ),
    );
  }
}