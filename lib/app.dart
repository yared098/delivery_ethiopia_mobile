import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

class DeliverEthiopiaApp extends StatelessWidget {
  const DeliverEthiopiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the singleton AuthBloc at the top so every route can read it.
    return BlocProvider<AuthBloc>.value(
      value: sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Deliver Ethiopia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0A7E3D),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
