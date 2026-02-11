import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../data/services/auth_service.dart';

// Instancia del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Provider del usuario autenticado
class AuthNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(null) {
    _checkCurrentUser();
  }
  // Confirmar registro con código
Future<Map<String, dynamic>> confirmRegistration({
  required String email,
  required String code,
}) async {
  return await _authService.confirmRegistration(email: email, code: code);
}

// Reenviar código de confirmación
Future<Map<String, dynamic>> resendConfirmationCode(String email) async {
  return await _authService.resendConfirmationCode(email);
}
  // Verificar si hay un usuario autenticado al iniciar
  Future<void> _checkCurrentUser() async {
    final userData = await _authService.getCurrentUser();
    
    if (userData != null && userData['success'] != false) {
      state = User(
        id: userData['userId'] ?? '',
        email: userData['email'] ?? '',
        name: userData['name'],
      );
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _authService.login(email: email, password: password);

    if (result['success'] == true) {
      state = User(
        id: result['userId'] ?? '',
        email: result['email'] ?? email,
        name: result['name'],
      );
    }

    return result;
  }

 // Registro
Future<Map<String, dynamic>> register({
  required String email,
  required String password,
  required String name,
}) async {
  final result = await _authService.register(
    email: email,
    password: password,
    name: name,
  );

  // NO hacer login automático, solo retornar el resultado del registro
  return result;
}

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }

  // Obtener token para API
  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Provider para verificar si está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider);
  return user != null;
});