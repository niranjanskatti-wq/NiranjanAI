package com.essential.app.share

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException

/** Minimal read-only provider that hands files in cache/share to the Android share sheet. */
class ShareProvider : ContentProvider() {
    companion object {
        fun authority(ctx: Context) = ctx.packageName + ".share"
        fun uriFor(ctx: Context, name: String): Uri = Uri.parse("content://${authority(ctx)}/${Uri.encode(name)}")
    }

    private fun file(uri: Uri): File {
        val name = uri.lastPathSegment ?: throw FileNotFoundException()
        val dir = File(context!!.cacheDir, "share")
        val f = File(dir, name)
        if (!f.canonicalPath.startsWith(dir.canonicalPath) || !f.exists()) throw FileNotFoundException(name)
        return f
    }

    override fun onCreate() = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor =
        ParcelFileDescriptor.open(file(uri), ParcelFileDescriptor.MODE_READ_ONLY)

    override fun getType(uri: Uri): String = when (uri.lastPathSegment?.substringAfterLast('.')?.lowercase()) {
        "json" -> "application/json"; "csv" -> "text/csv"; "png" -> "image/png"; "txt" -> "text/plain"
        else -> "application/octet-stream"
    }

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor {
        val f = file(uri)
        val cols = projection ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        val c = MatrixCursor(cols)
        c.addRow(cols.map { when (it) { OpenableColumns.DISPLAY_NAME -> f.name; OpenableColumns.SIZE -> f.length(); else -> null } })
        return c
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?) = 0
}
