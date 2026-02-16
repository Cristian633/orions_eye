import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/device_detail_screen.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/gallery_screen.dart';
import '../presentation/screens/observation_detail_screen.dart';  
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/verify_email_screen.dart';
import '../presentation/screens/welcome_screen.dart';           // NUEVO
import '../presentation/screens/bluetooth_scan_screen.dart';    // NUEVO
import '../presentation/screens/wifi_setup_screen.dart';        //  NUEVO
import '../presentation/screens/add_spectrometer_bluetooth_screen.dart';
import '../presentation/screens/add_spectrometer_wifi_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: '/welcome',  //  Cambia a /welcome para que sea la primera pantalla
    
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isVerifying = state.matchedLocation == '/verify-email';
      final isWelcome = state.matchedLocation == '/welcome';           //  NUEVO
      final isBluetoothScan = state.matchedLocation == '/bluetooth-scan';  // ✨ NUEVO
      final isWifiSetup = state.matchedLocation == '/wifi-setup';      //  NUEVO

      // Permitir acceso a pantallas públicas sin autenticación
      if (!isAuthenticated && 
          !isLoggingIn && 
          !isRegistering && 
          !isVerifying && 
          !isWelcome &&           //  NUEVO
          !isBluetoothScan &&     // NUEVO
          !isWifiSetup) {         // NUEVO
        return '/welcome';  // Redirige a welcome en lugar de login
      }

      if (isAuthenticated && (isLoggingIn || isRegistering || isWelcome)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      //  RUTA NUEVA: Welcome (Pantalla inicial)
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      
      //  RUTA NUEVA: Bluetooth Scan
      GoRoute(
        path: '/bluetooth-scan',
        name: 'bluetooth-scan',
        builder: (context, state) => const BluetoothScanScreen(),
      ),
      
      //  RUTA NUEVA: WiFi Setup
      GoRoute(
        path: '/wifi-setup',
        name: 'wifi-setup',
        builder: (context, state) => const WifiSetupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/add-spectrometer-bluetooth',
        name: 'add-spectrometer-bluetooth',
        builder: (context, state) => const AddSpectrometerBluetoothScreen(),
      ),
      GoRoute(
        path: '/add-spectrometer-wifi',
        name: 'add-spectrometer-wifi',
        builder: (context, state) => const AddSpectrometerWifiScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: '/device/:id',  
        name: 'device-detail',
        builder: (context, state) {
          final deviceId = state.pathParameters['id']!;
          final deviceName = state.uri.queryParameters['name'] ?? 'Dispositivo';

          return DeviceDetailScreen(
            deviceId: deviceId,
            deviceName: deviceName,
          );
        },
      ),
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/observation/:id',
        name: 'observation-detail',
        builder: (context, state) {
          final observationId = state.pathParameters['id']!;
          return ObservationDetailScreen(
            observationId: observationId,
          );
        },
      ),
      GoRoute(  
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ], 
  );
});