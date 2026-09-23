import 'dart:async';

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

class AppRouter {
  AppRouter._();

  static GoRouter? _router;

  /// Lazily-built router. The first access constructs it (after DI is ready).
  static GoRouter get router => _router ??= _build();

  static GoRouter _build() {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false,
      refreshListenable: _AuthListenable(),
      redirect: (context, state) {
        final auth = sl<AuthBloc>().state;
        final loc = state.matchedLocation;

        // 1. Bootstrapping → splash
        if (auth is AuthInitial) {
          return loc == '/' ? null : '/';
        }

        // 2. Not authenticated → login
        if (auth is AuthUnauthenticated) {
          return loc == '/login' ? null : '/login';
        }

        // 3. Authenticated
        if (auth is AuthAuthenticated) {
          final hasName =
              auth.account.name != null && auth.account.name!.trim().isNotEmpty;

          if (!hasName) {
            return loc == '/complete-profile' ? null : '/complete-profile';
          }

          if (loc == '/login' || loc == '/complete-profile' || loc == '/') {
            return '/home';
          }
        }

        // 4. Transient states (AuthLoading, OtpSent, AuthError,
        //    RegistrationRequired) → stay where we are.
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const PhoneInputPage(),
        ),
        GoRoute(
          path: '/complete-profile',
          name: 'completeProfile',
          builder: (context, state) => const CompleteProfilePage(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/order-detail',
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
          path: '/tracking',
          name: 'tracking',
          builder: (context, state) => const TrackingTab(),
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
/// Notifies when the **class** of state changes (not every emit).
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

  // 🔑 `late`, not `late final` — we reassign it on every state change.
  late AuthState _last;
  StreamSubscription<AuthState>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
