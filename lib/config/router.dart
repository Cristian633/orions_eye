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
import '../presentation/screens/welcome_screen.dart';
import '../presentation/screens/bluetooth_scan_screen.dart';
import '../presentation/screens/wifi_setup_screen.dart';
import '../presentation/screens/device_setup_success_screen.dart';  //  NUEVO
import '../presentation/screens/device_connecting_screen.dart';      // NUEVO

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: '/welcome',
    
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isVerifying = state.matchedLocation == '/verify-email';
      final isWelcome = state.matchedLocation == '/welcome';
      final isBluetoothScan = state.matchedLocation == '/bluetooth-scan';
      final isWifiSetup = state.matchedLocation == '/wifi-setup';
      final isDeviceSetup = state.matchedLocation.startsWith('/device-setup');  // ✨ NUEVO

      if (!isAuthenticated && 
          !isLoggingIn && 
          !isRegistering && 
          !isVerifying && 
          !isWelcome &&
          !isBluetoothScan &&
          !isWifiSetup &&
          !isDeviceSetup) {  // ✨ NUEVO
        return '/welcome';
      }

      if (isAuthenticated && (isLoggingIn || isRegistering || isWelcome)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      
      GoRoute(
        path: '/bluetooth-scan',
        name: 'bluetooth-scan',
        builder: (context, state) => const BluetoothScanScreen(),
      ),
      
      GoRoute(
        path: '/wifi-setup',
        name: 'wifi-setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WifiSetupScreen(
            deviceId: extra?['deviceId'],
            deviceExtra: extra,
          );
        },
      ),
      
      //  NUEVAS RUTAS
      GoRoute(
        path: '/device-connecting',
        name: 'device-connecting',
        builder: (context, state) {
          final deviceName = (state.extra as Map<String, dynamic>?)?['deviceName'] ?? 'Dispositivo';
          return DeviceConnectingScreen(deviceName: deviceName);
        },
      ),
      
      GoRoute(
        path: '/device-setup-success',
        name: 'device-setup-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DeviceSetupSuccessScreen(extra: extra);
        },
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
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
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