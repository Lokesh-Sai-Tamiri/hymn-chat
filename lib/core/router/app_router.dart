import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/profile/presentation/screens/create_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../config/app_config.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: AppConfig.debugMode,
    
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.matchedLocation;
      
      // Auth flow pages - DON'T auto-redirect from these
      final isAuthFlowPage = currentPath == '/login' || 
                             currentPath == '/otp' ||
                             currentPath == '/create-profile';
      
      if (AppConfig.debugMode) {
        print('🔀 Router redirect: path=$currentPath, authenticated=$isAuthenticated');
      }
      
      // If not authenticated and trying to access protected routes
      if (!isAuthenticated && !isAuthFlowPage) {
        if (AppConfig.debugMode) {
          print('🚫 Not authenticated, redirecting to /login');
        }
        return '/login';
      }
      
      // If authenticated and on login page ONLY (not OTP or create-profile)
      // We ONLY redirect from /login - let other pages handle their own navigation
      if (isAuthenticated && currentPath == '/login') {
        if (AppConfig.debugMode) {
          print('✅ Authenticated on login page, redirecting to /home');
        }
        return '/home';
      }
      
      // For ALL other cases, don't redirect - let the page handle navigation
      return null;
    },
    
    routes: [
      // Auth routes
      GoRoute(
        path: '/login', 
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(phoneNumber: extra?['phone'] ?? '');
        },
      ),
      GoRoute(
        path: '/create-profile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/home', 
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/profile', 
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    
    // DON'T use refreshListenable - it causes race conditions
    // Let each screen handle its own navigation
  );
});
