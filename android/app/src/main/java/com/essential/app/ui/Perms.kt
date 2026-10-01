package com.essential.app.ui

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.essential.app.notify.Alarms
import com.essential.app.notify.Notifier

/** Permission status and one-tap fixes, plus phone-brand specific battery guidance. */
object Perms {
    fun notifications(ctx: Context): Boolean = Notifier.nm(ctx).areNotificationsEnabled() &&
        (Build.VERSION.SDK_INT < 33 || ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
    fun exactAlarms(ctx: Context): Boolean = Alarms.canExact(ctx)
    fun battery(ctx: Context): Boolean = ctx.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(ctx.packageName)
    fun mic(ctx: Context): Boolean = ctx.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    fun allCritical(ctx: Context) = notifications(ctx) && exactAlarms(ctx) && battery(ctx)

    fun fixNotifications(a: MainActivity, done: () -> Unit) {
        if (Build.VERSION.SDK_INT >= 33 && a.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED &&
            !a.repo.settings.bool("notif_asked")) {
            a.repo.settings.set("notif_asked", true)
            a.requestPerm(Manifest.permission.POST_NOTIFICATIONS) { done() }
        } else {
            val i = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, a.packageName)
            a.startForResult(i) { _, _ -> done() }
        }
    }

    fun fixExact(a: MainActivity, done: () -> Unit) {
        if (Build.VERSION.SDK_INT >= 31) {
            val i = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${a.packageName}"))
            a.startForResult(i) { _, _ -> Alarms.schedule(a); done() }
        } else done()
    }

    @android.annotation.SuppressLint("BatteryLife")
    fun fixBattery(a: MainActivity, done: () -> Unit) {
        val i = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:${a.packageName}"))
        a.startForResult(i) { _, _ -> done() }
    }

    fun openAppDetails(a: MainActivity) {
        a.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${a.packageName}")))
    }

    data class Brand(val name: String, val steps: List<String>, val intents: List<ComponentName>)

    fun brand(): Brand {
        val m = (Build.MANUFACTURER + " " + Build.BRAND).lowercase()
        return when {
            m.contains("xiaomi") || m.contains("redmi") || m.contains("poco") -> Brand("Xiaomi / Redmi / POCO", listOf(
                "Open Security → Permissions → Autostart, and turn Essential on.",
                "Settings → Apps → Essential → Battery saver → No restrictions.",
                "Recent apps: long-press Essential → tap the lock icon so it isn't cleared."),
                listOf(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")))
            m.contains("vivo") || m.contains("iqoo") -> Brand("Vivo / iQOO", listOf(
                "i Manager → App manager → Autostart manager → allow Essential.",
                "Settings → Battery → Background power consumption → Essential → Allow.",
                "Recent apps: pull Essential down to lock it."),
                listOf(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
                    ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
            m.contains("realme") -> Brand("Realme", listOf(
                "Settings → Apps → Auto launch → turn Essential on.",
                "Settings → Battery → App battery management → Essential → Allow background activity.",
                "Recent apps: tap ⋮ on Essential → Lock."),
                listOf(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
                    ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
            m.contains("oppo") -> Brand("Oppo", listOf(
                "Settings → Apps → Auto launch (or Startup manager) → turn Essential on.",
                "Settings → Battery → Essential → Allow background activity / Don't optimise.",
                "Recent apps: tap ⋮ on Essential → Lock."),
                listOf(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
                    ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")))
            m.contains("oneplus") -> Brand("OnePlus", listOf(
                "Settings → Apps → Essential → Battery usage → Allow background activity.",
                "Settings → Battery → Battery optimisation → Essential → Don't optimise.",
                "Recent apps: lock Essential so it isn't cleared."),
                listOf(ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")))
            m.contains("samsung") -> Brand("Samsung", listOf(
                "Settings → Apps → Essential → Battery → Unrestricted.",
                "Settings → Battery → Background usage limits → make sure Essential is not in Sleeping or Deep sleeping apps.",
                "Add Essential to Never sleeping apps."),
                listOf(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity")))
            m.contains("motorola") || m.contains("moto") -> Brand("Motorola", listOf(
                "Settings → Apps → Essential → App battery usage → Unrestricted.",
                "Keep Essential out of Adaptive Battery restrictions."), emptyList())
            else -> Brand(Build.MANUFACTURER.replaceFirstChar { it.uppercase() }, listOf(
                "Settings → Apps → Essential → Battery → Unrestricted / Don't optimise.",
                "If your phone has an Autostart list, allow Essential."), emptyList())
        }
    }

    /** Try each brand-specific page; fall back to the app's details page. */
    fun openBrandSettings(a: MainActivity) {
        for (cn in brand().intents) {
            val i = Intent().setComponent(cn).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try { a.startActivity(i); return } catch (_: Exception) { }
        }
        openAppDetails(a)
    }
}
