package com.manalogadiel.schediel.image

import org.junit.Assert.*
import org.junit.Test
import java.nio.ByteBuffer

class ImageDecodePolicyTest {
    private fun header(brand: String): ByteArray = ByteBuffer.allocate(20).putInt(20)
        .put("ftyp".toByteArray()).put(brand.toByteArray()).putInt(0).put("mif1".toByteArray()).array()

    private fun fails(code: String, action: () -> Unit) {
        try { action(); fail("Expected $code") } catch (error: ImageDecodeFailure) { assertEquals(code, error.code) }
    }

    @Test fun validatesBytesAndRejectsSequencesInsteadOfTrustingAnExtension() {
        ImageDecodePolicy.validateEncoded(header("heic"))
        ImageDecodePolicy.validateEncoded(header("avif"))
        fails("unsupported") { ImageDecodePolicy.validateEncoded(header("avis")) }
        fails("unsupported") { ImageDecodePolicy.validateEncoded(header("msf1")) }
        fails("unsupported") { ImageDecodePolicy.validateEncoded("not an image.heic".toByteArray()) }
        fails("unreadable") { ImageDecodePolicy.validateEncoded(header("heic").also { it[3] = 100 }) }
        fails("tooLarge") { ImageDecodePolicy.validateEncoded(ByteArray(ImageDecodePolicy.SOURCE_BYTES + 1)) }
    }

    @Test fun enforcesHeaderPixelLimitsBeforeAllocatingABitmap() {
        fails("tooLarge") { ImageDecodePolicy.target(40000001, 1) }
        fails("tooLarge") { ImageDecodePolicy.target(Int.MAX_VALUE, Int.MAX_VALUE) }
        fails("unreadable") { ImageDecodePolicy.target(0, 100) }
        fails("unsupported") { ImageDecodePolicy.target(100, 100, animated = true) }
    }

    @Test fun requestsBoundedDecodeWithoutUpscalingSmallImages() {
        assertEquals(8 to 6, ImageDecodePolicy.target(8, 6))
        for ((width, height) in listOf(8000 to 5000, 5000 to 8000, 6000 to 6000, 40000000 to 1)) {
            val (w, h) = ImageDecodePolicy.target(width, height)
            assertTrue(w in 1..4096 && h in 1..4096)
            assertTrue(w.toLong() * h <= 12000000)
            assertTrue(w <= width && h <= height)
        }
    }
}
