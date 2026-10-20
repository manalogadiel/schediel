package com.manalogadiel.schediel.widget

import com.manalogadiel.schediel.R
import org.json.JSONObject
import kotlin.math.roundToInt

/** One brightness of the app theme as written in snapshot 1.1 (design §8.2). */
data class WidgetPalette(
    val accent: Int,
    val onAccent: Int,
    val neutralFill: Int,
    val cardInk: Int,
    val outline: Int,
    val categoryFills: Map<String, Int>,
    val clearOpacity: Double,
    val softTintOpacity: Double,
)

data class WidgetTheme(val style: String, val light: WidgetPalette, val dark: WidgetPalette) {
    fun palette(night: Boolean): WidgetPalette = if (night) dark else light
}

/** Colors for one themed holder; [fill] carries the surface opacity. */
data class HolderColors(val fill: Int, val ink: Int, val outline: Int)

/**
 * Pure theme logic for the native widget, mirroring
 * lib/features/widgets/domain/widget_theme.dart (holderColors).
 */
object ThemeStyle {
    val STYLES = setOf("soft", "pop", "pixel", "sketch")
    const val MIN_CLEAR = 0.70
    const val MIN_SOFT_TINT = 0.88
    private val CATEGORY_KEYS = setOf("blue", "green", "orange", "red", "purple", "gray")
    private val HEX = Regex("^#[0-9A-Fa-f]{6}$")

    /** "#RRGGBB" to an opaque ARGB int; anything else is rejected. */
    fun parseColor(value: String): Int {
        require(HEX.matches(value)) { "bad color $value" }
        return (0xFF000000L or value.substring(1).toLong(16)).toInt()
    }

    /** The snapshot theme, or null when absent or malformed (legacy look). */
    fun parse(json: JSONObject?): WidgetTheme? {
        if (json == null) return null
        return try {
            val style = json.getString("style")
            require(style in STYLES)
            WidgetTheme(style, palette(json.getJSONObject("light")), palette(json.getJSONObject("dark")))
        } catch (e: Exception) {
            null
        }
    }

    private fun palette(json: JSONObject): WidgetPalette {
        val fills = json.getJSONObject("categoryFills")
        val opacity = json.getJSONObject("opacity")
        val clear = opacity.getDouble("clear")
        val soft = opacity.getDouble("softTint")
        require(clear in 0.0..1.0 && soft in 0.0..1.0)
        // Never more see-through than the tested starting points (design §8.3).
        return WidgetPalette(
            accent = parseColor(json.getString("accent")),
            onAccent = parseColor(json.getString("onAccent")),
            neutralFill = parseColor(json.getString("neutralFill")),
            cardInk = parseColor(json.getString("cardInk")),
            outline = parseColor(json.getString("outline")),
            categoryFills = CATEGORY_KEYS.associateWith { parseColor(fills.getString(it)) },
            clearOpacity = clear.coerceAtLeast(MIN_CLEAR),
            softTintOpacity = soft.coerceAtLeast(MIN_SOFT_TINT),
        )
    }

    fun opacity(palette: WidgetPalette, surface: String): Double = when (surface) {
        "clear" -> palette.clearOpacity
        "softTint" -> palette.softTintOpacity
        else -> 1.0
    }

    /** Next holders use the accent; others their category fill or neutral. */
    fun holderColors(palette: WidgetPalette, next: Boolean, categoryColor: String?, surface: String): HolderColors {
        val base = if (next) palette.accent else palette.categoryFills[categoryColor] ?: palette.neutralFill
        val ink = if (next) palette.onAccent else palette.cardInk
        val alpha = (opacity(palette, surface) * 255).roundToInt().coerceIn(0, 255)
        return HolderColors(fill = (alpha shl 24) or (base and 0xFFFFFF), ink = ink, outline = palette.outline)
    }

    /** One layout per style family; null theme keeps the original layout. */
    fun layoutFor(theme: WidgetTheme?): Int = when (theme?.style) {
        null -> R.layout.widget_schedule
        "pop" -> R.layout.widget_schedule_pop
        "pixel" -> R.layout.widget_schedule_pixel
        "sketch" -> R.layout.widget_schedule_sketch
        else -> R.layout.widget_schedule_soft
    }

    /**
     * One image alpha has to serve both palettes (RemoteViews cannot switch
     * alpha with night mode), so use the more opaque one: readable in both.
     */
    fun sharedAlpha(light: HolderColors, dark: HolderColors): Int = maxOf(light.fill ushr 24, dark.fill ushr 24)

    /** Reserved layout padding, even when a translucent surface hides its shadow. */
    fun extraChromeDp(style: String?): Float = if (style == "pop" || style == "pixel") 3f else 0f

    /** Title line height (sp) for the style's title font; Caveat and Silkscreen differ from the system font. */
    fun titleLineSp(style: String?): Float = when (style) {
        "sketch" -> 25f
        "pixel" -> 17f
        else -> WidgetPlanner.DEFAULT_TITLE_LINE_SP
    }

    /** Hard shadows imply an opaque card, so only the solid surface draws them. */
    fun showsShadow(style: String, surface: String): Boolean = (style == "pop" || style == "pixel") && surface == "solid"
}
