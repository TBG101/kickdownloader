package com.example.kickdownloader

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat


class MyService : Service() {
    val notificationId = 1
    private lateinit var wakeLock: PowerManager.WakeLock


    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Create a notification with low priority
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }

        val notification =
            NotificationCompat.Builder(this, "channel_id").setContentTitle("Foreground Service")
                .setContentText("This service is running in the background")
                .setSmallIcon(R.drawable.offline_dialog_default_icon_42dp)

                .setPriority(NotificationCompat.PRIORITY_MIN) // Set low priority
                .build()

        // Start the service as foreground with the given notification
        acquireWifiLock()
        acquireWakeLock()
        startForeground(1, notification)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        // Release the wakelock when the service is destroyed
        releaseWakeLock()
        releaseWifiLock()
    }


    override fun onBind(intent: Intent): IBinder? {
        // Service doesn't support binding, return null
        return null
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "channelName"
            val descriptionText = "descrip^tion channel"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel("channel_id", name, importance).apply {
                description = descriptionText
            }
            // Register the channel with the system
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "app:wakelock.")
        wakeLock.acquire()
    }

    private fun releaseWakeLock() {
        if (wakeLock.isHeld) {
            wakeLock.release()
        }
    }

    private var wifiLock: WifiManager.WifiLock? = null

    fun acquireWifiLock() {
        val wifiManager = applicationContext.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        wifiLock = wifiManager.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "YourWifiLockTag")
        wifiLock?.acquire()
    }

    fun releaseWifiLock() {
        wifiLock?.release()
    }

}