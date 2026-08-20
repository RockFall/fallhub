package com.fallhub.fallhub

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

internal object NotificationChannels {
    const val METHODS = "colony/notifications"
    const val EVENTS = "colony/notifications/events"

    @Volatile
    var eventSink: EventChannel.EventSink? = null

    fun register(activity: MainActivity, flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHODS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isListenerEnabled" -> result.success(isListenerEnabled(activity))
                    "openListenerSettings" -> {
                        activity.startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS),
                        )
                        result.success(null)
                    }
                    "drainInbox" -> result.success(NotificationInbox.drain(activity))
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun isListenerEnabled(activity: MainActivity): Boolean {
        val cn = ComponentName(activity, ColonyNotificationListenerService::class.java)
        val flat = Settings.Secure.getString(
            activity.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return flat.split(':').any { entry ->
            val parsed = ComponentName.unflattenFromString(entry)
            parsed == cn || entry.contains(activity.packageName)
        }
    }
}
