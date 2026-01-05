import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutingService {
  // Replace with your actual API Key
  static const String _apiKey = "AIzaSyBnMsdnzFmec_ey_-fHqkM6ywXv7VfaHbE"; 

  final PolylinePoints _polylinePoints = PolylinePoints();

  Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    print("RoutingService: Fetching route from $origin to $destination");
    
    PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: _apiKey,
      request: PolylineRequest(
        origin: PointLatLng(origin.latitude, origin.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.status == 'OK' && result.points.isNotEmpty) {
      print("RoutingService: Success! Found ${result.points.length} points.");
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      final msg = "Error: ${result.errorMessage ?? 'Unknown error'}, Status: ${result.status}";
      print("RoutingService: $msg");
      throw Exception(msg);
    }
  }
}
