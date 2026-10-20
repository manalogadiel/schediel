package com.manalogadiel.schediel.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class WidgetPlannerTest {
    @Test
    fun expandedStylesFitThreeAtReferenceHeight() {
        for (style in ThemeStyle.STYLES) {
            val plan = WidgetPlanner.plan(result(upcoming = listOf(entry(2), entry(3))), 260f, 1f,
                extraChromeDp = ThemeStyle.extraChromeDp(style), titleLineSp = ThemeStyle.titleLineSp(style))
            assertEquals(style, 3, plan.holders.size)
        }
    }

    @Test
    fun onePixelBelowThreeRowBoundaryShowsTwo() {
        for (style in ThemeStyle.STYLES) {
            val required = 16f + 3 * (22f + ThemeStyle.extraChromeDp(style) + 16f + ThemeStyle.titleLineSp(style) + 16f)
            val plan = WidgetPlanner.plan(result(upcoming = listOf(entry(2), entry(3))), required - 1f, 1f,
                extraChromeDp = ThemeStyle.extraChromeDp(style), titleLineSp = ThemeStyle.titleLineSp(style))
            assertEquals(style, 2, plan.holders.size)
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
    fun keepsTheFirstHolderBeforeAllDayCaptions() {
        // Room for one holder only: captions give way to the next schedule.
        val plan = WidgetPlanner.plan(result(allDay = listOf(entry(6))), heightDp = 95f, fontScale = 1f)
        assertEquals(1, plan.holders.size)
        assertEquals(RowStatus.NEXT, plan.holders[0].status)
        assertEquals(emptyList<SnapshotEntry>(), plan.allDay)
    }

    @Test
    fun taller_title_fonts_fit_fewer_holders_instead_of_clipping() {
        // Expanded holders with a location: 22 + (16 + title + 16) * scale.
        val system = WidgetPlanner.plan(result(), heightDp = 230f, fontScale = 1.3f)
        val sketch = WidgetPlanner.plan(
            result(), heightDp = 230f, fontScale = 1.3f, extraChromeDp = 4f, titleLineSp = ThemeStyle.titleLineSp("sketch"),
        )
        assertTrue("${sketch.holders.size} vs ${system.holders.size}", sketch.holders.size < system.holders.size)
        val used = 16f + sketch.holders.sumOf { (22.0 + 4 + (16 + 25 + if (it.details != null) 16 else 0) * 1.3) }
        assertTrue("used $used", used <= 230.0)
        assertEquals(WidgetPlanner.DEFAULT_TITLE_LINE_SP, ThemeStyle.titleLineSp(null))
        assertEquals(17f, ThemeStyle.titleLineSp("pixel"))
    }
}
