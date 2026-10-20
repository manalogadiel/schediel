package com.manalogadiel.schediel.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Typeface
import android.icu.text.SimpleDateFormat
import android.icu.util.TimeZone
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.SpannableString
import android.text.Spanned
import android.text.format.DateFormat
import android.text.style.StyleSpan
import android.util.SizeF
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
    private companion object {
        const val OPAQUE = 0xFF000000.toInt()
        val BITMAP_TITLE_STYLES = setOf("pixel", "sketch")
    }

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

    /** Bitmap title views, present only in the pixel and sketch layouts. */
    private val titleImageIds = listOf(
        R.id.holder_0_title_image,
        R.id.holder_1_title_image,
        R.id.holder_2_title_image,
        R.id.holder_3_title_image,
    )

    /** Shape layers present only in the themed layouts. */
    private data class Shapes(val shadow: Int, val outline: Int, val fill: Int)

    private val shapeIds = listOf(
        Shapes(R.id.holder_0_shadow, R.id.holder_0_outline, R.id.holder_0_fill),
        Shapes(R.id.holder_1_shadow, R.id.holder_1_outline, R.id.holder_1_fill),
        Shapes(R.id.holder_2_shadow, R.id.holder_2_outline, R.id.holder_2_fill),
        Shapes(R.id.holder_3_shadow, R.id.holder_3_outline, R.id.holder_3_fill),
    )

    private fun isNight(): Boolean =
        (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    // Title bitmaps for the current build, shared by every size variant: the
    // sized RemoteViews share one bitmap cache that stores a reused Bitmap
    // object once, so the variants do not multiply the parcel size.
    private val titleBitmaps = HashMap<Pair<String, Boolean>, Bitmap?>()

    fun build(result: ReadResult, options: Bundle?, nowMs: Long): RemoteViews {
        titleBitmaps.clear()
        val style = result.theme?.takeIf { result.settings?.useAppTheme == true }?.style
        val fontScale = context.resources.configuration.fontScale
        val chrome = ThemeStyle.holderChromeDp(style)
        val title = ThemeStyle.titleLineSp(style)
        // Android 12+: title/time and detailed layouts, keyed by their height;
        // the host picks the largest that fits the widget's real size, so the
        // container fills even when the reported size is conservative.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && result.state == ReadState.ENTRIES && result.settings != null) {
            val sized = WidgetPlanner.sized(result, fontScale, chrome, title)
            if (sized.isNotEmpty()) {
                return RemoteViews(sized.associate { (height, plan) -> SizeF(1f, height) to buildFor(result, options, nowMs, plan) })
            }
        }
        return buildFor(result, options, nowMs, WidgetPlanner.plan(result, heightDp(options), fontScale, chrome, title))
    }

    private fun buildFor(result: ReadResult, options: Bundle?, nowMs: Long, plan: WidgetPlan): RemoteViews {
        // Themed holders when this widget opted in and the snapshot carries a
        // valid theme; otherwise exactly the original look.
        val theme = result.theme?.takeIf { result.settings?.useAppTheme == true }
        val views = RemoteViews(context.packageName, ThemeStyle.layoutFor(theme))
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
        if (plan.holders.isEmpty() && plan.allDay.isEmpty()) {
            // The host can resize below even one complete card. Keep a
            // readable launch action instead of cutting off title/time.
            views.setViewVisibility(R.id.widget_message, View.VISIBLE)
            views.setTextViewText(R.id.widget_message, context.getString(R.string.widget_open_app))
            views.setInt(R.id.widget_message, "setMaxLines", 1)
            views.setTextColor(R.id.widget_message, primary)
            return views
        }
        views.setViewVisibility(R.id.widget_message, View.GONE)

        val settings = result.settings!!
        val today = Instant.ofEpochMilli(nowMs).atZone(zone).toLocalDate()
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
            // Day and night ink: equal unless themed (the legacy look keeps its
            // chosen text tone).
            var ink = Pair(primary, primary)
            var subtle = Pair(secondary, secondary)
            if (theme != null) {
                val day = ThemeStyle.holderColors(theme.light, row.emphasized, entry.categoryColor, settings.surface)
                val night = ThemeStyle.holderColors(theme.dark, row.emphasized, entry.categoryColor, settings.surface)
                paintShapes(views, shapeIds[i], theme.style, settings.surface, day, night)
                ink = Pair(day.ink, night.ink)
                subtle = ink
            } else {
                views.setInt(ids.root, "setBackgroundResource", holderBackground(settings.surface, light, row.emphasized))
            }
            val (shown, spoken) = timeTexts(row, today)
            views.setTextViewText(ids.time, shown)
            dayNight(views, ids.time, "setTextColor", subtle)
            views.setTextViewText(ids.title, if (row.emphasized) bold(entry.title) else entry.title)
            dayNight(views, ids.title, "setTextColor", ink)
            val titleImage = titleImageIds[i]
            val bitmap = if (theme != null && theme.style in BITMAP_TITLE_STYLES) {
                TitleBitmap.maxWidthPx(widthDp(options), context.resources.displayMetrics.density)?.let { max ->
                    titleBitmaps.getOrPut(entry.title to row.emphasized) {
                        TitleBitmap.render(context, theme.style, entry.title, row.emphasized, context.resources.configuration.fontScale, max)
                    }
                }
            } else {
                null
            }
            if (bitmap != null) {
                views.setImageViewBitmap(titleImage, bitmap)
                dayNight(views, titleImage, "setColorFilter", ink)
                views.setViewVisibility(titleImage, View.VISIBLE)
                views.setViewVisibility(ids.title, View.GONE)
            } else if (theme != null && theme.style in BITMAP_TITLE_STYLES) {
                views.setViewVisibility(titleImage, View.GONE)
                views.setViewVisibility(ids.title, View.VISIBLE)
            }
            if (row.details != null) {
                views.setViewVisibility(ids.details, View.VISIBLE)
                views.setTextViewText(ids.details, row.details)
                dayNight(views, ids.details, "setTextColor", subtle)
            } else {
                views.setViewVisibility(ids.details, View.GONE)
            }
            views.setContentDescription(ids.root, listOfNotNull(entry.title, spoken, row.details).joinToString(". "))
            views.setOnClickPendingIntent(ids.root, launch(Uri.parse(entry.deepLink)))
        }
        return views
    }

    /**
     * Tints the white shape layers: fill with the holder color and surface
     * opacity, ring in the theme outline, hard shadow only on solid holders.
     * Soft holders show a faint ring only on the clear surface.
     */
    private fun paintShapes(views: RemoteViews, ids: Shapes, style: String, surface: String, day: HolderColors, night: HolderColors) {
        dayNight(views, ids.fill, "setColorFilter", Pair(day.fill or OPAQUE, night.fill or OPAQUE))
        views.setInt(ids.fill, "setImageAlpha", ThemeStyle.sharedAlpha(day, night))
        val ringAlpha = when {
            style != "soft" -> 255
            surface == "clear" -> 0x66
            else -> 0
        }
        dayNight(views, ids.outline, "setColorFilter", Pair(day.outline or OPAQUE, night.outline or OPAQUE))
        views.setInt(ids.outline, "setImageAlpha", ringAlpha)
        if (ThemeStyle.showsShadow(style, surface)) {
            views.setViewVisibility(ids.shadow, View.VISIBLE)
            dayNight(views, ids.shadow, "setColorFilter", Pair(day.outline or OPAQUE, night.outline or OPAQUE))
        } else {
            views.setViewVisibility(ids.shadow, View.GONE)
        }
    }

    /**
     * Android 12+ switches these colors itself when night mode changes, even
     * while the app is closed. Older versions get the current mode's color;
     * the next widget update (app open, data change or scheduled refresh)
     * picks up a later change.
     */
    private fun dayNight(views: RemoteViews, id: Int, method: String, colors: Pair<Int, Int>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setColorInt(id, method, colors.first, colors.second)
        } else {
            views.setInt(id, method, if (isNight()) colors.second else colors.first)
        }
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

    private fun widthDp(options: Bundle?): Float? {
        if (options == null) return null
        val portrait = context.resources.configuration.orientation != Configuration.ORIENTATION_LANDSCAPE
        val width = options.getInt(if (portrait) AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH)
        return if (width > 0) width.toFloat() else null
    }

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
