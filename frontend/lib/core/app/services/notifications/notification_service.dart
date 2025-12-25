import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(settings);
  }

  static Future<void> showStationaryAlert(int level) async {
    String title = "Stationary Alert";
    String body = "You haven't moved for a while.";
    
    switch (level) {
      case 1:
        title = "Are you okay?";
        body = "You've been stationary for 2 minutes.";
        break;
      case 2:
        title = "Safety Check";
        body = "Still stationary. SOS will be sent in 2 minutes.";
        break;
      case 3:
        title = "Urgent Safety Check";
        body = "SOS will be sent in 1 minute! Please respond.";
        break;
      case 4:
        title = "SOS Triggered";
        body = "Sending SOS to your emergency contacts...";
        break;
    }

    await _plugin.show(
      1,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'stationary_channel',
          'Stationary Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
  static Future<void> showGeofenceAlert() async {
    await _plugin.show(
      2,
      "Geofence Breach",
      "You have left the safe zone!",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'geofence_channel',
          'Geofence Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> showTravelAlert() async {
    await _plugin.show(
      3,
      "Wrong Direction!",
      "You seem to be moving away from your destination.",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'travel_channel',
          'Travel Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
