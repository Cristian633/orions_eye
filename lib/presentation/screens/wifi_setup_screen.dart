import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../providers/esp32_provider.dart';
import 'package:orions_eye_app/domain/models/wifi_network.dart';

class WifiSetupScreen extends ConsumerStatefulWidget {
  final String? deviceId;
  final Map<String, dynamic>? deviceExtra;
  
  const WifiSetupScreen({
    super.key,
    this.deviceId,
    this.deviceExtra,
  });

  @override
  ConsumerState<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends ConsumerState<WifiSetupScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  WiFiNetwork? _selectedNetwork;

  @override
  void initState() {
    super.initState();
    _checkESP32Connection();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkESP32Connection() async {
    final esp32State = ref.read(esp32StateProvider.notifier);
    final isConnected = await esp32State.checkConnection();
    
    if (!isConnected && mounted) {
      _showErrorDialog('No se puede conectar al dispositivo. Asegúrate de estar conectado a la red WiFi del ESP32.');
    } else {
      // Escanear redes WiFi disponibles
      await esp32State.scanWiFiNetworks();
    }
  }

  Future<void> _provisionWiFi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final esp32State = ref.read(esp32StateProvider.notifier);
    final success = await esp32State.provisionWiFi(
      _ssidController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      // Navegar a pantalla de éxito
      context.pushReplacement('/device-setup-success', extra: {
        'deviceId': ref.read(esp32StateProvider).deviceId,
        'deviceIp': ref.read(esp32StateProvider).deviceIp,
      });
    } else {
      _showErrorDialog(
        ref.read(esp32StateProvider).errorMessage ?? 'Error desconocido',
      );
    }
  }

  void _selectNetwork(WiFiNetwork network) {
    setState(() {
      _selectedNetwork = network;
      _ssidController.text = network.ssid;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esp32State = ref.watch(esp32StateProvider);
    final deviceName = widget.deviceExtra?['deviceName'] ?? 'Dispositivo';

    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar WiFi • $deviceName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instrucciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.secondary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Conecta tu dispositivo a WiFi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa las credenciales del WiFi al que quieres conectar tu Orion\'s Eye.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Redes WiFi disponibles
            if (esp32State.availableNetworks.isNotEmpty) ...[
              const Text(
                'Redes disponibles:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              ...esp32State.availableNetworks.map((network) {
                final isSelected = _selectedNetwork?.ssid == network.ssid;
                return Card(
                  color: isSelected ? AppTheme.secondary.withOpacity(0.2) : null,
                  child: ListTile(
                    leading: Icon(
                      network.isSecured ? Icons.wifi_lock : Icons.wifi,
                      color: AppTheme.secondary,
                    ),
                    title: Text(
                      network.ssid,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 16,
                          color: _getSignalColor(network.signalLevel),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${network.rssi} dBm',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: AppTheme.secondary)
                        : null,
                    onTap: () => _selectNetwork(network),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),
            ],

            // Formulario manual
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SSID
                  TextFormField(
                    controller: _ssidController,
                    decoration: InputDecoration(
                      labelText: 'SSID (Nombre de la red)',
                      hintText: 'Mi_WiFi',
                      prefixIcon: const Icon(Icons.wifi),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el SSID';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa la contraseña';
                      }
                      if (value.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Botón de enviar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _provisionWiFi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Conectar dispositivo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botón de actualizar redes
            if (esp32State.connectionState == ESP32ConnectionState.connected)
              TextButton.icon(
                onPressed: () {
                  ref.read(esp32StateProvider.notifier).scanWiFiNetworks();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar redes disponibles'),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSignalColor(int signalLevel) {
    if (signalLevel >= 3) return Colors.green;
    if (signalLevel >= 2) return Colors.orange;
    return Colors.red;
  }
}