package com.linkmax.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.linkmax.app/share"
    private var channel: MethodChannel? = null
    private var pendingShare: String? = null

    private fun extractSharedText(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action != Intent.ACTION_SEND) return null
        if (intent.type != "text/plain") return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShare" -> {
                        val text = pendingShare
                        pendingShare = null
                        result.success(text)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        pendingShare = extractSharedText(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val text = extractSharedText(intent) ?: return
        setIntent(intent)
        val ch = channel
        if (ch != null) {
            ch.invokeMethod("onShareReceived", text)
        } else {
            pendingShare = text
        }
    }
}
