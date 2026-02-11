import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/devices_provider.dart';
import '../providers/observations_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref){
    final user = ref.watch(authProvider);
    final devices = ref.watch(devicesProvider);
    final observations = ref.watch(observationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),

      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            //Avatar y nombre
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.secondary,
                    child: user?.avatarUrl != null
                    ? ClipOval(
                      child: Image.network(
                        user!.avatarUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Text(
                      user?.name?.substring(0,1).toUpperCase() ??
                      user?.email.substring(0,1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ), 
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            //Estadisticas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.radar,
                        label: 'Dispositivos',
                        value: devices.length.toString(),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.secondary.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        icon: Icons.photo_library,
                        label: 'Observaciones',
                        value: observations.length.toString(),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.secondary.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        icon: Icons.access_time,
                        label: 'Dias activo',
                        value: user?.createdAt != null
                            ? DateTime.now().difference(user!.createdAt!).inDays.toString()
                            : '0',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            //opciones de configuracion
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Configuracion",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSettingItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'Editar Perfil',
                    onTap: () {
                      //TODO: Ir a editar perfil
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Función próximamente")),
                      );
                    },
                  ),
                 _buildSettingItem(
                  context: context,
                  icon: Icons.security_outlined,
                  title: 'Notificaciones',
                  onTap: () {
                    //TODO: Ir a configuracion de notificaciones
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Función próximamente")),
                    );
                  },
                ),
                _buildSettingItem(
                  context: context,
                  icon: Icons.security_outlined,
                  title: 'Seguridad',
                  subtitle: 'Cambiar contraseña',
                  onTap: () {
                    // TODO: Ir a cambiar contraseña
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Función próximamente")),
                    );
                  },
                ),
                _buildSettingItem(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Ayuda y soporte',
                    onTap: () {
                      // TODO: Ir a ayuda
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Función próximamente")),
                      );
                    },
                  ),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'Acerca de',
                    subtitle: 'Versión 1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: "Orion's Eye",
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.radar,
                          size: 48,
                          color: AppTheme.secondary,
                        ),
                        children: [
                          const Text(
                            'Acercandote a las estrellas',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  //Boton de cerrar sesion
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (){
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
                                onPressed: (){
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Cerrar Sesión",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
   Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
   }){
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.secondary,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }){
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.secondary,
          ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
       subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white,
        ),
        onTap: onTap,
      ),
    );
  }
}