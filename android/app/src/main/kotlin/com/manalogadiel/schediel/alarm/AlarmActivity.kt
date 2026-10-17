package com.manalogadiel.schediel.alarm

import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import com.manalogadiel.schediel.R

/**
 * Prominent alarm screen shown only where the OS permits a full-screen
 * intent. Shows the title and permitted body; Stop and Snooze never modify
 * schedule data.
 */
class AlarmActivity : Activity() {
    private var request: AlarmRequest? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        }
        setContentView(R.layout.activity_alarm)
        val key = intent.getStringExtra(AlarmReceiver.EXTRA_KEY)
        val current = key?.let { AlarmStore(this).find(it) }
        if (current == null) {
            finish()
            return
        }
        request = current
        findViewById<TextView>(R.id.alarm_title).text = current.title
        findViewById<TextView>(R.id.alarm_body).apply {
            text = current.body
            visibility = if (current.body.isEmpty()) View.GONE else View.VISIBLE
        }
        findViewById<Button>(R.id.alarm_stop).setOnClickListener {
            AlarmReceiver.stop(this, current)
            finish()
        }
        findViewById<Button>(R.id.alarm_snooze).apply {
            val minutes = current.snoozeMinutes
            if (minutes == null) {
                visibility = View.GONE
            } else {
                text = getString(R.string.alarm_snooze_minutes, minutes)
                setOnClickListener {
                    getSystemService(android.app.NotificationManager::class.java).cancel(current.requestCode)
                    AlarmScheduler(this@AlarmActivity).snooze(current, minutes)
                    finish()
                }
            }
        }
        findViewById<Button>(R.id.alarm_open).setOnClickListener {
            AlarmReceiver.stop(this, current)
            startActivity(AlarmScheduler.openIntent(this, current.deepLink))
            finish()
        }
    }
}
