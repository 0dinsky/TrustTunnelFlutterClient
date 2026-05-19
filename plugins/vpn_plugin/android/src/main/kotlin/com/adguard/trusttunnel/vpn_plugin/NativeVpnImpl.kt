package com.adguard.trusttunnel.vpn_plugin

import android.app.NotificationManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.Build
import android.util.Log
import java.util.ArrayDeque
import java.util.Queue
import com.adguard.trusttunnel.AppNotifier
import com.adguard.trusttunnel.VpnService
import io.flutter.plugin.common.EventChannel
import java.io.File

class NativeVpnImpl(
    private val appContext: Context
) : EventChannel.StreamHandler, AppNotifier {

    private var events: EventChannel.EventSink? = null
    private var currentState = VpnManagerState.DISCONNECTED
    private val main = Handler(Looper.getMainLooper())

    val queryLogHandler: QueryLogStreamHandler = QueryLogStreamHandler()

    // Уведомление со скоростью
    private val speedNotification = SpeedNotificationManager(appContext)
    private var speedNotificationEnabled = false

    private val notifManager =
        appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        VpnService.startNetworkManager(appContext)
        val queryLogFile = File(appContext.filesDir, "query_log.dat")
        VpnService.setAppNotifier(queryLogFile, this)
    }

    fun startPrepared(ctx: Context, config: String) {
        Log.i("VPN_PLUGIN", "startPrepared()")
        VpnService.start(ctx, config)
    }

    fun stop() {
        Log.i("VPN_PLUGIN", "stop()")
        speedNotification.stop()
        VpnService.stop(appContext)
    }

    fun setSpeedNotificationEnabled(enabled: Boolean) {
        speedNotificationEnabled = enabled
        if (!enabled) {
            speedNotification.stop()
        } else if (currentState == VpnManagerState.CONNECTED) {
            startSpeedNotification()
        }
    }

    fun getCurrentState(): VpnManagerState = currentState

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.i("VPN_PLUGIN", "onListen() -> subscribe state notifier")
        this.events = events
        postEvent(currentState.ordinal)
    }

    override fun onCancel(arguments: Any?) {
        Log.i("VPN_PLUGIN", "onCancel() -> unsubscribe")
        try {
            events = null
        } catch (t: Throwable) {
            Log.w("VPN_PLUGIN", "clearStateNotifier failed", t)
        }
    }

    override fun onStateChanged(state: Int) {
        Log.i("VPN_PLUGIN", "onStateChanged($state)")
        currentState = VpnManagerState.entries[state]
        postEvent(state)

        // Управление уведомлением
        main.post {
            when (currentState) {
                VpnManagerState.CONNECTED -> {
                    if (speedNotificationEnabled) startSpeedNotification()
                    // Серия попыток отмены foreground-уведомления библиотеки:
                    // библиотека может пересоздать его после первой отмены,
                    // поэтому повторяем несколько раз с нарастающей задержкой.
                    for (delayMs in longArrayOf(300, 700, 1500, 3000, 5000)) {
                        main.postDelayed({ cancelForegroundServiceNotification() }, delayMs)
                    }
                }
                VpnManagerState.DISCONNECTED -> {
                    speedNotification.stop()
                }
                else -> {}
            }
        }
    }

    override fun onConnectionInfo(info: String) {
        Log.i("VPN_PLUGIN", "onConnectionInfo")
        queryLogHandler.onQueryLog(info)
    }

    private fun startSpeedNotification() {
        speedNotification.start {
            // Кнопка «Отключить» в уведомлении
            stop()
        }
    }

    /**
     * Отменяет foreground-уведомление «vpn.js is running in foreground»,
     * показываемое библиотекой trusttunnel-client-android.
     * Наше уведомление скорости (канал tt_speed_channel) при этом не трогается.
     *
     * Критерии совпадения (достаточно одного):
     *   • текст содержит "running in foreground"  — стандартная фраза Android foreground-service
     *   • текст содержит "vpn.js"                 — имя Go/JS-воркера библиотеки
     *   • канал уведомления НЕ является нашим tt_speed_channel И пакет отправителя совпадает с нашим
     *     И заголовок содержит "TrustTunnel"
     */
    private fun cancelForegroundServiceNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val ourPkg = appContext.packageName
                for (sbn in notifManager.activeNotifications) {
                    val channelId = sbn.notification.channelId ?: ""
                    val extras   = sbn.notification.extras
                    val title = extras?.getCharSequence("android.title")?.toString() ?: ""
                    val text  = extras?.getCharSequence("android.text")?.toString()  ?: ""
                    val pkg   = sbn.packageName ?: ""

                    // Наше уведомление со скоростью — не трогаем
                    if (channelId == SpeedNotificationManager.CHANNEL_ID) continue

                    val isVpnJsNotification =
                        text.contains("vpn.js", ignoreCase = true) ||
                        text.contains("running in foreground", ignoreCase = true)

                    val isTrustTunnelOwnNotif =
                        pkg == ourPkg &&
                        title.contains("TrustTunnel", ignoreCase = true)

                    if (isVpnJsNotification || isTrustTunnelOwnNotif) {
                        Log.d("VPN_PLUGIN", "cancel foreground notif id=${sbn.id} tag=${sbn.tag} channel=$channelId title=$title text=$text")
                        notifManager.cancel(sbn.tag, sbn.id)
                    }
                }
            } catch (e: Exception) {
                Log.w("VPN_PLUGIN", "cancelForegroundServiceNotification failed", e)
            }
        }
    }

    private fun postEvent(value: Any) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            events?.success(value)
        } else {
            main.post { events?.success(value) }
        }
    }
}

class QueryLogStreamHandler : EventChannel.StreamHandler {

    private var events: EventChannel.EventSink? = null
    private val main = Handler(Looper.getMainLooper())
    private val queue: Queue<String> = ArrayDeque()

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.i("VPN_PLUGIN", "QueryLog#onListen() -> subscribe state notifier")
        this.events = events
        for (log in queue) {
            postEvent(log)
        }
        queue.clear()
    }

    override fun onCancel(arguments: Any?) {
        Log.i("VPN_PLUGIN", "QueryLog#onCancel() -> unsubscribe")
        try {
            events = null
        } catch (t: Throwable) {
            Log.w("VPN_PLUGIN", "clearNotifier failed for QueryLog", t)
        }
    }

    private fun postEvent(value: Any) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            events?.success(value)
        } else {
            main.post { events?.success(value) }
        }
    }

    fun onQueryLog(log: String) {
        main.post {
            if (events == null) {
                queue.offer(log)
            } else {
                postEvent(log)
            }
        }
    }
}
