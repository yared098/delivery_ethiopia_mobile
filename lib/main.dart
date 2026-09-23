import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/storage/secure_storage.dart';
import 'di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Future<void> onLogout() async {
    sl<AuthBloc>().add(const LogoutEvent());
  }

  await setupLocator(onLogout: onLogout);

  final bloc = sl<AuthBloc>();
  final storage = sl<SecureStorage>();

  // Kick off session restore asynchronously (do NOT block runApp).
  // The splash screen covers the UI while we decide.
  Future<void>.microtask(() async {
    try {
      final has = await storage.hasSession;
      if (kDebugMode) debugPrint('🔍 cold start hasSession=$has');

      if (!has) {
        // No tokens → go to login, splash is dismissed
        bloc.add(const LogoutEvent());
        return;
      }

      // We have tokens → try to fetch the account.
      // If access is expired, the Dio interceptor auto-refreshes.
      bloc.add(const RefreshMeEvent());
    } catch (e) {
      if (kDebugMode) debugPrint('🔍 cold start failed: $e');
      bloc.add(const LogoutEvent());
    }
  });

  runApp(
    BlocProvider<AuthBloc>.value(
      value: bloc,
      child: const DeliverEthiopiaApp(),
    ),
  );
}
