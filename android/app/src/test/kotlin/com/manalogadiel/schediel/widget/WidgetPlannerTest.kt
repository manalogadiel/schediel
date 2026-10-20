package com.manalogadiel.schediel.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.time.LocalDate
import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Element

class WidgetPlannerTest {
    @Test
    fun expandedStylesFitThreeAtReferenceHeight() {
        for (style in ThemeStyle.STYLES) {
            val plan = WidgetPlanner.plan(result(upcoming = listOf(entry(2), entry(3))), 244f, 1f,
                holderChromeDp = ThemeStyle.holderChromeDp(style), titleLineSp = ThemeStyle.titleLineSp(style))
            assertEquals(style, 3, plan.holders.size)
            assertTrue(style, plan.holders.all { it.details != null })
        }
    }

    @Test
    fun onePixelBelowThreeBareRowBoundaryShowsTwo() {
        for (style in ThemeStyle.STYLES) {
            val required = 16f + 3 * (ThemeStyle.holderChromeDp(style) + 16f + ThemeStyle.titleLineSp(style))
            val plan = WidgetPlanner.plan(result(upcoming = listOf(entry(2), entry(3))), required - 1f, 1f,
                holderChromeDp = ThemeStyle.holderChromeDp(style), titleLineSp = ThemeStyle.titleLineSp(style))
            assertEquals(style, 2, plan.holders.size)
        }
    }

    @Test
    fun holderChromeMatchesTheMeasuredLayouts() {
        // Margin + fill inset + padding from res/layout/widget_schedule_{style}.xml.
        assertEquals(24f, ThemeStyle.holderChromeDp("soft"))
        assertEquals(24f, ThemeStyle.holderChromeDp("pop"))
        assertEquals(27f, ThemeStyle.holderChromeDp("pixel"))
        assertEquals(19f, ThemeStyle.holderChromeDp("sketch"))
        for (style in ThemeStyle.STYLES) {
            assertEquals(style, 76f, ThemeStyle.holderChromeDp(style) + 16f + ThemeStyle.titleLineSp(style) + 16f, .01f)
            val root = File(requireNotNull(System.getProperty("schediel.contractsDir"))).parentFile
            val factory = DocumentBuilderFactory.newInstance().apply {
                setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
            }
            val document = factory.newDocumentBuilder().parse(File(root, "android/app/src/main/res/layout/widget_schedule_$style.xml"))
            val holder = document.getElementsByTagName("FrameLayout").item(0) as Element
            val content = holder.getElementsByTagName("LinearLayout").item(0) as Element
            val images = holder.getElementsByTagName("ImageView")
            val fill = (0 until images.length).map { images.item(it) as Element }
                .first { it.getAttribute("android:id").endsWith("_fill") }
            fun dp(element: Element, attribute: String) = element.getAttribute("android:$attribute").removeSuffix("dp").toFloat()
            val measured = dp(holder, "layout_marginBottom") + dp(content, "paddingTop") + dp(content, "paddingBottom") +
                dp(fill, "layout_marginTop") + dp(fill, "layout_marginBottom")
            assertEquals("$style XML must match the planner", measured, ThemeStyle.holderChromeDp(style), .01f)
        }
    }

    @Test
    fun sizedOffersBareAndDetailedRowsKeyedByTheirMeasuredHeight() {
        for (style in ThemeStyle.STYLES) {
            val chrome = ThemeStyle.holderChromeDp(style)
            val title = ThemeStyle.titleLineSp(style)
            val sized = WidgetPlanner.sized(result(upcoming = listOf(entry(2), entry(3))), 1f, holderChromeDp = chrome, titleLineSp = title)
            assertEquals(style, listOf(0, 1, 1, 2, 2, 3, 3), sized.map { it.second.holders.size })
            assertEquals(style, 16f + 3 * (chrome + 16f + title + 16f), sized.last().first, 0.01f)
            assertTrue(style, sized.zipWithNext().all { (a, b) -> a.first < b.first })
        }
    }

    private fun entry(n: Int, location: String? = "Fixture room $n") = SnapshotEntry(
        id = "s$n/2026-11-02",
        title = "Fixture $n",
        startEpochMs = 1_000L * n,
        endEpochMs = null,
        startDate = LocalDate.of(2026, 11, 2),
        zoneLabel = null,
        location = location,
        professor = null,
        subtitle = null,
        deepLink = "schediel://occurrence/s$n/2026-11-02",
    )

    private fun settings(layout: String = "expanded", emphasis: Boolean = true) =
        WidgetSettings(layout, "clear", "light", emphasis, showLocation = true, showProfessor = true, showSubtitle = true)

    private fun result(
        layout: String = "expanded",
        emphasis: Boolean = true,
        ongoing: List<SnapshotEntry> = emptyList(),
        upcoming: List<SnapshotEntry> = listOf(entry(2), entry(3), entry(4), entry(5)),
        allDay: List<SnapshotEntry> = emptyList(),
        review: List<SnapshotEntry> = emptyList(),
    ) = ReadResult(
        state = ReadState.ENTRIES,
        settings = settings(layout, emphasis),
        ongoing = ongoing,
        next = entry(1),
        upcoming = upcoming,
        allDay = allDay,
        needsReview = review,
    )

    @Test
    fun ordersNowThenNextThenUpcomingAndEmphasizesOnlyNext() {
        val plan = WidgetPlanner.plan(result(ongoing = listOf(entry(9))), heightDp = null, fontScale = 1f)
        assertEquals(listOf("s9", "s1", "s2", "s3"), plan.holders.map { it.entry.id.substringBefore('/') })
        assertEquals(listOf(RowStatus.NOW, RowStatus.NEXT, RowStatus.UPCOMING, RowStatus.UPCOMING), plan.holders.map { it.status })
        assertEquals(listOf(false, true, false, false), plan.holders.map { it.emphasized })
    }

    @Test
    fun compactShowsTwoHoldersWithoutDetails() {
        val plan = WidgetPlanner.plan(result(layout = "compact"), heightDp = null, fontScale = 1f)
        assertEquals(2, plan.holders.size)
        assertNull(plan.holders[0].details)
    }

    @Test
    fun expandedShowsEnabledDetailsOnlyWhenPresent() {
        val plan = WidgetPlanner.plan(result(upcoming = listOf(entry(2, location = null))), heightDp = null, fontScale = 1f)
        assertEquals("Fixture room 1", plan.holders[0].details)
        assertNull(plan.holders[1].details)
    }

    @Test
    fun emphasisCanBeTurnedOff() {
        val plan = WidgetPlanner.plan(result(emphasis = false), heightDp = null, fontScale = 1f)
        assertEquals(false, plan.holders[0].emphasized)
        assertEquals(RowStatus.NEXT, plan.holders[0].status)
    }

    @Test
    fun needsReviewFollowsTimedEntriesWithinTheLimit() {
        val plan = WidgetPlanner.plan(result(upcoming = listOf(entry(2)), review = listOf(entry(7), entry(8))), heightDp = null, fontScale = 1f)
        assertEquals(listOf(RowStatus.NEXT, RowStatus.UPCOMING, RowStatus.REVIEW), plan.holders.map { it.status })
    }

    @Test
    fun showsAtMostTwoAllDayCaptions() {
        val plan = WidgetPlanner.plan(result(allDay = listOf(entry(6), entry(7), entry(8))), heightDp = null, fontScale = 1f)
        assertEquals(listOf("s6", "s7"), plan.allDay.map { it.id.substringBefore('/') })
    }

    @Test
    fun showsFewerHoldersWhenTheWidgetIsShort() {
        // Padding 16 + two holders with details (2 x 74) fits; a third does not.
        val plan = WidgetPlanner.plan(result(), heightDp = 170f, fontScale = 1f)
        assertEquals(2, plan.holders.size)
    }

    @Test
    fun largeTextHidesDetailsBeforeEntries() {
        val plan = WidgetPlanner.plan(result(), heightDp = null, fontScale = 1.3f)
        assertEquals(4, plan.holders.size)
        assertNull(plan.holders[0].details)
    }

    @Test
    fun keepsTheFirstHolderAndFitsACaptionByOmittingOptionalDetails() {
        val plan = WidgetPlanner.plan(result(allDay = listOf(entry(6))), heightDp = 95f, fontScale = 1f)
        assertEquals(1, plan.holders.size)
        assertEquals(RowStatus.NEXT, plan.holders[0].status)
        assertEquals(listOf(entry(6)), plan.allDay)
        assertNull(plan.holders[0].details)
        assertTrue(16f + 20f + 22f + 16f + 20f <= 95f)
    }

    @Test
    fun taller_title_fonts_fit_fewer_holders_instead_of_clipping() {
        // Expanded holders with a location: 22 + (16 + title + 16) * scale.
        val system = WidgetPlanner.plan(result(), heightDp = 230f, fontScale = 1.3f)
        val sketch = WidgetPlanner.plan(
            result(), heightDp = 230f, fontScale = 1.3f, holderChromeDp = ThemeStyle.holderChromeDp("sketch"), titleLineSp = ThemeStyle.titleLineSp("sketch"),
        )
        assertTrue("${sketch.holders.size} vs ${system.holders.size}", sketch.holders.size < system.holders.size)
        val used = 16f + sketch.holders.sumOf { (ThemeStyle.holderChromeDp("sketch") + (16 + 25 + if (it.details != null) 16 else 0) * 1.3) }
        assertTrue("used $used", used <= 230.0)
        assertEquals(WidgetPlanner.DEFAULT_TITLE_LINE_SP, ThemeStyle.titleLineSp(null))
        assertEquals(17f, ThemeStyle.titleLineSp("pixel"))
    }

    @Test
    fun smallestCardVariantIsTheBareNextItemAfterTheTinyWidgetFallback() {
        val withCaptions = result(allDay = listOf(entry(7), entry(8)))
        val sized = WidgetPlanner.sized(withCaptions, 1f, holderChromeDp = 24f)
        assertTrue(sized.first().second.holders.isEmpty())
        assertTrue(sized.first().second.allDay.isEmpty())
        val (height, plan) = sized.first { it.second.holders.isNotEmpty() }
        assertTrue(plan.allDay.isEmpty())
        assertEquals(1, plan.holders.size)
        assertNull(plan.holders.first().details)
        assertEquals(RowStatus.NEXT, plan.holders.first().status)
        assertEquals(16f + 24f + 16f + 20f, height, 0.01f)
    }

    @Test
    fun allStylesFitThreeAtTheSameGridHeightBeforeKeepingDetails() {
        for (style in ThemeStyle.STYLES) {
            val plan = WidgetPlanner.plan(result(), 240f, 1f,
                ThemeStyle.holderChromeDp(style), ThemeStyle.titleLineSp(style))
            assertEquals(style, 3, plan.holders.size)
            assertEquals(style, listOf("s1", "s2", "s3"), plan.holders.map { it.entry.id.substringBefore('/') })
        }
    }

    @Test
    fun everyStyleAndSizeFitsWithoutClippingAndUsesTheSamePlanOnOldAndNewHosts() {
        for (style in listOf(null, "soft", "pop", "pixel", "sketch")) {
            val chrome = ThemeStyle.holderChromeDp(style)
            val title = ThemeStyle.titleLineSp(style)
            for (scale in listOf(1f, 1.15f, 1.3f, 1.6f, 2f)) {
                for (layout in listOf("compact", "expanded")) {
                    val source = result(layout = layout, allDay = listOf(entry(7), entry(8)))
                    val full = WidgetPlanner.plan(source, null, scale, chrome, title)
                    val variants = WidgetPlanner.sized(source, scale, chrome, title)
                    assertTrue("$style $scale $layout: too many RemoteViews variants", variants.size <= 13)
                    assertTrue(variants.zipWithNext().all { (a, b) ->
                        a.first < b.first && a.second.holders.size <= b.second.holders.size })
                    for (height in listOf(70f, 90f, 110f, 140f, 170f, 200f, 220f, 240f, 250f, 280f, 320f, 400f, 500f)) {
                        val label = "$style $scale $layout $height"
                        val plan = WidgetPlanner.plan(source, height, scale, chrome, title)
                        val expected = minOf(full.holders.size, ((height - 16f) / (chrome + (16f + title) * scale)).toInt().coerceAtLeast(0))
                        assertEquals(label, expected, plan.holders.size)
                        val used = 16f + plan.allDay.size * (16f * scale + 4f) + plan.holders.sumOf {
                            (chrome + (16f + title + if (it.details != null) 16f else 0f) * scale).toDouble()
                        }
                        assertTrue("$label used $used", used <= height + .01f)
                        assertEquals(label, plan, variants.last { it.first <= height }.second)
                        assertEquals(label, full.holders.take(plan.holders.size).map { it.entry.id }, plan.holders.map { it.entry.id })
                    }
                }
            }
        }
    }

    @Test
    fun captionsAloneAlsoRespectTheAvailableHeight() {
        val source = result(allDay = listOf(entry(7), entry(8)), upcoming = emptyList()).copy(next = null)
        val plan = WidgetPlanner.plan(source, 40f, 1f)
        assertEquals(1, plan.allDay.size)
        assertTrue(plan.holders.isEmpty())
    }
}
