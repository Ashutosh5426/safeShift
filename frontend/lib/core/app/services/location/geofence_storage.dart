import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'geofence_detector.dart';

class GeofenceStorage {
  static const String _keyGeofences = 'geofences_list';

  static Future<void> saveGeofences(List<Geofence> geofences) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = geofences
        .map((g) => jsonEncode(g.toMap()))
        .toList();
    await prefs.setStringList(_keyGeofences, jsonList);
    print("Geofences saved: ${geofences.length}");
  }

  static Future<List<Geofence>> loadGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_keyGeofences);

    if (jsonList == null) {
      return [];
    }

    return jsonList
        .map((jsonStr) => Geofence.fromMap(jsonDecode(jsonStr)))
        .toList();
  }
}
