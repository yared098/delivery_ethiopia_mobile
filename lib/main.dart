import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/notifications/push_service.dart';
import 'core/storage/secure_storage.dart';
import 'di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Firebase ──
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    debugPrint('🔥 Firebase: ${Firebase.app().options.projectId}');
  }

  // ── 2. onLogout — also detaches this device from FCM ──
  Future<void> onLogout() async {
    // The AuthBloc.LogoutEvent already handles device-token removal.
    // This callback fires only when the interceptor detects a dead session.
    sl<AuthBloc>().add(const LogoutEvent());
  }

  // ── 3. DI ──
  await setupLocator(onLogout: onLogout);

  // ── 4. Push service ──
  final push = sl<PushService>();
  if (push.isSupported) {
    await push.initialize();
  }

  // ── 5. Session restore (non-blocking) ──
  final bloc = sl<AuthBloc>();
  final storage = sl<SecureStorage>();

  Future<void>.microtask(() async {
    try {
      final has = await storage.hasSession;
      if (kDebugMode) debugPrint('🔍 cold start hasSession=$has');

      if (!has) {
        bloc.add(const NoSessionEvent()); // ← use NoSessionEvent
        return;
      }
      bloc.add(const RefreshMeEvent());
    } catch (e) {
      if (kDebugMode) debugPrint('🔍 cold start failed: $e');
      bloc.add(const NoSessionEvent());
    }
  });

  runApp(
    BlocProvider<AuthBloc>.value(
      value: bloc,
      child: const DeliverEthiopiaApp(),
    ),
  );
}
