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

  // Only restore on TRUE cold start — not on every hot restart
  final bloc = sl<AuthBloc>();
  final storage = sl<SecureStorage>();

  if (bloc.state is AuthInitial) {
    if (await storage.hasSession) {
      bloc.add(const RefreshMeEvent());
    }
  }

  runApp(
    BlocProvider<AuthBloc>.value(
      value: bloc,
      child: const DeliverEthiopiaApp(),
    ),
  );
}
