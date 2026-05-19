// plugins/vpn_plugin/android/src/main/kotlin/com/adguard/trusttunnel/vpn_plugin/VpnPlugin.kt
package com.adguard.trusttunnel.vpn_plugin

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService as AndroidVpnService
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry

class VpnPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.RequestPermissionsResultListener,
    IVpnManager {

    companion object {
        private const val REQ_VPN_PREPARE           = 1001
        private const val REQ_POST_NOTIFICATIONS    = 1002
        private const val STATE_CHANNEL_NAME        = "vpn_plugin_event_channel"
        private const val QUERY_LOG_CHANNEL_NAME    = "vpn_plugin_event_channel_query_log"
    }

    private lateinit var appContext: Context
    private var activity: Activity? = null

    private var stateChannel: EventChannel? = null
    private var queryLogChannel: EventChannel? = null
    
    private lateinit var vpnImpl: NativeVpnImpl

    private lateinit var deepLinkImpl: DeepLinkImpl

    private var pendingConfig: String? = null

    /** Pending value for setSpeedNotificationEnabled waiting for permission result. */
    private var pendingSpeedEnabled: Boolean? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        val messenger: BinaryMessenger = binding.binaryMessenger

        vpnImpl = NativeVpnImpl(appContext)

        IVpnManager.setUp(messenger, this)

        deepLinkImpl = DeepLinkImpl()

        IDeepLink.setUp(messenger, deepLinkImpl)

        stateChannel = EventChannel(messenger, STATE_CHANNEL_NAME).apply {
            setStreamHandler(vpnImpl)
        }

        queryLogChannel = EventChannel(messenger, QUERY_LOG_CHANNEL_NAME).apply {
            setStreamHandler(vpnImpl.queryLogHandler)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stateChannel?.setStreamHandler(null)
        queryLogChannel?.setStreamHandler(null)
        stateChannel = null
        queryLogChannel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQ_VPN_PREPARE) {
            val cfg = pendingConfig
            pendingConfig = null
            if (cfg != null && resultCode == Activity.RESULT_OK) {
                val ctx = activity ?: appContext
                vpnImpl.startPrepared(ctx, cfg)
            }
            return true
        }
        return false
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == REQ_POST_NOTIFICATIONS) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            val pending = pendingSpeedEnabled
            pendingSpeedEnabled = null
            if (pending == true && granted) {
                vpnImpl.setSpeedNotificationEnabled(true)
            }
            return true
        }
        return false
    }

    override fun start(config: String) {
        val act = activity
        if (act != null) {
            val prepare = AndroidVpnService.prepare(act)
            if (prepare == null) {
                vpnImpl.startPrepared(act, config)
            } else {
                pendingConfig = config
                act.startActivityForResult(prepare, REQ_VPN_PREPARE)
            }
        } else {
            val prepare = AndroidVpnService.prepare(appContext)
            if (prepare == null) {
                vpnImpl.startPrepared(appContext, config)
            }
        }
    }

    override fun stop() {
        vpnImpl.stop()
    }

    override fun updateConfiguration(config: String?) {
        // Do nothing, this is iOS specific
    }

    override fun getCurrentState(): VpnManagerState {
        return vpnImpl.getCurrentState()
    }

    override fun setSpeedNotificationEnabled(enabled: Boolean) {
        if (!enabled) {
            vpnImpl.setSpeedNotificationEnabled(false)
            return
        }

        // На Android 13+ нужно явно запросить разрешение POST_NOTIFICATIONS
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val act = activity
            if (act != null &&
                ContextCompat.checkSelfPermission(act, Manifest.permission.POST_NOTIFICATIONS)
                    != PackageManager.PERMISSION_GRANTED
            ) {
                pendingSpeedEnabled = true
                ActivityCompat.requestPermissions(
                    act,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    REQ_POST_NOTIFICATIONS,
                )
                return
            }
        }

        vpnImpl.setSpeedNotificationEnabled(true)
    }
}