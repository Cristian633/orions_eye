import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  print('DEBUG: Intentando login...');

  final result = await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );

  print('DEBUG: Resultado del login: $result');

  setState(() => _isLoading = false);

  if (result['success'] == true && mounted) {
    print('DEBUG: Login exitoso, navegando a dashboard');
    context.go('/dashboard');
  } else if (result['needsConfirmation'] == true && mounted) {
    print('DEBUG: Usuario no confirmado, redirigiendo a verify-email');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes confirmar tu email. Te reenviamos el código.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
    
    await ref.read(authProvider.notifier).resendConfirmationCode(
      _emailController.text.trim(),
    );
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      context.push('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}');
    }
  } else if (mounted) {
    print('DEBUG: Error en login: ${result['error']}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['error'] ?? 'Error al iniciar sesión')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo o título
                  const Icon(
                    Icons.radar,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Orion's Eye",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight. bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "C",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Campo de email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon:  const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu email';
                      }
                      if (!value. contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon:  const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón de login
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height:  20,
                            width:  20,
                            child:  CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Iniciar Sesión",
                            style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Link de registro
                  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const Text(
                      "¿No tienes cuenta? ",
                  style: TextStyle(color: Colors.white),
                ),
          TextButton(
          onPressed: () {
          context.go('/register');
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        "Regístrate",
        style:  TextStyle(
          color: AppTheme.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}