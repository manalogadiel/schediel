package com.manalogadiel.schediel.alarm

import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/** One app-owned alarm request (contracts/native-bridge-v1.md, AlarmRequest). */
data class AlarmRequest(
    val requestKey: String,
    val triggerAtEpochMs: Long,
    val title: String,
    val body: String,
    val deepLink: String,
    val snoozeMinutes: Int?,
    val prominent: Boolean,
) {
    /** Stable request code shared by the trigger, snooze and notification. */
    val requestCode: Int get() = requestKey.hashCode()

    fun toJson(): JSONObject = JSONObject()
        .put("requestKey", requestKey)
        .put("triggerAtEpochMs", triggerAtEpochMs)
        .put("title", title)
        .put("body", body)
        .put("deepLink", deepLink)
        .put("snoozeMinutes", snoozeMinutes ?: JSONObject.NULL)
        .put("prominent", prominent)

    companion object {
        const val MAX_KEY_LENGTH = 160
        const val MAX_TITLE_CODE_POINTS = 120
        private const val DEEP_LINK_PREFIX = "schediel://occurrence/"
        private val SNOOZE_RANGE = 1..30

        /** Validates a channel map; null when it breaks the contract. */
        fun fromMap(map: Map<String, Any?>): AlarmRequest? {
            val key = map["requestKey"] as? String ?: return null
            if (key.isEmpty() || key.length > MAX_KEY_LENGTH) return null
            val trigger = (map["triggerAtEpochMs"] as? Number)?.toLong() ?: return null
            val deepLink = map["deepLink"] as? String ?: return null
            if (!deepLink.startsWith(DEEP_LINK_PREFIX)) return null
            return AlarmRequest(
                requestKey = key,
                triggerAtEpochMs = trigger,
                title = limitCodePoints(map["title"] as? String ?: "", MAX_TITLE_CODE_POINTS),
                body = map["body"] as? String ?: "",
                deepLink = deepLink,
                snoozeMinutes = (map["snoozeMinutes"] as? Number)?.toInt()?.takeIf { it in SNOOZE_RANGE },
                prominent = map["prominent"] == true,
            )
        }

        private fun limitCodePoints(text: String, max: Int): String =
            if (text.codePointCount(0, text.length) <= max) text else text.substring(0, text.offsetByCodePoints(0, max))

        private fun fromJson(json: JSONObject): AlarmRequest? = try {
            AlarmRequest(
                requestKey = json.getString("requestKey"),
                triggerAtEpochMs = json.getLong("triggerAtEpochMs"),
                title = json.optString("title", ""),
                body = json.optString("body", ""),
                deepLink = json.getString("deepLink"),
                snoozeMinutes = if (json.isNull("snoozeMinutes")) null else json.getInt("snoozeMinutes"),
                prominent = json.optBoolean("prominent", false),
            )
        } catch (e: Exception) {
            null
        }

        fun listToJson(list: List<AlarmRequest>): String = JSONArray().apply { list.forEach { put(it.toJson()) } }.toString()

        fun listFromJson(text: String?): List<AlarmRequest> {
            if (text.isNullOrEmpty()) return emptyList()
            return try {
                val array = JSONArray(text)
                (0 until array.length()).mapNotNull { fromJson(array.getJSONObject(it)) }
            } catch (e: Exception) {
                emptyList()
            }
        }
    }
}

data class AlarmResult(val requestKey: String, val status: String, val errorCode: String? = null) {
    fun toMap(): Map<String, Any?> = mapOf("requestKey" to requestKey, "status" to status, "errorCode" to errorCode)
}

/** ISO weekdays (1 = Monday) to java.util.Calendar day constants for AlarmClock.EXTRA_DAYS. */
object ClockDays {
    private val calendarDays = mapOf(
        1 to Calendar.MONDAY,
        2 to Calendar.TUESDAY,
        3 to Calendar.WEDNESDAY,
        4 to Calendar.THURSDAY,
        5 to Calendar.FRIDAY,
        6 to Calendar.SATURDAY,
        7 to Calendar.SUNDAY,
    )

    fun toCalendarDays(isoDays: List<Int>): ArrayList<Int> =
        ArrayList(isoDays.distinct().sorted().map { calendarDays[it] ?: throw IllegalArgumentException("ISO weekday out of range") })
}
