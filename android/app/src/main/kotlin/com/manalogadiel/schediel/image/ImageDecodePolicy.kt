package com.manalogadiel.schediel.image

import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

internal class ImageDecodeFailure(val code: String) : RuntimeException()

internal object ImageDecodePolicy {
    const val SOURCE_BYTES = 10 * 1024 * 1024
    const val OUTPUT_BYTES = 5 * 1024 * 1024
    private const val SOURCE_PIXELS = 40_000_000L
    private const val OUTPUT_PIXELS = 12_000_000L
    private const val MAX_DIMENSION = 4096

    fun validateEncoded(bytes: ByteArray) {
        if (bytes.size > SOURCE_BYTES) throw ImageDecodeFailure("tooLarge")
        if (bytes.size < 16 || String(bytes, 4, 4, Charsets.US_ASCII) != "ftyp") throw ImageDecodeFailure("unsupported")
        val size = java.nio.ByteBuffer.wrap(bytes, 0, 4).int
        if (size < 16 || size > bytes.size || size > 1024 || size % 4 != 0) throw ImageDecodeFailure("unreadable")
        val brands = (8 until size step 4).filter { it != 12 }.map { String(bytes, it, 4, Charsets.US_ASCII) }
        if (brands.any { it in setOf("hevc", "hevx", "msf1", "avis") }) throw ImageDecodeFailure("unsupported")
        if (brands.none { it in setOf("heic", "heix", "mif1", "avif") }) throw ImageDecodeFailure("unsupported")
    }

    fun target(width: Int, height: Int, animated: Boolean = false): Pair<Int, Int> {
        if (width < 1 || height < 1) throw ImageDecodeFailure("unreadable")
        val pixels = width.toLong() * height
        if (pixels > SOURCE_PIXELS) throw ImageDecodeFailure("tooLarge")
        if (animated) throw ImageDecodeFailure("unsupported")
        val scale = min(1.0, min(MAX_DIMENSION.toDouble() / max(width, height), sqrt(OUTPUT_PIXELS.toDouble() / pixels)))
        return max(1, floor(width * scale).toInt()) to max(1, floor(height * scale).toInt())
    }
}
