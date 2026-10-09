package com.goldvault.saf

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileNotFoundException

/**
 * Lets the user pick ONE file once (for example in Google Drive) and then keeps
 * overwriting it with fresh backups. Works in WorkManager background jobs too,
 * because writing only needs the application context and the persisted grant.
 */
class GvSafPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var binding: ActivityPluginBinding? = null
    private var pending: MethodChannel.Result? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
        context = b.applicationContext
        channel = MethodChannel(b.binaryMessenger, "goldvault/saf")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "create" -> create(call.argument<String>("name") ?: "GoldVault-backup.gvb", result)
            "write" -> write(call.argument<String>("uri")!!, call.argument<String>("path")!!, result)
            "canWrite" -> {
                val uri = call.argument<String>("uri")!!
                result.success(context.contentResolver.persistedUriPermissions.any {
                    it.uri.toString() == uri && it.isWritePermission
                })
            }
            "release" -> {
                try {
                    context.contentResolver.releasePersistableUriPermission(
                        Uri.parse(call.argument<String>("uri")!!),
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    )
                } catch (_: Exception) {
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun create(name: String, result: MethodChannel.Result) {
        val activity: Activity = binding?.activity ?: return result.error("no_activity", null, null)
        if (pending != null) return result.error("busy", null, null)
        pending = result
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, name)
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
        }
        try {
            activity.startActivityForResult(intent, REQUEST)
        } catch (e: Exception) {
            pending = null
            result.error("no_picker", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        try {
            context.contentResolver.takePersistableUriPermission(
                uri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        } catch (_: Exception) {
            // Provider without persistable grants: still usable while the app runs.
        }
        result.success(
            mapOf(
                "uri" to uri.toString(),
                "name" to displayName(uri),
                "drive" to (uri.authority?.contains("com.google.android.apps.docs") == true)
            )
        )
        return true
    }

    private fun displayName(uri: Uri): String? = try {
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) it.getString(0) else null
        }
    } catch (_: Exception) {
        null
    }

    private fun write(uriText: String, path: String, result: MethodChannel.Result) {
        Thread {
            try {
                val uri = Uri.parse(uriText)
                val resolver = context.contentResolver
                val out = try {
                    resolver.openOutputStream(uri, "wt")
                } catch (_: IllegalArgumentException) {
                    resolver.openOutputStream(uri, "w")
                } catch (_: FileNotFoundException) {
                    resolver.openOutputStream(uri, "w")
                } ?: throw FileNotFoundException("No stream")
                out.use { o -> File(path).inputStream().use { it.copyTo(o, 1 shl 16) } }
                main.post { result.success(true) }
            } catch (e: SecurityException) {
                main.post { result.error("no_access", e.message, null) }
            } catch (e: FileNotFoundException) {
                main.post { result.error("no_access", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("io", e.message, null) }
            }
        }.start()
    }

    override fun onAttachedToActivity(b: ActivityPluginBinding) {
        binding = b
        b.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(b: ActivityPluginBinding) = onAttachedToActivity(b)

    override fun onDetachedFromActivity() {
        binding?.removeActivityResultListener(this)
        binding = null
    }

    companion object {
        private const val REQUEST = 47311
    }
}
