import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/complete_profile_page.dart';
import 'features/auth/presentation/pages/phone_input_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/home/presentation/pages/home_page.dart';

class DeliverEthiopiaApp extends StatelessWidget {
  const DeliverEthiopiaApp({super.key});

  Widget _screen(AuthState state) {
    if (state is AuthInitial) return const SplashPage();

    if (state is AuthAuthenticated) {
      final account = state.account;
      final hasName = account.name != null && account.name!.trim().isNotEmpty;
      return hasName ? const HomePage() : const CompleteProfilePage();
    }

    if (state is AuthUnauthenticated) return const PhoneInputPage();

    // AuthLoading / OtpSent / AuthError / RegistrationRequired
    // are owned by the currently-pushed page — never swap the shell.
    return const PhoneInputPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deliver Ethiopia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0A7E3D),
        useMaterial3: true,
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        bloc: sl<AuthBloc>(),
        buildWhen: (prev, next) {
          // Never rebuild on transient flow states
          if (next is AuthLoading) return false;
          if (next is OtpSent) return false;
          if (next is AuthError) return false;
          if (next is RegistrationRequired) return false;

          // Rebuild only when the class actually changes
          // (AuthInitial → AuthUnauthenticated → AuthAuthenticated → ...)
          return prev.runtimeType != next.runtimeType;
        },
        builder: (_, state) => _screen(state),
      ),
    );
  }
}
