package com.niranjan.smriti

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Shows over the lock screen only while the midnight alarm is on screen,
 * so the rest of Smriti never appears over a locked phone.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "smriti/window"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyAlarmFlags(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        applyAlarmFlags(intent)
    }

    private fun applyAlarmFlags(intent: Intent?) {
        val payload = intent?.getStringExtra("payload") ?: return
        if (payload.contains("\"k\":\"mid\"")) setLockScreen(true)
    }

    private fun setLockScreen(on: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(on)
            setTurnScreenOn(on)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (on) window.addFlags(flags) else window.clearFlags(flags)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setLockScreen" -> {
                    setLockScreen(call.arguments as? Boolean ?: false)
                    result.success(null)
                }
                "manufacturer" -> result.success(Build.MANUFACTURER ?: "")
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                else -> result.notImplemented()
            }
        }
    }
}
