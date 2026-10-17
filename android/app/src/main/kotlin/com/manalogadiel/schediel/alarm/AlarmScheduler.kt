package com.manalogadiel.schediel.alarm

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import com.manalogadiel.schediel.MainActivity

/** Accepted alarms, persisted so they can be re-armed after reboot without Flutter. */
class AlarmStore(context: Context) {
    private val prefs = context.getSharedPreferences("schediel_alarms", Context.MODE_PRIVATE)

    fun load(): List<AlarmRequest> = AlarmRequest.listFromJson(prefs.getString(KEY, null))

    fun save(list: List<AlarmRequest>) {
        prefs.edit().putString(KEY, AlarmRequest.listToJson(list)).apply()
    }

    fun find(requestKey: String): AlarmRequest? = load().firstOrNull { it.requestKey == requestKey }

    fun upsert(request: AlarmRequest) = save(load().filter { it.requestKey != request.requestKey } + request)

    fun remove(requestKey: String) = save(load().filter { it.requestKey != requestKey })

    private companion object {
        const val KEY = "accepted"
    }
}

/**
 * One-shot AlarmManager.setAlarmClock requests with stable request codes
 * (spec 7.2). Replace-all: after [replaceAll] native holds exactly the set
 * that was accepted.
 */
class AlarmScheduler(private val context: Context) {
    private val alarms = context.getSystemService(AlarmManager::class.java)
    private val store = AlarmStore(context)

    private fun canExact(): Boolean = Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()

    fun replaceAll(requests: List<AlarmRequest>): List<AlarmResult> {
        store.load().forEach { cancelNative(it) }
        val now = System.currentTimeMillis()
        val accepted = mutableListOf<AlarmRequest>()
        val results = requests.map { request ->
            when {
                request.triggerAtEpochMs <= now -> AlarmResult(request.requestKey, "pastTrigger")
                !canExact() -> AlarmResult(request.requestKey, "needsPermission")
                else -> try {
                    arm(request)
                    accepted += request
                    AlarmResult(request.requestKey, "scheduled")
                } catch (e: SecurityException) {
                    AlarmResult(request.requestKey, "needsPermission")
                } catch (e: Exception) {
                    AlarmResult(request.requestKey, "failed", "scheduleFailed")
                }
            }
        }
        store.save(accepted)
        return results
    }

    /** Stops a ringing alarm or cancels it before it rings; schedule data is untouched. */
    fun stop(request: AlarmRequest) {
        cancelNative(request)
        store.remove(request.requestKey)
    }

    fun cancelAll(): Int {
        val held = store.load()
        held.forEach { cancelNative(it) }
        store.save(emptyList())
        return held.size
    }

    /** Re-arms stored future alarms after reboot, update or clock changes. */
    fun rearmAll() {
        val now = System.currentTimeMillis()
        val kept = store.load().filter { it.triggerAtEpochMs > now }
        if (canExact()) {
            kept.forEach { runCatching { arm(it) } }
        }
        store.save(kept)
    }

    /** Snooze re-arms the same request key later; schedule data never changes. */
    fun snooze(request: AlarmRequest, minutes: Int) {
        val later = request.copy(triggerAtEpochMs = System.currentTimeMillis() + minutes * 60_000L)
        store.upsert(later)
        if (canExact()) runCatching { arm(later) }
    }

    fun arm(request: AlarmRequest) {
        val show = PendingIntent.getActivity(
            context,
            request.requestCode,
            openIntent(context, request.deepLink),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarms.setAlarmClock(AlarmManager.AlarmClockInfo(request.triggerAtEpochMs, show), firePendingIntent(request, PendingIntent.FLAG_UPDATE_CURRENT)!!)
    }

    private fun cancelNative(request: AlarmRequest) {
        firePendingIntent(request, PendingIntent.FLAG_NO_CREATE)?.let {
            alarms.cancel(it)
            it.cancel()
        }
        context.getSystemService(NotificationManager::class.java).cancel(request.requestCode)
    }

    private fun firePendingIntent(request: AlarmRequest, flag: Int): PendingIntent? = PendingIntent.getBroadcast(
        context,
        request.requestCode,
        AlarmReceiver.intent(context, AlarmReceiver.ACTION_FIRE, request),
        flag or PendingIntent.FLAG_IMMUTABLE,
    )

    companion object {
        fun openIntent(context: Context, deepLink: String): Intent =
            Intent(Intent.ACTION_VIEW, Uri.parse(deepLink), context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
}
