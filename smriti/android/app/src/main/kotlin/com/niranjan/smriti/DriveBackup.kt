package com.niranjan.smriti

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File

/**
 * Copies a backup into a file the user picked once with Android's "Save to"
 * screen (usually in Google Drive). Smriti keeps permission to that one file,
 * so later backups overwrite it; Google Drive keeps the older versions.
 */
object DriveBackup {
    fun write(ctx: Context, uri: String, path: String): Boolean = try {
        ctx.contentResolver.openOutputStream(Uri.parse(uri), "wt")!!.use { out ->
            File(path).inputStream().use { it.copyTo(out) }
        }
        true
    } catch (_: Exception) {
        false
    }

    fun name(ctx: Context, uri: String): String? = try {
        ctx.contentResolver.query(Uri.parse(uri), arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) it.getString(0) else null
        }
    } catch (_: Exception) {
        null
    }

    /** True while Smriti still has permission to write the file. */
    fun allowed(ctx: Context, uri: String): Boolean =
        ctx.contentResolver.persistedUriPermissions.any { it.uri.toString() == uri && it.isWritePermission }
}
