package com.manalogadiel.schediel.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.text.TextPaint
import android.text.TextUtils
import androidx.core.graphics.createBitmap
import com.manalogadiel.schediel.R
import kotlin.math.ceil

/**
 * Widget titles in a bundled display font. Launchers inflate RemoteViews
 * without app font resources (verified on a Samsung One UI launcher), so the
 * title is drawn here in white, then tinted per day/night by the renderer.
 */
object TitleBitmap {
    /** Space beside the title inside a holder: root and holder padding, outline and shadow. */
    const val HORIZONTAL_CHROME_DP = 16f + 24f + 4f + 3f

    /** Usable title width, or null when the widget width is unknown. */
    fun maxWidthPx(widgetWidthDp: Float?, density: Float): Int? {
        if (widgetWidthDp == null || widgetWidthDp <= HORIZONTAL_CHROME_DP) return null
        return ((widgetWidthDp - HORIZONTAL_CHROME_DP) * density).toInt()
    }

    /** Title size in sp for the style (matches the generated layouts). */
    fun sizeSp(style: String): Float = if (style == "sketch") 19f else 13f

    private fun typeface(context: Context, style: String, bold: Boolean): Typeface? = try {
        val base = context.resources.getFont(if (style == "sketch") R.font.caveat_variable else R.font.silkscreen)
        val weight = if (bold) 700 else if (style == "sketch") 600 else 400
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) Typeface.create(base, weight, false) else base
    } catch (e: Exception) {
        null
    }

    /** White title bitmap, ellipsized to [maxWidthPx]; null if the font cannot load. */
    fun render(context: Context, style: String, title: String, bold: Boolean, fontScale: Float, maxWidthPx: Int): Bitmap? {
        val face = typeface(context, style, bold) ?: return null
        val metrics = context.resources.displayMetrics
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = face
            color = Color.WHITE
            textSize = sizeSp(style) * fontScale * metrics.density
        }
        val shown = TextUtils.ellipsize(title, paint, maxWidthPx - paint.textSize * 0.25f, TextUtils.TruncateAt.END).toString()
        if (shown.isEmpty()) return null
        val fm = paint.fontMetrics
        // Handwritten glyphs overhang their advance width; leave room so the last letter is not cut.
        val overhang = paint.textSize * 0.25f
        val width = ceil(paint.measureText(shown) + overhang).toInt().coerceIn(1, maxWidthPx)
        val height = ceil(fm.descent - fm.ascent).toInt().coerceAtLeast(1)
        return createBitmap(width, height).also {
            Canvas(it).drawText(shown, 0f, -fm.ascent, paint)
        }
    }
}
