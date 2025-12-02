import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';

class PlacesService {
  // Replace with your actual API Key
  static const String _apiKey = "AIzaSyBnMsdnzFmec_ey_-fHqkM6ywXv7VfaHbE"; 
  late final places.FlutterGooglePlacesSdk _places;

  PlacesService() {
    _places = places.FlutterGooglePlacesSdk(_apiKey);
  }

  Future<List<Map<String, dynamic>>> getAutocomplete(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _places.findAutocompletePredictions(query);
      
      if (response.predictions.isNotEmpty) {
        return response.predictions.map((p) => {
          'description': p.fullText,
          'place_id': p.placeId,
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("PlacesService: Error fetching autocomplete: $e");
      return [
        {'description': 'Error: $e', 'place_id': ''}
      ];
    }
  }

  Future<LatLng?> getPlaceDetails(String placeId) async {
    try {
      final response = await _places.fetchPlace(
        placeId,
        fields: [places.PlaceField.Location],
      );

      if (response.place != null && response.place!.latLng != null) {
        final location = response.place!.latLng!;
        return LatLng(location.lat, location.lng);
      } else {
        print("PlacesService: Details error: Place not found or no location");
        return null;
      }
    } catch (e) {
      print("PlacesService: Error fetching details: $e");
      return null;
    }
  }
  Future<String?> getAddressFromLatLng(LatLng latLng) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_apiKey';
      print("PlacesService: Fetching address from $url");
      final response = await Dio().get(url);
      print("PlacesService: Response status: ${response.statusCode}");
      print("PlacesService: Response data: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        } else {
          print("PlacesService: Geocoding API Error: ${data['status']} - ${data['error_message']}");
        }
      }
      return null;
    } catch (e) {
      print("PlacesService: Error fetching address: $e");
      return null;
    }
  }
}
