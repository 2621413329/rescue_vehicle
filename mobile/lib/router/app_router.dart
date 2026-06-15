import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../modules/audit/pages/audit_pages.dart';
import '../modules/auth/pages/login_page.dart';
import '../modules/auth/services/auth_service.dart';
import '../modules/cart/pages/cart_pages.dart';
import '../modules/dashboard/pages/dashboard_page.dart';
import '../modules/inspection/pages/inspection_pages.dart';
import '../modules/inventory/pages/inventory_pages.dart';
import '../modules/label/pages/label_pages.dart';
import '../modules/profile/pages/profile_page.dart';
import '../modules/warning/pages/warning_center_page.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboard = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorInventory = GlobalKey<NavigatorState>(debugLabel: 'inventory');
final _shellNavigatorInspection = GlobalKey<NavigatorState>(debugLabel: 'inspection');
final _shellNavigatorWarning = GlobalKey<NavigatorState>(debugLabel: 'warning');
final _shellNavigatorProfile = GlobalKey<NavigatorState>(debugLabel: 'profile');

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (!isLoggedIn && !loggingIn) return '/login';
      if (isLoggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboard,
            routes: [GoRoute(path: '/', builder: (_, __) => const DashboardPage())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInventory,
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (_, state) => InventoryListPage(initialFilter: state.uri.queryParameters['filter']),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInspection,
            routes: [GoRoute(path: '/inspection', builder: (_, __) => const InspectionTaskPage())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorWarning,
            routes: [GoRoute(path: '/warning', builder: (_, __) => const WarningCenterPage())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfile,
            routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfilePage())],
          ),
        ],
      ),
      GoRoute(path: '/inventory/create', builder: (_, __) => const InventoryCreatePage()),
      GoRoute(
        path: '/inventory/:id',
        builder: (_, state) => InventoryDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/inventory/:id/edit',
        builder: (_, state) => InventoryEditPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/inventory/:id/history',
        builder: (_, state) => InventoryHistoryPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/inspection/execute/:cartId',
        builder: (_, state) => InspectionExecutePage(cartId: int.parse(state.pathParameters['cartId']!)),
      ),
      GoRoute(path: '/inspection/history', builder: (_, __) => const InspectionHistoryPage()),
      GoRoute(
        path: '/inspection/detail/:id',
        builder: (_, state) => InspectionDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartListPage()),
      GoRoute(path: '/cart/risk', builder: (_, __) => const CartRiskPage()),
      GoRoute(
        path: '/cart/:id',
        builder: (_, state) => CartDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/cart/:id/layers',
        builder: (_, state) => CartLayerPage(cartId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/label', builder: (_, __) => const LabelCenterPage()),
      GoRoute(path: '/audit', builder: (_, __) => const AuditLogPage()),
      GoRoute(
        path: '/audit/:id',
        builder: (_, state) => AuditDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
