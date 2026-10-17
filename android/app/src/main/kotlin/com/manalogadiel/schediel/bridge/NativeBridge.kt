package com.manalogadiel.schediel.bridge

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.AlarmClock
import android.provider.Settings
import com.manalogadiel.schediel.alarm.AlarmReceiver
import com.manalogadiel.schediel.alarm.AlarmRequest
import com.manalogadiel.schediel.alarm.AlarmScheduler
import com.manalogadiel.schediel.alarm.AlarmStore
import com.manalogadiel.schediel.alarm.ClockDays
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native side of contracts/native-bridge-v1.md. Expected states are returned
 * as typed values; unexpected failures become `native_error` without user
 * content. Nothing here logs titles, details or deep links.
 */
class NativeBridge(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.manalogadiel.schediel/native"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getCapabilities" -> result.success(capabilities())
                "requestAppAlarmAuthorization" -> result.success(appAlarmStatus())
                "openSystemSettings" -> result.success(openSettings(call.argument<String>("target") ?: "app"))
                "scheduleAlarms" -> {
                    val raw = call.argument<List<Map<String, Any?>>>("alarms") ?: emptyList()
                    val requests = raw.mapNotNull { AlarmRequest.fromMap(it) }
                    result.success(AlarmScheduler(context).replaceAll(requests).map { it.toMap() })
                }
                "cancelAllAlarms" -> result.success(AlarmScheduler(context).cancelAll())
                "stopAlarm" -> {
                    val request = call.argument<String>("requestKey")?.let { AlarmStore(context).find(it) }
                    if (request != null) AlarmScheduler(context).stop(request)
                    result.success(request != null)
                }
                "getScheduledAlarms" -> result.success(AlarmStore(context).load().map { it.requestKey })
                "launchClockAlarm" -> result.success(launchClock(call))
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("native_error", "Native operation failed", null)
        }
    }

    private fun exactStatus(): String {
        if (Build.VERSION.SDK_INT < 31) return "notRequired"
        val alarms = context.getSystemService(AlarmManager::class.java)
        return if (alarms.canScheduleExactAlarms()) "authorized" else "denied"
    }

    /**
     * Android alarms ring through a notification, so they also need
     * notifications and the alarm channel to be on.
     */
    private fun appAlarmStatus(): String {
        val notifications = context.getSystemService(NotificationManager::class.java)
        val channel = notifications.getNotificationChannel(AlarmReceiver.CHANNEL_ID)
        val canPresent = notifications.areNotificationsEnabled() &&
            (channel == null || channel.importance != NotificationManager.IMPORTANCE_NONE)
        return if (exactStatus() == "denied" || !canPresent) "denied" else "authorized"
    }

    private fun fullScreenStatus(): String {
        if (Build.VERSION.SDK_INT < 34) return "authorized"
        val notifications = context.getSystemService(NotificationManager::class.java)
        return if (notifications.canUseFullScreenIntent()) "authorized" else "denied"
    }

    private fun clockIntent() = Intent(AlarmClock.ACTION_SET_ALARM)

    private fun capabilities(): Map<String, Any?> = mapOf(
        "platform" to "android",
        "osVersion" to Build.VERSION.RELEASE,
        "apiLevel" to Build.VERSION.SDK_INT,
        "exactAlarms" to exactStatus(),
        "appAlarms" to appAlarmStatus(),
        "fullScreen" to fullScreenStatus(),
        "externalClock" to (clockIntent().resolveActivity(context.packageManager) != null),
    )

    private fun openSettings(target: String): Boolean {
        val pkg = context.packageName
        val intent = when (target) {
            "exactAlarms" -> if (Build.VERSION.SDK_INT >= 31) {
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$pkg"))
            } else {
                null
            }
            "fullScreen" -> if (Build.VERSION.SDK_INT >= 34) {
                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:$pkg"))
            } else {
                null
            }
            "notifications" -> Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
            else -> null
        } ?: Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg"))
        return try {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private fun launchClock(call: MethodCall): String {
        val hour = call.argument<Int>("hour") ?: return "failed"
        val minute = call.argument<Int>("minute") ?: return "failed"
        val message = call.argument<String>("message") ?: ""
        val weekdays = call.argument<List<Int>>("weekdays")
        val intent = clockIntent()
            .putExtra(AlarmClock.EXTRA_HOUR, hour)
            .putExtra(AlarmClock.EXTRA_MINUTES, minute)
            .putExtra(AlarmClock.EXTRA_MESSAGE, message)
            .putExtra(AlarmClock.EXTRA_SKIP_UI, false)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (!weekdays.isNullOrEmpty()) {
            intent.putIntegerArrayListExtra(AlarmClock.EXTRA_DAYS, ClockDays.toCalendarDays(weekdays))
        }
        if (intent.resolveActivity(context.packageManager) == null) return "unavailable"
        return try {
            context.startActivity(intent)
            "launched"
        } catch (e: ActivityNotFoundException) {
            "unavailable"
        } catch (e: SecurityException) {
            "failed"
        }
    }
}
