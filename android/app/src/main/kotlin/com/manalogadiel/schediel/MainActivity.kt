package com.manalogadiel.schediel

import android.content.Intent
import com.manalogadiel.schediel.bridge.NativeBridge
import com.manalogadiel.schediel.image.NativeImageDecoder
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeBridge.CHANNEL)
            .setMethodCallHandler(NativeBridge(applicationContext))
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "schediel/image_decode", StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue())
            .setMethodCallHandler(NativeImageDecoder())
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
