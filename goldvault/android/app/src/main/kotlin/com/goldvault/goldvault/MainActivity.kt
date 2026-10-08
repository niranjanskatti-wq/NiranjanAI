package com.goldvault.goldvault

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth (fingerprint / face unlock).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets Dart toggle FLAG_SECURE, which blocks screenshots / screen
        // recording and blanks the app in the recent-apps switcher.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "goldvault/secure")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "secure" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE,
                        )
                        result.success(null)
                    }
                    "unsecure" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
