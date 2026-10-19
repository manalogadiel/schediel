package com.manalogadiel.schediel.widget

import com.manalogadiel.schediel.R
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.time.Instant
import java.time.ZoneId

/** Runs the shared 1.1 fixture (contracts/fixtures/widget-snapshot-v1_1-cases.json). */
class SnapshotReaderThemeTest {
    private val doc = JSONObject(
        File(System.getProperty("schediel.contractsDir"), "fixtures/widget-snapshot-v1_1-cases.json").readText(),
    )
    private val zone: ZoneId = ZoneId.of(doc.getString("deviceTimeZone"))
    private val now = Instant.parse(doc.getString("now")).toEpochMilli()
    private val snapshot = doc.getJSONObject("snapshot")
    private val expect = doc.getJSONObject("expect")

    private fun argb(hex: String) = hex.substring(1).toLong(16).toInt()

    @Test
    fun readsThemeUseAppThemeAndCategoryColors() {
        val result = SnapshotReader.read(snapshot.toString(), "default", now, zone)
        assertEquals(ReadState.ENTRIES, result.state)
        assertEquals(expect.getString("style"), result.theme!!.style)
        assertEquals(expect.getBoolean("defaultUseAppTheme"), result.settings!!.useAppTheme)
        assertEquals(expect.getString("next"), result.next!!.id)
        assertEquals(expect.getString("nextCategoryColor"), result.next!!.categoryColor)
        assertNull(result.upcoming.single().categoryColor)
        val other = SnapshotReader.read(snapshot.toString(), "21", now, zone)
        assertEquals(expect.getBoolean("widget21UseAppTheme"), other.settings!!.useAppTheme)
    }

    @Test
    fun holderColorsMatchTheDartReference() {
        val theme = SnapshotReader.read(snapshot.toString(), "default", now, zone).theme!!
        val holders = expect.getJSONObject("holders")
        fun check(name: String, colors: HolderColors) {
            val e = holders.getJSONObject(name)
            assertEquals(name, argb(e.getString("fill")), colors.fill)
            assertEquals(name, ThemeStyle.parseColor(e.getString("ink")), colors.ink)
        }
        check("lightNextClear", ThemeStyle.holderColors(theme.palette(night = false), next = true, categoryColor = null, surface = "clear"))
        check("lightGreenClear", ThemeStyle.holderColors(theme.palette(night = false), next = false, categoryColor = "green", surface = "clear"))
        check("darkNeutralSolid", ThemeStyle.holderColors(theme.palette(night = true), next = false, categoryColor = null, surface = "solid"))
    }

    @Test
    fun aVersion10SnapshotStillReadsWithoutTheme() {
        val legacy = JSONObject(snapshot.toString()).apply {
            put("schemaVersion", "1.0")
            remove("theme")
        }
        val result = SnapshotReader.read(legacy.toString(), "default", now, zone)
        assertEquals(ReadState.ENTRIES, result.state)
        assertNull(result.theme)
        assertFalse(result.settings!!.useAppTheme)
    }

    @Test
    fun malformedThemeFallsBackToTheLegacyLookInsteadOfFailing() {
        for (mutate in listOf<(JSONObject) -> Unit>(
            { it.getJSONObject("theme").put("style", "neon") },
            { it.getJSONObject("theme").getJSONObject("light").put("accent", "red") },
            { it.getJSONObject("theme").getJSONObject("dark").getJSONObject("categoryFills").remove("gray") },
            { it.getJSONObject("theme").getJSONObject("light").getJSONObject("opacity").put("clear", 2.0) },
            { it.put("theme", "not an object") },
        )) {
            val copy = JSONObject(snapshot.toString()).also(mutate)
            val result = SnapshotReader.read(copy.toString(), "default", now, zone)
            assertEquals(ReadState.ENTRIES, result.state)
            assertNull(result.theme)
        }
    }

    @Test
    fun unknownVersionsStillOpenTheApp() {
        val copy = JSONObject(snapshot.toString()).put("schemaVersion", "2.0")
        assertEquals(ReadState.UNSUPPORTED, SnapshotReader.read(copy.toString(), "default", now, zone).state)
    }

    @Test
    fun eachStyleHasItsLayoutAndOptingOutKeepsTheOriginal() {
        val theme = SnapshotReader.read(snapshot.toString(), "default", now, zone).theme!!
        assertEquals(R.layout.widget_schedule_pixel, ThemeStyle.layoutFor(theme))
        assertEquals(R.layout.widget_schedule_soft, ThemeStyle.layoutFor(theme.copy(style = "soft")))
        assertEquals(R.layout.widget_schedule_pop, ThemeStyle.layoutFor(theme.copy(style = "pop")))
        assertEquals(R.layout.widget_schedule_sketch, ThemeStyle.layoutFor(theme.copy(style = "sketch")))
        assertEquals(R.layout.widget_schedule, ThemeStyle.layoutFor(null))
    }

    @Test
    fun nightModePicksTheDarkPalette() {
        val theme = SnapshotReader.read(snapshot.toString(), "default", now, zone).theme!!
        val json = snapshot.getJSONObject("theme")
        assertEquals(ThemeStyle.parseColor(json.getJSONObject("dark").getString("accent")), theme.palette(night = true).accent)
        assertEquals(ThemeStyle.parseColor(json.getJSONObject("light").getString("accent")), theme.palette(night = false).accent)
    }

    @Test
    fun oneAlphaServesBothPalettesUsingTheMoreOpaque() {
        val light = HolderColors(fill = (0xB3 shl 24) or 0x112233, ink = 0, outline = 0)
        val dark = HolderColors(fill = (0xC7 shl 24) or 0x445566, ink = 0, outline = 0)
        assertEquals(0xC7, ThemeStyle.sharedAlpha(light, dark))
        assertEquals(0xC7, ThemeStyle.sharedAlpha(dark, light))
    }

    @Test
    fun opacityBelowTheTestedStartIsRaisedNotTrusted() {
        val copy = JSONObject(snapshot.toString())
        copy.getJSONObject("theme").getJSONObject("light").getJSONObject("opacity").put("clear", 0.1).put("softTint", 0.2)
        val palette = SnapshotReader.read(copy.toString(), "default", now, zone).theme!!.palette(night = false)
        assertEquals(ThemeStyle.MIN_CLEAR, palette.clearOpacity, 0.0)
        assertEquals(ThemeStyle.MIN_SOFT_TINT, palette.softTintOpacity, 0.0)
    }

    @Test
    fun bitmapTitlesFitTheHolderAndNeedAKnownWidth() {
        assertNull(TitleBitmap.maxWidthPx(null, 2f))
        assertNull(TitleBitmap.maxWidthPx(30f, 2f))
        // 334dp widget at 1.875x density: everything but the holder chrome.
        assertEquals(((334f - TitleBitmap.HORIZONTAL_CHROME_DP) * 1.875f).toInt(), TitleBitmap.maxWidthPx(334f, 1.875f))
        assertEquals(19f, TitleBitmap.sizeSp("sketch"), 0f)
        assertEquals(13f, TitleBitmap.sizeSp("pixel"), 0f)
    }

    @Test
    fun colorParsingIsStrict() {
        assertEquals(0xFF3D5AFE.toInt(), ThemeStyle.parseColor("#3D5AFE"))
        for (bad in listOf("3D5AFE", "#3D5AF", "#3D5AFEFF", "#GGGGGG", "")) {
            assertTrue(bad, runCatching { ThemeStyle.parseColor(bad) }.isFailure)
        }
    }

    @Test
    fun surfacesSetOpacityAndOnlySolidDrawsHardShadows() {
        val palette = SnapshotReader.read(snapshot.toString(), "default", now, zone).theme!!.palette(night = false)
        val clear = ThemeStyle.holderColors(palette, next = false, categoryColor = "blue", surface = "clear").fill ushr 24
        val soft = ThemeStyle.holderColors(palette, next = false, categoryColor = "blue", surface = "softTint").fill ushr 24
        val solid = ThemeStyle.holderColors(palette, next = false, categoryColor = "blue", surface = "solid").fill ushr 24
        assertTrue(clear <= soft)
        assertEquals(255, solid)
        assertTrue(ThemeStyle.showsShadow("pop", "solid"))
        assertFalse(ThemeStyle.showsShadow("pop", "clear"))
        assertFalse(ThemeStyle.showsShadow("soft", "solid"))
        assertNotNull(ThemeStyle.STYLES.single { it == "sketch" })
    }
}
