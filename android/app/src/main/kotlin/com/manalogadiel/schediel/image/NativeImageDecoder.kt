package com.manalogadiel.schediel.image

import android.graphics.Bitmap
import android.graphics.ColorSpace
import android.graphics.ImageDecoder
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import kotlin.math.max

/** Registered on a serial background task queue; never decodes on the UI thread. */
class NativeImageDecoder : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "normalize") { result.notImplemented(); return }
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null) { result.error("unreadable", "Cannot read image", null); return }
        try {
            ImageDecodePolicy.validateEncoded(bytes)
            if (Build.VERSION.SDK_INT < 28) throw ImageDecodeFailure("unsupported")
            result.success(decode(bytes))
        } catch (error: ImageDecodeFailure) {
            result.error(error.code, "Cannot prepare this image", null)
        } catch (_: Exception) {
            result.error("unreadable", "Cannot decode this image on this device", null)
        }
    }

    @android.annotation.TargetApi(28)
    private fun decode(bytes: ByteArray): ByteArray {
        var bitmap = ImageDecoder.decodeBitmap(ImageDecoder.createSource(ByteBuffer.wrap(bytes))) { decoder, info, _ ->
            val (width, height) = ImageDecodePolicy.target(info.size.width, info.size.height, info.isAnimated)
            decoder.setTargetSize(width, height)
            decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            decoder.setTargetColorSpace(ColorSpace.get(ColorSpace.Named.SRGB))
            decoder.setOnPartialImageListener { false }
        }
        try {
            while (true) {
                val output = BoundedPngOutput()
                try {
                    if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)) throw ImageDecodeFailure("unreadable")
                    return output.toByteArray()
                } catch (_: OutputLimit) {
                    val smaller = Bitmap.createScaledBitmap(bitmap, max(1, (bitmap.width * .8).toInt()), max(1, (bitmap.height * .8).toInt()), true)
                    bitmap.recycle()
                    bitmap = smaller
                }
            }
        } finally {
            bitmap.recycle()
        }
    }

    private class OutputLimit : RuntimeException()
    private class BoundedPngOutput : ByteArrayOutputStream() {
        override fun write(value: Int) {
            if (count >= ImageDecodePolicy.OUTPUT_BYTES) throw OutputLimit()
            super.write(value)
        }
        override fun write(bytes: ByteArray, offset: Int, length: Int) {
            if (length > ImageDecodePolicy.OUTPUT_BYTES - count) throw OutputLimit()
            super.write(bytes, offset, length)
        }
    }
}
