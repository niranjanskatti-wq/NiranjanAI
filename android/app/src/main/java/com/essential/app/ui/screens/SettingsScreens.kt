package com.essential.app.ui.screens

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings as AS
import android.view.View
import com.essential.app.core.*
import com.essential.app.data.Cat
import com.essential.app.data.KeywordRule
import com.essential.app.data.Type
import com.essential.app.notify.Alarms
import com.essential.app.notify.Notifier
import com.essential.app.ui.*

class SettingsScreen(a: MainActivity) : Screen(a) {
    override fun content(): View = page {
        val s = repo.settings
        add(a.h1("Settings"), top = 8, bottom = 16)
        if (!Perms.allCritical(a)) add(a.card(12, Th.alpha(Th.yellow, 0.12f)) { a.push(PermissionsScreen(a)) }.apply {
            add(a.txt("Some permissions are off — reminders may be late. Tap to fix.", 14.5f))
        }, bottom = 12)

        group("Bottom tabs") {
            it.add(a.dimText("Choose which tabs appear at the bottom. Settings always stays so you can turn tabs back on."), top = 6, bottom = 2)
            val on = s.str("tabs").split(',').map { t -> t.trim() }.toMutableSet()
            val desc = mapOf("now" to "Current block, ONE thing, score", "log" to "Plan vs actual, hour by hour", "habits" to "Daily habit chains and calendars",
                "insights" to "Charts and weekly report", "tools" to "Goals, focus, sleep, reviews…")
            MainActivity.ALL_TABS.filter { t -> t.first != "settings" }.forEach { (id, label) ->
                it.add(a.switchRow(label, desc[id], id in on) { checked ->
                    if (checked) on.add(id) else on.remove(id)
                    s.set("tabs", MainActivity.ALL_TABS.map { t -> t.first }.filter { t -> t in on }.joinToString(","))
                    a.renderNav()
                })
            }
        }
        group("Your day") {
            it.add(a.listRow("Day & targets", "Wake/sleep, targets per mode, review time", "now") { a.push(TargetsScreen(a)) })
            it.add(a.listRow("Daily Score weights", "${s.int("w_eh")}/${s.int("w_work")}/${s.int("w_one")}/${s.int("w_plan")}/${s.int("w_routine")}/${s.int("w_sleep")}", "insights") { a.push(WeightsScreen(a)) })
            it.add(a.listRow("Schedule templates", null, "log") { a.push(TemplatesScreen(a)) })
            it.add(a.listRow("My activities", "Add, rename, recolour, archive", "tools") { a.push(VenturesScreen(a)) })
        }
        group("Reminders") {
            it.add(a.listRow("Notifications", "Which reminders, quiet hours, reliability", "bell") { a.push(NotificationSettingsScreen(a)) })
            it.add(a.listRow("Permissions & reliability", if (Perms.allCritical(a)) "All set" else "Needs attention", "check", if (Perms.allCritical(a)) Th.primary else Th.yellow) { a.push(PermissionsScreen(a)) })
            it.add(a.listRow("Phone-specific settings", Perms.brand().name, "settings") { a.push(PhoneHelpScreen(a)) })
            it.add(a.listRow("Test notification", "Sends one now", "bell") { Notifier.test(a); a.toast(if (Notifier.canPost(a)) "Sent" else "Notifications are off") })
        }
        group("Voice") {
            it.add(a.listRow("Voice language", if (s.str("voice_lang").startsWith("kn")) "ಕನ್ನಡ (Kannada) — needs the offline pack" else "English (India)", "mic") {
                s.set("voice_lang", if (s.str("voice_lang").startsWith("kn")) "en-IN" else "kn-IN"); a.refresh()
            })
            it.add(a.listRow("Voice keyword rules", "${repo.rules().size} rules auto-fill category and activity", "edit") { a.push(KeywordRulesScreen(a)) })
        }
        group("Appearance") {
            it.add(a.switchRow("Dark mode", "Default. Calm at night.", s.darkTheme) { on -> s.set("theme", if (on) "dark" else "light"); Th.dark = on; a.recreate() })
            it.add(a.switchRow("Haptic feedback", "A gentle tap when you log", s.bool("haptics")) { on -> s.set("haptics", on); App.haptics = on })
            it.add(a.switchRow("Always use India time (IST)", "Off = follow the phone's time zone", s.bool("use_ist")) { on ->
                s.set("use_ist", on); TimeUtil.zone = if (on) TimeUtil.IST else java.time.ZoneId.systemDefault(); Hooks.scheduleChanged(a); a.refresh()
            })
        }
        group("Your data") {
            it.add(a.listRow("Backup & restore", "Export to Downloads, restore, weekly auto-backup", "share") { a.push(BackupScreen(a)) })
            it.add(a.listRow("Export CSV", "Hour logs, reviews, habits, sleep", "copy") {
                val uris = Backup.exportCsv(a); a.shareUris(uris, "text/csv", "${App.NAME} CSV export"); a.toast("Saved to Downloads/Daily Chain")
            })
            if (repo.hasSampleData()) it.add(a.listRow("Clear sample data", "Removes only the 14 sample days", "trash", Th.red) {
                a.confirm("Clear sample data?", "Your own logs, goals and settings stay.", "Clear") { repo.clearSampleData(); Hooks.afterChange(a); a.refresh() }
            }) else it.add(a.listRow("Load sample data", "14 days of example logs, habits and sleep", "plus") {
                SampleData.load(a); a.toast("Sample data loaded"); a.refresh()
            })
        }
        add(a.card(16).apply {
            add(a.h3(App.NAME))
            add(a.dimText("Less, but better. Version ${a.packageManager.getPackageInfo(a.packageName, 0).versionName}"), top = 2)
            add(a.dimText("100% offline: this app has no internet permission. Your data lives only on this phone."), top = 6)
        })
    }

    private fun android.widget.LinearLayout.group(name: String, f: (android.widget.LinearLayout) -> Unit) {
        add(a.label(name), bottom = 6)
        val c = a.card(6)
        f(c)
        add(c, bottom = 14)
    }
}

class TargetsScreen(a: MainActivity) : Screen(a) {
    override val title = "Day & targets"
    override fun content(): View = page {
        val s = repo.settings
        fun timeRow(label: String, key: String) = a.listRow(label, TimeUtil.fmtTimeFull(s.int(key)), null) {
            a.pickTime(label, s.int(key)) { s.set(key, it); Hooks.scheduleChanged(a); a.refresh() }
        }
        fun numRow(label: String, key: String, suffix: String) = a.listRow(label, "${TimeUtil.fmtHours(s.dbl(key))}$suffix", null) {
            val sh = Sheet(a, label)
            val f = a.field(label, TimeUtil.fmtHours(s.dbl(key)), numeric = true, decimal = true)
            sh.add(f).actions("Save") { f.value.toDoubleOrNull()?.let { v -> s.set(key, v) }; sh.dismiss(); Hooks.scheduleChanged(a); a.refresh() }.show()
        }
        add(a.label("Normal Mode"), bottom = 6)
        add(a.card(6).apply {
            add(timeRow("Wake", "wake_normal")); add(timeRow("Sleep", "sleep_normal"))
            add(numRow("Essential Hours target", "target_eh_normal", " h")); add(numRow("Working hours target", "target_work_normal", " h"))
            add(timeRow("Daily review", "review_normal"))
        }, bottom = 14)
        add(a.label("Max Mode"), bottom = 6)
        add(a.card(6).apply {
            add(timeRow("Wake", "wake_max")); add(timeRow("Sleep", "sleep_max"))
            add(numRow("Essential Hours target", "target_eh_max", " h")); add(numRow("Working hours target", "target_work_max", " h"))
            add(timeRow("Daily review", "review_max"))
        }, bottom = 14)
        add(a.dimText("The day starts at your earliest wake time (${TimeUtil.fmtTime(repo.dayStart())}). Hours logged after midnight belong to the previous day. Templates control blocks; edit them in Templates."))
    }
}

class WeightsScreen(a: MainActivity) : Screen(a) {
    override val title = "Daily Score weights"
    override fun content(): View = page {
        val s = repo.settings
        val keys = listOf("w_eh" to "Essential Hours vs target", "w_work" to "Working hours vs target", "w_one" to "ONE thing completed",
            "w_plan" to "Plan followed", "w_routine" to "Routines completed", "w_sleep" to "Sleep on time")
        val total = a.dimText("")
        fun upd() { val t = keys.sumOf { s.int(it.first) }; total.text = "Total $t" + if (t != 100) " — the score scales to 100 either way" else "" }
        keys.forEach { (k, l) ->
            val r = a.hbox(); r.add(a.txt(l, 15f), 0, WRAP, 1f)
            val v = a.txt("${s.int(k)}", 15f, Th.dim, Fonts.medium); r.add(v, WRAP, WRAP)
            add(r, top = 6)
            add(a.slider(s.int(k), 50) { s.set(k, it); v.text = "$it"; upd() })
        }
        upd(); add(total, top = 8)
        add(a.btn("Reset to defaults", Btn.TEXT) { keys.forEach { s.set(it.first, WeightDefaults.MAP[it.first]) }; a.refresh() }, top = 8)
    }
}

private object WeightDefaults { val MAP = mapOf("w_eh" to 35, "w_work" to 10, "w_one" to 15, "w_plan" to 15, "w_routine" to 15, "w_sleep" to 10) }

class NotificationSettingsScreen(a: MainActivity) : Screen(a) {
    override val title = "Notifications"
    override fun content(): View = page {
        val s = repo.settings
        fun t(k: String, l: String, d: String) = a.switchRow(l, d, s.bool(k)) { on -> s.set(k, on); Hooks.scheduleChanged(a) }
        add(a.card(14).apply {
            add(t("n_checkin", "Hourly check-in", "On the hour, wake to sleep, with one-tap buttons"))
            add(t("n_block", "Next block", "5 minutes before each block"))
            add(t("n_review", "Daily review", "Evening, under 2 minutes"))
            add(t("n_wind", "Wind-down", "15 minutes before sleep"))
            add(t("n_sleep", "Morning sleep log", "After you wake"))
            add(t("n_backup", "Weekly backup reminder", "Sunday evening"))
            add(t("n_tools", "Reviews & reports", "Weekly report, obstacle, monthly uncommit"))
        }, bottom = 14)
        add(a.label("Quiet hours"), bottom = 6)
        add(a.card(14).apply {
            add(a.switchRow("Quiet hours", "No reminders in this window", s.bool("quiet_enabled")) { on -> s.set("quiet_enabled", on) })
            add(a.listRow("From", TimeUtil.fmtTimeFull(s.int("quiet_start"))) { a.pickTime("Quiet from", s.int("quiet_start")) { v -> s.set("quiet_start", v); a.refresh() } })
            add(a.listRow("Until", TimeUtil.fmtTimeFull(s.int("quiet_end"))) { a.pickTime("Quiet until", s.int("quiet_end")) { v -> s.set("quiet_end", v); a.refresh() } })
        }, bottom = 14)
        add(a.label("Reliability"), bottom = 6)
        add(a.card(14).apply {
            add(a.switchRow("Alarm-clock mode", "Most reliable on aggressive phones. Shows an alarm icon in the status bar.", s.bool("alarm_clock_mode")) { on ->
                s.set("alarm_clock_mode", on); Alarms.schedule(a)
            })
            val next = s.long("next_alarm_at")
            if (next > 0) add(a.dimText("Next reminder: ${TimeUtil.fmtDay(TimeUtil.at(next).toLocalDate())} ${TimeUtil.fmtClock(TimeUtil.at(next))}"), top = 6)
        }, bottom = 14)
        add(a.btn("Android notification channels", Btn.TONAL) {
            a.startActivity(Intent(AS.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(AS.EXTRA_APP_PACKAGE, a.packageName))
        }, bottom = 8)
        add(a.btn("Send test notification", Btn.TEXT) { Notifier.test(a) })
    }
}

class PermissionsScreen(a: MainActivity) : Screen(a) {
    override val title = "Permissions & reliability"
    override fun content(): View = page {
        add(a.dimText("Essential works fully offline. These keep reminders on time."), bottom = 12)
        add(PermissionRows.build(a) { a.refresh() })
        val c = a.card(16)
        val r = a.hbox()
        val col = a.vbox(); col.add(a.h3("Microphone")); col.add(a.dimText("For voice logging. Asked the first time you hold the mic."), top = 2)
        r.add(col, 0, WRAP, 1f)
        r.add(if (Perms.mic(a)) a.badge("On", Th.green, "check") else a.btn("Allow", Btn.TONAL) { a.requestPerm(android.Manifest.permission.RECORD_AUDIO) { a.refresh() } }, WRAP, WRAP, start = 8)
        c.add(r)
        add(c, bottom = 10)
        val d = a.card(16)
        val dr = a.hbox()
        val dc = a.vbox(); dc.add(a.h3("Do Not Disturb access")); dc.add(a.dimText("Optional: lets Focus Mode silence your phone."), top = 2)
        dr.add(dc, 0, WRAP, 1f)
        dr.add(if (Focus.dndAccess(a)) a.badge("On", Th.green, "check") else a.btn("Allow", Btn.TONAL) {
            a.startForResult(Intent(AS.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)) { _, _ -> a.refresh() }
        }, WRAP, WRAP, start = 8)
        d.add(dr)
        add(d, bottom = 14)
        add(a.btn("Phone-specific settings (${Perms.brand().name})", Btn.TONAL) { a.push(PhoneHelpScreen(a)) }, bottom = 8)
        add(a.btn("Send test notification", Btn.TEXT, "bell") { Notifier.test(a); a.toast("Sent") })
        if (Build.VERSION.SDK_INT >= 33) add(a.dimText("Android ${Build.VERSION.RELEASE}: exact alarms are allowed automatically for reminder apps."), top = 8)
    }
}

class PhoneHelpScreen(a: MainActivity) : Screen(a) {
    override val title = "Phone-specific settings"
    override fun content(): View = page {
        val b = Perms.brand()
        add(a.h2(b.name), bottom = 4)
        add(a.dimText("Some phones stop background apps to save battery. Two minutes here keeps your reminders on time."), bottom = 14)
        val c = a.card(16)
        b.steps.forEachIndexed { i, s ->
            val r = a.hbox().apply { gravity = android.view.Gravity.TOP; setPadding(0, a.dp(6), 0, a.dp(6)) }
            r.add(a.txt("${i + 1}", 15f, Th.primary, Fonts.semibold), a.dp(24), WRAP)
            r.add(a.body(s), 0, WRAP, 1f)
            c.add(r)
        }
        add(c, bottom = 14)
        add(a.btn(if (b.intents.isNotEmpty()) "Open Autostart / battery page" else "Open app settings") { Perms.openBrandSettings(a) }, bottom = 8)
        add(a.btn("Battery optimisation", Btn.TONAL) { Perms.fixBattery(a) { a.refresh() } }, bottom = 8)
        add(a.btn("App info", Btn.TEXT) { Perms.openAppDetails(a) })
        add(a.dimText("Other brands: Xiaomi/Redmi/POCO, Vivo, Oppo, Realme, OnePlus, Samsung and Motorola are detected automatically."), top = 12)
    }
}

class BackupScreen(a: MainActivity) : Screen(a) {
    override val title = "Backup & restore"
    override fun content(): View = page {
        val s = repo.settings
        add(a.dimText("One file holds everything: logs, goals, templates, habits, settings."), bottom = 14)
        add(a.btn("Export backup", icon = "share") {
            val e = Backup.export(a)
            a.toast(if (e.downloads != null) "Saved to Downloads/Daily Chain/${e.name}" else "Ready to share")
            a.shareUris(listOf(e.share), "application/json", e.name)
        }, bottom = 8)
        add(a.btn("Restore backup", Btn.TONAL) {
            val i = Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*")
            a.startForResult(i) { code, data ->
                val uri = data?.data
                if (code != android.app.Activity.RESULT_OK || uri == null) return@startForResult
                a.confirm("Restore this backup?", "It replaces everything currently in the app.", "Restore", danger = true) {
                    try { Backup.restore(a, uri); a.toast("Restored"); a.recreate() } catch (e: Exception) { a.info("Couldn't restore", e.message ?: "Unknown error") }
                }
            }
        }, bottom = 16)
        add(a.label("Automatic weekly backup"), bottom = 6)
        val c = a.card(14)
        val tree = s.str("backup_tree_uri")
        c.add(a.switchRow("Weekly auto-backup", "Sunday evening, into a folder you choose", s.bool("backup_auto")) { on ->
            if (on && tree.isEmpty()) pickFolder() else { s.set("backup_auto", on); Hooks.scheduleChanged(a) }
        })
        c.add(a.listRow("Folder", if (tree.isEmpty()) "Not chosen" else Uri.decode(Uri.parse(tree).lastPathSegment ?: tree), null) { pickFolder() })
        val last = s.long("last_auto_backup")
        if (last > 0) c.add(a.dimText("Last auto-backup: ${TimeUtil.fmtDay(TimeUtil.at(last).toLocalDate())} ${TimeUtil.fmtClock(TimeUtil.at(last))}"), top = 4)
        if (tree.isNotEmpty()) c.add(a.btn("Back up to folder now", Btn.TEXT) {
            val n = try { Backup.autoBackup(a) } catch (e: Exception) { null }
            a.toast(n?.let { "Saved $it" } ?: "Couldn't write to that folder — choose it again"); a.refresh()
        })
        add(c, bottom = 16)
        add(a.btn("Export CSV files", Btn.TONAL, "copy") { a.shareUris(Backup.exportCsv(a), "text/csv", "${App.NAME} CSV export") })
    }

    private fun pickFolder() {
        a.startForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)) { code, data ->
            val uri = data?.data ?: return@startForResult
            if (code != android.app.Activity.RESULT_OK) return@startForResult
            a.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            repo.settings.set("backup_tree_uri", uri.toString()); repo.settings.set("backup_auto", true)
            Hooks.scheduleChanged(a); a.refresh()
        }
    }
}

class KeywordRulesScreen(a: MainActivity) : Screen(a) {
    override val title = "Voice keyword rules"
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "New rule") { edit(null) })
    override fun content(): View = page {
        add(a.dimText("When a spoken or typed activity contains a keyword, ${App.NAME} fills in the category, activity and type. The longest matching keyword wins. You always confirm before saving."), bottom = 12)
        val vs = repo.ventures(true).associateBy { it.id }
        val c = a.card(6)
        repo.rules().forEach { r ->
            c.add(a.listRow(r.keywords, listOfNotNull(r.category, r.ventureId?.let { vs[it]?.name }, r.type).joinToString(" · ")) { edit(r) })
        }
        add(c, bottom = 12)
        val test = a.field("Try it: e.g. \"walked in the park\"")
        val res = a.dimText("")
        test.addTextChangedListener(Watch { t ->
            val m = Classifier.parse(t, repo.rules())
            res.text = m?.let { listOfNotNull("Matched \"${it.keyword}\"", it.category, it.ventureId?.let { id -> vs[id]?.name }, it.type).joinToString(" → ") } ?: if (t.isBlank()) "" else "No match"
        })
        add(test, bottom = 6); add(res)
    }

    private fun edit(r: KeywordRule?) {
        var cat = r?.category; var vid = r?.ventureId; var type = r?.type
        val sh = Sheet(a, if (r == null) "New rule" else "Edit rule")
        val f = a.field("Keywords, comma separated", r?.keywords, multiline = true)
        sh.add(f)
        sh.add(a.label("Category"), bottom = 6)
        sh.add(a.choice(Cat.ALL, cat, allowNone = true) { cat = it })
        sh.add(a.label("Activity"), bottom = 6)
        val vs = repo.ventures()
        sh.add(a.choice(vs.map { it.name }, vs.firstOrNull { it.id == vid }?.name, allowNone = true) { n -> vid = vs.firstOrNull { it.name == n }?.id })
        sh.add(a.label("Type (optional)"), bottom = 6)
        sh.add(a.choice(Type.ALL, type, allowNone = true) { type = it })
        if (r != null) sh.add(a.btn("Delete rule", Btn.TEXT, color = Th.red) { repo.deleteRule(r.id); sh.dismiss(); a.refresh() })
        sh.actions("Save") {
            if (f.value.isBlank()) return@actions
            repo.saveRule(KeywordRule(r?.id ?: 0, f.value, cat, vid, type)); sh.dismiss(); a.refresh()
        }
        sh.show()
    }
}

