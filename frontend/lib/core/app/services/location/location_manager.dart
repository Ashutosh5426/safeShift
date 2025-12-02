import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'background_location_service.dart';
import 'location_repository.dart';

import 'package:frontend/core/app/services/notifications/notification_service.dart';

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();

  factory LocationManager() => _instance;

  LocationManager._internal() {
    registerBackgroundListeners();
  }

  final StreamController<Position> _foregroundController =
      StreamController.broadcast();

  Stream<Position> get foregroundStream => _foregroundController.stream;

  StreamSubscription<Position>? _foregroundSubscription;

  Future<void> startForegroundTracking() async {
    await stopForegroundTracking(); // Cancel existing if any

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      _foregroundSubscription = stream.listen((pos) {
        _foregroundController.add(pos);
        locationRepository.emit(pos);
      });
    } else {
      print("Location permission not granted!");
    }
  }

  Future<void> stopForegroundTracking() async {
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }

  Future<void> startBackgroundTracking() async {
    await initializeService();
    final service = FlutterBackgroundService();
    await service.startService();
  }

  Future<void> stopBackgroundTracking() async {
    print("LocationManager: stopBackgroundTracking invoked");
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  void registerBackgroundListeners() {
    final service = FlutterBackgroundService();

    service.on("location_update").listen((data) {
      if (data != null) {
        try {
          final pos = Position(
            longitude: data['lng'],
            latitude: data['lat'],
            timestamp: DateTime.parse(data['time']),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          locationRepository.emit(pos);
        } catch (e) {
          print("Error parsing background location: $e");
        }
      }
    });

    service.on("stationary_alert").listen((_) {
      print("STATIONARY ALERT RECEIVED");
      NotificationService.showStationaryAlert();
    });
  }

  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
