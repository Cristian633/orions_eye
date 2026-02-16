import 'package:flutter/material.dart';
import '../../config/theme.dart';

class DeviceConnectingScreen extends StatefulWidget {
  final String deviceName;
  
  const DeviceConnectingScreen({
    super.key,
    required this.deviceName,
  });

  @override
  State<DeviceConnectingScreen> createState() => _DeviceConnectingScreenState();
}

class _DeviceConnectingScreenState extends State<DeviceConnectingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;

  final List<String> _steps = [
    'Conectando al dispositivo...',
    'Enviando credenciales WiFi...',
    'Esperando confirmación...',
    'Registrando en AWS IoT...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _simulateSteps();
  }

  void _simulateSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animación de carga
              RotationTransition(
                turns: _controller,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.secondary,
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.radar,
                    color: AppTheme.secondary,
                    size: 50,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Configurando ${widget.deviceName}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Lista de pasos
              ..._steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      // Ícono de estado
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.success
                              : isCurrent
                                  ? AppTheme.secondary
                                  : Colors.grey.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : isCurrent
                                  ? Icons.sync
                                  : Icons.circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Texto del paso
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            color: isCurrent || isCompleted
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            fontSize: 16,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const Spacer(),

              const CircularProgressIndicator(
                color: AppTheme.secondary,
              ),

              const SizedBox(height: 16),

              Text(
                'Esto puede tomar unos segundos...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}