package com.manalogadiel.schediel

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.manalogadiel.schediel.alarm.AlarmScheduler
import com.manalogadiel.schediel.widget.ScheduleWidgetProvider

/**
 * Restores derived native state without starting Flutter: re-arms accepted
 * alarms after reboot, app update or exact-alarm re-grant, and re-renders
 * widgets after time, time-zone or locale changes.
 */
class SystemEventsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            EXACT_ALARM_PERMISSION_CHANGED,
            -> {
                AlarmScheduler(context).rearmAll()
                ScheduleWidgetProvider.updateAll(context)
            }
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
            -> ScheduleWidgetProvider.updateAll(context)
        }
    }

    private companion object {
        const val EXACT_ALARM_PERMISSION_CHANGED = "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED"
    }
}
