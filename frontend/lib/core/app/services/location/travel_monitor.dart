import 'dart:math';
import 'package:geolocator/geolocator.dart';

class TravelMonitor {
  List<Map<String, double>>? _routePoints; // Simplified LatLng for background
  DateTime? _wrongDirectionStartTime;
  
  // Configurable threshold
  final Duration deviationThreshold = const Duration(seconds: 30); // Quicker for testing
  final double maxCrossTrackError = 50.0; // Meters allowed off-path

  bool get isActive => _routePoints != null && _routePoints!.isNotEmpty;

  void start(List<Map<String, double>> route) {
    _routePoints = route;
    _wrongDirectionStartTime = null;
    print("TravelMonitor: Started with ${route.length} route points.");
  }

  void stop() {
    _routePoints = null;
    _wrongDirectionStartTime = null;
    print("TravelMonitor: Stopped.");
  }

  /// Returns true if "Route Deviation" alert should be triggered.
  bool check(Position currentPos) {
    if (!isActive) return false;

    // Calculate Cross-Track Error (shortest distance to the polyline)
    double minDistance = double.infinity;

    for (int i = 0; i < _routePoints!.length - 1; i++) {
      final p1 = _routePoints![i];
      final p2 = _routePoints![i + 1];
      
      final dist = _distanceToSegment(
        currentPos.latitude, currentPos.longitude,
        p1['lat']!, p1['lng']!,
        p2['lat']!, p2['lng']!
      );
      
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    print("TravelMonitor: Off-track by ${minDistance.toStringAsFixed(1)}m");

    if (minDistance > maxCrossTrackError) {
      // We are OFF TRACK
      if (_wrongDirectionStartTime == null) {
        _wrongDirectionStartTime = DateTime.now();
        print("TravelMonitor: DEVIATION DETECTED. Timer started.");
      } else {
        final duration = DateTime.now().difference(_wrongDirectionStartTime!);
        print("TravelMonitor: Deviating for ${duration.inSeconds}s");
        
        if (duration >= deviationThreshold) {
          _wrongDirectionStartTime = DateTime.now(); // Reset to avoid spam, or keep alerting
          return true;
        }
      }
    } else {
      // Back on track
      if (_wrongDirectionStartTime != null) {
        print("TravelMonitor: Back on track. Timer reset.");
        _wrongDirectionStartTime = null;
      }
    }

    return false;
  }

  // Helper to calculate distance from point (p) to line segment (v-w)
  double _distanceToSegment(double pLat, double pLng, double vLat, double vLng, double wLat, double wLng) {
    final l2 = _distSq(vLat, vLng, wLat, wLng);
    if (l2 == 0) return _dist(pLat, pLng, vLat, vLng);

    var t = ((pLat - vLat) * (wLat - vLat) + (pLng - vLng) * (wLng - vLng)) / l2;
    t = max(0, min(1, t));

    final projLat = vLat + t * (wLat - vLat);
    final projLng = vLng + t * (wLng - vLng);

    return _dist(pLat, pLng, projLat, projLng);
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  double _distSq(double lat1, double lng1, double lat2, double lng2) {
    // Approximate squared distance in degrees (sufficient for segment projection ratio)
    // For real distance, use Geolocator, but for 't' calculation, Euclidean on lat/lng is okay for small segments.
    // Actually, let's just use Euclidean on lat/lng degrees for projection ratio 't'.
    final dLat = lat1 - lat2;
    final dLng = lng1 - lng2;
    return dLat * dLat + dLng * dLng;
  }
}
