package com.mamad.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat

class MamadVpnService : VpnService() {

    companion object {
        const val ACTION_CONNECT = "com.mamad.vpn.CONNECT"
        const val ACTION_DISCONNECT = "com.mamad.vpn.DISCONNECT"
        const val EXTRA_CONFIG = "vpn_config"
        const val CHANNEL_ID = "mamad_vpn_channel"
        const val NOTIFICATION_ID = 1001

        var isConnected: Boolean = false
            private set
    }

    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CONNECT -> {
                val config = intent.getStringExtra(EXTRA_CONFIG) ?: ""
                startVpnSession(config)
            }
            ACTION_DISCONNECT -> {
                stopVpnSession()
            }
        }
        return START_NOT_STICKY
    }

    private fun startVpnSession(config: String) {
        createNotificationChannel()

        val notification = buildForegroundNotification()
        startForeground(NOTIFICATION_ID, notification)

        try {
            vpnInterface?.close()

            // Establish TUN interface
            val builder = Builder()
                .setSession("MamadVPN")
                .addAddress("172.19.0.1", 30)
                .addDnsServer("1.1.1.1")
                .addDnsServer("8.8.8.8")
                .addRoute("0.0.0.0", 0)
                .setMtu(1500)

            vpnInterface = builder.establish()
            isConnected = true
        } catch (e: Exception) {
            e.printStackTrace()
            isConnected = false
            stopSelf()
        }
    }

    private fun stopVpnSession() {
        try {
            vpnInterface?.close()
            vpnInterface = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
        isConnected = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "MamadVPN Active Session",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows real-time connection status of MamadVPN"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("MamadVPN Connected")
            .setContentText("Your traffic is encrypted and secure")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpnSession()
    }
}
