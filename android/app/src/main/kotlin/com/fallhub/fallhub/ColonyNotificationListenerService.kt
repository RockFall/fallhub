package com.fallhub.fallhub

import android.app.Notification
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class ColonyNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        if (sbn.packageName == packageName) return
        if (sbn.isOngoing) return
        val notification = sbn.notification ?: return
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty()
        val body = when {
            bigText.isNotBlank() -> bigText
            else -> text
        }
        if (title.isBlank() && body.isBlank()) return

        val appLabel = try {
            val appInfo = packageManager.getApplicationInfo(sbn.packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            sbn.packageName
        }

        val payload = hashMapOf<String, Any?>(
            "nativeKey" to sbn.key,
            "packageName" to sbn.packageName,
            "appLabel" to appLabel,
            "title" to title,
            "text" to body,
            "postedAtMs" to sbn.postTime,
        )

        NotificationInbox.append(applicationContext, payload)
        val sink = NotificationChannels.eventSink
        if (sink != null) {
            Handler(Looper.getMainLooper()).post {
                sink.success(payload)
            }
        }
    }
}
