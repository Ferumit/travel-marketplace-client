import 'package:explora_app/models/tour_models.dart' as tour;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:explora_app/route_builder/route_builder_controller.dart';
import 'package:explora_app/route_builder/route_builder_screen.dart';
import 'package:explora_app/screens/active_trip_screen.dart';
import 'package:explora_app/screens/active_trips_list_screen.dart';
import 'package:explora_app/screens/auth_screen.dart';
import 'package:explora_app/screens/booking_screen.dart';
import 'package:explora_app/screens/documents_screen.dart';
import 'package:explora_app/screens/favorites_screen.dart';
import 'package:explora_app/navigation/main_tab_scaffold.dart';
import 'package:explora_app/screens/my_orders_screen.dart';
import 'package:explora_app/screens/onboarding_screen.dart';
import 'package:explora_app/screens/profile_screen.dart';
import 'package:explora_app/screens/route_preview_screen.dart';
import 'package:explora_app/screens/settings_screen.dart';
import 'package:explora_app/screens/sos_screen.dart';
import 'package:explora_app/screens/mesh_screen.dart';
import 'package:explora_app/screens/trip_completed_screen.dart';
import 'package:explora_app/screens/walkie_talkie_screen.dart';
import 'package:explora_app/screens/messenger_screen.dart';
import 'package:explora_app/screens/sos_history_screen.dart';
import 'package:explora_app/services/auth_service.dart';


/// Global navigator key — used by ConnectivityService for imperative navigation.
final appRouterKey = GlobalKey<NavigatorState>();

/// Единственный маршрутизатор приложения.
///
/// Использует [GoRouter] с guard‑перенаправлениями на основе [AuthService].
final appRouter = GoRouter(
  navigatorKey: appRouterKey,
  initialLocation: '/auth',
  refreshListenable: AuthService.instance,
  redirect: (context, state) {
    final auth = AuthService.instance;
    final location = state.uri.path;

    if (auth.isAuthInProgress) {
      if (location != '/auth') return '/auth';
      return null;
    }

    // Не зарегистрирован → всегда на /auth
    if (!auth.isRegistered) {
      if (location != '/auth') return '/auth';
      return null;
    }

    // Зарегистрирован, онбординг не пройден → /onboarding
    if (!auth.isOnboarded) {
      if (location != '/onboarding') return '/onboarding';
      return null;
    }

    // Полностью авторизован — не пускаем на /auth и /onboarding
    if (location == '/auth' || location == '/onboarding') return '/';

    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const MainTabScaffold()),
    GoRoute(
      path: '/constructor',
      builder: (context, state) => const RouteBuilderScreen(),
    ),
    GoRoute(
      path: '/route-details',
      builder: (context, state) {
        final route = state.extra as tour.Route;
        return RoutePreviewScreen(route: route);
      },
    ),
    GoRoute(
      path: '/booking',
      builder: (context, state) {
        final extra = state.extra;
        // From route constructor → passes RouteBuilderController directly
        if (extra is RouteBuilderController) {
          return BookingScreen(controller: extra);
        }
        // From popular route preview → passes {'route': tour.Route}
        if (extra is Map) {
          final route = extra['route'];
          if (route is tour.Route) {
            return BookingScreen(route: route);
          }
        }
        return const BookingScreen();
      },
    ),
    GoRoute(
      path: '/active_trips',
      builder: (context, state) => const ActiveTripsListScreen(),
    ),
    GoRoute(
      path: '/active/:tripId',
      builder: (context, state) =>
          ActiveTripScreen(tripId: state.pathParameters['tripId']!),
    ),
    GoRoute(
      path: '/trip_completed/:tripId',
      builder: (context, state) =>
          TripCompletedScreen(tripId: state.pathParameters['tripId']!),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/my-orders',
      builder: (context, state) => const MyOrdersScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/documents',
      builder: (context, state) => const DocumentsScreen(),
    ),
    GoRoute(path: '/sos',  builder: (context, state) => const SOSScreen()),
    GoRoute(path: '/mesh', builder: (context, state) => const MeshScreen()),
    GoRoute(path: '/sos-history', builder: (context, state) => const SosHistoryScreen()),
    // Legacy routes — kept for backward compat
    GoRoute(
      path: '/wave',
      builder: (context, state) => const WalkieTalkieScreen(),
    ),
    GoRoute(
      path: '/walkie_talkie',
      builder: (context, state) => const WalkieTalkieScreen(),
    ),
    GoRoute(
      path: '/messenger',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final tripId = extra['tripId'] as String? ?? '';
        final title = extra['title'] as String? ?? 'Чат';
        return MessengerScreen(tripId: tripId, title: title);
      },
    ),
  ],
);

