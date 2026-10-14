package com.fallhub.fallhub

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

object PiggyWork {
    private const val UNIQUE = "piggy-sync"

    fun enqueue(context: Context) {
        val request = OneTimeWorkRequestBuilder<PiggyHeadlessWorker>().build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            UNIQUE,
            ExistingWorkPolicy.APPEND_OR_REPLACE,
            request,
        )
    }

    fun shouldWake(packageName: String, title: String, body: String): Boolean {
        val blob = "$title\n$body"
        if (blob.contains("R$")) return true
        val pkg = packageName.lowercase()
        return listOf("banco", "inter", "nubank", "itau", "bradesco", "picpay")
            .any { pkg.contains(it) }
    }
}

object PiggyMidnight {
    private const val REQUEST = 44021

    fun schedule(context: Context) {
        val alarm = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = Intent(context, PiggyMidnightReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            context,
            REQUEST,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val whenMs = nextSaoPauloMidnight()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarm.canScheduleExactAlarms()) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenMs, pending)
        } else {
            alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, whenMs, pending)
        }
    }

    fun nextSaoPauloMidnight(now: Instant = Instant.now()): Long {
        val zone = ZoneId.of("America/Sao_Paulo")
        val tomorrow = LocalDate.now(zone).plusDays(1).atStartOfDay(zone)
        return tomorrow.toInstant().toEpochMilli().coerceAtLeast(now.toEpochMilli() + 1000)
    }
}

object PiggyAlerts {
    private const val CHANNEL = "piggy_bank"
    private const val NOTIFICATION_ID = 44022

    fun showRed(context: Context, message: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL,
                context.getString(R.string.piggy_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            )
            manager.createNotificationChannel(channel)
        }
        val notification = Notification.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_piggy_notification)
            .setContentTitle(context.getString(R.string.piggy_alert_title))
            .setContentText(message)
            .setAutoCancel(true)
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }
}

class PiggyMidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        PiggyWork.enqueue(context)
        PiggyMidnight.schedule(context)
    }
}

class PiggyBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return
        PiggyMidnight.schedule(context)
        PiggyWork.enqueue(context)
    }
}
