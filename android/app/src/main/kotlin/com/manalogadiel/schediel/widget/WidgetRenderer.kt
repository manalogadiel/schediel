package com.manalogadiel.schediel.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.graphics.Typeface
import android.icu.text.SimpleDateFormat
import android.icu.util.TimeZone
import android.net.Uri
import android.os.Bundle
import android.text.SpannableString
import android.text.Spanned
import android.text.format.DateFormat
import android.text.style.StyleSpan
import android.view.View
import android.widget.RemoteViews
import com.manalogadiel.schediel.MainActivity
import com.manalogadiel.schediel.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.Date

/**
 * Builds RemoteViews for one widget instance from a [ReadResult]. Text comes
 * only from the snapshot and approved labels; the root stays transparent.
 */
class WidgetRenderer(private val context: Context, private val zone: ZoneId) {
    private val locale = context.resources.configuration.locales[0]
    private val icuZone = TimeZone.getTimeZone(zone.id)
    private val timeFormat = SimpleDateFormat(
        DateFormat.getBestDateTimePattern(locale, if (DateFormat.is24HourFormat(context)) "Hm" else "hm"),
        locale,
    ).apply { timeZone = icuZone }
    private val dateFormat = SimpleDateFormat(DateFormat.getBestDateTimePattern(locale, "EEEMMMd"), locale)
        .apply { timeZone = icuZone }

    private val holderIds = listOf(
        Holder(R.id.holder_0, R.id.holder_0_time, R.id.holder_0_title, R.id.holder_0_details),
        Holder(R.id.holder_1, R.id.holder_1_time, R.id.holder_1_title, R.id.holder_1_details),
        Holder(R.id.holder_2, R.id.holder_2_time, R.id.holder_2_title, R.id.holder_2_details),
        Holder(R.id.holder_3, R.id.holder_3_time, R.id.holder_3_title, R.id.holder_3_details),
    )
    private val captionIds = listOf(R.id.all_day_0, R.id.all_day_1)

    private data class Holder(val root: Int, val time: Int, val title: Int, val details: Int)

    fun build(result: ReadResult, options: Bundle?, nowMs: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_schedule)
        val light = (result.settings?.textTone ?: "light") == "light"
        val primary = context.getColor(if (light) R.color.widget_light_primary else R.color.widget_dark_primary)
        val secondary = context.getColor(if (light) R.color.widget_light_secondary else R.color.widget_dark_secondary)
        views.setOnClickPendingIntent(R.id.widget_root, launch(Uri.parse("schediel://today")))
        captionIds.forEach { views.setViewVisibility(it, View.GONE) }
        holderIds.forEach { views.setViewVisibility(it.root, View.GONE) }

        if (result.state != ReadState.ENTRIES) {
            views.setViewVisibility(R.id.widget_message, View.VISIBLE)
            views.setTextViewText(R.id.widget_message, context.getString(messageText(result.message)))
            views.setTextColor(R.id.widget_message, primary)
            return views
        }
        views.setViewVisibility(R.id.widget_message, View.GONE)

        val settings = result.settings!!
        val today = Instant.ofEpochMilli(nowMs).atZone(zone).toLocalDate()
        val plan = WidgetPlanner.plan(result, heightDp(options), context.resources.configuration.fontScale)
        plan.allDay.forEachIndexed { i, entry ->
            val id = captionIds[i]
            views.setViewVisibility(id, View.VISIBLE)
            views.setTextViewText(id, "${context.getString(R.string.widget_all_day)} · ${entry.title}")
            views.setTextColor(id, secondary)
        }
        plan.holders.forEachIndexed { i, row ->
            val ids = holderIds[i]
            val entry = row.entry
            views.setViewVisibility(ids.root, View.VISIBLE)
            views.setInt(ids.root, "setBackgroundResource", holderBackground(settings.surface, light, row.emphasized))
            val (shown, spoken) = timeTexts(row, today)
            views.setTextViewText(ids.time, shown)
            views.setTextColor(ids.time, secondary)
            views.setTextViewText(ids.title, if (row.emphasized) bold(entry.title) else entry.title)
            views.setTextColor(ids.title, primary)
            if (row.details != null) {
                views.setViewVisibility(ids.details, View.VISIBLE)
                views.setTextViewText(ids.details, row.details)
                views.setTextColor(ids.details, secondary)
            } else {
                views.setViewVisibility(ids.details, View.GONE)
            }
            views.setContentDescription(ids.root, listOfNotNull(entry.title, spoken, row.details).joinToString(". "))
            views.setOnClickPendingIntent(ids.root, launch(Uri.parse(entry.deepLink)))
        }
        return views
    }

    /** Visible and spoken time lines (x-readerRules R01-R05, R09). */
    private fun timeTexts(row: HolderRow, today: LocalDate): Pair<String, String> {
        val entry = row.entry
        val status = when (row.status) {
            RowStatus.NOW -> context.getString(R.string.widget_now)
            RowStatus.NEXT -> context.getString(R.string.widget_next)
            else -> null
        }
        val date = if (entry.startDate != today) dateFormat.format(Date(dateMillis(entry))) else null
        val start = entry.startEpochMs
        val (range, spokenRange) = when {
            row.status == RowStatus.REVIEW || start == null -> {
                val text = context.getString(R.string.widget_time_needs_review)
                text to text
            }
            entry.endEpochMs == null -> timeFormat.format(Date(start)).let { it to it }
            else -> {
                val from = timeFormat.format(Date(start))
                val to = timeFormat.format(Date(entry.endEpochMs))
                context.getString(R.string.widget_time_range, from, to) to context.getString(R.string.widget_time_range_spoken, from, to)
            }
        }
        val zoneSuffix = entry.zoneLabel?.let { " ($it)" } ?: ""
        val shown = listOfNotNull(status, date, range + zoneSuffix).joinToString(" · ")
        val spoken = listOfNotNull(status, date, spokenRange + zoneSuffix).joinToString(", ")
        return shown to spoken
    }

    private fun dateMillis(entry: SnapshotEntry): Long =
        entry.startEpochMs ?: entry.startDate.atTime(12, 0).atZone(zone).toInstant().toEpochMilli()

    private fun bold(text: String): CharSequence =
        SpannableString(text).apply { setSpan(StyleSpan(Typeface.BOLD), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE) }

    private fun launch(uri: Uri) = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)

    private fun heightDp(options: Bundle?): Float? {
        if (options == null) return null
        val portrait = context.resources.configuration.orientation != Configuration.ORIENTATION_LANDSCAPE
        val height = options.getInt(if (portrait) AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        return if (height > 0) height.toFloat() else null
    }

    private fun messageText(message: ReadMessage?): Int = when (message) {
        ReadMessage.OPEN_APP_TO_UPDATE -> R.string.widget_open_app_to_update
        ReadMessage.NO_SCHEDULES -> R.string.widget_no_schedules
        ReadMessage.NONE_IN_FILTER -> R.string.widget_none_in_filter
        ReadMessage.NO_UPCOMING -> R.string.widget_no_upcoming
        ReadMessage.OPEN_APP, null -> R.string.widget_open_app
    }

    private fun holderBackground(surface: String, light: Boolean, emphasized: Boolean): Int = when (surface) {
        "softTint" -> when {
            light && emphasized -> R.drawable.widget_holder_soft_light_next
            light -> R.drawable.widget_holder_soft_light_upcoming
            emphasized -> R.drawable.widget_holder_soft_dark_next
            else -> R.drawable.widget_holder_soft_dark_upcoming
        }
        "solid" -> when {
            light && emphasized -> R.drawable.widget_holder_solid_light_next
            light -> R.drawable.widget_holder_solid_light_upcoming
            emphasized -> R.drawable.widget_holder_solid_dark_next
            else -> R.drawable.widget_holder_solid_dark_upcoming
        }
        else -> when {
            light && emphasized -> R.drawable.widget_holder_clear_light_next
            light -> R.drawable.widget_holder_clear_light_upcoming
            emphasized -> R.drawable.widget_holder_clear_dark_next
            else -> R.drawable.widget_holder_clear_dark_upcoming
        }
    }
}
