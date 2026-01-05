import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/core/app/app_provider.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/app/services/notifications/notification_service.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/routes/app_routes.dart';
import 'package:frontend/core/routes/navigation_service.dart';
import 'package:frontend/core/shared_preferences/local_storage.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LocalStorage.init();
  await configureDependencies();

  /// Setup background service before running the app
  await initializeBackgroundService();

  runApp(const SafeShiftApp());
}

/// -------------------------------------------------------------
/// 🔥 BACKGROUND SERVICE INITIALIZATION
/// -------------------------------------------------------------
Future<void> initializeBackgroundService() async {
  // final service = FlutterBackgroundService();
  //
  // await service.configure(
  //   androidConfiguration: AndroidConfiguration(
  //     onStart: onStart,
  //     autoStart: true,
  //     isForegroundMode: true,
  //     notificationChannelId: 'location_channel',
  //     // foregroundServiceType: AndroidForegroundServiceType.location,
  //     initialNotificationTitle: 'SafeShift is tracking location',
  //     initialNotificationContent: 'Your location is being updated in background',
  //   ),
  //   iosConfiguration: IosConfiguration(
  //     onForeground: onStart,
  //     onBackground: onIosBackground,
  //   ),
  // );

  // start service automatically
  // service.startService();
}

/// Needed for iOS background fetch
// @pragma('vm:entry-point')
// bool onIosBackground(ServiceInstance service) {
//   return true;
// }

/// -------------------------------------------------------------
/// 🚀 BACKGROUND SERVICE ENTRY POINT (Runs in a separate isolate)
/// -------------------------------------------------------------
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) {
//   // Required for Android foreground
//   if (service is AndroidServiceInstance) {
//     service.setForegroundNotificationInfo(
//       title: "SafeShift Running",
//       content: "Tracking location…",
//     );
//   }
//
//   // listen for location updates sent from your LocationService
//   service.on("location_update").listen((data) {
//     // example:
//     // data = { "lat": 28.62, "lng": 77.23 }
//     print("Background location received: $data");
//   });
// }

/// -------------------------------------------------------------
/// 🚀 Main App Widget
/// -------------------------------------------------------------
class SafeShiftApp extends StatelessWidget {
  const SafeShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableProvider.value(
      value: getIt<AppState>(),
      child: MaterialApp(
        title: 'SafeShift',
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.initialRoute,
        onGenerateRoute: AppRoutes.generateRoute,
        navigatorKey: NavigationService.navigatorKey,
        home: ChangeNotifierProvider.value(
          value: getIt<AppState>(),
          child: const AppProvider(),
        ),
      ),
    );
  }
}
