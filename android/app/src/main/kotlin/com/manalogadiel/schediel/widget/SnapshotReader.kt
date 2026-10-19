package com.manalogadiel.schediel.widget

import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

enum class ReadState(val wireName: String) {
    ENTRIES("entries"),
    EMPTY("empty"),
    STALE("stale"),
    UNSUPPORTED("unsupported"),
}

/** Reader messages (x-readerRules R06, R07); rendered from string resources. */
enum class ReadMessage(val english: String) {
    OPEN_APP("Open Schediel"),
    OPEN_APP_TO_UPDATE("Open Schediel to update"),
    NO_SCHEDULES("No schedules yet"),
    NONE_IN_FILTER("No schedules in this filter"),
    NO_UPCOMING("No upcoming schedules"),
}

data class WidgetSettings(
    val layout: String,
    val surface: String,
    val textTone: String,
    val nextEmphasis: Boolean,
    val showLocation: Boolean,
    val showProfessor: Boolean,
    val showSubtitle: Boolean,
    /** 1.1: holders follow the app theme; false for 1.0 or when absent. */
    val useAppTheme: Boolean = false,
)

data class SnapshotEntry(
    val id: String,
    val title: String,
    val startEpochMs: Long?,
    val endEpochMs: Long?,
    val startDate: LocalDate,
    val zoneLabel: String?,
    val location: String?,
    val professor: String?,
    val subtitle: String?,
    val deepLink: String,
    /** 1.1: the category's color key, or null for neutral. */
    val categoryColor: String? = null,
)

data class ReadResult(
    val state: ReadState,
    val message: ReadMessage? = null,
    val settings: WidgetSettings? = null,
    val ongoing: List<SnapshotEntry> = emptyList(),
    val next: SnapshotEntry? = null,
    val upcoming: List<SnapshotEntry> = emptyList(),
    val allDay: List<SnapshotEntry> = emptyList(),
    val needsReview: List<SnapshotEntry> = emptyList(),
    /** R10: when to render again; null when only the app can help. */
    val nextRefreshEpochMs: Long? = null,
    /** 1.1 app theme; null for 1.0 or a malformed theme (legacy look). */
    val theme: WidgetTheme? = null,
)

/**
 * Android reader for widget snapshots 1.0 and 1.1 (1.1 adds the optional app
 * theme), implementing x-readerRules R01-R07
 * and R10 exactly like the Dart reference reader. Any unexpected shape yields
 * the safe "Open Schediel" state instead of a partial render.
 */
object SnapshotReader {
    const val KEY = "schediel_widget_snapshot"
    private val SCHEMA_VERSIONS = setOf("1.0", "1.1")

    private val unsupported = ReadResult(ReadState.UNSUPPORTED, ReadMessage.OPEN_APP)

    fun read(raw: String?, widgetKey: String, nowMs: Long, zone: ZoneId): ReadResult {
        if (raw.isNullOrEmpty()) return unsupported
        return try {
            val snapshot = JSONObject(raw)
            if (snapshot.optString("schemaVersion") !in SCHEMA_VERSIONS) unsupported else parse(snapshot, widgetKey, nowMs, zone)
        } catch (e: Exception) {
            unsupported
        }
    }

    private fun parse(snapshot: JSONObject, widgetKey: String, nowMs: Long, zone: ZoneId): ReadResult {
        val coverageEnd = Instant.parse(snapshot.getString("coverageEnd")).toEpochMilli()
        if (nowMs >= coverageEnd) return ReadResult(ReadState.STALE, ReadMessage.OPEN_APP_TO_UPDATE)

        val widgets = snapshot.getJSONObject("widgets")
        val projection = widgets.optJSONObject(widgetKey) ?: widgets.getJSONObject("default")
        val v11 = snapshot.optString("schemaVersion") == "1.1"
        val settings = settings(projection.getJSONObject("configuration"), v11)
        val theme = if (v11) ThemeStyle.parse(snapshot.optJSONObject("theme")) else null
        val today = Instant.ofEpochMilli(nowMs).atZone(zone).toLocalDate()
        val midnight = today.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val refreshFloor = minOf(midnight, coverageEnd)

        when (if (projection.isNull("emptyReason")) null else projection.getString("emptyReason")) {
            "noSchedules" -> return ReadResult(ReadState.EMPTY, ReadMessage.NO_SCHEDULES, settings, nextRefreshEpochMs = refreshFloor, theme = theme)
            "noneInFilter" -> return ReadResult(ReadState.EMPTY, ReadMessage.NONE_IN_FILTER, settings, nextRefreshEpochMs = refreshFloor, theme = theme)
            null -> Unit
            else -> return unsupported
        }

        val ongoing = mutableListOf<SnapshotEntry>()
        val future = mutableListOf<SnapshotEntry>()
        val allDay = mutableListOf<SnapshotEntry>()
        val needsReview = mutableListOf<SnapshotEntry>()
        var refresh = refreshFloor
        val occurrences = projection.getJSONArray("occurrences")
        for (i in 0 until occurrences.length()) {
            val raw = occurrences.getJSONObject(i)
            val entry = entry(raw)
            when {
                raw.getString("kind") == "dateOnly" -> {
                    val end = LocalDate.parse(raw.getString("endDateExclusive"))
                    if (!today.isBefore(entry.startDate) && today.isBefore(end)) allDay += entry
                }
                raw.getString("timeStatus") == "needsTimeReview" -> {
                    if (!entry.startDate.isBefore(today)) needsReview += entry
                }
                else -> {
                    val start = entry.startEpochMs ?: throw IllegalStateException("resolved timed entry without start")
                    val end = entry.endEpochMs
                    if (end == null) {
                        if (nowMs < start) future += entry
                    } else if (start <= nowMs && nowMs < end) {
                        ongoing += entry
                    } else if (nowMs < start) {
                        future += entry
                    }
                    if (start > nowMs) refresh = minOf(refresh, start)
                    if (end != null && end > nowMs) refresh = minOf(refresh, end)
                }
            }
        }
        // Stable: ties keep snapshot order (R02).
        val sorted = future.sortedBy { it.startEpochMs }
        if (ongoing.isEmpty() && sorted.isEmpty() && allDay.isEmpty() && needsReview.isEmpty()) {
            return ReadResult(ReadState.EMPTY, ReadMessage.NO_UPCOMING, settings, nextRefreshEpochMs = refresh, theme = theme)
        }
        return ReadResult(
            state = ReadState.ENTRIES,
            settings = settings,
            ongoing = ongoing,
            next = sorted.firstOrNull(),
            upcoming = sorted.drop(1),
            allDay = allDay,
            needsReview = needsReview,
            nextRefreshEpochMs = refresh,
            theme = theme,
        )
    }

    private fun settings(json: JSONObject, v11: Boolean): WidgetSettings {
        val details = json.getJSONObject("visibleDetails")
        return WidgetSettings(
            layout = json.getString("layout").also { require(it == "compact" || it == "expanded") },
            surface = json.getString("surface").also { require(it == "clear" || it == "softTint" || it == "solid") },
            textTone = json.getString("textTone").also { require(it == "light" || it == "dark") },
            nextEmphasis = json.getBoolean("nextEmphasis"),
            showLocation = details.getBoolean("location"),
            showProfessor = details.getBoolean("professor"),
            showSubtitle = details.getBoolean("subtitle"),
            useAppTheme = v11 && json.optBoolean("useAppTheme", false),
        )
    }

    private fun JSONObject.optText(name: String): String? = if (isNull(name)) null else getString(name)

    private fun JSONObject.optEpoch(name: String): Long? = if (isNull(name)) null else getLong(name)

    private fun entry(json: JSONObject): SnapshotEntry {
        val deepLink = json.getString("deepLink")
        require(deepLink.startsWith("schediel://occurrence/"))
        return SnapshotEntry(
            id = json.getString("occurrenceId"),
            title = json.getString("title"),
            startEpochMs = json.optEpoch("startEpochMs"),
            endEpochMs = json.optEpoch("endEpochMs"),
            startDate = LocalDate.parse(json.getString("startDate")),
            zoneLabel = json.optText("zoneLabel"),
            location = json.optText("location"),
            professor = json.optText("professor"),
            subtitle = json.optText("subtitle"),
            deepLink = deepLink,
            categoryColor = if (json.has("categoryColor")) json.optText("categoryColor") else null,
        )
    }
}
