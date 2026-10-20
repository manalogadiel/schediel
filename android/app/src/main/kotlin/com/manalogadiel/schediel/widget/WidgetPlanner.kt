package com.manalogadiel.schediel.widget

enum class RowStatus { NOW, NEXT, UPCOMING, REVIEW }

data class HolderRow(val entry: SnapshotEntry, val status: RowStatus, val emphasized: Boolean, val details: String?)

data class WidgetPlan(val allDay: List<SnapshotEntry>, val holders: List<HolderRow>)

/**
 * Chooses what a widget instance shows (SCHEDULER_SPEC.md 5.2-5.3):
 * Now, then Next, then Upcoming, then one "needs review" entry; at most two
 * All day captions. Optional details and captions give way before schedules;
 * even the smallest size has a readable Open Schediel fallback.
 */
object WidgetPlanner {
    const val MAX_EXPANDED = 4
    const val MAX_COMPACT = 2
    const val MAX_ALL_DAY = 2
    const val LARGE_TEXT_SCALE = 1.3f

    private const val ROOT_PADDING_DP = 16f
    const val DEFAULT_HOLDER_CHROME_DP = 22f
    private const val SMALL_LINE_SP = 16f
    private const val TITLE_LINE_SP = 20f
    private const val CAPTION_MARGIN_DP = 4f

    const val DEFAULT_TITLE_LINE_SP = TITLE_LINE_SP

    /**
     * [holderChromeDp]: a holder's non-text height (margin, inset, padding)
     * measured from its layout; [titleLineSp]: the title font's line height.
     */
    fun plan(
        result: ReadResult,
        heightDp: Float?,
        fontScale: Float,
        holderChromeDp: Float = DEFAULT_HOLDER_CHROME_DP,
        titleLineSp: Float = TITLE_LINE_SP,
    ): WidgetPlan {
        val settings = result.settings ?: return WidgetPlan(emptyList(), emptyList())
        val compact = settings.layout == "compact"
        val showDetails = !compact && fontScale < LARGE_TEXT_SCALE
        val candidates = buildList {
            result.ongoing.forEach { add(row(it, RowStatus.NOW, false, settings, showDetails)) }
            result.next?.let { add(row(it, RowStatus.NEXT, settings.nextEmphasis, settings, showDetails)) }
            result.upcoming.forEach { add(row(it, RowStatus.UPCOMING, false, settings, showDetails)) }
            result.needsReview.take(1).forEach { add(row(it, RowStatus.REVIEW, false, settings, showDetails)) }
        }.take(if (compact) MAX_COMPACT else MAX_EXPANDED)
        val captions = result.allDay.take(MAX_ALL_DAY)
        if (heightDp == null || heightDp <= 0f) return WidgetPlan(captions, candidates)
        if (candidates.isEmpty()) {
            val captionHeight = SMALL_LINE_SP * fontScale + CAPTION_MARGIN_DP
            val count = ((heightDp - ROOT_PADDING_DP) / captionHeight).toInt().coerceAtLeast(0)
            return WidgetPlan(captions.take(count), emptyList())
        }
        return sized(result, fontScale, holderChromeDp, titleLineSp)
            .lastOrNull { it.first <= heightDp }?.second ?: WidgetPlan(emptyList(), emptyList())
    }

    private fun holderHeight(row: HolderRow, fontScale: Float, chrome: Float, title: Float) =
        chrome + (SMALL_LINE_SP + title + if (row.details != null) SMALL_LINE_SP else 0f) * fontScale

    /**
     * A size frontier: each row count has a title/time-only variant before
     * captions/details are added. A taller variant must never show fewer
     * schedules than a shorter one. Android 12+ picks the largest fitting
     * RemoteViews size; older hosts use the same frontier in plan().
     * At most 13 variants (three per count plus the tiny-widget fallback).
     */
    fun sized(
        result: ReadResult,
        fontScale: Float,
        holderChromeDp: Float = DEFAULT_HOLDER_CHROME_DP,
        titleLineSp: Float = TITLE_LINE_SP,
    ): List<Pair<Float, WidgetPlan>> {
        val full = plan(result, null, fontScale, holderChromeDp, titleLineSp)
        if (full.holders.isEmpty()) return emptyList()
        val captionHeight = SMALL_LINE_SP * fontScale + CAPTION_MARGIN_DP
        fun height(plan: WidgetPlan): Float = ROOT_PADDING_DP + plan.allDay.size * captionHeight +
            plan.holders.sumOf { holderHeight(it, fontScale, holderChromeDp, titleLineSp).toDouble() }.toFloat()
        fun quality(a: WidgetPlan, b: WidgetPlan): Int = compareValuesBy(a, b,
            { it.holders.size }, { it.allDay.size }, { it.holders.count { row -> row.details != null } })
        val variants = buildList {
            add(1f to WidgetPlan(emptyList(), emptyList()))
            for (count in 1..full.holders.size) {
                val rows = full.holders.take(count)
                val bare = rows.map { it.copy(details = null) }
                for (plan in listOf(WidgetPlan(emptyList(), bare), WidgetPlan(full.allDay, bare), WidgetPlan(full.allDay, rows))) {
                    add(height(plan) to plan)
                }
            }
        }
        val frontier = mutableListOf<Pair<Float, WidgetPlan>>()
        for (variant in variants.sortedWith(compareBy<Pair<Float, WidgetPlan>> { it.first }
            .thenComparator { a, b -> quality(a.second, b.second) })) {
            val previous = frontier.lastOrNull()
            if (previous != null && quality(variant.second, previous.second) <= 0) continue
            if (previous?.first == variant.first) frontier.removeAt(frontier.lastIndex)
            frontier += variant
        }
        return frontier
    }

    private fun row(entry: SnapshotEntry, status: RowStatus, emphasized: Boolean, settings: WidgetSettings, showDetails: Boolean): HolderRow {
        val details = if (!showDetails) {
            null
        } else {
            listOfNotNull(
                entry.location.takeIf { settings.showLocation },
                entry.professor.takeIf { settings.showProfessor },
                entry.subtitle.takeIf { settings.showSubtitle },
            ).filter { it.isNotBlank() }.joinToString(" · ").ifEmpty { null }
        }
        return HolderRow(entry, status, emphasized, details)
    }
}
