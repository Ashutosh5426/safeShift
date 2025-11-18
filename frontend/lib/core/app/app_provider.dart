import 'package:flutter/material.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/routes/app_routes.dart';
import 'package:provider/provider.dart';

class AppProvider extends StatefulWidget {
  const AppProvider({super.key});

  @override
  State<AppProvider> createState() => _AppProviderState();
}

class _AppProviderState extends State<AppProvider> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, _, __) =>
          getIt<AppState>().loggedInState == LoggedState.loggedIn
          ? AppRoutes.contactListScreen()
          : AppRoutes.loginScreen(),
    );
  }
}
