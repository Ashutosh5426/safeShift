import 'package:geolocator/geolocator.dart';

class Geofence {
  final String id;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  Geofence({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }

  factory Geofence.fromMap(Map<String, dynamic> map) {
    return Geofence(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      radiusMeters: map['radiusMeters'],
    );
  }
}

class GeofenceDetector {
  final List<Geofence> _geofences = [];

  void addGeofence(Geofence geofence) {
    // Remove existing with same ID if any
    _geofences.removeWhere((g) => g.id == geofence.id);
    _geofences.add(geofence);
    print("Geofence added: ${geofence.id} at ${geofence.latitude}, ${geofence.longitude} (r=${geofence.radiusMeters}m)");
  }

  void removeGeofence(String id) {
    _geofences.removeWhere((g) => g.id == id);
    print("Geofence removed: $id");
  }

  void clearGeofences() {
    _geofences.clear();
    print("All geofences cleared");
  }

  /// Returns true if the user is OUTSIDE all active geofences (Breach).
  /// Returns false if the user is INSIDE at least one geofence, or if no geofences are set.
  bool checkBreach(Position current) {
    if (_geofences.isEmpty) {
      return false; // No restrictions
    }

    bool insideAny = false;

    for (final geofence in _geofences) {
      double dist = Geolocator.distanceBetween(
        geofence.latitude,
        geofence.longitude,
        current.latitude,
        current.longitude,
      );

      if (dist <= geofence.radiusMeters) {
        insideAny = true;
        break; // Safe inside this one
      }
    }

    // If not inside any, it's a breach
    return !insideAny;
  }
}
