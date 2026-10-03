package com.niranjan.deepwork

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager

/**
 * Watches which app comes to the foreground. During a focus session, opening a paused app shows
 * the "Stay with it" screen instead. It never reads screen content; the only thing recorded is the
 * attempt itself, which Deepwork reads back as a distraction.
 */
class BlockerService : AccessibilityService() {
    private val alwaysAllowed = HashSet<String>()

    override fun onServiceConnected() {
        super.onServiceConnected()
        refreshAlwaysAllowed()
    }

    private fun refreshAlwaysAllowed() {
        alwaysAllowed.clear()
        alwaysAllowed += listOf(packageName, "com.android.systemui", "android")
        val pm = packageManager
        // Home screens, the phone app (calls must always work) and keyboards are never blocked.
        pm.queryIntentActivities(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), 0).forEach { alwaysAllowed += it.activityInfo.packageName }
        pm.queryIntentActivities(Intent(Intent.ACTION_DIAL), 0).forEach { alwaysAllowed += it.activityInfo.packageName }
        (getSystemService(INPUT_METHOD_SERVICE) as? InputMethodManager)?.enabledInputMethodList?.forEach { alwaysAllowed += it.packageName }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (!BlockerState.active(this)) return
        if (alwaysAllowed.isEmpty()) refreshAlwaysAllowed()
        if (pkg in alwaysAllowed) return

        val list = BlockerState.packages(this)
        val blocked = if (BlockerState.mode(this) == "allow") {
            // In allow-only mode, block real apps (with a launcher icon), not system overlays.
            pkg !in list && packageManager.getLaunchIntentForPackage(pkg) != null
        } else {
            pkg in list
        }
        if (!blocked) return

        val label = try {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
        } catch (e: Exception) {
            pkg
        }
        BlockerState.recordAttempt(this, pkg, label)
        startActivity(
            Intent(this, BlockedActivity::class.java)
                .putExtra("label", label)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NO_ANIMATION),
        )
    }

    override fun onInterrupt() {}
}
