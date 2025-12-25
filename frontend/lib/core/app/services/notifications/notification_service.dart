import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
  }

  static Future<void> showStationaryAlert() async {
    await _plugin.show(
      1,
      "You are stationary",
      "You haven't moved for 5 minutes",
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
}
