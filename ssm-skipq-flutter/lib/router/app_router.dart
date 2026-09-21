import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_services.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../screens/manager/manager_login_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/student/student_checkout_screen.dart';
import '../screens/student/student_order_confirmation_screen.dart';
import '../screens/student/student_order_history_screen.dart';
import '../screens/student/student_track_order_screen.dart';
import '../widgets/manager_shell.dart';
import '../widgets/student_shell.dart';

int studentTabFromQuery(String? tab) {
  switch (tab) {
    case 'cart':
    case 'orders':
      return 1;
    case 'track':
      return 2;
    case 'profile':
      return 3;
    default:
      return 0;
  }
}

int managerTabFromQuery(String? tab) => tab == 'orders' ? 1 : 0;

GoRouter createRouter(AppServices services, AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoading) return null;

      final loc = state.matchedLocation;
      final isPublic = loc == '/' || loc == '/manager/login';

      if (auth.user == null && !isPublic) {
        return '/';
      }
      if (auth.isStudent && loc.startsWith('/manager')) {
        return '/student';
      }
      if (auth.isManager && loc.startsWith('/student')) {
        return '/manager';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/student/login', redirect: (_, __) => '/'),
      GoRoute(
          path: '/manager/login',
          builder: (_, __) => const ManagerLoginScreen()),
      GoRoute(
        path: '/student',
        builder: (_, state) => StudentShell(
          menuService: services.menuService,
          ordersService: services.ordersService,
          socketService: services.socketService,
          feedbackService: services.feedbackService,
          paymentService: services.paymentService,
          initialTab: studentTabFromQuery(state.uri.queryParameters['tab']),
        ),
      ),
      GoRoute(
        path: '/student/cart',
        redirect: (_, __) => '/student?tab=cart',
      ),
      GoRoute(
        path: '/student/order-history',
        builder: (_, __) => StudentOrderHistoryScreen(
          ordersService: services.ordersService,
        ),
      ),
      GoRoute(
        path: '/student/checkout',
        builder: (_, __) => StudentCheckoutScreen(
          ordersService: services.ordersService,
          paymentService: services.paymentService,
        ),
      ),
      GoRoute(
        path: '/student/order-confirmation/:orderId',
        builder: (_, state) {
          final orderId = state.pathParameters['orderId']!;
          final order = state.extra as Order?;
          return StudentOrderConfirmationScreen(
            orderId: orderId,
            initialOrder: order,
            ordersService: services.ordersService,
            socketService: services.socketService,
          );
        },
      ),
      GoRoute(
        path: '/student/track-order/:orderId',
        builder: (_, state) {
          final orderId = state.pathParameters['orderId']!;
          final order = state.extra as Order?;
          return StudentTrackOrderScreen(
            orderId: orderId,
            initialOrder: order,
            ordersService: services.ordersService,
            socketService: services.socketService,
            feedbackService: services.feedbackService,
            showBottomNavigation: true,
          );
        },
      ),
      GoRoute(
        path: '/manager',
        builder: (_, state) => ManagerShell(
          ordersService: services.ordersService,
          menuService: services.menuService,
          feedbackService: services.feedbackService,
          socketService: services.socketService,
          superAdminService: services.superAdminService,
          initialTab: managerTabFromQuery(state.uri.queryParameters['tab']),
        ),
      ),
    ],
  );
}
