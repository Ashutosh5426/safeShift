import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/core/app/services/location/stationary_detector.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  /// Ensure plugin services are initialized
  DartPluginRegistrant.ensureInitialized();

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
    firstAlertDuration: const Duration(minutes: 5),
    secondAlertDuration: const Duration(minutes: 6),
    thirdAlertDuration: const Duration(minutes: 7),
  );

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    ),
  ).listen((pos) {
    bool shouldAlert = detector.check(pos);

    if (shouldAlert) {
      service.invoke("stationary_alert");
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


