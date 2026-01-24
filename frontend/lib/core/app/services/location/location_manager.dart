import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'background_location_service.dart';
import 'location_repository.dart';
import 'package:frontend/core/app/services/location/geofence_detector.dart';
import 'package:frontend/core/app/services/location/geofence_storage.dart';
import 'package:frontend/core/app/services/notifications/notification_service.dart';
import 'package:frontend/core/app/services/alert_service.dart';

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
    print("LocationManager: startBackgroundTracking invoked");
    await initializeService();
    final service = FlutterBackgroundService();
    print("LocationManager: Calling service.startService()");
    await service.startService();
    print("LocationManager: service.startService() returned");
  }

  Future<void> stopBackgroundTracking() async {
    print("LocationManager: stopBackgroundTracking invoked");
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  final StreamController<int> _stationaryAlertController = StreamController.broadcast();
  Stream<int> get stationaryAlertStream => _stationaryAlertController.stream;

  // Stream for stationary reset acknowledgement
  final _stationaryResetController = StreamController<void>.broadcast();
  Stream<void> get stationaryResetStream => _stationaryResetController.stream;

  void registerBackgroundListeners() {
    final service = FlutterBackgroundService();

    service.on("location_update").listen((data) {
      if (data != null) {
        try {
          final pos = Position(
            longitude: data['lng'] as double,
            latitude: data['lat'] as double,
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

    service.on("stationary_alert").listen((data) {
      if (data != null && data['level'] != null) {
        int level = data['level'];
        NotificationService.showStationaryAlert(level);
        _stationaryAlertController.add(level);
        
        if (level == 4) {
           // Trigger SOS
           print("LocationManager: Triggering SOS!");
           // We use a slight delay to ensure the notification is shown first
           Future.delayed(const Duration(seconds: 1), () async {
             // Use the new WhatsApp SOS method
             final result = await AlertService().sendWhatsAppSOS();
             print("LocationManager SOS Result: $result");
             
             // Optional: Also trigger the local SMS SOS as a fallback or parallel action
             // AlertService().sendSOS(); 
           });
        }
      }
    });
    service.on("geofence_alert").listen((_) {
      print("GEOFENCE ALERT RECEIVED");
      NotificationService.showGeofenceAlert();
    });

    service.on("travel_alert").listen((_) {
      print("TRAVEL ALERT RECEIVED");
      NotificationService.showTravelAlert();
    });
  }

  void startTravel(List<LatLng> route) {
    final service = FlutterBackgroundService();

    final routeList = route.map((p) => {
      'lat': p.latitude,
      'lng': p.longitude,
    }).toList();

    service.invoke("start_travel", {
      "route": routeList,
    });
  }

  void stopTravel() {
    final service = FlutterBackgroundService();
    service.invoke("stop_travel");
  }

  Future<void> addGeofence(Geofence geofence) async {
    final list = await GeofenceStorage.loadGeofences();
    list.removeWhere((g) => g.id == geofence.id);
    list.add(geofence);
    await GeofenceStorage.saveGeofences(list);

    final service = FlutterBackgroundService();
    service.invoke("reload_geofences");
  }

  Future<void> removeGeofence(String id) async {
    final list = await GeofenceStorage.loadGeofences();
    list.removeWhere((g) => g.id == id);
    await GeofenceStorage.saveGeofences(list);

    final service = FlutterBackgroundService();
    service.invoke("reload_geofences");
  }

  Future<void> clearGeofences() async {
    await GeofenceStorage.saveGeofences([]);
    final service = FlutterBackgroundService();
    service.invoke("reload_geofences");
  }

  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  void resetStationary() {
    final service = FlutterBackgroundService();
    service.invoke("reset_stationary");
  }
}
