import 'dart:io';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:frontend/core/app/services/location/location_repository.dart';
import 'package:frontend/feature/contacts/data/repository/contacts_repository.dart';
import 'package:frontend/core/api/api_client.dart';

class AlertService {
  final ContactsRepository _contactsRepository = ContactsRepository();

  /// Sends an SOS message to all contacts with the current location.
  Future<String> sendSOS() async {
    try {
      /// 1. Get Location
      final pos = await locationRepository.getLastLocation();
      final lat = pos.lat;
      final lng = pos.lng;

      /// 2. Get Address (Optional)
      String address = "Unknown Location";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          /// Construct a more detailed address
          final parts = [
            p.name,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode
          ].where((element) => element != null && element.isNotEmpty).toSet().toList(); 
          /// toSet() removes duplicates if any (e.g. if name == street)
          
          address = parts.join(", ");
        }
      } catch (e) {
        print("Error fetching address: $e");
      }

      /// 3. Get Contacts
      final contacts = await _contactsRepository.getAllContacts();
      if (contacts.isEmpty) {
        return "No emergency contacts found. Please add contacts first.";
      }

      final recipients = contacts.map((c) => c.phone).toList();

      /// 4. Construct Message
      final googleMapsLink = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
      final message = "SOS! I need help!\n\nLocation: $address\n$googleMapsLink";

      /// 5. Send SMS via url_launcher
      await _launchSMS(recipients, message);

      return "SMS App Opened";
    } catch (e) {
      print("SOS Error: $e");
      return "Failed to send SOS: $e";
    }
  }

  /// Sends an SOS message via WhatsApp Backend API
  Future<String> sendWhatsAppSOS() async {
    try {
      // 1. Get Location
      final pos = await locationRepository.getLastLocation();
      final lat = pos.lat;
      final lng = pos.lng;
      
      // 2. Get Contacts
      final contacts = await _contactsRepository.getAllContacts();
      if (contacts.isEmpty) {
        return "No contacts found";
      }

      final numbers = contacts.map((c) => c.phone).toList();
      final googleMapsLink = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
      final message = "SOS! I have been stationary for too long and may be in danger.\n\nLocation: $googleMapsLink";
      
      // 3. Send Request using ApiClient (handles baseUrl and headers)
      final dio = ApiClient.getDio();
      final response = await dio.post(
        "/api/whatsapp/send-sos",
        data: {
          "numbers": numbers,
          "message": message,
        },
      );

      if (response.statusCode == 200) {
        return "WhatsApp SOS Sent";
      } else {
        return "Failed to send WhatsApp SOS: ${response.statusCode}";
      }
    } catch (e) {
      print("WhatsApp SOS Error: $e");
      return "Error sending WhatsApp SOS: $e";
    }
  }

  Future<void> _launchSMS(List<String> recipients, String message) async {
    String _result = "";
    String _phones = recipients.join(",");
    
    /// Android uses comma or semicolon, iOS uses comma usually but sometimes requires specific handling.
    /// For simplicity, we use comma which works on most modern devices.
    if (Platform.isAndroid) {
       /// On some Android devices, '?' is used for body, on iOS '&' is sometimes preferred if not using 'sms:' properly.
       /// The 'sms:<phone>?body=<message>' is the standard URI scheme.
       final uri = Uri(
         scheme: 'sms',
         path: _phones,
         queryParameters: <String, String>{
           'body': message,
         },
       );
       
       if (await canLaunchUrl(uri)) {
         await launchUrl(uri);
       } else {
         throw 'Could not launch SMS';
       }
    } else if (Platform.isIOS) {
       /// iOS handling
       final uri = Uri(
         scheme: 'sms',
         path: _phones,
         queryParameters: <String, String>{
           'body': message,
         },
       );
       
       if (await canLaunchUrl(uri)) {
         await launchUrl(uri);
       } else {
         throw 'Could not launch SMS';
       }
    }
  }

  /// Calls the primary emergency contact.
  Future<bool> callPrimaryContact() async {
    try {
      final contacts = await _contactsRepository.getAllContacts();
      final primary = contacts.firstWhere(
        (c) => c.isPrimary,
        orElse: () => contacts.isNotEmpty ? contacts.first : throw Exception("No contacts"),
      );

      final Uri launchUri = Uri(
        scheme: 'tel',
        path: primary.phone,
      );

      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Call Error: $e");
      return false;
    }
  }
}
