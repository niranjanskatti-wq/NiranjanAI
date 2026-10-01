package com.essential.app.ui.screens

import android.view.View
import android.widget.LinearLayout
import com.essential.app.core.SampleData
import com.essential.app.core.TimeUtil
import com.essential.app.ui.*

/**
 * First launch. Every step is optional: "Skip setup" goes straight into the app.
 * Welcome → choose your tabs → (optional) Essential Intent → reminders → start.
 */
class OnboardingScreen(a: MainActivity) : Screen(a) {
    private var step = 0
    private var intentTitle = ""
    private var endDate = TimeUtil.now().toLocalDate().plusDays(90)
    private val supporting = arrayOf("", "")
    private var loadSample = false
    private val tabs = repo.settings.str("tabs").split(',').map { it.trim() }.toMutableSet()

    override fun content(): View = page {
        setPadding(a.dp(24), a.dp(28), a.dp(24), a.dp(32))
        val top = a.hbox()
        val dots = a.hbox()
        for (i in 0..4) dots.add(a.dot(if (i == step) Th.primary else Th.surface3, 8), a.dp(if (i == step) 22 else 8), a.dp(8), end = 6)
        top.add(dots, 0, WRAP, 1f)
        if (step < 4) top.add(a.btn("Skip setup", Btn.TEXT, color = Th.dim) { done() }, WRAP, WRAP)
        add(top, bottom = 20)
        when (step) {
            0 -> welcome(this)
            1 -> chooseTabs(this)
            2 -> intent(this)
            3 -> permissions(this)
            else -> finish(this)
        }
    }

    private fun go(s: Int) { step = s; a.refresh() }

    private fun nav(v: LinearLayout, back: Int, next: String, onNext: () -> Unit) {
        val row = a.hbox()
        row.add(a.btn("Back", Btn.TEXT, color = Th.dim) { go(back) }, WRAP, WRAP, end = 8)
        row.add(a.btn(next) { onNext() }, 0, WRAP, 1f)
        v.add(row)
    }

    private fun welcome(v: LinearLayout) = with(v) {
        add(a.txt(App.NAME, 40f, Th.text, Fonts.semibold))
        add(a.txt("अभ्यास · steady daily practice", 15f, Th.dim, Fonts.regular), top = 2)
        add(a.txt("Less, but better.", 20f, Th.primary, Fonts.light), top = 8, bottom = 24)
        add(a.body("Track your hours, build daily habit chains, and spend your best time on what matters. Use only the parts you want."), bottom = 20)
        listOf(
            Triple("Habits", "Daily ticks and unbroken chains of dots.", "check"),
            Triple("Hours", "One-tap hourly logs and plan vs actual.", "log"),
            Triple("Focus & insights", "Calm focus timer, charts and a weekly report.", "insights")
        ).forEach { (t, d, ic) ->
            val c = a.card(16)
            val row = a.hbox()
            row.add(a.iconView(ic, Th.primary, 22), a.dp(36), a.dp(36), end = 12)
            val col = a.vbox(); col.add(a.h3(t)); col.add(a.dimText(d), top = 2)
            row.add(col, 0, WRAP, 1f)
            c.add(row)
            add(c, bottom = 10)
        }
        add(a.dimText("Everything stays on this phone. No account, no internet. Every step here is optional."), top = 12, bottom = 20)
        add(a.btn("Begin") { go(1) }, bottom = 8)
        add(a.btn("Skip setup and open the app", Btn.TEXT, color = Th.dim) { done() })
    }

    private fun chooseTabs(v: LinearLayout) = with(v) {
        add(a.h1("Choose your tabs"), bottom = 6)
        add(a.dimText("Turn on only what you'll use. Settings is always there, and you can change this anytime in Settings → Bottom tabs."), bottom = 16)
        val desc = mapOf("now" to "Current block, ONE thing, daily score", "log" to "Hour by hour: plan vs actual",
            "habits" to "Daily habit chains and calendars", "insights" to "Charts and weekly report", "tools" to "Goals, focus, sleep, reviews and more")
        val c = a.card(10)
        MainActivity.ALL_TABS.filter { it.first != "settings" }.forEach { (id, label) ->
            c.add(a.switchRow(label, desc[id], id in tabs) { on -> if (on) tabs.add(id) else tabs.remove(id); saveTabs() })
        }
        add(c, bottom = 20)
        nav(this, 0, "Continue") { saveTabs(); go(2) }
    }

    private fun saveTabs() {
        repo.settings.set("tabs", MainActivity.ALL_TABS.map { it.first }.filter { it in tabs }.joinToString(","))
    }

    private fun intent(v: LinearLayout) = with(v) {
        add(a.h1("A main goal?"), bottom = 6)
        add(a.dimText("Optional. One concrete goal for the next 90 days, shown with its progress. Leave it empty to skip — you can add it later in Tools → Goals."), bottom = 20)
        val f = a.field("e.g. Finish my main project by 31 Dec", intentTitle, multiline = true)
        f.addTextChangedListener(Watch { intentTitle = it })
        add(f, bottom = 12)
        val due = a.listRow("Target date", TimeUtil.fmtDayLong(endDate), "log") { a.pickDate(endDate) { endDate = it; a.refresh() } }
        add(due, bottom = 16)
        add(a.label("Optional · up to 2 more goals"), bottom = 8)
        for (i in 0..1) {
            val s = a.field(if (i == 0) "e.g. Walk 10,000 steps a day" else "e.g. Read 6 books", supporting[i])
            s.addTextChangedListener(Watch { supporting[i] = it })
            add(s, bottom = 8)
        }
        add(a.space(12))
        nav(this, 1, "Continue") { go(3) }
    }

    private fun permissions(v: LinearLayout) = with(v) {
        add(a.h1("Reminders"), bottom = 6)
        add(a.dimText("Optional. Allow these if you want hourly check-ins and habit reminders to arrive on time, even in battery saver."), bottom = 20)
        add(PermissionRows.build(a) { a.refresh() }, bottom = 12)
        add(a.listRow("Phone-specific settings", "Steps for ${Perms.brand().name}: Autostart and battery", "settings") { a.push(PhoneHelpScreen(a)) }, bottom = 4)
        add(a.dimText("Microphone is asked only when you first use voice logging."), top = 6, bottom = 20)
        nav(this, 2, "Continue") { go(4) }
    }

    private fun finish(v: LinearLayout) = with(v) {
        add(a.h1("Ready"), bottom = 6)
        add(a.dimText("Everything can be changed later in Settings and Tools."), bottom = 20)
        val c = a.card(16)
        c.add(a.switchRow("Load 14 days of sample data", "To see charts and reports filled in. Clear it anytime from Settings.", loadSample) { loadSample = it })
        add(c, bottom = 24)
        add(a.btn("Start") { done() })
    }

    /** Save whatever was filled in (nothing is required) and open the app. */
    private fun done() {
        saveTabs()
        val today = TimeUtil.logicalDate(TimeUtil.now(), repo.dayStart())
        val goals = (listOf(intentTitle) + supporting).map { it.trim() }.filter { it.isNotEmpty() }
        goals.forEachIndexed { i, g -> repo.addGoal(g, if (i == 0) "intent" else "supporting", today, endDate) }
        repo.settings.set("onboarded", true)
        repo.settings.set("last_alarm_handled", TimeUtil.nowMillis())
        if (loadSample) SampleData.load(a)
        a.finishOnboarding()
    }
}

/** Simple TextWatcher lambda adapter. */
class Watch(val f: (String) -> Unit) : android.text.TextWatcher {
    override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
    override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
    override fun afterTextChanged(s: android.text.Editable?) { f(s?.toString() ?: "") }
}

/** Notification / exact alarm / battery rows with status and one-tap fixes. */
object PermissionRows {
    fun build(a: MainActivity, changed: () -> Unit): View {
        val box = a.vbox()
        fun row(title: String, reason: String, ok: Boolean, fix: () -> Unit) {
            val c = a.card(16)
            val r = a.hbox()
            val col = a.vbox(); col.add(a.h3(title)); col.add(a.dimText(reason), top = 2)
            r.add(col, 0, WRAP, 1f)
            if (ok) r.add(a.badge("On", Th.green, "check"), WRAP, WRAP, start = 8)
            else r.add(a.btn("Allow", Btn.TONAL) { fix() }, WRAP, WRAP, start = 8)
            c.add(r)
            box.add(c, bottom = 10)
        }
        row("Notifications", "So the hourly check-in can reach you.", Perms.notifications(a)) { Perms.fixNotifications(a, changed) }
        if (android.os.Build.VERSION.SDK_INT >= 31)
            row("Exact alarms", "So reminders fire on the hour, not minutes late.", Perms.exactAlarms(a)) { Perms.fixExact(a, changed) }
        row("Battery optimisation off", "So Android doesn't silence ${App.NAME} in the background.", Perms.battery(a)) { Perms.fixBattery(a, changed) }
        return box
    }
}
