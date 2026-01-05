import 'package:frontend/core/app/services/location/position_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveMapController {
  GoogleMapController? mapController;
  Marker? userMarker;

  void init(GoogleMapController controller) {
    mapController = controller;
  }

  void updateUserMarker(PositionModel pos) {
    userMarker = Marker(
      markerId: const MarkerId("user"),
      position: LatLng(pos.lat, pos.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  void moveCamera(PositionModel pos) {
    mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(pos.lat, pos.lng),
      ),
    );
  }
}
