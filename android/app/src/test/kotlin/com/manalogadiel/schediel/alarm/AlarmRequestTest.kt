package com.manalogadiel.schediel.alarm

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Calendar

/** AlarmRequest rules from contracts/native-bridge-v1.md. */
class AlarmRequestTest {
    private fun valid(): MutableMap<String, Any?> = mutableMapOf(
        "requestKey" to "rule-1|series-1/2026-11-02|android",
        "triggerAtEpochMs" to 1_793_581_200_000L,
        "title" to "Fixture class",
        "body" to "09:00 – 10:00",
        "deepLink" to "schediel://occurrence/series-1/2026-11-02",
        "snoozeMinutes" to 10,
        "prominent" to true,
    )

    @Test
    fun acceptsAValidRequestFromTheChannel() {
        val request = AlarmRequest.fromMap(valid())!!
        assertEquals("rule-1|series-1/2026-11-02|android", request.requestKey)
        assertEquals(1_793_581_200_000L, request.triggerAtEpochMs)
        assertEquals("Fixture class", request.title)
        assertEquals("09:00 – 10:00", request.body)
        assertEquals(10, request.snoozeMinutes)
        assertEquals(true, request.prominent)
    }

    @Test
    fun acceptsIntegerTriggersFromTheStandardCodec() {
        // The method codec sends small values as Int.
        assertNotNull(AlarmRequest.fromMap(valid().apply { put("triggerAtEpochMs", 5) }))
    }

    @Test
    fun rejectsMalformedRequests() {
        val broken = listOf<(MutableMap<String, Any?>) -> Unit>(
            { it.remove("requestKey") },
            { it["requestKey"] = "" },
            { it["requestKey"] = "k".repeat(161) },
            { it.remove("triggerAtEpochMs") },
            { it["triggerAtEpochMs"] = "soon" },
            { it["deepLink"] = "https://example.invalid/x" },
            { it.remove("deepLink") },
        )
        for ((i, change) in broken.withIndex()) {
            assertNull("case $i", AlarmRequest.fromMap(valid().also(change)))
        }
    }

    @Test
    fun hidesSnoozeOutsideTheSupportedRange() {
        for (value in listOf(null, 0, 31, -5)) {
            assertNull("$value", AlarmRequest.fromMap(valid().apply { put("snoozeMinutes", value) })!!.snoozeMinutes)
        }
        assertEquals(30, AlarmRequest.fromMap(valid().apply { put("snoozeMinutes", 30) })!!.snoozeMinutes)
    }

    @Test
    fun limitsTitlesTo120CodePointsWithoutSplittingCharacters() {
        val title = "\uD83D\uDCDA".repeat(130)
        val request = AlarmRequest.fromMap(valid().apply { put("title", title) })!!
        assertEquals(120, request.title.codePointCount(0, request.title.length))
        assertEquals("\uD83D\uDCDA".repeat(120), request.title)
    }

    @Test
    fun persistsAndRestoresAcceptedRequests() {
        val requests = listOf(AlarmRequest.fromMap(valid())!!, AlarmRequest.fromMap(valid().apply { put("snoozeMinutes", null) })!!)
        assertEquals(requests, AlarmRequest.listFromJson(AlarmRequest.listToJson(requests)))
        assertEquals(emptyList<AlarmRequest>(), AlarmRequest.listFromJson("{broken"))
        assertEquals(emptyList<AlarmRequest>(), AlarmRequest.listFromJson(null))
    }

    @Test
    fun keepsAStableRequestCodePerKey() {
        val a = AlarmRequest.fromMap(valid())!!
        val b = AlarmRequest.fromMap(valid().apply { put("triggerAtEpochMs", 1L) })!!
        assertEquals(a.requestCode, b.requestCode)
    }

    @Test
    fun mapsIsoWeekdaysToCalendarDays() {
        assertEquals(
            arrayListOf(Calendar.MONDAY, Calendar.WEDNESDAY, Calendar.SUNDAY),
            ClockDays.toCalendarDays(listOf(7, 3, 1, 3)),
        )
        assertEquals(
            arrayListOf(Calendar.MONDAY, Calendar.TUESDAY, Calendar.WEDNESDAY, Calendar.THURSDAY, Calendar.FRIDAY, Calendar.SATURDAY, Calendar.SUNDAY),
            ClockDays.toCalendarDays(listOf(1, 2, 3, 4, 5, 6, 7)),
        )
    }
}
