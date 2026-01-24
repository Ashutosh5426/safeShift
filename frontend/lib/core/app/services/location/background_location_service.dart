import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/core/app/services/alert_service.dart';
import 'package:frontend/core/app/services/location/stationary_detector.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:geolocator/geolocator.dart';

import 'package:frontend/core/app/di/injections.dart'; 

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print("BackgroundService: onStart called!");
  WidgetsFlutterBinding.ensureInitialized();
  /// Ensure plugin services are initialized
  DartPluginRegistrant.ensureInitialized();

  try {
    // Initialize dependencies (GetIt, dotenv, LocalStorage) for this isolate
    print("BackgroundService: Configuring dependencies...");
    await configureDependencies();
    print("BackgroundService: Dependencies configured.");
    
    if (!getIt.isRegistered<AppState>()) {
        print("BackgroundService: AppState NOT registered! Registering manually.");
        getIt.registerSingleton<AppState>(AppState());
    } else {
        print("BackgroundService: AppState is registered.");
    }
  } catch (e, stack) {
    print("BackgroundService: Dependency initialization failed: $e\n$stack");
    // Attempt fallback registration
    try {
        if (!getIt.isRegistered<AppState>()) {
             getIt.registerSingleton<AppState>(AppState());
        }
    } catch (e2) {
        print("BackgroundService: Fallback registration failed: $e2");
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    /// Explicitly set notification info on start to ensure it's valid
    service.setForegroundNotificationInfo(
      title: "SafeShift Active",
      content: "Tracking location...",
    );
  }

  service.on('stopService').listen((event) {
    print("BackgroundService: stopService received. Stopping self.");
    service.stopSelf();
  });

  final detector = StationaryDetector(
    radiusMeters: 50,
    level1Duration: const Duration(seconds: 30),
    level2Duration: const Duration(seconds: 45),
    level3Duration: const Duration(seconds: 60),
    level4Duration: const Duration(seconds: 75),
  );

  bool _isStationaryDetectionActive = true;
  bool _isSosTriggered = false;

  service.on('reset_stationary').listen((event) {
    print("BackgroundService: Resetting stationary detector.");
    detector.reset();
    _isStationaryDetectionActive = true;
    print("BackgroundService: Stationary detection RESUMED.");
    
    // Trigger "I am Safe" message ONLY if SOS was previously triggered
    if (_isSosTriggered) {
        AlertService().sendWhatsAppSafeMessage().then((result) {
        print("BackgroundService: Safe message result: $result");
        });
        _isSosTriggered = false; // Reset flag after sending message
    } else {
        print("BackgroundService: SOS was not triggered, skipping Safe Message.");
    }
  });

  Position? lastKnownPosition;

  // Periodic check to trigger alerts even if GPS is silent (stationary)
  Timer.periodic(const Duration(seconds: 5), (timer) {
    if (!_isStationaryDetectionActive) return;

    if (lastKnownPosition != null) {
      int alertLevel = detector.check(lastKnownPosition!);
      if (alertLevel > 0) {
        service.invoke("stationary_alert", {"level": alertLevel});

        if (alertLevel == 4) {
          print("BackgroundService (Timer): Level 4 reached! Triggering SOS.");
          _isStationaryDetectionActive = false;
          _isSosTriggered = true;
          print("BackgroundService: Stationary detection PAUSED until reset.");
        }
      }
    }
  });

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    ),
  ).listen((pos) async {
    lastKnownPosition = pos; // Update last known position

    if (_isStationaryDetectionActive) {
      int alertLevel = detector.check(pos);

      if (alertLevel > 0) {
        service.invoke("stationary_alert", {"level": alertLevel});
        
        if (alertLevel == 4) {
          print("BackgroundService: Level 4 reached! Triggering SOS.");
          _isStationaryDetectionActive = false;
          _isSosTriggered = true;
          print("BackgroundService: Stationary detection PAUSED until reset.");
          // We need to trigger SOS. Since AlertService depends on UI/Plugins that might not work fully in background isolate
          // without proper setup, we invoke the main isolate to handle it if possible, OR try to run it here.
          // Best practice: Invoke main isolate to handle complex plugin interactions if UI is involved, 
          // but for SMS/Call we might need to do it here or ensure AlertService works.
          // However, 'url_launcher' might not work in background isolate on some platforms.
          // Let's invoke the main UI to handle the actual SOS call/SMS if the app is alive.
          // If the app is terminated, this background service is running headless.
          // For now, we send the event. The main isolate (LocationManager) will listen and trigger AlertService.
        }
      }
    }

    service.invoke("location_update", {
      "lat": pos.latitude,
      "lng": pos.longitude,
      "time": DateTime.now().toIso8601String(),
    });

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "SafeShift Active",
        content: "Tracking location for safety...",
      );
    }

    print("Background Location: ${pos.latitude}, ${pos.longitude}");
  }, onError: (e) {
    print("Background Location Error: $e");
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description:
        'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      /// this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      /// auto start service
      autoStart: false,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'SafeShift Service',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}


