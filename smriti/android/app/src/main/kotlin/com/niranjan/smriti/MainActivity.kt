package com.niranjan.smriti

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Shows over the lock screen only while the midnight alarm is on screen,
 * so the rest of Smriti never appears over a locked phone.
 */
class MainActivity : FlutterFragmentActivity() {
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smriti/calendar").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "calendars" -> result.success(PhoneCalendar.calendars(contentResolver))
                    "upsert" -> {
                        @Suppress("UNCHECKED_CAST")
                        result.success(PhoneCalendar.upsert(contentResolver, call.arguments as Map<String, Any?>))
                    }
                    "delete" -> {
                        @Suppress("UNCHECKED_CAST")
                        PhoneCalendar.delete(contentResolver, (call.arguments as List<Number>).map { it.toLong() })
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: SecurityException) {
                result.error("permission", e.message, null)
            } catch (e: Exception) {
                result.error("failed", e.message, null)
            }
        }
    }
}
