import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../providers/aws_iot_provider.dart';
import '../providers/devices_provider.dart';

class DeviceSetupSuccessScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;

  const DeviceSetupSuccessScreen({super.key, this.extra});

  @override
  ConsumerState<DeviceSetupSuccessScreen> createState() =>
      _DeviceSetupSuccessScreenState();
}

class _DeviceSetupSuccessScreenState
    extends ConsumerState<DeviceSetupSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isRegistering = true;
  bool _registrationSuccess = false;
  String _statusMessage = 'Registrando en AWS IoT Core...';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Iniciar registro en AWS
    _registerInAWS();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _registerInAWS() async {
    final deviceId = widget.extra?['deviceId'] ?? 'unknown';
    final deviceName = 'Orion\'s Eye ${deviceId.substring(0, 8)}';

    setState(() {
      _statusMessage = 'Registrando dispositivo...';
    });

    await Future.delayed(const Duration(seconds: 1));

    // Registrar en AWS IoT Core
    final success = await ref.read(iotRegistrationProvider.notifier).registerDevice(
          deviceId: deviceId,
          deviceName: deviceName,
        );

    if (!mounted) return;

    if (success) {
      setState(() {
        _statusMessage = 'Guardando en base de datos...';
      });

      await Future.delayed(const Duration(seconds: 1));

      // Agregar a la lista de dispositivos del usuario
      // TODO: Integrar con devices_provider para guardar en DynamoDB

      setState(() {
        _isRegistering = false;
        _registrationSuccess = true;
        _statusMessage = '¡Dispositivo configurado exitosamente!';
      });
    } else {
      setState(() {
        _isRegistering = false;
        _registrationSuccess = false;
        _statusMessage = 'Error al registrar dispositivo';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceId = widget.extra?['deviceId'] ?? 'Desconocido';
    final deviceIp = widget.extra?['deviceIp'];
    final iotStatus = ref.watch(iotRegistrationProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Ícono animado
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isRegistering
                        ? AppTheme.secondary.withOpacity(0.2)
                        : _registrationSuccess
                            ? AppTheme.success.withOpacity(0.2)
                            : AppTheme.error.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: _isRegistering
                      ? const CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppTheme.secondary,
                        )
                      : Icon(
                          _registrationSuccess ? Icons.check_circle : Icons.error,
                          color: _registrationSuccess ? AppTheme.success : AppTheme.error,
                          size: 80,
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Título
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  _registrationSuccess
                      ? '¡Dispositivo configurado!'
                      : _isRegistering
                          ? 'Configurando...'
                          : 'Error',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Mensaje de estado
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Información del dispositivo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.radar,
                        label: 'ID del dispositivo',
                        value: deviceId,
                      ),
                      if (deviceIp != null) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.wifi,
                          label: 'Dirección IP',
                          value: deviceIp,
                        ),
                      ],
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.cloud,
                        label: 'Estado AWS IoT',
                        value: _isRegistering
                            ? 'Registrando...'
                            : _registrationSuccess
                                ? 'Conectado'
                                : 'Error',
                        valueColor: _isRegistering
                            ? Colors.orange
                            : _registrationSuccess
                                ? AppTheme.success
                                : AppTheme.error,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Botones de acción
              if (!_isRegistering) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_registrationSuccess) ...[
                      ElevatedButton(
                        onPressed: () {
                          context.go('/dashboard');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ir al Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          context.go('/bluetooth-scan');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Configurar otro dispositivo',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = true;
                          });
                          _registerInAWS();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          context.go('/dashboard');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}