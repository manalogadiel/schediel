package com.manalogadiel.schediel.widget

enum class RowStatus { NOW, NEXT, UPCOMING, REVIEW }

data class HolderRow(val entry: SnapshotEntry, val status: RowStatus, val emphasized: Boolean, val details: String?)

data class WidgetPlan(val allDay: List<SnapshotEntry>, val holders: List<HolderRow>)

/**
 * Chooses what a widget instance shows (SCHEDULER_SPEC.md 5.2-5.3):
 * Now, then Next, then Upcoming, then one "needs review" entry; at most two
 * All day captions. Large text hides details before entries; a short widget
 * shows fewer entries, and the next schedule wins over captions.
 */
object WidgetPlanner {
    const val MAX_EXPANDED = 4
    const val MAX_COMPACT = 2
    const val MAX_ALL_DAY = 2
    const val LARGE_TEXT_SCALE = 1.3f

    private const val ROOT_PADDING_DP = 16f
    private const val HOLDER_CHROME_DP = 22f
    private const val SMALL_LINE_SP = 16f
    private const val TITLE_LINE_SP = 20f
    private const val CAPTION_MARGIN_DP = 4f

    const val DEFAULT_TITLE_LINE_SP = TITLE_LINE_SP

    /**
     * [extraChromeDp]: per-holder space themed shapes add (offset shadow);
     * [titleLineSp]: the title line height of the layout's title font.
     */
    fun plan(
        result: ReadResult,
        heightDp: Float?,
        fontScale: Float,
        extraChromeDp: Float = 0f,
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
        var captions = result.allDay.take(MAX_ALL_DAY)
        if (heightDp == null || heightDp <= 0f) return WidgetPlan(captions, candidates)

        val available = heightDp - ROOT_PADDING_DP
        val captionHeight = SMALL_LINE_SP * fontScale + CAPTION_MARGIN_DP
        fun holderHeight(row: HolderRow) =
            HOLDER_CHROME_DP + extraChromeDp + (SMALL_LINE_SP + titleLineSp + if (row.details != null) SMALL_LINE_SP else 0f) * fontScale

        fun fitting(captionCount: Int): List<HolderRow> {
            var used = captionCount * captionHeight
            val shown = mutableListOf<HolderRow>()
            for (row in candidates) {
                used += holderHeight(row)
                if (used > available) break
                shown += row
            }
            return shown
        }

        var holders = fitting(captions.size)
        while (holders.isEmpty() && captions.isNotEmpty() && candidates.isNotEmpty()) {
            captions = captions.dropLast(1)
            holders = fitting(captions.size)
        }
        if (holders.isEmpty() && candidates.isNotEmpty()) {
            // Too short for a full holder: keep the essential title and time.
            holders = listOf(candidates.first().copy(details = null))
        }
        return WidgetPlan(captions, holders)
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
