package com.fallhub.fallhub

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews

class PiggyBankWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            render(context, appWidgetManager, id)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        render(context, appWidgetManager, appWidgetId)
    }

    companion object {
        const val PREFS = "HomeWidgetPreferences"

        fun publishSnapshot(context: Context, values: Map<*, *>) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString("piggy_balance", values["balance"]?.toString().orEmpty())
                .putString("piggy_spent_today", values["spentToday"]?.toString().orEmpty())
                .putString("piggy_available", values["available"]?.toString().orEmpty())
                .putString("piggy_debt", values["debt"]?.toString().orEmpty())
                .putString("piggy_status", values["status"]?.toString().orEmpty())
                .putString("piggy_week", values["week"]?.toString().orEmpty())
                .commit()
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, PiggyBankWidgetProvider::class.java)
            for (id in manager.getAppWidgetIds(component)) {
                render(context, manager, id)
            }
        }

        fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val options = manager.getAppWidgetOptions(id)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 40)
            val large = minHeight >= 100
            val layout = if (large) {
                R.layout.piggy_bank_widget_large
            } else {
                R.layout.piggy_bank_widget
            }
            val views = RemoteViews(context.packageName, layout)
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val balance = prefs.getString("piggy_balance", "Cofrinho")
            val spent = prefs.getString("piggy_spent", null)
                ?: prefs.getString("piggy_spent_today", "Hoje: —")
            val available = prefs.getString("piggy_available", "Pode gastar hoje: —")
            val debt = prefs.getString("piggy_debt", "") ?: ""
            val status = prefs.getString("piggy_status", "green")
            views.setTextViewText(R.id.piggy_balance, balance)
            views.setTextViewText(R.id.piggy_spent, spent)
            views.setTextViewText(R.id.piggy_available, available)
            views.setTextColor(R.id.piggy_balance, statusColor(status))
            views.setContentDescription(R.id.piggy_root, balance)
            if (large) {
                views.setTextViewText(R.id.piggy_debt, debt)
                views.setViewVisibility(
                    R.id.piggy_debt,
                    if (debt.isBlank()) View.GONE else View.VISIBLE,
                )
                val week = prefs.getString("piggy_week", "0,0,0,0,0,0,0") ?: "0,0,0,0,0,0,0"
                val values = week.split(",").map { it.trim().toIntOrNull() ?: 0 }
                val max = (values.maxOrNull() ?: 0).coerceAtLeast(1)
                val bars = intArrayOf(R.id.bar0, R.id.bar1, R.id.bar2, R.id.bar3, R.id.bar4, R.id.bar5, R.id.bar6)
                for (index in bars.indices) {
                    val value = values.getOrElse(index) { 0 }
                    views.setProgressBar(bars[index], max, value, false)
                }
            }
            val launch = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("colony://piggy")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                44020,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.piggy_root, pending)
            manager.updateAppWidget(id, views)
        }

        private fun statusColor(status: String?): Int {
            return when (status) {
                "red" -> Color.parseColor("#C62828")
                "yellow" -> Color.parseColor("#F9A825")
                else -> Color.parseColor("#2E7D32")
            }
        }
    }
}
