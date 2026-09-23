import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/complete_profile_page.dart';
import 'features/auth/presentation/pages/phone_input_page.dart';
import 'features/home/presentation/pages/home_page.dart';

class DeliverEthiopiaApp extends StatelessWidget {
  const DeliverEthiopiaApp({super.key});

  Widget _home(AuthState state) {
    if (state is AuthAuthenticated) {
      final account = state.account;
      final hasName = account.name != null && account.name!.trim().isNotEmpty;
      return hasName ? const HomePage() : const CompleteProfilePage();
    }
    return const PhoneInputPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deliver Ethiopia',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0A7E3D),
        useMaterial3: true,
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        bloc: sl<AuthBloc>(),
        builder: (_, state) => _home(state),
      ),
    );
  }
}
