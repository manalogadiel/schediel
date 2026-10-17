package com.manalogadiel.schediel.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import com.manalogadiel.schediel.R

/** Posts the alarm when it fires and handles Stop/Snooze. Never edits schedules. */
class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_FIRE = "com.manalogadiel.schediel.alarm.FIRE"
        const val ACTION_STOP = "com.manalogadiel.schediel.alarm.STOP"
        const val ACTION_SNOOZE = "com.manalogadiel.schediel.alarm.SNOOZE"
        const val EXTRA_KEY = "requestKey"
        const val CHANNEL_ID = "schediel_alarms"

        /** An unanswered alarm stops ringing after this long. */
        private const val RING_TIMEOUT_MS = 10 * 60 * 1000L

        /** Unique data per request key keeps PendingIntents distinct even if request codes collide. */
        fun intent(context: Context, action: String, request: AlarmRequest): Intent =
            Intent(context, AlarmReceiver::class.java)
                .setAction(action)
                .setData(Uri.Builder().scheme("schediel-alarm").opaquePart(request.requestKey).build())
                .putExtra(EXTRA_KEY, request.requestKey)

        fun ensureChannel(context: Context) {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(CHANNEL_ID) != null) return
            val channel = NotificationChannel(CHANNEL_ID, context.getString(R.string.alarm_channel_name), NotificationManager.IMPORTANCE_HIGH)
            channel.description = context.getString(R.string.alarm_channel_description)
            channel.setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build(),
            )
            channel.enableVibration(true)
            channel.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            manager.createNotificationChannel(channel)
        }

        fun stop(context: Context, request: AlarmRequest) {
            context.getSystemService(NotificationManager::class.java).cancel(request.requestCode)
            AlarmStore(context).remove(request.requestKey)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val key = intent.getStringExtra(EXTRA_KEY) ?: return
        val request = AlarmStore(context).find(key) ?: return
        when (intent.action) {
            ACTION_FIRE -> post(context, request)
            ACTION_STOP -> stop(context, request)
            ACTION_SNOOZE -> {
                context.getSystemService(NotificationManager::class.java).cancel(request.requestCode)
                request.snoozeMinutes?.let { AlarmScheduler(context).snooze(request, it) }
            }
        }
    }

    private fun post(context: Context, request: AlarmRequest) {
        ensureChannel(context)
        val manager = context.getSystemService(NotificationManager::class.java)
        val screen = PendingIntent.getActivity(
            context,
            request.requestCode,
            Intent(context, AlarmActivity::class.java)
                .putExtra(EXTRA_KEY, request.requestKey)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setContentTitle(request.title)
            .setContentText(request.body)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(screen)
            .setTimeoutAfter(RING_TIMEOUT_MS)
            .addAction(action(context, request, ACTION_STOP, R.string.alarm_stop))
        request.snoozeMinutes?.let {
            builder.addAction(action(context, request, ACTION_SNOOZE, R.string.alarm_snooze))
        }
        val fullScreenAllowed = Build.VERSION.SDK_INT < 34 || manager.canUseFullScreenIntent()
        if (request.prominent && fullScreenAllowed) builder.setFullScreenIntent(screen, true)
        val notification = builder.build()
        notification.flags = notification.flags or Notification.FLAG_INSISTENT
        manager.notify(request.requestCode, notification)
    }

    private fun action(context: Context, request: AlarmRequest, action: String, label: Int): Notification.Action {
        val pending = PendingIntent.getBroadcast(
            context,
            request.requestCode + action.hashCode(),
            intent(context, action, request),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Action.Builder(null, context.getString(label), pending).build()
    }
}
