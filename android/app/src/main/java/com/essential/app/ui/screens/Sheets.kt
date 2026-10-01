package com.essential.app.ui.screens

import android.content.Intent
import android.view.View
import com.essential.app.core.*
import com.essential.app.data.DailyReview
import com.essential.app.data.Mode
import com.essential.app.data.SleepLog
import com.essential.app.ui.*
import java.time.LocalDate
import kotlin.math.roundToInt

/** Switch a day's mode or template in one tap. */
object ModeSheet {
    fun open(a: MainActivity, date: LocalDate) {
        val repo = a.repo
        val day = Days.resolve(repo, date)
        val sh = Sheet(a, "Today's mode", TimeUtil.fmtDayLong(date))
        val row = a.hbox()
        listOf(Mode.NORMAL to "Normal", Mode.MAX to "Max Mode").forEachIndexed { i, (m, label) ->
            val sel = day.mode == m
            val c = a.card(14, if (sel) Th.primaryContainer else Th.surface2) {
                val err = Days.setMode(repo, date, m)
                if (err != null) {
                    sh.dismiss()
                    if (repo.activeSprint(date) == null && repo.recoverySprint(date) == null)
                        a.confirm("Max Mode needs a sprint", err, "Start a sprint") { a.selectTab("tools"); a.push(SprintScreen(a)); SprintScreen.newSprint(a) }
                    else a.info("Recovery week", err)
                } else { Hooks.scheduleChanged(a); sh.dismiss(); a.refresh() }
            }
            c.add(a.txt(label, 16f, Th.text, Fonts.semibold))
            val s = repo.settings
            c.add(a.dimText("${TimeUtil.fmtHours(s.targetEssential(m))} Essential · ${TimeUtil.fmtHours(s.targetWork(m))}h work"), top = 2)
            c.add(a.dimText("Wake ${TimeUtil.fmtTime(s.wake(m))} · Sleep ${TimeUtil.fmtTime(s.sleep(m))}"), top = 2)
            row.add(c, 0, WRAP, 1f, start = if (i == 0) 0 else 8)
        }
        sh.add(row, bottom = 16)
        sh.add(a.label("Template"), bottom = 8)
        val f = Flow(a)
        repo.templates().forEach { t ->
            f.addView(a.chip(t.name + if (t.mode == Mode.MAX) " ⚡" else "", day.template?.id == t.id) {
                val err = Days.setTemplate(repo, date, t)
                if (err != null) a.toast(err) else { Hooks.scheduleChanged(a); sh.dismiss(); a.refresh() }
            })
        }
        sh.add(f, bottom = 12)
        if (day.sprint == null && day.recovery == null)
            sh.add(a.dimText("Max Mode is time-limited: it runs only inside a sprint (up to 6 weeks), followed by a recovery week."))
        sh.add(a.btn("Edit templates", Btn.TEXT) { sh.dismiss(); a.selectTab("tools"); a.push(TemplatesScreen(a)) }, top = 4)
        sh.show()
    }
}

/** Daily Score breakdown. */
object ScoreSheet {
    fun open(a: MainActivity, date: LocalDate) {
        val sc = Metrics.dayScore(a.repo, date)
        val sh = Sheet(a, "Daily Score: ${sc.total}", "How today adds up. Weights can be changed in Settings.")
        sc.parts.forEach { p ->
            val r = a.hbox()
            r.add(a.txt(p.name, 15f), 0, WRAP, 1f)
            r.add(a.txt("${p.points.roundToInt()} / ${p.weight}", 14f, Th.dim, Fonts.medium), WRAP, WRAP)
            sh.add(r, bottom = 4)
            sh.add(a.dimText(p.detail), bottom = 4)
            sh.body.addProgress(p.fraction.coerceIn(0.0, 1.0), Th.primary, 5)
            sh.add(a.space(6), bottom = 8)
        }
        sh.show()
    }
}

/** Evening review: under 2 minutes. */
object ReviewSheet {
    fun open(a: MainActivity, date: LocalDate) {
        val repo = a.repo
        val ex = repo.review(date)
        val plan = repo.dayPlan(date)
        var done = ex?.oneThingDone ?: (plan?.oneDone == true)
        var rating = ex?.rating
        val sh = Sheet(a, "Daily review", TimeUtil.fmtDayLong(date) + " · under 2 minutes")
        sh.add(a.label("ONE thing done?"), bottom = 6)
        sh.add(a.dimText(plan?.oneThing ?: "No ONE thing was set today."), bottom = 6)
        sh.add(a.choice(listOf("Yes", "No"), if (done) "Yes" else "No") { done = it == "Yes" }, bottom = 14)
        val win = a.field("One small win (required)", ex?.smallWin)
        sh.add(win)
        val cut = a.field("What was trivial today that I can cut?", ex?.trivialToCut)
        sh.add(cut)
        val head = a.field("One-line headline for today", ex?.headline)
        sh.add(head)
        val tomorrow = a.field("Tomorrow's ONE thing", ex?.tomorrowOneThing ?: repo.dayPlan(date.plusDays(1))?.oneThing)
        sh.add(tomorrow)
        sh.add(a.label("Rate the day"), top = 4, bottom = 6)
        sh.add(a.rating(rating, 10) { rating = it }, bottom = 8)
        val err = a.dimText("").apply { setTextColor(Th.red); visibility = View.GONE }
        sh.add(err)
        sh.actions("Save review") {
            if (win.value.isBlank()) { err.text = "Add one small win — even a tiny one counts."; err.visibility = View.VISIBLE; return@actions }
            repo.saveReview(DailyReview(date, done, win.value, cut.value.ifBlank { null }, head.value.ifBlank { null }, rating, tomorrow.value.ifBlank { null }))
            Hooks.afterChange(a); sh.dismiss(); a.toast("Review saved. Rest well."); a.refresh()
        }
        sh.show()
    }
}

/** Morning sleep log. */
object SleepSheet {
    fun open(a: MainActivity, date: LocalDate) {
        val repo = a.repo
        val ex = repo.sleepLog(date)
        val prevMode = Days.resolve(repo, date.minusDays(1)).mode
        var bed = ex?.bedtime ?: repo.settings.sleep(prevMode)
        var wake = ex?.wake ?: repo.settings.wake(Days.resolve(repo, date).mode)
        var q = ex?.quality
        val sh = Sheet(a, "Last night's sleep", TimeUtil.fmtDayLong(date))
        val hrs = a.txt("", 15f, Th.dim)
        fun upd() { hrs.text = "${TimeUtil.fmtHours(SleepLog(date, bed, wake, 3).hours)} hours" }
        lateinit var bedRow: android.widget.LinearLayout
        lateinit var wakeRow: android.widget.LinearLayout
        bedRow = a.listRow("Bedtime", TimeUtil.fmtTimeFull(bed), "moon") {
            a.pickTime("Bedtime", bed) { bed = it; ((bedRow.getChildAt(1) as android.widget.LinearLayout).getChildAt(1) as android.widget.TextView).text = TimeUtil.fmtTimeFull(it); upd() }
        }
        wakeRow = a.listRow("Wake time", TimeUtil.fmtTimeFull(wake), "now") {
            a.pickTime("Wake time", wake) { wake = it; ((wakeRow.getChildAt(1) as android.widget.LinearLayout).getChildAt(1) as android.widget.TextView).text = TimeUtil.fmtTimeFull(it); upd() }
        }
        sh.add(bedRow, bottom = 0); sh.add(wakeRow, bottom = 4)
        upd(); sh.add(hrs, bottom = 10)
        sh.add(a.label("Quality"), bottom = 6)
        sh.add(a.rating(q) { q = it }, bottom = 10)
        sh.actions("Save") {
            repo.saveSleep(SleepLog(date, bed, wake, q ?: 3))
            Hooks.afterChange(a); sh.dismiss(); a.toast("Sleep logged"); a.refresh()
        }
        sh.show()
    }
}

/** Start a focus session: 25 / 50 / 90 minutes. */
object FocusSheet {
    fun open(a: MainActivity) {
        val repo = a.repo
        var minutes = 50
        val sh = Sheet(a, "Start Focus", "Check-ins pause; completed time is logged as Essential.")
        val task = a.field("What will you work on?", repo.dayPlan(Days.today(repo))?.oneThing)
        sh.add(task)
        sh.add(a.choice(listOf("25 min", "50 min", "90 min"), "50 min") { minutes = it?.removeSuffix(" min")?.toInt() ?: 50 }, bottom = 12)
        val dnd = repo.settings.bool("focus_dnd")
        sh.add(a.switchRow("Do Not Disturb during session", if (Focus.dndAccess(a)) "Silences calls and notifications except priority." else "Needs Do Not Disturb access (you'll be asked).", dnd) { on ->
            repo.settings.set("focus_dnd", on)
            if (on && !Focus.dndAccess(a)) a.startForResult(Intent(android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)) { _, _ -> }
        })
        sh.actions("Start") {
            Focus.start(a, minutes, task.value)
            sh.dismiss()
            a.startActivity(Intent(a, FocusActivity::class.java))
        }
        sh.show()
    }
}
