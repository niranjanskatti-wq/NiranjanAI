package com.lovebombing.app.ui

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent

private val whatsAppPackages = listOf("com.whatsapp", "com.whatsapp.w4b")

/**
 * Opens WhatsApp with [text] pre-filled (she's picked as the contact there).
 * Falls back to the Android share sheet if WhatsApp isn't installed.
 * Pure intent hand-off: the app itself never touches the network.
 */
fun shareToWhatsApp(context: Context, text: String) {
    for (pkg in whatsAppPackages) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            setPackage(pkg)
        }
        try {
            context.startActivity(intent)
            return
        } catch (_: ActivityNotFoundException) {
            // try the next one
        }
    }
    shareAnywhere(context, text)
}

fun shareAnywhere(context: Context, text: String) {
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, text)
    }
    context.startActivity(Intent.createChooser(send, "Send to her"))
}

fun copyToClipboard(context: Context, text: String) {
    val cm = context.getSystemService(ClipboardManager::class.java)
    cm.setPrimaryClip(ClipData.newPlainText("Love Bombing message", text))
}
