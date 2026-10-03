package com.niranjan.deepwork

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.provider.Settings
import android.util.Base64
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.security.MessageDigest

/**
 * Hosts the Flutter UI and exposes Deepwork's Android-only features over the
 * `deepwork/native` channel: app blocking, keep-screen-on and signing info.
 */
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "deepwork/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "blockerStatus" -> result.success(mapOf("serviceEnabled" to isServiceEnabled(), "active" to BlockerState.active(this)))
                "openBlockerSettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(null)
                }
                "openAppSettings" -> {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, android.net.Uri.fromParts("package", packageName, null)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(null)
                }
                "getInstalledApps" -> Thread {
                    val apps = try { installedApps() } catch (e: Exception) { emptyList() }
                    runOnUiThread { result.success(apps) }
                }.start()
                "startBlocking" -> {
                    val until = (call.argument<Number>("until") ?: 0).toLong()
                    val mode = call.argument<String>("mode") ?: "block"
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val task = call.argument<String>("taskTitle") ?: ""
                    BlockerState.start(this, until, mode, packages.toSet(), task)
                    result.success(null)
                }
                "stopBlocking" -> {
                    BlockerState.stop(this)
                    result.success(null)
                }
                "takeBlockedAttempts" -> result.success(BlockerState.takeAttempts(this))
                "setKeepAwake" -> {
                    if (call.argument<Boolean>("on") == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                }
                "getSigningInfo" -> result.success(mapOf("packageName" to packageName, "sha1" to signingSha1()))
                else -> result.notImplemented()
            }
        }
    }

    private fun isServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
        val me = ComponentName(this, BlockerService::class.java)
        return enabled.split(':').any { it.equals(me.flattenToString(), true) || it.equals(me.flattenToShortString(), true) }
    }

    private fun installedApps(): List<Map<String, String>> {
        val pm = packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val seen = HashSet<String>()
        return pm.queryIntentActivities(launcher, 0)
            .filter { it.activityInfo.packageName != packageName && seen.add(it.activityInfo.packageName) }
            .map { ri ->
                mapOf(
                    "packageName" to ri.activityInfo.packageName,
                    "label" to ri.loadLabel(pm).toString(),
                    "icon" to iconToBase64(ri.loadIcon(pm)),
                )
            }
            .sortedBy { it["label"]!!.lowercase() }
    }

    private fun iconToBase64(d: android.graphics.drawable.Drawable): String = try {
        val size = 72
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        d.setBounds(0, 0, size, size)
        d.draw(Canvas(bmp))
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
    } catch (e: Exception) {
        ""
    }

    private fun signingSha1(): String = try {
        val sigs = if (Build.VERSION.SDK_INT >= 28) {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES).signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
        }
        val bytes = MessageDigest.getInstance("SHA-1").digest(sigs!![0].toByteArray())
        bytes.joinToString(":") { "%02X".format(it) }
    } catch (e: Exception) {
        ""
    }
}
