package com.safeShift.app
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val geolocatorChannelId = "geolocator_channel"
            val bgServiceChannelId = "bg_service_channel"

            val geolocatorChannel = NotificationChannel(
                geolocatorChannelId,
                "Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for location tracking"
            }

            val bgServiceChannel = NotificationChannel(
                bgServiceChannelId,
                "Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for background service"
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(geolocatorChannel)
            manager.createNotificationChannel(bgServiceChannel)
        }
    }
}
