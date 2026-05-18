package com.adguard.trusttunnel.vpn_plugin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.TrafficStats
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Управляет уведомлением со скоростью VPN.
 * Показывается только когда VPN подключён и пользователь включил настройку.
 */
class SpeedNotificationManager(private val context: Context) {

    companion object {
        private const val CHANNEL_ID      = "tt_speed_channel"
        private const val NOTIFICATION_ID  = 9001
        private const val ACTION_STOP      = "com.adguard.trusttunnel.STOP_VPN"
        private const val UPDATE_INTERVAL  = 1000L // 1 секунда
    }

    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private val handler = Handler(Looper.getMainLooper())
    private var isRunning = false
    private var stopCallback: (() -> Unit)? = null

    // TrafficStats snapshot
    private var lastRxBytes = 0L
    private var lastTxBytes = 0L
    private var lastTime    = 0L

    // BroadcastReceiver для кнопки «Отключить»
    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            if (intent?.action == ACTION_STOP) {
                stopCallback?.invoke()
            }
        }
    }

    private val updateRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                updateNotification()
                handler.postDelayed(this, UPDATE_INTERVAL)
            }
        }
    }

    fun start(onStop: () -> Unit) {
        if (isRunning) return
        stopCallback = onStop
        isRunning    = true

        createChannel()

        val filter = IntentFilter(ACTION_STOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(stopReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(stopReceiver, filter)
        }

        // Сброс счётчиков
        lastRxBytes = TrafficStats.getTotalRxBytes()
        lastTxBytes = TrafficStats.getTotalTxBytes()
        lastTime    = System.currentTimeMillis()

        handler.post(updateRunnable)
    }

    fun stop() {
        if (!isRunning) return
        isRunning = false
        handler.removeCallbacks(updateRunnable)
        try { context.unregisterReceiver(stopReceiver) } catch (_: Exception) {}
        notificationManager.cancel(NOTIFICATION_ID)
        stopCallback = null
    }

    private fun updateNotification() {
        val now   = System.currentTimeMillis()
        val dt    = ((now - lastTime).coerceAtLeast(1)).toDouble() / 1000.0

        val rxNow = TrafficStats.getTotalRxBytes()
        val txNow = TrafficStats.getTotalTxBytes()

        val rxSpeed = ((rxNow - lastRxBytes) / dt).toLong()
        val txSpeed = ((txNow - lastTxBytes) / dt).toLong()

        lastRxBytes = rxNow
        lastTxBytes = txNow
        lastTime    = now

        val text = "↓ ${formatSpeed(rxSpeed)}   ↑ ${formatSpeed(txSpeed)}"
        notificationManager.notify(NOTIFICATION_ID, buildNotification(text))
    }

    private fun buildNotification(speedText: String): Notification {
        val stopIntent = PendingIntent.getBroadcast(
            context, 0,
            Intent(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        // Открыть приложение по тапу
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP }
        val contentIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("TrustTunnel VPN")
            .setContentText(speedText)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(contentIntent)
            .addAction(
                android.R.drawable.ic_delete,
                "Отключить",
                stopIntent,
            )
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Скорость VPN",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Показывает скорость VPN соединения"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun formatSpeed(bytesPerSec: Long): String = when {
        bytesPerSec < 0           -> "0 B/s"
        bytesPerSec < 1024        -> "$bytesPerSec B/s"
        bytesPerSec < 1024 * 1024 -> "${"%.1f".format(bytesPerSec / 1024.0)} KB/s"
        else                      -> "${"%.1f".format(bytesPerSec / 1024.0 / 1024.0)} MB/s"
    }
}
