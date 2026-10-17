package com.manalogadiel.schediel.widget

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.File
import java.time.Instant
import java.time.ZoneId

/** Runs the shared reader fixtures (contracts/fixtures/widget-snapshot-cases.json). */
class SnapshotReaderTest {
    private val doc = JSONObject(
        File(System.getProperty("schediel.contractsDir"), "fixtures/widget-snapshot-cases.json").readText(),
    )
    private val zone: ZoneId = ZoneId.of(doc.getString("deviceTimeZone"))
    private val snapshot = doc.getJSONObject("snapshot").toString()

    private fun ms(iso: String) = Instant.parse(iso).toEpochMilli()

    private fun strings(array: JSONArray) = (0 until array.length()).map { array.getString(it) }

    private fun ids(entries: List<SnapshotEntry>) = entries.map { it.id }

    @Test
    fun matchesEverySharedFixtureCheck() {
        val checks = doc.getJSONArray("checks")
        for (i in 0 until checks.length()) {
            val check = checks.getJSONObject(i)
            val name = check.getString("name")
            val expect = check.getJSONObject("expect")
            val result = SnapshotReader.read(snapshot, check.getString("widgetKey"), ms(check.getString("now")), zone)
            assertEquals(name, expect.getString("state"), result.state.wireName)
            if (expect.getString("state") == "entries") {
                assertEquals(name, strings(expect.getJSONArray("ongoing")), ids(result.ongoing))
                assertEquals(name, if (expect.isNull("next")) null else expect.getString("next"), result.next?.id)
                assertEquals(name, strings(expect.getJSONArray("upcoming")), ids(result.upcoming))
                assertEquals(name, strings(expect.getJSONArray("allDay")), ids(result.allDay))
                assertEquals(name, strings(expect.getJSONArray("needsReview")), ids(result.needsReview))
            } else {
                val message = if (expect.has("emptyMessage")) expect.getString("emptyMessage") else expect.getString("message")
                assertEquals(name, message, result.message?.english)
            }
        }
    }

    @Test
    fun unsupportedMissingOrInterruptedSnapshotsOpenTheApp() {
        val now = ms("2026-11-02T00:00:00Z")
        val expected = doc.getJSONObject("unsupportedExpect")
        val unsupported = SnapshotReader.read(doc.getJSONObject("unsupportedSnapshot").toString(), "default", now, zone)
        assertEquals(expected.getString("state"), unsupported.state.wireName)
        assertEquals(expected.getString("message"), unsupported.message?.english)
        for (raw in listOf(null, "", "{not json", snapshot.substring(0, snapshot.length / 2), "[]", """{"schemaVersion":"1.0"}""")) {
            val result = SnapshotReader.read(raw, "default", now, zone)
            assertEquals(raw.toString(), ReadState.UNSUPPORTED, result.state)
            assertEquals(raw.toString(), ReadMessage.OPEN_APP, result.message)
            assertNull(raw.toString(), result.nextRefreshEpochMs)
        }
    }

    @Test
    fun exposesTheSelectedWidgetConfigurationAndEntryFields() {
        val result = SnapshotReader.read(snapshot, "default", ms("2026-11-02T00:00:00Z"), zone)
        val settings = result.settings!!
        assertEquals("expanded", settings.layout)
        assertEquals("clear", settings.surface)
        assertEquals("light", settings.textTone)
        assertEquals(true, settings.nextEmphasis)
        val next = result.next!!
        assertEquals("Fixture class A", next.title)
        assertEquals(ms("2026-11-02T01:00:00Z"), next.startEpochMs)
        assertEquals(ms("2026-11-02T02:30:00Z"), next.endEpochMs)
        assertEquals("schediel://occurrence/00000000-0000-4000-8000-000000000001/2026-11-02", next.deepLink)
    }

    @Test
    fun requestsTheNextRefreshAtTheEarliestBoundaryMidnightOrCoverageEnd() {
        fun refresh(now: String, key: String = "default") = SnapshotReader.read(snapshot, key, ms(now), zone).nextRefreshEpochMs
        // Next start.
        assertEquals(ms("2026-11-02T01:00:00Z"), refresh("2026-11-02T00:00:00Z"))
        // End of the ongoing class.
        assertEquals(ms("2026-11-02T02:30:00Z"), refresh("2026-11-02T01:30:00Z"))
        // A point event at its start is past; the ongoing class end is next.
        assertEquals(ms("2026-11-02T04:00:00Z"), refresh("2026-11-02T03:00:00Z"))
        // Nothing remaining: next local midnight in Asia/Manila.
        assertEquals(ms("2026-11-03T16:00:00Z"), refresh("2026-11-03T03:00:00Z"))
        // Empty filters still flip at local midnight and before coverage ends.
        assertEquals(ms("2026-11-02T16:00:00Z"), refresh("2026-11-02T00:00:00Z", "12"))
        // Coverage end wins when it is earliest.
        assertEquals(ms("2026-11-09T00:00:00Z"), refresh("2026-11-08T23:00:00Z"))
        // A stale snapshot needs the app, not another refresh.
        assertNull(refresh("2026-11-09T00:00:00Z"))
    }
}
