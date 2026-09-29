// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';

// import '../../di/service_locator.dart';
// import '../../features/auth/presentation/bloc/auth_bloc.dart';
// import '../../features/auth/presentation/bloc/auth_state.dart';
// import '../../features/auth/presentation/pages/complete_profile_page.dart';
// import '../../features/auth/presentation/pages/phone_input_page.dart';
// import '../../features/auth/presentation/pages/splash_page.dart';
// import '../../features/home/presentation/pages/home_page.dart';
// import '../../features/home/presentation/pages/tracking_tab.dart';
// import '../../features/orders/presentation/pages/order_detail_page.dart';

// class AppRouter {
//   AppRouter._();

//   static GoRouter? _router;

//   /// Lazily-built router. The first access constructs it (after DI is ready).
//   static GoRouter get router => _router ??= _build();

//   static GoRouter _build() {
//     return GoRouter(
//       initialLocation: '/',
//       debugLogDiagnostics: false,
//       refreshListenable: _AuthListenable(),
//       redirect: (context, state) {
//         final auth = sl<AuthBloc>().state;
//         final loc = state.matchedLocation;

//         // 1. Bootstrapping → splash
//         if (auth is AuthInitial) {
//           return loc == '/' ? null : '/';
//         }

//         // 2. Not authenticated → login
//         if (auth is AuthUnauthenticated) {
//           return loc == '/login' ? null : '/login';
//         }

//         // 3. Authenticated
//         if (auth is AuthAuthenticated) {
//           final hasName =
//               auth.account.name != null && auth.account.name!.trim().isNotEmpty;

//           if (!hasName) {
//             return loc == '/complete-profile' ? null : '/complete-profile';
//           }

//           if (loc == '/login' || loc == '/complete-profile' || loc == '/') {
//             return '/home';
//           }
//         }

//         // 4. Transient states (AuthLoading, OtpSent, AuthError,
//         //    RegistrationRequired) → stay where we are.
//         return null;
//       },
//       routes: [
//         GoRoute(
//           path: '/',
//           name: 'splash',
//           builder: (context, state) => const SplashPage(),
//         ),
//         GoRoute(
//           path: '/login',
//           name: 'login',
//           builder: (context, state) => const PhoneInputPage(),
//         ),
//         GoRoute(
//           path: '/complete-profile',
//           name: 'completeProfile',
//           builder: (context, state) => const CompleteProfilePage(),
//         ),
//         GoRoute(
//           path: '/home',
//           name: 'home',
//           builder: (context, state) => const HomePage(),
//         ),
//         GoRoute(
//           path: '/order-detail',
//           name: 'orderDetail',
//           builder: (context, state) {
//             final id = state.extra as String?;
//             if (id == null || id.isEmpty) {
//               return const Scaffold(
//                 body: Center(child: Text('Missing order id')),
//               );
//             }
//             return OrderDetailPage(id: id);
//           },
//         ),
//         GoRoute(
//           path: '/tracking',
//           name: 'tracking',
//           builder: (context, state) => const TrackingTab(),
//         ),
//       ],
//       errorBuilder: (context, state) => Scaffold(
//         appBar: AppBar(title: const Text('Not found')),
//         body: Center(child: Text('No route for ${state.uri}')),
//       ),
//     );
//   }

//   static void push(String location, {Object? extra}) {
//     router.push(location, extra: extra);
//   }

//   static void go(String location, {Object? extra}) {
//     router.go(location, extra: extra);
//   }
// }

// /// Bridges AuthBloc state changes to GoRouter's refresh mechanism.
// /// Notifies when the **class** of state changes (not every emit).
// class _AuthListenable extends ChangeNotifier {
//   _AuthListenable() {
//     final bloc = sl<AuthBloc>();
//     _last = bloc.state;
//     _sub = bloc.stream.listen((next) {
//       if (next.runtimeType != _last.runtimeType) {
//         _last = next;
//         notifyListeners();
//       }
//     });
//   }

//   // 🔑 `late`, not `late final` — we reassign it on every state change.
//   late AuthState _last;
//   StreamSubscription<AuthState>? _sub;

//   @override
//   void dispose() {
//     _sub?.cancel();
//     super.dispose();
//   }
// }

import 'dart:async';

import 'package:deliver_ethiopia/features/auth/domain/usecases/account_kind.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../di/service_locator.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/phone_input_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/tracking_tab.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';

// ── Courier imports ──
import '../../features/courier/presentation/pages/courier_home_page.dart';
import '../../features/courier/presentation/pages/courier_job_detail_page.dart';
import '../../features/courier/presentation/pages/courier_earnings_page.dart';
import '../../features/courier/presentation/pages/courier_profile_page.dart';

import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter? _router;

  /// Lazily-built router. First access constructs it (after DI is ready).
  static GoRouter get router => _router ??= _build();

  static GoRouter _build() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: false,
      refreshListenable: _AuthListenable(),
      redirect: (context, state) {
        final auth = sl<AuthBloc>().state;
        final loc = state.matchedLocation;

        // 1. Bootstrapping → splash
        if (auth is AuthInitial) {
          return loc == AppRoutes.splash ? null : AppRoutes.splash;
        }

        // 2. Not authenticated → login
        if (auth is AuthUnauthenticated) {
          return loc == AppRoutes.login ? null : AppRoutes.login;
        }

        // 3. Authenticated
        if (auth is AuthAuthenticated) {
          // ── COURIER ──
          if (auth.kind == AccountKind.courier) {
            // Allow courier routes + sub-routes
            if (loc.startsWith('/courier')) return null;
            // Any other authenticated route → courier home
            return AppRoutes.courierHome;
          }

          // ── CUSTOMER ──
          final hasName =
              auth.account.name != null && auth.account.name!.trim().isNotEmpty;

          if (!hasName) {
            return loc == AppRoutes.completeProfile
                ? null
                : AppRoutes.completeProfile;
          }

          if (loc == AppRoutes.login ||
              loc == AppRoutes.completeProfile ||
              loc == AppRoutes.splash ||
              loc.startsWith('/courier')) {
            return AppRoutes.home;
          }
        }

        // 4. Transient states (loading, OTP sent, error, registration)
        return null;
      },
      routes: [
        // ══════════════════════════════════════════════
        // SHARED
        // ══════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const PhoneInputPage(),
        ),

        // ══════════════════════════════════════════════
        // CUSTOMER
        // ══════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.completeProfile,
          name: 'completeProfile',
          builder: (context, state) => const CompleteProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.orderDetail,
          name: 'orderDetail',
          builder: (context, state) {
            final id = state.extra as String?;
            if (id == null || id.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Missing order id')),
              );
            }
            return OrderDetailPage(id: id);
          },
        ),
        GoRoute(
          path: AppRoutes.tracking,
          name: 'tracking',
          builder: (context, state) => const TrackingTab(),
        ),

        // ══════════════════════════════════════════════
        // COURIER
        // ══════════════════════════════════════════════
        GoRoute(
          path: AppRoutes.courierHome,
          name: 'courierHome',
          builder: (context, state) => const CourierHomePage(),
        ),
        GoRoute(
          path: AppRoutes.courierJobDetail,
          name: 'courierJobDetail',
          builder: (context, state) {
            final id = state.extra as String?;
            if (id == null || id.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Missing job id')),
              );
            }
            return CourierJobDetailPage(jobId: id);
          },
        ),
        GoRoute(
          path: AppRoutes.courierEarnings,
          name: 'courierEarnings',
          builder: (context, state) => const CourierEarningsPage(),
        ),
        GoRoute(
          path: AppRoutes.courierProfile,
          name: 'courierProfile',
          builder: (context, state) => const CourierProfilePage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(child: Text('No route for ${state.uri}')),
      ),
    );
  }

  static void push(String location, {Object? extra}) {
    router.push(location, extra: extra);
  }

  static void go(String location, {Object? extra}) {
    router.go(location, extra: extra);
  }
}

/// Bridges AuthBloc state changes to GoRouter's refresh mechanism.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    final bloc = sl<AuthBloc>();
    _last = bloc.state;
    _sub = bloc.stream.listen((next) {
      if (next.runtimeType != _last.runtimeType) {
        _last = next;
        notifyListeners();
      }
    });
  }

  late AuthState _last;
  StreamSubscription<AuthState>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
