package com.essential.app.ui.screens

import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import com.essential.app.core.SampleData
import com.essential.app.core.TimeUtil
import com.essential.app.ui.*

/** First launch: philosophy → ONE Essential Intent → permissions → start. Works fully offline. */
class OnboardingScreen(a: MainActivity) : Screen(a) {
    private var step = 0
    private var intentTitle = ""
    private var endDate = TimeUtil.now().toLocalDate().plusDays(90)
    private val supporting = arrayOf("", "")
    private var loadSample = true

    override fun content(): View = page {
        setPadding(a.dp(24), a.dp(28), a.dp(24), a.dp(32))
        val dots = a.hbox().apply { gravity = Gravity.CENTER_HORIZONTAL }
        for (i in 0..3) dots.add(a.dot(if (i == step) Th.primary else Th.surface3, 8), a.dp(if (i == step) 22 else 8), a.dp(8), end = 6)
        add(dots, WRAP, WRAP, bottom = 28)
        when (step) {
            0 -> welcome(this)
            1 -> intent(this)
            2 -> permissions(this)
            else -> finish(this)
        }
    }

    private fun go(s: Int) { step = s; a.refresh() }

    private fun welcome(v: LinearLayout) = with(v) {
        add(a.txt(App.NAME, 40f, Th.text, Fonts.semibold))
        add(a.txt("Less, but better.", 20f, Th.primary, Fonts.light), top = 2, bottom = 28)
        add(a.body("Spend your best hours on the few things that matter most. Cut the trivial. Make essential work effortless through routine."), bottom = 24)
        listOf(
            Triple("Explore", "Decide what matters: one Essential Intent for 90 days.", "idea"),
            Triple("Eliminate", "Cut the rest: say no, park ideas, uncommit monthly.", "close"),
            Triple("Execute", "Do it with ease: routines, focus blocks, one-tap hourly logs.", "check")
        ).forEach { (t, d, ic) ->
            val c = a.card(16)
            val row = a.hbox()
            row.add(a.iconView(ic, Th.primary, 22), a.dp(36), a.dp(36), end = 12)
            val col = a.vbox(); col.add(a.h3(t)); col.add(a.dimText(d), top = 2)
            row.add(col, 0, WRAP, 1f)
            c.add(row)
            add(c, bottom = 10)
        }
        add(a.dimText("Everything stays on this phone. No account, no internet."), top = 14, bottom = 20)
        add(a.btn("Begin") { go(1) })
    }

    private fun intent(v: LinearLayout) = with(v) {
        add(a.h1("Your Essential Intent"), bottom = 6)
        add(a.dimText("One concrete, measurable goal for the next 90 days. If everything else waited, this would move."), bottom = 20)
        val f = a.field("e.g. Finish my main project by 31 Dec", intentTitle, multiline = true)
        f.addTextChangedListener(Watch { intentTitle = it })
        add(f, bottom = 12)
        val due = a.listRow("Target date", TimeUtil.fmtDayLong(endDate), "log") { a.pickDate(endDate) { endDate = it; a.refresh() } }
        add(due, bottom = 16)
        add(a.label("Optional · up to 2 supporting goals"), bottom = 8)
        for (i in 0..1) {
            val s = a.field(if (i == 0) "e.g. Walk 10,000 steps a day" else "e.g. Read 6 books", supporting[i])
            s.addTextChangedListener(Watch { supporting[i] = it })
            add(s, bottom = 8)
        }
        add(a.dimText("Maximum three goals in total. Fewer is better."), top = 4, bottom = 20)
        val row = a.hbox()
        row.add(a.btn("Back", Btn.TEXT, color = Th.dim) { go(0) }, WRAP, WRAP, end = 8)
        row.add(a.btn("Set my intent") {
            if (intentTitle.isBlank()) { a.toast("Write your Essential Intent first"); return@btn }
            go(2)
        }, 0, WRAP, 1f)
        add(row)
    }

    private fun permissions(v: LinearLayout) = with(v) {
        add(a.h1("Reliable reminders"), bottom = 6)
        add(a.dimText("Logging an hour should take one tap from a notification. These make sure reminders arrive on time, even in battery saver."), bottom = 20)
        add(PermissionRows.build(a) { a.refresh() }, bottom = 12)
        add(a.listRow("Phone-specific settings", "Steps for ${Perms.brand().name}: Autostart and battery", "settings") { a.push(PhoneHelpScreen(a)) }, bottom = 4)
        add(a.dimText("Microphone is asked only when you first use voice logging."), top = 6, bottom = 20)
        val row = a.hbox()
        row.add(a.btn("Back", Btn.TEXT, color = Th.dim) { go(1) }, WRAP, WRAP, end = 8)
        row.add(a.btn("Continue") { go(3) }, 0, WRAP, 1f)
        add(row)
    }

    private fun finish(v: LinearLayout) = with(v) {
        add(a.h1("Ready"), bottom = 6)
        add(a.dimText("Your default days are set up: a Normal weekday, a Max Mode sprint day, Sunday with Think Time, and a Travel day. Edit them anytime in Tools."), bottom = 20)
        val c = a.card(16)
        c.add(a.switchRow("Load 14 days of sample data", "See every chart and report filled in. Clear it anytime from Settings.", loadSample) { loadSample = it })
        add(c, bottom = 24)
        add(a.btn("Start") {
            val today = TimeUtil.logicalDate(TimeUtil.now(), repo.dayStart())
            repo.addGoal(intentTitle.trim(), "intent", today, endDate)
            supporting.filter { it.isNotBlank() }.take(2).forEach { repo.addGoal(it.trim(), "supporting", today, endDate) }
            repo.settings.set("onboarded", true)
            repo.settings.set("last_alarm_handled", TimeUtil.nowMillis())
            if (loadSample) SampleData.load(a)
            a.finishOnboarding()
        })
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
