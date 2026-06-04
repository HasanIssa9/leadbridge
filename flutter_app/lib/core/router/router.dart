import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/leads/presentation/leads_screen.dart';
import '../../features/delivery/presentation/delivery_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final loggedIn = auth.value != null;
      final isAuth   = state.matchedLocation.startsWith('/auth');
      if (!loggedIn && !isAuth) return '/auth/login';
      if (loggedIn && isAuth)   return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/leads',     builder: (_, __) => const LeadsScreen()),
          GoRoute(path: '/delivery',  builder: (_, __) => const DeliveryScreen()),
          GoRoute(path: '/settings',  builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
