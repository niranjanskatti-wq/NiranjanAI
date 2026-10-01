package com.essential.app.ui.screens

import android.view.View
import com.essential.app.core.*
import com.essential.app.data.Opportunity
import com.essential.app.ui.*
import kotlin.math.roundToInt

// ============================================================ Opportunity filter
class OpportunityScreen(a: MainActivity) : Screen(a) {
    override val title = "Opportunity filter"
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "New idea") { newIdea(a) })

    companion object {
        fun newIdea(a: MainActivity) {
            val repo = a.repo
            val scores = intArrayOf(50, 50, 50, 50)
            val sh = Sheet(a, "New idea", "Is it essential? Score honestly. Anything under 90 is a no — for now.")
            val name = a.field("Idea, project, request or opportunity")
            sh.add(name)
            val total = a.txt("", 34f, Th.text, Fonts.light)
            val rec = a.dimText("")
            fun upd() {
                val t = scores.average().roundToInt()
                total.text = "$t"
                total.setTextColor(if (t >= 90) Th.primary else Th.trivial)
                rec.text = if (t >= 90) "Clear yes. Strong fit — make room for it." else "Recommendation: NO. It moves to Not Now, reviewed monthly. Nothing is lost."
            }
            val labels = listOf("Fit with Essential Intent", "Money potential", "Uses my strengths", "Energy it gives me")
            labels.forEachIndexed { i, l ->
                val r = a.hbox()
                r.add(a.txt(l, 14.5f), 0, WRAP, 1f)
                val v = a.txt("${scores[i]}", 14.5f, Th.dim, Fonts.medium)
                r.add(v, WRAP, WRAP)
                sh.add(r, bottom = 0)
                sh.add(a.slider(scores[i]) { scores[i] = it; v.text = "$it"; upd() }, bottom = 6)
            }
            val give = a.field("What will I give up to make time for this? (required)", multiline = true)
            sh.add(give, top = 4)
            val tr = a.hbox(); tr.add(total, WRAP, WRAP, end = 12); tr.add(rec, 0, WRAP, 1f)
            sh.add(tr)
            upd()
            sh.actions("Decide") {
                if (name.value.isBlank()) { a.toast("Name the idea"); return@actions }
                if (give.value.isBlank()) { a.toast("Answer what you'll give up"); return@actions }
                val t = scores.average().roundToInt()
                val today = Days.today(repo)
                val yes = t >= 90
                repo.addOpportunity(Opportunity(0, name.value, scores[0], scores[1], scores[2], scores[3], give.value, t,
                    if (yes) "Yes" else "Not Now", today.toString(), if (yes) null else today.withDayOfMonth(1).plusMonths(1).toString()))
                sh.dismiss()
                a.toast(if (yes) "Yes — now protect time for it" else "Parked in Not Now. Reviewed on the 1st.")
                a.refresh()
            }
            sh.show()
        }
    }

    override fun content(): View = page {
        val all = repo.opportunities()
        val due = all.filter { it.decision == "Not Now" && it.reviewDate != null && it.reviewDate <= today.toString() }
        if (due.isNotEmpty()) {
            add(a.label("Monthly review · ${due.size} due"), bottom = 6)
            due.forEach { o -> add(oppCard(o, true), bottom = 8) }
        }
        add(a.btn("New idea", icon = "idea") { newIdea(a) }, top = 4, bottom = 16)
        listOf("Yes", "Not Now", "No").forEach { d ->
            val items = all.filter { it.decision == d && it !in due }
            if (items.isEmpty()) return@forEach
            add(a.label(if (d == "Not Now") "Not Now · parked, not lost" else d), bottom = 6)
            items.forEach { add(oppCard(it, false), bottom = 8) }
        }
    }

    private fun oppCard(o: Opportunity, review: Boolean): View {
        val c = a.card(14)
        val r = a.hbox()
        r.add(a.txt(o.title, 15.5f, Th.text, Fonts.medium), 0, WRAP, 1f)
        r.add(a.txt("${o.total}", 18f, if (o.total >= 90) Th.primary else Th.trivial, Fonts.semibold), WRAP, WRAP)
        c.add(r)
        c.add(a.dimText("Fit ${o.fit} · Money ${o.money} · Strengths ${o.strengths} · Energy ${o.energy}"), top = 2)
        c.add(a.dimText("Gives up: ${o.giveUp}"), top = 2)
        if (review || o.decision == "Not Now") {
            val row = a.hbox()
            row.add(a.btn("Keep parked", Btn.TEXT, color = Th.dim) {
                repo.setOpportunityDecision(o.id, "Not Now", today.withDayOfMonth(1).plusMonths(1).toString()); a.refresh()
            }, WRAP, WRAP)
            row.add(a.btn("Say yes", Btn.TEXT) {
                a.confirm("Is this worth giving up \"${o.giveUp}\"?", "Scored ${o.total}. Saying yes means saying no to that.", "Yes, worth it") {
                    repo.setOpportunityDecision(o.id, "Yes", null); a.refresh()
                }
            }, WRAP, WRAP)
            row.add(a.btn("Drop", Btn.TEXT, color = Th.red) { repo.setOpportunityDecision(o.id, "No", null); a.refresh() }, WRAP, WRAP)
            c.add(row, top = 4)
        } else c.click { a.confirm("Delete idea?", o.title, "Delete", danger = true) { repo.deleteOpportunity(o.id); a.refresh() } }
        return c
    }
}

// ============================================================ No log & scripts
class NoLogScreen(a: MainActivity) : Screen(a) {
    override val title = "\"No\" log & scripts"

    companion object {
        /** (situation, English, Kannada) — Kannada drafts; edit freely to your own voice. */
        val SCRIPTS = listOf(
            Triple("Any request",
                "Thank you for thinking of me. I'm focused on a few commitments right now, so I can't take this on. I hope it goes really well.",
                "ನನ್ನನ್ನು ನೆನಪಿಸಿಕೊಂಡಿದ್ದಕ್ಕೆ ಧನ್ಯವಾದಗಳು. ಈಗ ನಾನು ಕೆಲವು ಮುಖ್ಯ ಕೆಲಸಗಳ ಮೇಲೆ ಗಮನ ಕೊಡುತ್ತಿದ್ದೇನೆ, ಹಾಗಾಗಿ ಇದನ್ನು ಒಪ್ಪಿಕೊಳ್ಳಲು ಆಗುವುದಿಲ್ಲ. ಇದು ಚೆನ್ನಾಗಿ ನಡೆಯಲಿ ಎಂದು ಆಶಿಸುತ್ತೇನೆ."),
            Triple("Event or meeting",
                "Thanks for the invite. I'm keeping my evenings for focused work these weeks, so I'll pass this time.",
                "ಆಹ್ವಾನಕ್ಕೆ ಧನ್ಯವಾದಗಳು. ಈ ವಾರಗಳಲ್ಲಿ ನನ್ನ ಸಂಜೆಯ ಸಮಯವನ್ನು ಮುಖ್ಯ ಕೆಲಸಕ್ಕೆ ಮೀಸಲಿಟ್ಟಿದ್ದೇನೆ, ಹಾಗಾಗಿ ಈ ಬಾರಿ ಬರಲು ಆಗುವುದಿಲ್ಲ."),
            Triple("Free astrology reading",
                "I'd be glad to help through a proper consultation. I don't do free readings, but I can share my available slots.",
                "ಸರಿಯಾದ ಸಮಾಲೋಚನೆಯ ಮೂಲಕ ಸಹಾಯ ಮಾಡಲು ನನಗೆ ಸಂತೋಷ. ನಾನು ಉಚಿತವಾಗಿ ಜಾತಕ ನೋಡುವುದಿಲ್ಲ, ಆದರೆ ನನ್ನ ಲಭ್ಯವಿರುವ ಸಮಯವನ್ನು ತಿಳಿಸುತ್ತೇನೆ."),
            Triple("Partnership / new idea",
                "This sounds interesting, but it doesn't fit what I'm focused on this quarter. Let's revisit after a few months.",
                "ಇದು ಆಸಕ್ತಿದಾಯಕವಾಗಿದೆ, ಆದರೆ ಈ ತ್ರೈಮಾಸಿಕದಲ್ಲಿ ನಾನು ಗಮನ ಕೊಡುತ್ತಿರುವ ಕೆಲಸಕ್ಕೆ ಹೊಂದುವುದಿಲ್ಲ. ಕೆಲವು ತಿಂಗಳ ನಂತರ ಮತ್ತೆ ಮಾತನಾಡೋಣ."),
            Triple("Call during a work block",
                "I'm in a work block right now. Can I call you back at 10:45?",
                "ಈಗ ನಾನು ಮುಖ್ಯ ಕೆಲಸದಲ್ಲಿದ್ದೇನೆ. 10:45ಕ್ಕೆ ನಿಮಗೆ ಮತ್ತೆ ಕರೆ ಮಾಡಲೇ?")
        )
    }

    private var kannada = false

    override fun content(): View = page {
        val month = repo.hoursSaved(today.withDayOfMonth(1), today)
        val c = a.card(18, Th.primaryContainer)
        c.add(a.label("Hours protected by saying no · this month"))
        c.add(a.txt(TimeUtil.fmtHours(month), 44f, Th.primary, Fonts.light), top = 2)
        add(c, bottom = 12)
        add(a.btn("Log a no", icon = "plus") { logNo() }, bottom = 16)

        val hr = a.hbox()
        hr.add(a.label("Polite decline scripts"), 0, WRAP, 1f)
        hr.add(a.choice(listOf("English", "ಕನ್ನಡ"), if (kannada) "ಕನ್ನಡ" else "English") { kannada = it == "ಕನ್ನಡ"; a.refresh() }, WRAP, WRAP)
        add(hr, bottom = 8)
        val custom = repo.settings.str("custom_scripts").split("\n").filter { it.isNotBlank() }
        (SCRIPTS.map { it.first to (if (kannada) it.third else it.second) } + custom.map { "My script" to it }).forEach { (sit, text) ->
            val sc = a.card(14)
            sc.add(a.label(sit))
            sc.add(a.body(text), top = 4)
            val r = a.hbox()
            r.add(a.btn("Copy", Btn.TEXT, "copy") { a.copy(text) }, WRAP, WRAP)
            r.add(a.btn("Share", Btn.TEXT, "share") { a.shareText(text, "Reply") }, WRAP, WRAP)
            sc.add(r, top = 4)
            add(sc, bottom = 8)
        }
        add(a.btn("Add my own script", Btn.TEXT, "plus") {
            val sh = Sheet(a, "Your script")
            val f = a.field("Write it the way you'd say it", multiline = true)
            sh.add(f).actions("Save") {
                if (f.value.isNotBlank()) repo.settings.set("custom_scripts", (custom + f.value.replace("\n", " ")).joinToString("\n"))
                sh.dismiss(); a.refresh()
            }.show()
        }, bottom = 12)

        val nos = repo.noLogs()
        if (nos.isNotEmpty()) {
            add(a.label("Your no's"), top = 8, bottom = 6)
            val list = a.card(6)
            nos.forEach { n -> list.add(a.listRow(n.what, "${TimeUtil.fmtDay(n.date)} · ${TimeUtil.fmtHours(n.hoursSaved)}h saved", null,
                trailing = a.iconBtn("trash", Th.faint, 40, "Delete") { repo.deleteNo(n.id); a.refresh() })) }
            add(list)
        }
    }

    private fun logNo() {
        var hours = 2.0
        val sh = Sheet(a, "I said no to…")
        val f = a.field("e.g. Weekend property expo stall")
        sh.add(f)
        sh.add(a.label("Hours it saved"), bottom = 6)
        sh.add(a.choice(listOf("0.5", "1", "2", "4", "8", "20"), "2") { hours = it?.toDouble() ?: 2.0 })
        sh.actions("Save") {
            if (f.value.isBlank()) return@actions
            repo.addNo(today, f.value, hours); sh.dismiss(); a.toast("Well protected."); a.refresh()
        }
        sh.show()
    }
}

// ============================================================ Monthly uncommit review
class UncommitScreen(a: MainActivity) : Screen(a) {
    override val title = "Uncommit review"

    override fun content(): View = page {
        val month = TimeUtil.monthKey(today)
        val existing = repo.uncommitReviews(month).associateBy { it.item }
        val logs = repo.logsRange(today.minusDays(30), today)
        add(a.h2(TimeUtil.fmtMonth(today)), bottom = 4)
        add(a.dimText("For each venture and recurring commitment: if you weren't already doing this, would you start it today?"), bottom = 14)

        val follow = repo.pendingFollowUps()
        if (follow.isNotEmpty()) {
            add(a.label("Follow-through"), bottom = 6)
            val c = a.card(10)
            follow.forEach { u ->
                val r = a.hbox().apply { setPadding(a.dp(4), a.dp(8), a.dp(4), a.dp(8)) }
                r.add(HomeScreen.checkBox(a, u.followUpDone) { repo.setFollowUp(u.id, it); a.refresh() }, a.dp(24), a.dp(24), end = 12)
                r.add(a.txt("${u.decision}: ${u.item} (${u.month})", 14.5f), 0, WRAP, 1f)
                c.add(r)
            }
            add(c, bottom = 14)
        }

        repo.ventures().forEach { v ->
            val l = logs.filter { it.ventureId == v.id }
            item(month, v.name, v.id, "${TimeUtil.fmtHours(Metrics.loggedHours(l))}h in 30 days · ${TimeUtil.rupees(Metrics.money(l))} earned", existing[v.name])
        }
        repo.commitments().filter { it.active }.forEach { c ->
            val l = logs.filter { it.activity.contains(c.name, ignoreCase = true) }
            item(month, c.name, null, if (l.isEmpty()) "Recurring commitment" else "${TimeUtil.fmtHours(Metrics.loggedHours(l))}h in 30 days", existing[c.name])
        }
        add(a.btn("Add a recurring commitment", Btn.TEXT, "plus") {
            val sh = Sheet(a, "Recurring commitment")
            val f = a.field("e.g. Weekly builders' association meeting")
            sh.add(f).actions("Add") { if (f.value.isNotBlank()) repo.addCommitment(f.value); sh.dismiss(); a.refresh() }.show()
        }, top = 6)
    }

    private fun android.widget.LinearLayout.item(month: String, name: String, ventureId: Long?, stats: String, ex: com.essential.app.data.UncommitReview?) {
        val c = a.card(16)
        c.add(a.h3(name))
        c.add(a.dimText(stats), top = 2, bottom = 8)
        var would = ex?.wouldStart
        var decision = ex?.decision
        c.add(a.dimText("Would I start it today?"), bottom = 4)
        c.add(a.choice(listOf("Yes", "No", "Not sure"), would) { would = it; repo.saveUncommit(month, name, ventureId, would, decision) }, bottom = 8)
        c.add(a.choice(listOf("Keep", "Reduce", "Stop", "Test-stop"), decision, { when (it) { "Keep" -> Th.primary; "Reduce" -> Th.yellow; else -> Th.red } }) {
            decision = it; repo.saveUncommit(month, name, ventureId, would, decision)
            if (it == "Test-stop") a.toast("Test-stop for 2 weeks. You'll get a follow-through reminder.")
            if (it == "Stop" && ventureId == null) repo.commitments().firstOrNull { c2 -> c2.name == name }?.let { c2 -> repo.setCommitmentActive(c2.id, false) }
        })
        add(c, bottom = 10)
    }
}

// ============================================================ Buffer tracking
class BufferScreen(a: MainActivity) : Screen(a) {
    override val title = "Estimates & buffer"
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "New task") { addTask() })

    override fun content(): View = page {
        val ratio = Insights.bufferRatio(repo)
        val c = a.card(18, Th.primaryContainer)
        if (ratio == null) {
            c.add(a.h3("Estimate, then measure"))
            c.add(a.dimText("Finish at least two estimated tasks to see your planning error."), top = 4)
        } else {
            c.add(a.label("Your planning error"))
            c.add(a.txt("%.1f×".format(ratio), 44f, Th.primary, Fonts.light), top = 2)
            c.add(a.body(if (ratio > 1.05) "Your tasks take ${"%.1f".format(ratio)}x your estimate. Add a ${((ratio - 1) * 100).roundToInt()}% buffer to future estimates."
                else "Your estimates are accurate. Keep a small buffer anyway."), top = 4)
        }
        add(c, bottom = 12)
        val trend = Insights.bufferTrend(repo)
        if (trend.size >= 2) {
            add(a.label("Accuracy by week (1.0 = perfect)"), bottom = 6)
            add(LineChart(a, listOf(trend.map { it.second }), listOf(Th.primary), trend.map { TimeUtil.fmtShort(it.first) }), bottom = 12)
        }
        val noBuffer = (0..6).map { today.plusDays(it.toLong()) }.filter { !Timeline.hasBuffer(Days.resolve(repo, it).blocks) }
        if (noBuffer.isNotEmpty()) add(a.dimText("No buffer time on: " + noBuffer.joinToString(", ") { TimeUtil.fmtDow(it) }), bottom = 12)
        add(a.btn("Estimate a task", icon = "plus") { addTask() }, bottom = 14)
        val tasks = repo.tasks()
        tasks.forEach { t ->
            val r = a.card(14)
            val row = a.hbox()
            val col = a.vbox()
            col.add(a.txt(t.title, 15f))
            col.add(a.dimText("Estimated ${TimeUtil.fmtDuration(t.est.toLong())}" + (t.actual?.let { " · took ${TimeUtil.fmtDuration(it.toLong())} (${"%.1f".format(it.toDouble() / t.est)}×)" } ?: "")), top = 2)
            row.add(col, 0, WRAP, 1f)
            if (t.actual == null) row.add(a.btn("Done", Btn.TONAL) { finish(t) }, WRAP, WRAP)
            else row.add(a.iconBtn("trash", Th.faint, 40, "Delete") { repo.deleteTask(t.id); a.refresh() }, WRAP, WRAP)
            r.add(row)
            add(r, bottom = 8)
        }
    }

    private fun addTask() {
        var est = 60
        val ratio = Insights.bufferRatio(repo)
        val sh = Sheet(a, "Estimate a task", ratio?.takeIf { it > 1.05 }?.let { "Tip: your tasks take ${"%.1f".format(it)}× your estimate." })
        val f = a.field("Task")
        sh.add(f)
        val sug = a.dimText("")
        fun upd() { sug.text = ratio?.takeIf { it > 1.05 }?.let { "With your buffer: plan ${TimeUtil.fmtDuration((est * it).roundToInt().toLong())}" } ?: "" }
        sh.add(a.choice(listOf("15", "30", "45", "60", "90", "120", "180"), "60") { est = it?.toInt() ?: 60; upd() })
        upd(); sh.add(sug)
        sh.actions("Save") { if (f.value.isBlank()) return@actions; repo.addTask(f.value, today, est); sh.dismiss(); a.refresh() }
        sh.show()
    }

    private fun finish(t: com.essential.app.data.TaskEstimate) {
        val sh = Sheet(a, "How long did it take?", t.title)
        val f = a.field("Actual minutes", "${t.est}", numeric = true)
        sh.add(f)
        sh.actions("Save") { f.value.toIntOrNull()?.let { repo.setTaskActual(t.id, it) }; sh.dismiss(); a.refresh() }
        sh.show()
    }
}

// ============================================================ Weekly obstacle
class ObstacleScreen(a: MainActivity) : Screen(a) {
    override val title = "Weekly obstacle"

    override fun content(): View = page {
        val week = TimeUtil.weekStart(today)
        val last = repo.obstacle(week.minusWeeks(1))
        if (last != null) {
            val c = a.card(16)
            c.add(a.label("Last week"))
            c.add(a.body(last.obstacle), top = 4)
            last.action?.let { c.add(a.dimText("Action: $it"), top = 2) }
            c.add(a.dimText("Did the action remove it?"), top = 10, bottom = 6)
            c.add(a.choice(listOf("Yes", "Partly", "No"), when (last.resolved) { true -> "Yes"; false -> "No"; null -> null }) {
                repo.setObstacleResolved(last.id, it == "Yes")
            })
            add(c, bottom = 14)
        }
        val ins = Insights(repo, week, today)
        add(a.label("From your logs this week"), bottom = 6)
        val sug = a.card(14)
        val reasons = ins.offPlanReasons().take(3)
        val leaks = ins.trivialLeaks().take(2)
        val peak = ins.distractionsByHour().maxByOrNull { it.value }
        if (reasons.isEmpty() && leaks.isEmpty() && peak == null) sug.add(a.dimText("Log a few days to see suggestions."))
        reasons.forEach { (r, n) -> sug.add(a.body("Off-plan: $r ($n×)"), bottom = 2) }
        leaks.forEach { (t, h) -> sug.add(a.body("Trivial: $t (${TimeUtil.fmtHours(h)}h)"), bottom = 2) }
        peak?.let { sug.add(a.body("Most distractions around ${TimeUtil.fmtTime(it.key * 60)}"), bottom = 2) }
        add(sug, bottom = 14)

        val cur = repo.obstacle(week)
        add(a.label("This week"), bottom = 6)
        val ob = a.field("What one obstacle slowed my Essential Intent most?", cur?.obstacle, multiline = true)
        add(ob, bottom = 8)
        val chips = Flow(a)
        (reasons.map { it.first } + leaks.map { it.first }).distinct().forEach { s -> chips.addView(a.chip(s, false) { ob.setText(s) }) }
        add(chips, bottom = 8)
        val act = a.field("One action to remove it", cur?.action, multiline = true)
        add(act, bottom = 10)
        add(a.btn("Save") { if (ob.value.isBlank()) return@btn; repo.saveObstacle(week, ob.value, act.value.ifBlank { null }); a.toast("Saved. Checked next Sunday."); a.refresh() })

        val hist = repo.obstacles().filter { it.week != week.toString() }
        if (hist.isNotEmpty()) {
            add(a.label("History"), top = 18, bottom = 6)
            val c = a.card(6)
            hist.forEach { o -> c.add(a.listRow(o.obstacle, "Week of ${o.week} · " + when (o.resolved) { true -> "resolved"; false -> "not yet"; null -> "unchecked" })) }
            add(c)
        }
    }
}

// ============================================================ Distractions
class DistractionScreen(a: MainActivity) : Screen(a) {
    override val title = "Distractions"
    override fun content(): View = page {
        val todayList = repo.distractions(today, today)
        val c = a.card(18)
        c.add(a.label("Today"))
        c.add(a.txt("${todayList.size}", 44f, Th.trivial, Fonts.light), top = 2)
        c.add(a.btn("Distracted", Btn.TONAL, color = Th.trivial) { HomeScreen.distracted(a) }, top = 6)
        add(c, bottom = 14)
        val from = today.minusDays(13)
        val all = repo.distractions(from, today)
        val days = (0..13).map { from.plusDays(it.toLong()) }
        add(a.label("Last 14 days"), bottom = 6)
        add(BarChart(a, days.map { d -> all.count { it.date == d }.toDouble() }, days.map { TimeUtil.fmtDow(it).take(1) }, List(14) { Th.trivial }, fmt = { "${it.toInt()}" }), bottom = 14)
        val byHour = all.groupingBy { TimeUtil.at(it.ts).hour }.eachCount()
        if (byHour.isNotEmpty()) {
            val hours = (byHour.keys.minOrNull()!!..byHour.keys.maxOrNull()!!).toList()
            add(a.label("Peak distraction hours"), bottom = 6)
            add(BarChart(a, hours.map { (byHour[it] ?: 0).toDouble() }, hours.map { TimeUtil.fmtTime(it * 60).replace(" ", "").lowercase() }, hours.map { Th.trivial }, fmt = { "${it.toInt()}" }), bottom = 14)
        }
        val reasons = all.groupingBy { it.reason ?: "No reason" }.eachCount().toList().sortedByDescending { it.second }
        if (reasons.isNotEmpty()) {
            add(a.label("Reasons"), bottom = 2)
            add(a.hbars(reasons.map { Triple(it.first, it.second.toDouble(), Th.trivial) }, { "${it.toInt()}" }), bottom = 14)
        }
    }
}

// ============================================================ Habits
class HabitsScreen(a: MainActivity) : Screen(a) {
    override val title = "Routines & habits"
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "New habit") { edit(null) })

    private fun streaks(dates: List<java.time.LocalDate>): Pair<Int, Int> {
        val set = dates.toSet()
        var cur = 0
        var d = if (today in set) today else today.minusDays(1)
        while (d in set) { cur++; d = d.minusDays(1) }
        var best = 0; var run = 0; var prev: java.time.LocalDate? = null
        for (x in dates.sorted()) { run = if (prev != null && prev.plusDays(1) == x) run + 1 else 1; best = maxOf(best, run); prev = x }
        return cur to best
    }

    override fun content(): View = page {
        val done = repo.habitDone(today)
        val habits = repo.habits(false)
        val active = habits.filter { it.active }
        add(a.dimText("${done.count { id -> active.any { it.id == id } }} of ${active.size} today. Routines make essential work effortless."), bottom = 12)
        active.forEach { h ->
            val (cur, best) = streaks(repo.habitDates(h.id))
            val c = a.card(14)
            val r = a.hbox()
            r.add(HomeScreen.checkBox(a, h.id in done) { repo.setHabit(h.id, today, it); Hooks.afterChange(a); a.refresh() }, a.dp(28), a.dp(28), end = 14)
            val col = a.vbox()
            col.add(a.txt(h.name, 16f, Th.text, Fonts.medium))
            h.trigger?.takeIf { it.isNotBlank() }?.let { col.add(a.dimText(it), top = 2) }
            col.add(a.txt(when {
                cur > 0 -> "$cur-day streak · best $best"
                best > 0 -> "Fresh start today · best $best"
                else -> "Start whenever you're ready"
            }, 12.5f, Th.faint), top = 4)
            r.add(col, 0, WRAP, 1f)
            r.add(a.iconBtn("edit", Th.faint, 40, "Edit habit") { edit(h) }, WRAP, WRAP)
            c.add(r)
            add(c, bottom = 8)
        }
        val inactive = habits.filter { !it.active }
        if (inactive.isNotEmpty()) {
            add(a.label("Paused"), top = 10, bottom = 6)
            val c = a.card(6)
            inactive.forEach { h -> c.add(a.listRow(h.name, h.trigger) { edit(h) }) }
            add(c)
        }
    }

    private fun edit(h: com.essential.app.data.Habit?) {
        var active = h?.active ?: true
        val sh = Sheet(a, if (h == null) "New habit" else "Edit habit")
        val n = a.field("Habit", h?.name)
        val t = a.field("Trigger, e.g. After bath → write ONE thing", h?.trigger)
        sh.add(n); sh.add(t)
        if (h != null) {
            sh.add(a.switchRow("Active", null, active) { active = it })
            sh.add(a.btn("Delete habit", Btn.TEXT, color = Th.red) { a.confirm("Delete \"${h.name}\"?", "Its history is removed too.", "Delete", danger = true) { repo.deleteHabit(h.id); sh.dismiss(); a.refresh() } })
        }
        sh.actions("Save") {
            if (n.value.isBlank()) return@actions
            if (h == null) repo.addHabit(n.value, t.value) else repo.updateHabit(h.copy(name = n.value, trigger = t.value, active = active))
            sh.dismiss(); a.refresh()
        }
        sh.show()
    }
}

// ============================================================ Sleep
class SleepScreen(a: MainActivity) : Screen(a) {
    override val title = "Sleep"
    override fun content(): View = page {
        add(a.btn(if (repo.sleepLog(today) == null) "Log last night" else "Edit last night", icon = "moon") { SleepSheet.open(a, today) }, bottom = 14)
        val from = today.minusDays(13)
        val sleeps = repo.sleepLogs(from, today).associateBy { it.date }
        val ins = Insights(repo, from, today)
        val byDate = ins.days.associateBy { it.date }
        val days = (0..13).map { from.plusDays(it.toLong()) }
        add(a.label("Sleep hours vs that day's Essential Hours"), bottom = 6)
        add(DualBarChart(a, days.map { sleeps[it]?.hours }, days.map { byDate[it]?.essential }, Th.necessary, Th.primary, days.map { TimeUtil.fmtDow(it).take(1) },
            fmt = { TimeUtil.fmtHours(it) }), bottom = 4)
        add(a.legend("Sleep h" to Th.necessary, "Essential h" to Th.primary), bottom = 14)
        add(a.label("Sleep hours vs focus"), bottom = 6)
        add(LineChart(a, listOf(days.map { sleeps[it]?.hours?.div(2) }, days.map { byDate[it]?.focus }), listOf(Th.necessary, Th.primary),
            days.map { TimeUtil.fmtDow(it).take(1) }, 5.0), bottom = 4)
        add(a.legend("Sleep h ÷ 2" to Th.necessary, "Avg focus" to Th.primary), bottom = 12)
        val good = days.filter { (sleeps[it]?.hours ?: 0.0) >= 6.5 }.mapNotNull { byDate[it]?.essential }
        val short = days.filter { sleeps[it] != null && sleeps[it]!!.hours < 6.0 }.mapNotNull { byDate[it]?.essential }
        if (good.isNotEmpty() && short.isNotEmpty())
            add(a.card(14, Th.primaryContainer).apply { add(a.body("After 6.5h+ sleep you average ${TimeUtil.fmtHours(good.average())} Essential Hours; after under 6h, ${TimeUtil.fmtHours(short.average())}.")) }, bottom = 12)
        add(a.label("Log"), bottom = 6)
        val c = a.card(6)
        days.reversed().mapNotNull { sleeps[it] }.forEach { s ->
            c.add(a.listRow("${TimeUtil.fmtDay(s.date)} · ${TimeUtil.fmtHours(s.hours)}h", "${TimeUtil.fmtTime(s.bedtime)} → ${TimeUtil.fmtTime(s.wake)} · quality ${s.quality}/5") { SleepSheet.open(a, s.date) })
        }
        add(c)
    }
}

// ============================================================ Play & Think Time
class PlayThinkScreen(a: MainActivity) : Screen(a) {
    override val title = "Play & Think Time"
    override fun content(): View = page {
        add(a.dimText("Play restores. Think Time decides what's essential. Both are protected, not leftovers."), bottom = 14)
        val weeks = (7 downTo 0).map { TimeUtil.weekStart(today).minusWeeks(it.toLong()) }
        val play = ArrayList<Double>(); val think = ArrayList<Double>()
        weeks.forEach { w ->
            val l = repo.logsRange(w, w.plusDays(6))
            play.add(l.filter { it.category == com.essential.app.data.Cat.LIFE }.sumOf { it.minutes } / 60.0)
            think.add(l.filter { it.category == com.essential.app.data.Cat.THINK }.sumOf { it.minutes } / 60.0)
        }
        val c = a.card(16)
        val r = a.hbox()
        fun stat(v: Double, l: String, col: Int) { val x = a.vbox(); x.add(a.txt(TimeUtil.fmtHours(v) + "h", 30f, col, Fonts.light)); x.add(a.dimText(l)); r.add(x, 0, WRAP, 1f) }
        stat(play.last(), "Play / life this week", Th.necessary)
        stat(think.last(), "Think Time this week", Th.primary)
        c.add(r)
        add(c, bottom = 12)
        if (Insights.thinkTimeSkippedWeeks(repo, today) >= 2)
            add(a.card(14, Th.alpha(Th.yellow, 0.12f)).apply { add(a.body("Think Time has been skipped two weeks in a row. Even one quiet hour this Sunday helps you choose what matters.")) }, bottom = 12)
        add(a.label("Last 8 weeks"), bottom = 6)
        add(DualBarChart(a, play, think, Th.necessary, Th.primary, weeks.map { TimeUtil.fmtShort(it).substringBefore(' ') }, fmt = { TimeUtil.fmtHours(it) }), bottom = 4)
        add(a.legend("Play / life" to Th.necessary, "Think Time" to Th.primary))
    }
}
