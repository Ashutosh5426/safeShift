import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/core/app/app_provider.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/shared_preferences/local_storage.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalStorage.init();
  await configureDependencies();
  runApp(const SafeShiftApp());
}

class SafeShiftApp extends StatelessWidget {
  const SafeShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableProvider.value(
      value: getIt<AppState>(),
      child: MaterialApp(
        title: 'SafeShift',
        debugShowCheckedModeBanner: false,
        home: ChangeNotifierProvider.value(
          value: getIt<AppState>(),
          child: const AppProvider(),
        ),
      ),
    );
  }
}
