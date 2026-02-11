import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import '../../config/aws_config.dart';

class CognitoAuthService {
  late CognitoUserPool _userPool;
  CognitoUser? _currentUser;

 CognitoAuthService() {
  _userPool = CognitoUserPool(
    AwsConfig.userPoolId,
    AwsConfig.clientId,
    endpoint: 'https://cognito-idp.${AwsConfig.region}.amazonaws.com/',
  );
}
  // REGISTRO DE USUARIO
  Future<Map<String, dynamic>> signUpp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final CognitoUserAttributes =[
        AttributeArg(name: 'email', value: email),
        AttributeArg(name: 'name', value: name),
      ];

      final result = await _userPool.signUp(
        email, 
        password,
        userAttributes: CognitoUserAttributes,
        );

        return {
          'success': true,
          'message': 'Usuario registrado. Por favor, verifica tu correo electrónico.',
          'userConfirmed': result.userConfirmed ?? false,
          'userSub': result.userSub,
        };

    } catch (e) {
      return{
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
  }

  // CONFIRMAR CÓDIGO DE VERIFICACIÓN (email)
  Future<Map<String, dynamic>> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      final cognitoUser = CognitoUser(email, _userPool);
      final result = await cognitoUser.confirmRegistration(confirmationCode);

      return {
        'success': result,
        'message': result ? 'Email verificado correctamente' : 'Código inválido', 
      };
    } catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e),
      };
    }
}
// LOGIN
Future<Map<String, dynamic>> signIn({
  required String email,
  required String password,
}) async {
  try {
    final cognitoUser = CognitoUser(email, _userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );
    
    final session = await cognitoUser.authenticateUser(authDetails);

    if (session != null && session.isValid()) {
      _currentUser = cognitoUser;

      // obtener atributos del usuario (nombre, etc)
      final attributes = await cognitoUser.getUserAttributes();
String userName = 'Usuario';

  if (attributes != null) {
  for (var attr in attributes) {
    if (attr.getName() == 'name') {
      userName = attr.getValue() ?? 'Usuario';
      break;
    }
  }
}
      return {
        'success': true,
        'message': 'Inicio de sesión exitoso',
        'userName': userName,
        'email': email,
      };
    } else {
      return {
        'success': false,
        'message': 'Sesión inválida',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': _getErrorMessage(e),
    };
  }
}
    // LOGOUT
  Future<void> signOut() async {
    if (_currentUser != null) {
      await _currentUser!.signOut();
      _currentUser = null;
    }
  }
    // RECUPERAR CONTRASEÑA (enviar código)
    Future<Map<String, dynamic>> forgotPassword({
    required String email,

    }) async {
      try {
        final cognitoUser = CognitoUser(email, _userPool);
        await cognitoUser.forgotPassword();

        return{
          'success': true,
          'message': 'Código de recuperación enviado a tu correo electrónico.',
        };

      } catch (e) {
        return{
          'success': false,
          'message': _getErrorMessage(e),
        };
      }
    }
    // CONFIRMAR NUEVA CONTRASEÑA
    Future<Map<String, dynamic>> confirmNewPassword({
      required String email,
      required String confirmationCode,
      required String newPassword,
    }) async {
      try {
        final cognitoUser= CognitoUser(email, _userPool);
        final result = await cognitoUser.confirmPassword(
          confirmationCode,
          newPassword,
        );
        return {
          'success': result,
          'message': result ? 'Contraseña actualizada correctamente' : 'Error al actualizar contraseña',
        };
      } catch (e) {
        return {
          'success': false,
          'message': _getErrorMessage(e),
        };
      }
}
   // OBTENER SESIÓN ACTUAL
    Future<CognitoUserSession?> getCurrentSession() async {
      if (_currentUser != null) return null; 
     try {
      return await _currentUser!.getSession();
    } catch (e) {
      print('Error obteniendo sesión: $e');
      return null;
    }
  }
    // VERIFICAR SI HAY SESIÓN ACTIVA
    Future<bool> isUserSignedIn() async {
    try {
      final session = await getCurrentSession();
      return session?.isValid() ?? false;
    } catch (e) {
      return false;
    }
  }
  // HELPER: Convertir errores a mensajes legibles
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('user already exists') || 
        errorString.contains('usernameexistsexception')) {
      return 'Este email ya está registrado';
    }
    if (errorString.contains('invalid password') || 
        errorString.contains('invalidpasswordexception')) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (errorString.contains('user not found') || 
        errorString.contains('usernotfoundexception')) {
      return 'Usuario no encontrado';
    }
    if (errorString.contains('incorrect username or password') || 
        errorString.contains('notauthorizedexception')) {
      return 'Email o contraseña incorrectos';
    }
    if (errorString.contains('code mismatch') || 
        errorString.contains('codemismatchexception')) {
      return 'Código de verificación incorrecto';
    }
    if (errorString.contains('expired code') || 
        errorString.contains('expiredcodeexception')) {
      return 'El código ha expirado. Solicita uno nuevo';
    }
    if (errorString.contains('network')) {
      return 'Error de conexión. Verifica tu internet';
    }

    return 'Error: $error';
  }
}