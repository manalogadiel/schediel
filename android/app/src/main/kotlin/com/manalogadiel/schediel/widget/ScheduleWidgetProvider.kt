package com.manalogadiel.schediel.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.ZoneId

/**
 * Home screen widget. Renders the cached snapshot without a running Flutter
 * UI and requests its next render at the reader's R10 boundary with an
 * inexact, non-waking alarm; no exact refresh time is promised.
 */
class ScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        render(context, appWidgetManager, widgetData)
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        render(context, appWidgetManager, HomeWidgetPlugin.getData(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH) {
            updateAll(context)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        scheduleRefresh(context, null)
    }

    companion object {
        const val ACTION_REFRESH = "com.manalogadiel.schediel.widget.REFRESH"

        /** Window after a boundary within which the system may deliver the refresh. */
        private const val REFRESH_WINDOW_MS = 10 * 60 * 1000L

        fun updateAll(context: Context) {
            render(context, AppWidgetManager.getInstance(context), HomeWidgetPlugin.getData(context))
        }

        private fun render(context: Context, manager: AppWidgetManager, data: SharedPreferences) {
            val ids = manager.getAppWidgetIds(ComponentName(context, ScheduleWidgetProvider::class.java))
            val raw = data.getString(SnapshotReader.KEY, null)
            val zone = ZoneId.systemDefault()
            val now = System.currentTimeMillis()
            val renderer = WidgetRenderer(context, zone)
            var nextRefresh: Long? = null
            for (id in ids) {
                // Each placed widget reads its own projection, else "default".
                val result = SnapshotReader.read(raw, id.toString(), now, zone)
                manager.updateAppWidget(id, renderer.build(result, manager.getAppWidgetOptions(id), now))
                result.nextRefreshEpochMs?.let { at -> nextRefresh = nextRefresh?.let { minOf(it, at) } ?: at }
            }
            scheduleRefresh(context, if (ids.isEmpty()) null else nextRefresh)
        }

        private fun scheduleRefresh(context: Context, atEpochMs: Long?) {
            val alarms = context.getSystemService(AlarmManager::class.java)
            val pending = PendingIntent.getBroadcast(
                context,
                0,
                Intent(context, ScheduleWidgetProvider::class.java).setAction(ACTION_REFRESH),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            if (atEpochMs == null) {
                alarms.cancel(pending)
            } else {
                alarms.setWindow(AlarmManager.RTC, atEpochMs, REFRESH_WINDOW_MS, pending)
            }
        }
    }
}
