import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import '../../config/aws_config.dart';

class AuthService {
  late CognitoUserPool _userPool;
  CognitoUser? _cognitoUser;
  CognitoUserSession? _session;

  AuthService(){
    _userPool = CognitoUserPool(
      AwsConfig.userPoolId,
      AwsConfig.clientId,
    );
  }

    // Registrar nuevo usuario
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
}) async {
  try{
    final userAttributes = [
      AttributeArg(name: 'email', value: email),
      AttributeArg(name: 'name', value: name),
    ];
    final result = await _userPool.signUp(
      email,
      password,
      userAttributes: userAttributes,
    );
    return {
      'success': true,
      'userId': result.userSub,
      'confirmed': result.userConfirmed
    };

    }catch(e){
      print('Error en registro: $e');
      return {
        'success': false,
        'error':  _parseError(e.toString()),
      };
    }
  }
  // Confirmar usuario con código de verificación
Future<Map<String, dynamic>> confirmRegistration({
  required String email,
  required String code,
}) async {
  try {
    final cognitoUser = CognitoUser(email, _userPool);
    
    final result = await cognitoUser.confirmRegistration(code);
    
    if (result) {
      // Después de confirmar, hacer login automático
      return {
        'success': true,
        'message': 'Email verificado exitosamente',
      };
    } else {
      return {
        'success': false,
        'error': 'Código de verificación inválido',
      };
    }
  } catch (e) {
    print('Error confirmando usuario: $e');
    
    if (e.toString().contains('CodeMismatchException')) {
      return {
        'success': false,
        'error': 'Código incorrecto. Verifica e intenta de nuevo.',
      };
    } else if (e.toString().contains('ExpiredCodeException')) {
      return {
        'success': false,
        'error': 'El código ha expirado. Solicita uno nuevo.',
      };
    } else if (e.toString().contains('LimitExceededException')) {
      return {
        'success': false,
        'error': 'Demasiados intentos. Intenta más tarde.',
      };
    } else {
      return {
        'success': false,
        'error': _parseError(e.toString()),
      };
    }
  }
}

// Reenviar código de confirmación
Future<Map<String, dynamic>> resendConfirmationCode(String email) async {
  try {
    final cognitoUser = CognitoUser(email, _userPool);
    await cognitoUser.resendConfirmationCode();
    
    return {
      'success': true,
      'message': 'Código reenviado a tu email',
    };
  } catch (e) {
    print('Error reenviando código: $e');
    return {
      'success': false,
      'error': _parseError(e.toString()),
    };
  }
}
    // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try{
      _cognitoUser = CognitoUser(email, _userPool);
      final authDetails = AuthenticationDetails(
        username: email,
        password: password,
      );
      _session = await _cognitoUser!.authenticateUser(authDetails);

    if (_session == null || !_session!.isValid()) {
      return {
    'success': false,
    'error': 'Sesión inválida',
  };
}
          // Obtener atributos del usuario
      final attributes = await _cognitoUser!.getUserAttributes();
      final userAttributes = <String, String>{};
      
      if (attributes != null) {
        for (var attr in attributes) {
          userAttributes[attr.name!] = attr.value!;
        }
      }
      return {
       'success': true,
        'userId': _session!.getIdToken().payload['sub'],
        'email': userAttributes['email'] ?? email,
        'name': userAttributes['name'] ?? '',
        'idToken': _session!.getIdToken().getJwtToken(),
        'accessToken': _session!.getAccessToken().getJwtToken(),
        'refreshToken': _session!.getRefreshToken()?.getToken(),
        };
    } catch (e) {
      print(' Error en login: $e');
      return {
        'success': false,
        'error': _parseError(e.toString()),
      };
    }
  }
        // Logout
  Future<void> logout() async {
    if (_cognitoUser != null) {
      await _cognitoUser!.signOut();
      _cognitoUser = null;
      _session = null;
    }
  }
  // Verificar si hay sesión activa
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      _cognitoUser = await _userPool.getCurrentUser();
      
      if (_cognitoUser == null) {
        return null;
      }

      _session = await _cognitoUser!.getSession();

      if (_session == null || !_session!.isValid()) {
        return null;
      }

      // Obtener atributos del usuario
      final attributes = await _cognitoUser!.getUserAttributes();
      final userAttributes = <String, String>{};
      
      if (attributes != null) {
        for (var attr in attributes) {
          userAttributes[attr.name!] = attr.value!;
        }
      }

      return {
        'userId': _session!.getIdToken().payload['sub'],
        'email': userAttributes['email'] ?? '',
        'name': userAttributes['name'] ?? '',
        'idToken': _session!.getIdToken().getJwtToken(),
        'accessToken': _session!.getAccessToken().getJwtToken(),
        'refreshToken': _session!.getRefreshToken()?.getToken(),
      };
    } catch (e) {
      print(' Error obteniendo usuario actual: $e');
      return null;
    }
  }

  // Obtener token de acceso (para API Gateway)
  Future<String?> getIdToken() async {
    try {
      if (_session == null || !_session!.isValid()) {
        // Intentar refrescar la sesión
        final userData = await getCurrentUser();
        if (userData == null) return null;
      }
      return _session?.getIdToken().getJwtToken();
    } catch (e) {
      print(' Error obteniendo token: $e');
      return null;
    }
  }

  // Parsear errores de Cognito
  String _parseError(String error) {
    if (error.contains('UserNotFoundException') || error.contains('NotAuthorizedException')) {
      return 'Email o contraseña incorrectos';
    } else if (error.contains('UsernameExistsException')) {
      return 'Este email ya está registrado';
    } else if (error.contains('InvalidPasswordException')) {
      return 'La contraseña debe tener al menos 8 caracteres';
    } else if (error.contains('InvalidParameterException')) {
      return 'Email inválido';
    } else if (error.contains('NetworkError') || error.contains('Network')) {
      return 'Sin conexión a internet';
    } else {
      return 'Error: $error';
    }
  }
}
