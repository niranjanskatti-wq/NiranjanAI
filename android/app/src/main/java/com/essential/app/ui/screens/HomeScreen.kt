package com.essential.app.ui.screens

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.widget.TextView
import com.essential.app.core.*
import com.essential.app.data.Mode
import com.essential.app.notify.ActionReceiver
import com.essential.app.ui.*
import java.time.temporal.ChronoUnit

/** "What's important now?" */
class HomeScreen(a: MainActivity) : Screen(a) {
    companion object {
        fun distracted(a: MainActivity) {
            val id = ActionReceiver.logDistraction(a)
            a.snack("Distraction noted. What pulled you away?", listOf("Phone", "WhatsApp", "Unplanned call", "Visitor", "Thought").map { r ->
                r to { a.repo.setDistractionReason(id, r); a.refresh() }
            })
            a.refresh()
        }

        fun checkBox(a: MainActivity, checked: Boolean, onToggle: (Boolean) -> Unit): View {
            val v = android.widget.FrameLayout(a)
            val r = a.dp(8).toFloat()
            v.background = if (checked) rounded(Th.primary, r) else rounded(0, r, a.dp(2), Th.dim)
            if (checked) v.add(a.iconView("check", Th.onPrimary, 16), MATCH, MATCH)
            v.click(true) { onToggle(!checked) }
            return v
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var countdown: TextView? = null
    private var tick: Runnable? = null
    private var blockEnd: Long = 0

    override fun content(): View {
        val now = Days.now(repo)
        val day = now.day
        val d = day.date
        val s = repo.settings
        val logs = repo.logs(d)
        return page {
            // ---------- header: intent, mode, sprint
            val intent = repo.intent()
            val head = a.hbox()
            head.add(a.txt(TimeUtil.fmtDayLong(d), 14f, Th.dim, Fonts.medium), 0, WRAP, 1f)
            head.add(modeBadge(day), WRAP, WRAP)
            add(head, top = 4, bottom = 10)
            if (intent != null) {
                val c = a.card(16) { a.push(GoalsScreen(a)) }
                c.add(a.label("Essential Intent"))
                c.add(a.txt(intent.title, 17f, Th.text, Fonts.semibold), top = 4)
                c.addProgress(intent.progress / 100.0, Th.primary, 6, top = 12)
                val pace = Insights.goalPace(intent, d)
                c.add(a.dimText("${intent.progress}% · ${pace.daysLeft} days left" + if (!pace.onTrack) " · a little behind pace" else ""), top = 8)
                add(c, bottom = 10)
            } else add(a.card(16) { a.push(GoalsScreen(a)) }.apply { add(a.h3("Set your Essential Intent")); add(a.dimText("One goal for the next 90 days."), top = 2) }, bottom = 10)

            day.sprint?.let { sp ->
                val left = ChronoUnit.DAYS.between(d, sp.end) + 1
                add(a.card(14, Th.primaryContainer) { a.push(SprintScreen(a)) }.apply {
                    val r = a.hbox(); r.add(a.iconView("bolt", Th.primary, 18), WRAP, WRAP, end = 8)
                    r.add(a.txt("Sprint · ${sp.goal}", 14.5f, Th.onPrimaryContainer.takeIf { !Th.dark } ?: Th.text, Fonts.medium, maxLines = 1), 0, WRAP, 1f)
                    r.add(a.txt("$left day${if (left == 1L) "" else "s"} left", 13.5f, Th.primary, Fonts.semibold), WRAP, WRAP)
                    add(r)
                }, bottom = 10)
            }
            day.recovery?.let { rc -> add(a.dimText("Recovery week after \"${rc.goal}\" — Normal Mode until ${TimeUtil.fmtShort(rc.recoveryEnd!!)}."), bottom = 10) }

            // ---------- banners
            if (!Perms.allCritical(a)) add(banner("warn", Th.yellow, "Reminders may not arrive on time.", "Fix") { a.push(PermissionsScreen(a)) }, bottom = 10)
            if (repo.hasSampleData()) add(banner("dot", Th.necessary, "Showing 14 days of sample data.", "Clear") {
                a.confirm("Clear sample data?", "Removes only the sample rows. Your own logs, goals and settings stay.", "Clear") { repo.clearSampleData(); Hooks.afterChange(a); a.refresh() }
            }, bottom = 10)
            val burnout = Insights.burnout(repo, d)
            if (burnout != null && s.str("burnout_dismissed") != d.toString()) add(burnoutCard(burnout), bottom = 10)
            repo.sprints().firstOrNull { it.status == "done" && !it.reportSeen && !d.isBefore(it.end) }?.let { sp ->
                add(banner("insights", Th.primary, "Sprint \"${sp.goal}\" finished. See Max vs Normal.", "Open") { repo.markSprintReportSeen(sp.id); a.push(SprintReportScreen(a, sp.id)) }, bottom = 10)
            }

            // ---------- now card
            add(nowCard(now), bottom = 12)

            // ---------- numbers
            val eh = Metrics.essentialHours(logs); val target = s.targetEssential(day.mode)
            val work = Metrics.workHours(logs); val workT = s.targetWork(day.mode)
            val score = Metrics.dayScore(repo, d, day)
            val nums = a.card(18)
            val top = a.hbox().apply { gravity = Gravity.BOTTOM }
            val ehCol = a.vbox()
            ehCol.add(a.label("Essential Hours today"))
            val big = a.hbox().apply { gravity = Gravity.BOTTOM }
            big.add(a.txt(TimeUtil.fmtHours(eh), 64f, Th.primary, Fonts.light).apply { includeFontPadding = false }, WRAP, WRAP)
            big.add(a.txt(" / ${TimeUtil.fmtHours(target)} h", 18f, Th.dim), WRAP, WRAP, bottom = 10)
            ehCol.add(big)
            top.add(ehCol, 0, WRAP, 1f)
            val sc = a.vbox().apply { gravity = Gravity.CENTER_HORIZONTAL; setPadding(a.dp(14), a.dp(8), a.dp(14), a.dp(8)) }
            sc.background = ripple(rounded(Th.surface2, a.dp(18).toFloat()), a.dp(18).toFloat())
            sc.add(a.txt("${score.total}", 28f, Th.text, Fonts.semibold, center = true), WRAP, WRAP, gravity = Gravity.CENTER_HORIZONTAL)
            sc.add(a.txt("Daily Score", 11.5f, Th.dim, center = true), WRAP, WRAP, gravity = Gravity.CENTER_HORIZONTAL)
            sc.click(true) { ScoreSheet.open(a, d) }
            top.add(sc, WRAP, WRAP, bottom = 8)
            nums.add(top)
            nums.addProgress(eh / target.coerceAtLeast(0.1), Th.primary, 10, top = 8)
            val wr = a.hbox()
            wr.add(a.txt("Working hours", 14f, Th.dim), 0, WRAP, 1f)
            wr.add(a.txt("${TimeUtil.fmtHours(work)} / ${TimeUtil.fmtHours(workT)} h", 14f, Th.text, Fonts.medium), WRAP, WRAP)
            nums.add(wr, top = 14)
            nums.addProgress(work / workT.coerceAtLeast(0.1), Th.necessary, 5, top = 6)
            add(nums, bottom = 12)

            // ---------- ONE thing
            add(oneThing(day), bottom = 12)

            // ---------- actions
            val missing = Logging.missing(repo, day)
            val acts = a.vbox()
            val r1 = a.hbox()
            r1.add(a.btn("Log hour", icon = "plus") { val sl = Logging.targetSlot(repo); LogHourSheet.open(a, sl.date, sl.hour) }, 0, WRAP, 1f, end = 8)
            r1.add(a.btn(if (missing.isEmpty()) "Missed hours" else "Missed (${missing.size})", Btn.TONAL) { a.push(MissedHoursScreen(a)) }, 0, WRAP, 1f)
            acts.add(r1)
            val r2 = a.hbox()
            r2.add(a.btn("Focus", Btn.TONAL, "timer") {
                if (Focus.isActive(a)) a.startActivity(Intent(a, FocusActivity::class.java)) else FocusSheet.open(a)
            }, 0, WRAP, 1f, end = 8)
            r2.add(a.btn("Distracted", Btn.TONAL, color = Th.trivial) { distracted(a) }, 0, WRAP, 1f, end = 8)
            r2.add(a.btn("Idea", Btn.TONAL, "idea", Th.necessary) { a.push(OpportunityScreen(a)); OpportunityScreen.newIdea(a) }, 0, WRAP, 1f)
            acts.add(r2, top = 8)
            add(acts, bottom = 16)

            // ---------- gentle notes
            if (!Timeline.hasBuffer(day.blocks)) add(a.dimText("Today has no buffer block. Tasks usually take longer than planned."), bottom = 8)
            if (Insights.thinkTimeSkippedWeeks(repo, d) >= 2) add(a.dimText("No Think Time for two weeks. A quiet hour this Sunday could help."), bottom = 8)
            val dist = repo.distractions(d, d).size
            if (dist > 0) add(a.dimText("$dist distraction${if (dist == 1) "" else "s"} noted today."), bottom = 8)

            // ---------- timeline
            add(a.label("Today"), top = 8, bottom = 8)
            add(TimelineView.build(a, day, logs) { h -> LogHourSheet.open(a, d, h) })
        }
    }

    private fun banner(icon: String, color: Int, text: String, action: String, onClick: () -> Unit): View {
        val c = a.card(12, Th.alpha(color, 0.12f))
        val r = a.hbox()
        r.add(a.iconView(icon, color, 18), WRAP, WRAP, end = 10)
        r.add(a.txt(text, 14f, Th.text), 0, WRAP, 1f)
        r.add(a.btn(action, Btn.TEXT, color = color) { onClick() }, WRAP, WRAP)
        c.add(r)
        return c
    }

    private fun burnoutCard(b: Insights.Companion.Burnout): View {
        val c = a.card(16, Th.alpha(Th.yellow, 0.12f))
        c.add(a.h3("Your body may need a lighter day"))
        b.reasons.forEach { c.add(a.dimText(it), top = 4) }
        c.add(a.body("Suggestion: make tomorrow a recovery day — Normal Mode, full sleep, one Essential Block only."), top = 8)
        val r = a.hbox()
        r.add(a.btn("Plan recovery day", Btn.TONAL, color = Th.yellow) {
            val tomorrow = Days.today(repo).plusDays(1)
            Days.setMode(repo, tomorrow, Mode.NORMAL)
            repo.setPlanField(tomorrow, "one_thing", "Recovery day: rest, sleep, one Essential Block")
            Hooks.scheduleChanged(a); a.toast("Tomorrow is a recovery day"); a.refresh()
        }, WRAP, WRAP, end = 8)
        r.add(a.btn("Dismiss", Btn.TEXT, color = Th.dim) { repo.settings.set("burnout_dismissed", Days.today(repo).toString()); a.refresh() }, WRAP, WRAP)
        c.add(r, top = 10)
        return c
    }

    private fun modeBadge(day: DayInfo): View {
        val max = day.isMax
        val b = a.badge((if (max) "Max Mode" else "Normal") + " · ${day.template?.name ?: "—"}", if (max) Th.trivial else Th.primary, if (max) "bolt" else null)
        b.minHeight = a.dp(32); b.gravity = Gravity.CENTER_VERTICAL
        b.click(true) { ModeSheet.open(a, day.date) }
        return b
    }

    private fun nowCard(now: Days.Now): View {
        val c = a.card(20)
        val fs = Focus.state(a)
        if (fs != null) {
            c.background = ripple(rounded(Th.primaryContainer, a.dp(22).toFloat()), a.dp(22).toFloat())
            c.click(true) { a.startActivity(Intent(a, FocusActivity::class.java)) }
            c.add(a.label(if (fs.paused) "Focus paused" else "Focus session"))
            c.add(a.txt(fs.task.ifBlank { "Essential work" }, 22f, Th.text, Fonts.semibold), top = 6)
            val cd = a.txt(TimeUtil.fmtCountdown(fs.leftMillis() / 1000), 34f, Th.primary, Fonts.light)
            c.add(cd, top = 6)
            c.add(a.dimText("Check-ins are paused. This time is logged as Essential."), top = 4)
            countdown = cd; blockEnd = if (fs.paused) 0 else fs.endAt
            return c
        }
        val b = now.current
        c.add(a.label("Now"))
        if (b == null) {
            c.add(a.h2("Unplanned time"), top = 6)
            c.add(a.dimText("No block covers this moment. Add one in Templates."), top = 4)
            return c
        }
        val tr = a.hbox()
        tr.add(a.txt(b.title, 22f, Th.text, Fonts.semibold), 0, WRAP, 1f)
        if (b.isProtected) tr.add(a.iconView("lock", Th.primary, 20), WRAP, WRAP, start = 8)
        c.add(tr, top = 6)
        val v = repo.venture(b.ventureId)
        c.add(a.dimText(b.category + (v?.let { " · ${it.name}" } ?: "") + " · ${TimeUtil.fmtTime(b.start)}–${TimeUtil.fmtTime(b.end)}"), top = 2)
        val cd = a.txt("", 34f, Th.primary, Fonts.light)
        c.add(cd, top = 10)
        countdown = cd; blockEnd = now.currentEnd?.toInstant()?.toEpochMilli() ?: 0
        updateCountdown()
        now.next?.let { n -> c.add(a.dimText("Next: ${TimeUtil.fmtTime(n.start)} · ${n.title}"), top = 6) }
        return c
    }

    private fun oneThing(day: DayInfo): View {
        val c = a.card(18)
        val p = day.plan
        c.add(a.label("Today's ONE thing"))
        fun row(text: String?, done: Boolean, field: String, doneField: String, hint: String, big: Boolean) {
            val r = a.hbox().apply { setPadding(0, a.dp(8), 0, a.dp(4)) }
            if (!text.isNullOrBlank()) r.add(checkBox(a, done) { repo.setPlanField(day.date, doneField, it); Hooks.afterChange(a); a.refresh() }, a.dp(26), a.dp(26), end = 12)
            val t = a.txt(if (text.isNullOrBlank()) hint else text, if (big) 18f else 15.5f,
                if (text.isNullOrBlank()) Th.faint else if (done) Th.dim else Th.text, if (big) Fonts.semibold else Fonts.regular)
            if (done) t.paintFlags = t.paintFlags or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
            r.add(t, 0, WRAP, 1f)
            r.click { editPlan(day, field, text, hint) }
            c.add(r)
        }
        row(p?.oneThing, p?.oneDone == true, "one_thing", "one_done", "Tap to set the ONE thing that matters most today", true)
        row(p?.task2, p?.task2Done == true, "task_2", "task_2_done", "+ Task 2 (optional)", false)
        row(p?.task3, p?.task3Done == true, "task_3", "task_3_done", "+ Task 3 (optional)", false)
        return c
    }

    private fun editPlan(day: DayInfo, field: String, value: String?, hint: String) {
        val sh = Sheet(a, if (field == "one_thing") "Today's ONE thing" else "Task")
        val f = a.field(hint.removePrefix("+ ").removePrefix("Tap to set "), value)
        sh.add(f)
        if (field == "one_thing") sh.add(a.dimText("If you did only this today, the day would be a success."))
        sh.actions("Save", if (!value.isNullOrBlank()) "Remove" else "Cancel", onSecondary = {
            if (!value.isNullOrBlank()) repo.setPlanField(day.date, field, null); sh.dismiss(); a.refresh()
        }) { repo.setPlanField(day.date, field, f.value.ifBlank { null }); sh.dismiss(); Hooks.afterChange(a); a.refresh() }
        sh.show()
        f.requestFocus()
    }

    private fun updateCountdown() {
        val cd = countdown ?: return
        if (blockEnd <= 0) return
        val left = (blockEnd - System.currentTimeMillis()) / 1000
        if (left <= 0) { a.refresh(); return }
        cd.text = "${TimeUtil.fmtCountdown(left)} left"
    }

    override fun onShow() {
        tick?.let { handler.removeCallbacks(it) }
        val r = object : Runnable { override fun run() { updateCountdown(); handler.postDelayed(this, 1000) } }
        tick = r
        handler.postDelayed(r, 1000)
    }

    override fun onHide() { tick?.let { handler.removeCallbacks(it) }; tick = null }
}

/** Today's hours, colored by log status; the current hour is highlighted. */
object TimelineView {
    fun build(a: MainActivity, day: DayInfo, logs: List<com.essential.app.data.HourLog>, onTap: (Int) -> Unit): View {
        val box = a.vbox()
        val byHour = logs.associateBy { it.hour }
        val nowT = TimeUtil.now()
        for (h in day.hours) {
            val planned = day.plannedFor(h)
            val log = byHour[h]
            val isNow = !day.slotStart(h).isAfter(nowT) && day.slotEnd(h).isAfter(nowT)
            val future = day.slotStart(h).isAfter(nowT)
            val row = a.hbox().apply { setPadding(a.dp(10), a.dp(10), a.dp(12), a.dp(10)); minimumHeight = a.dp(52) }
            val r = a.dp(14).toFloat()
            row.background = ripple(if (isNow) rounded(Th.surface2, r, a.dp(1), Th.alpha(Th.primary, 0.5f)) else null, r)
            row.add(a.txt(TimeUtil.fmtTime(h * 60), 13f, if (isNow) Th.primary else Th.faint, Fonts.medium), a.dp(58), WRAP)
            val bar = View(a).apply { background = rounded(if (log != null) Th.type(log.type) else if (future) Th.surface2 else Th.grey, a.dp(3).toFloat()) }
            row.add(bar, a.dp(5), a.dp(32), end = 12)
            val col = a.vbox()
            if (log != null) {
                col.add(a.txt(log.activity, 15f, Th.text, maxLines = 1))
                col.add(a.txt("${log.type}${log.focus?.let { " · focus $it" } ?: ""}${if (planned != null && log.followedPlan != null) " · plan: ${log.followedPlan}" else ""}", 12.5f, Th.dim, maxLines = 1), top = 1)
            } else {
                col.add(a.txt(planned?.title ?: "—", 15f, if (future) Th.dim else Th.faint, maxLines = 1))
                col.add(a.txt(if (future) planned?.category ?: "" else "Not logged", 12.5f, Th.faint, maxLines = 1), top = 1)
            }
            row.add(col, 0, WRAP, 1f)
            if (planned?.isProtected == true) row.add(a.iconView("lock", Th.faint, 14), WRAP, WRAP, start = 6)
            if (!future) row.click(true) { onTap(h) }
            box.add(row, bottom = 2)
        }
        if (day.hours.isEmpty()) box.add(a.dimText("No tracked hours."))
        return box
    }
}
