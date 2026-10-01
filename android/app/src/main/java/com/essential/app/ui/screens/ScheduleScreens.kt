package com.essential.app.ui.screens

import android.view.View
import com.essential.app.core.*
import com.essential.app.data.Block
import com.essential.app.data.Cat
import com.essential.app.data.Mode
import com.essential.app.data.Template
import com.essential.app.ui.*
import java.time.temporal.ChronoUnit

// ============================================================ Sprints
class SprintScreen(a: MainActivity) : Screen(a) {
    override val title = "Sprint & Max Mode"

    companion object {
        fun newSprint(a: MainActivity) {
            val repo = a.repo
            val today = Days.today(repo)
            if (repo.activeSprint(today) != null) { a.info("A sprint is running", "Finish or end the current sprint first. One intense push at a time."); return }
            repo.recoverySprint(today)?.let { a.info("Recovery week", "Recovery runs until ${TimeUtil.fmtDayLong(it.recoveryEnd!!)}. Rest is part of the plan."); return }
            var start = today; var weeks = 2
            val sh = Sheet(a, "Start a sprint", "Max Mode runs only inside a sprint: a clear goal, an end date, at most 6 weeks, then one recovery week.")
            val goal = a.field("Sprint goal, e.g. Sign 2 JV term sheets", repo.intent()?.title)
            sh.add(goal)
            lateinit var sr: android.widget.LinearLayout
            sr = a.listRow("Starts", TimeUtil.fmtDayLong(start), "log") { a.pickDate(start) { start = it; ((sr.getChildAt(1) as android.widget.LinearLayout).getChildAt(1) as android.widget.TextView).text = TimeUtil.fmtDayLong(it) } }
            sh.add(sr)
            sh.add(a.label("Length"), bottom = 6)
            sh.add(a.choice((1..6).map { "$it wk" }, "2 wk") { weeks = it?.removeSuffix(" wk")?.toInt() ?: 2 })
            sh.add(a.dimText("Max days: wake ${TimeUtil.fmtTime(repo.settings.wake(Mode.MAX))}, sleep ${TimeUtil.fmtTime(repo.settings.sleep(Mode.MAX))}. The app watches for burnout (short sleep or low focus 3 days running)."))
            sh.actions("Start sprint") {
                if (goal.value.isBlank()) { a.toast("Give the sprint a goal"); return@actions }
                val end = start.plusDays(weeks * 7L - 1)
                if (ChronoUnit.DAYS.between(start, end) + 1 > 42) { a.toast("Maximum 6 weeks"); return@actions }
                repo.addSprint(goal.value, start, end)
                if (start == today) Days.setMode(repo, today, Mode.MAX)
                Hooks.scheduleChanged(a); sh.dismiss(); a.toast("Sprint started. Protect your sleep."); a.refresh()
            }
            sh.show()
        }
    }

    override fun content(): View = page {
        val active = repo.activeSprint(today)
        val rec = repo.recoverySprint(today)
        if (active != null) {
            val total = ChronoUnit.DAYS.between(active.start, active.end) + 1
            val done = (ChronoUnit.DAYS.between(active.start, today) + 1).coerceIn(0, total)
            val c = a.card(18, Th.primaryContainer)
            c.add(a.badge("Max Mode sprint", Th.trivial, "bolt"))
            c.add(a.txt(active.goal, 19f, Th.text, Fonts.semibold), top = 10)
            c.add(a.dimText("${TimeUtil.fmtShort(active.start)} – ${TimeUtil.fmtShort(active.end)} · day $done of $total · ${total - done} left"), top = 4)
            c.addProgress(done.toDouble() / total, Th.primary, 8, top = 12)
            Insights.burnout(repo, today)?.let { b -> c.add(a.txt("Burnout watch: " + b.reasons.joinToString("; "), 13.5f, Th.yellow), top = 10) }
            c.add(a.btn("End sprint now", Btn.TEXT, color = Th.dim) {
                a.confirm("End sprint early?", "Your recovery week (Normal Mode) starts today. You can see the Max vs Normal report anytime.", "End sprint") {
                    repo.endSprintNow(active.id, today); repo.setDayTemplate(today, null, null); Hooks.scheduleChanged(a); a.refresh()
                }
            }, top = 8)
            add(c, bottom = 12)
            add(a.btn("Sprint report so far", Btn.TONAL) { a.push(SprintReportScreen(a, active.id)) }, bottom = 16)
        } else if (rec != null) {
            val c = a.card(18)
            c.add(a.h3("Recovery week"))
            c.add(a.dimText("After \"${rec.goal}\". Normal Mode until ${TimeUtil.fmtDayLong(rec.recoveryEnd!!)}. Sleep fully, keep one Essential Block, enjoy the evenings."), top = 4)
            c.add(a.btn("See sprint report", Btn.TONAL) { repo.markSprintReportSeen(rec.id); a.push(SprintReportScreen(a, rec.id)) }, top = 10)
            add(c, bottom = 16)
        } else {
            add(a.body("Max Mode is a time-limited push: about 18.5 hours awake and 15 hours of work. Use it for a clear goal, then recover."), bottom = 12)
            add(a.btn("Start a sprint", icon = "bolt") { newSprint(a) }, bottom = 16)
        }
        val s = repo.settings
        val t = a.card(16)
        t.add(a.label("Targets"))
        t.add(a.body("Normal: ${TimeUtil.fmtHours(s.targetEssential(Mode.NORMAL))} Essential / ${TimeUtil.fmtHours(s.targetWork(Mode.NORMAL))} working hours"), top = 6)
        t.add(a.body("Max: ${TimeUtil.fmtHours(s.targetEssential(Mode.MAX))} Essential / ${TimeUtil.fmtHours(s.targetWork(Mode.MAX))} working hours"), top = 2)
        t.add(a.dimText("Edit in Settings → Day & targets."), top = 4)
        add(t, bottom = 16)
        val past = repo.sprints().filter { it.id != active?.id }
        if (past.isNotEmpty()) {
            add(a.label("Past sprints"), bottom = 6)
            val c = a.card(6)
            past.forEach { sp -> c.add(a.listRow(sp.goal, "${TimeUtil.fmtShort(sp.start)} – ${TimeUtil.fmtShort(sp.end)} · ${sp.status}", "bolt") { a.push(SprintReportScreen(a, sp.id)) }) }
            add(c)
        }
    }
}

class SprintReportScreen(a: MainActivity, private val sprintId: Long) : Screen(a) {
    override val title = "Sprint report"
    override fun content(): View = page {
        val sp = repo.sprint(sprintId) ?: return@page
        val r = Insights.sprintReport(repo, sp)
        add(a.h2(sp.goal), bottom = 4)
        add(a.dimText("${TimeUtil.fmtShort(sp.start)} – ${TimeUtil.fmtShort(sp.end)} · Max days vs Normal days (last 4 weeks before the sprint and after)"), bottom = 14)
        val c = a.card(16)
        val head = a.hbox()
        head.add(a.label("Metric"), 0, WRAP, 1.4f); head.add(a.label("Max"), 0, WRAP, 1f); head.add(a.label("Normal"), 0, WRAP, 1f)
        c.add(head, bottom = 6)
        fun row(name: String, mx: String, nm: String) {
            val rr = a.hbox().apply { setPadding(0, a.dp(8), 0, a.dp(8)) }
            rr.add(a.txt(name, 14.5f), 0, WRAP, 1.4f); rr.add(a.txt(mx, 14.5f, Th.trivial, Fonts.medium), 0, WRAP, 1f); rr.add(a.txt(nm, 14.5f, Th.primary, Fonts.medium), 0, WRAP, 1f)
            c.add(rr)
        }
        fun f1(v: Double?) = v?.let { "%.1f".format(it) } ?: "–"
        row("Days", "${r.max.days}", "${r.normal.days}")
        row("Essential h/day", TimeUtil.fmtHours(r.max.essential), TimeUtil.fmtHours(r.normal.essential))
        row("Working h/day", TimeUtil.fmtHours(r.max.work), TimeUtil.fmtHours(r.normal.work))
        row("Focus", f1(r.max.focus), f1(r.normal.focus))
        row("Energy", f1(r.max.energy), f1(r.normal.energy))
        row("₹ per hour", TimeUtil.rupees(r.max.perHour), TimeUtil.rupees(r.normal.perHour))
        row("Trading P&L/day", TimeUtil.rupees(r.max.pnl), TimeUtil.rupees(r.normal.pnl))
        add(c, bottom = 12)
        r.lines.forEach { add(a.dimText("• $it"), bottom = 4) }
        val verdict = when {
            r.max.days == 0 -> "No Max days logged yet."
            (r.max.focus ?: 0.0) < (r.normal.focus ?: 0.0) - 0.5 && r.max.essential <= r.normal.essential * 1.2 ->
                "Max Mode added hours but cost focus. Next time: a shorter sprint or protect sleep."
            r.max.essential > r.normal.essential * 1.2 -> "Max Mode moved the needle. Recover well so the gain sticks."
            else -> "Similar results in both modes. Normal Mode may be the better trade."
        }
        add(a.card(16, Th.primaryContainer).apply { add(a.body(verdict)) }, top = 8)
    }
}

// ============================================================ Templates
class TemplatesScreen(a: MainActivity) : Screen(a) {
    override val title = "Schedule templates"
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "New template") { newTemplate() })

    override fun content(): View = page {
        add(a.dimText("Assign templates to weekdays. Switch any day's template or mode from Home in one tap."), bottom = 14)
        val dows = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        repo.templates().forEach { t ->
            val blocks = repo.blocks(t.id)
            val ess = Timeline.minutesBy(blocks, setOf(Cat.ESSENTIAL, Cat.THINK)) / 60.0
            val work = Timeline.minutesBy(blocks, Cat.WORK) / 60.0
            val days = if (t.weekdays.isEmpty()) "Not assigned" else t.weekdays.sorted().joinToString(" ") { dows[it - 1] }
            val c = a.card(16) { a.push(TemplateEditorScreen(a, t.id)) }
            val r = a.hbox()
            r.add(a.h3(t.name), 0, WRAP, 1f)
            r.add(a.badge(if (t.mode == Mode.MAX) "Max" else "Normal", if (t.mode == Mode.MAX) Th.trivial else Th.primary, if (t.mode == Mode.MAX) "bolt" else null), WRAP, WRAP)
            c.add(r)
            c.add(a.dimText("$days${if (t.mode == Mode.MAX) " (during sprints)" else ""} · ${blocks.size} blocks · ${TimeUtil.fmtHours(ess)}h essential · ${TimeUtil.fmtHours(work)}h work"), top = 4)
            add(c, bottom = 10)
        }
    }

    private fun newTemplate() {
        var mode = Mode.NORMAL
        val ts = repo.templates()
        var copy: Long? = ts.firstOrNull()?.id
        val sh = Sheet(a, "New template")
        val f = a.field("Name, e.g. Site Visit Day")
        sh.add(f)
        sh.add(a.choice(listOf("Normal", "Max"), "Normal") { mode = if (it == "Max") Mode.MAX else Mode.NORMAL })
        sh.add(a.label("Start from"), bottom = 6)
        sh.add(a.choice(ts.map { it.name }, ts.firstOrNull()?.name) { n -> copy = ts.firstOrNull { it.name == n }?.id })
        sh.actions("Create") {
            if (f.value.isBlank()) return@actions
            val id = repo.addTemplate(f.value, mode, copy)
            sh.dismiss(); a.push(TemplateEditorScreen(a, id))
        }
        sh.show()
    }
}

class TemplateEditorScreen(a: MainActivity, private val templateId: Long) : Screen(a) {
    override val title get() = repo.template(templateId)?.name ?: "Template"

    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "Add block") { editBlock(null) })

    override fun content(): View = page {
        val t = repo.template(templateId) ?: return@page
        val blocks = repo.blocks(templateId)
        val ds = repo.dayStart()

        val head = a.card(14)
        val hr = a.hbox()
        hr.add(a.txt(t.name, 16f, Th.text, Fonts.semibold), 0, WRAP, 1f)
        hr.add(a.iconBtn("edit", Th.dim, 40, "Rename") { rename(t) }, WRAP, WRAP)
        head.add(hr)
        head.add(a.choice(listOf("Normal", "Max"), if (t.mode == Mode.MAX) "Max" else "Normal") {
            repo.updateTemplate(t.copy(mode = if (it == "Max") Mode.MAX else Mode.NORMAL)); Hooks.scheduleChanged(a); a.refresh()
        }, top = 8)
        head.add(a.label("Weekdays"), top = 12, bottom = 6)
        val dows = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        head.add(a.multiChoice(dows, t.weekdays.map { dows[it - 1] }.toSet()) { sel ->
            repo.assignWeekdays(t, sel.map { dows.indexOf(it) + 1 }.toSet()); Hooks.scheduleChanged(a)
        })
        add(head, bottom = 12)

        val gaps = Timeline.gaps(blocks, ds)
        if (gaps.isNotEmpty()) add(a.card(12, Th.alpha(Th.yellow, 0.12f)).apply {
            add(a.txt("Unassigned time: " + gaps.joinToString(", ") { "${TimeUtil.fmtTime(it.first)}–${TimeUtil.fmtTime(it.second)}" }, 14f, Th.text))
            add(a.dimText("Gaps tend to fill with trivial things. Assign them, or make them buffer."), top = 2)
        }, bottom = 10)
        if (!Timeline.hasBuffer(blocks)) add(a.dimText("No buffer block. Your tasks usually take longer than estimated — consider one."), bottom = 10)
        val total = blocks.sumOf { it.duration }
        add(a.dimText("Day is fixed at 24 hours · ${TimeUtil.fmtDuration(total.toLong())} planned"), bottom = 8)

        val sorted = Timeline.sorted(blocks, ds)
        sorted.forEachIndexed { i, b ->
            val row = a.hbox().apply { setPadding(a.dp(12), a.dp(10), a.dp(4), a.dp(10)) }
            val r = a.dp(14).toFloat()
            row.background = ripple(rounded(Th.surface, r), r)
            val bar = View(a).apply { background = rounded(Th.category(b.category), a.dp(3).toFloat()) }
            row.add(bar, a.dp(4), a.dp(36), end = 12)
            val col = a.vbox()
            val tr = a.hbox()
            tr.add(a.txt(b.title, 15f, Th.text, maxLines = 1), 0, WRAP, 1f)
            if (b.isProtected) tr.add(a.iconView("lock", Th.primary, 16), WRAP, WRAP, start = 6)
            col.add(tr)
            col.add(a.txt("${TimeUtil.fmtTime(b.start)}–${TimeUtil.fmtTime(b.end)} · ${TimeUtil.fmtDuration(b.duration.toLong())} · ${b.category}", 12.5f, Th.dim, maxLines = 1))
            row.add(col, 0, WRAP, 1f)
            row.add(a.iconBtn("up", if (i > 0) Th.dim else Th.surface3, 40, "Move up") { if (i > 0) move(sorted, i - 1, i) }, WRAP, WRAP)
            row.add(a.iconBtn("down", if (i < sorted.size - 1) Th.dim else Th.surface3, 40, "Move down") { if (i < sorted.size - 1) move(sorted, i, i + 1) }, WRAP, WRAP)
            row.click(true) { editBlock(b) }
            add(row, bottom = 6)
        }
        add(a.btn("Add block", Btn.TONAL, "plus") { editBlock(null) }, top = 8)
        if (repo.templates().count { it.mode == t.mode } > 1)
            add(a.btn("Delete template", Btn.TEXT, color = Th.red) {
                a.confirm("Delete \"${t.name}\"?", "Days using it fall back to the template assigned to their weekday.", "Delete", danger = true) {
                    repo.deleteTemplate(t.id); Hooks.scheduleChanged(a); a.back()
                }
            }, top = 16)
    }

    private fun rename(t: Template) {
        val sh = Sheet(a, "Rename template")
        val f = a.field("Name", t.name)
        sh.add(f).actions("Save") { if (f.value.isNotBlank()) repo.updateTemplate(t.copy(name = f.value)); sh.dismiss(); a.refresh() }.show()
    }

    private fun move(sorted: List<Block>, i: Int, j: Int) {
        val first = sorted[i]; val second = sorted[j]
        val apply = {
            repo.saveBlocks(templateId, Timeline.swapAdjacent(sorted, first, second)); Hooks.scheduleChanged(a); a.refresh()
        }
        if (first.isProtected || second.isProtected || first.category == Cat.SLEEP || second.category == Cat.SLEEP)
            a.confirm("Is this worth giving up?", "\"${listOf(first, second).first { it.isProtected || it.category == Cat.SLEEP }.title}\" is protected. Moving it changes when your best or restful hours happen.", "Move it") { apply() }
        else apply()
    }

    private fun editBlock(b: Block?) {
        val blocks = repo.blocks(templateId)
        val gaps = Timeline.gaps(blocks, repo.dayStart())
        var start = b?.start ?: gaps.firstOrNull()?.first ?: 9 * 60
        var end = b?.end ?: gaps.firstOrNull()?.second ?: (start + 60)
        var cat = b?.category ?: Cat.ESSENTIAL
        var vid = b?.ventureId
        var prot = b?.isProtected ?: false
        val sh = Sheet(a, if (b == null) "New block" else "Edit block")
        val name = a.field("Title", b?.title)
        sh.add(name)
        val times = a.hbox()
        lateinit var sBtn: android.widget.TextView
        lateinit var eBtn: android.widget.TextView
        sBtn = a.btn("Start ${TimeUtil.fmtTime(start)}", Btn.OUTLINED) { a.pickTime("Start", start) { start = it; sBtn.text = "Start ${TimeUtil.fmtTime(it)}" } }
        eBtn = a.btn("End ${TimeUtil.fmtTime(end)}", Btn.OUTLINED) { a.pickTime("End", end) { end = it; eBtn.text = "End ${TimeUtil.fmtTime(it)}" } }
        times.add(sBtn, 0, WRAP, 1f, end = 8); times.add(eBtn, 0, WRAP, 1f)
        sh.add(times)
        sh.add(a.label("Category"), bottom = 6)
        sh.add(a.choice(Cat.ALL, cat) { cat = it ?: cat })
        sh.add(a.label("Venture"), bottom = 6)
        sh.add(a.choice(repo.ventures().map { it.name }, repo.venture(vid)?.name, allowNone = true) { n -> vid = repo.ventures().firstOrNull { it.name == n }?.id })
        sh.add(a.switchRow("Protected", "Shows a lock. Moving or shrinking it asks first.", prot) { prot = it })
        if (b != null) sh.add(a.btn("Delete block", Btn.TEXT, color = Th.red) { sh.dismiss(); deleteBlock(b, blocks) })
        sh.actions("Save") {
            if (name.value.isBlank()) { a.toast("Give the block a title"); return@actions }
            if (start == end) { a.toast("Start and end can't be the same"); return@actions }
            val edited = Block(b?.id ?: 0, templateId, start, end, name.value, cat, vid, prot)
            val res = Timeline.place(blocks, edited)
            val ownProtectedChange = b != null && (b.isProtected || b.category == Cat.SLEEP) && (b.start != start || b.end != end)
            sh.dismiss()
            if (res.affected.isEmpty() && !ownProtectedChange) { save(res.blocks); return@actions }
            tradeOff(res, ownProtectedChange, edited)
        }
        sh.show()
    }

    /** The trade-off rule: the day is fixed, so show exactly what gives up time. */
    private fun tradeOff(res: Timeline.Result, ownProtected: Boolean, edited: Block) {
        val sh = Sheet(a, "What does this replace?", "The day is fixed at 24 hours. \"${edited.title}\" takes time from:")
        res.affected.forEach { af ->
            val r = a.hbox().apply { setPadding(0, a.dp(6), 0, a.dp(6)) }
            if (af.block.isProtected || af.block.category == Cat.SLEEP) r.add(a.iconView("lock", Th.yellow, 18), WRAP, WRAP, end = 8)
            r.add(a.txt(af.block.title, 15f), 0, WRAP, 1f)
            r.add(a.txt(if (af.removed) "removed" else "−${TimeUtil.fmtDuration(af.lostMinutes.toLong())}", 14f, if (af.removed) Th.red else Th.dim, Fonts.medium), WRAP, WRAP)
            sh.add(r, bottom = 0)
        }
        if (res.affected.isEmpty() && ownProtected) sh.add(a.body("\"${edited.title}\" is protected."))
        val protectedHit = res.touchesProtected || ownProtected
        if (protectedHit) sh.add(a.card(12, Th.alpha(Th.yellow, 0.12f)).apply {
            add(a.h3("Is this worth giving up?"))
            add(a.dimText("Protected time (sleep, your best Essential Block, rest) is what makes the rest sustainable."), top = 2)
        }, top = 10)
        sh.actions(if (protectedHit) "Yes, worth it" else "Replace") { sh.dismiss(); save(res.blocks) }
        sh.show()
    }

    private fun save(list: List<Block>) {
        repo.saveBlocks(templateId, list)
        Hooks.scheduleChanged(a)
        a.refresh()
    }

    private fun deleteBlock(b: Block, blocks: List<Block>) {
        val ds = repo.dayStart()
        val sorted = Timeline.sorted(blocks, ds)
        val i = sorted.indexOfFirst { it.id == b.id }
        val prev = sorted.getOrNull((i - 1 + sorted.size) % sorted.size)?.takeIf { it.id != b.id }
        val next = sorted.getOrNull((i + 1) % sorted.size)?.takeIf { it.id != b.id }
        val doDelete = {
            val sh = Sheet(a, "Who gets ${TimeUtil.fmtDuration(b.duration.toLong())}?", "Removing \"${b.title}\" frees ${TimeUtil.fmtTime(b.start)}–${TimeUtil.fmtTime(b.end)}.")
            val rest = blocks.filter { it.id != b.id }
            if (prev != null) sh.add(a.btn("Extend \"${prev.title}\"", Btn.TONAL) { sh.dismiss(); save(rest.map { if (it.id == prev.id) it.copy(end = b.end) else it }) })
            if (next != null) sh.add(a.btn("Extend \"${next.title}\"", Btn.TONAL) { sh.dismiss(); save(rest.map { if (it.id == next.id) it.copy(start = b.start) else it }) })
            sh.add(a.btn("Make it a buffer block", Btn.TONAL) { sh.dismiss(); save(rest + b.copy(id = 0, title = "Buffer", category = Cat.BUFFER, isProtected = false, ventureId = null)) })
            sh.add(a.btn("Leave a gap", Btn.TEXT, color = Th.dim) { sh.dismiss(); save(rest) })
            sh.show()
        }
        if (b.isProtected || b.category == Cat.SLEEP) a.confirm("Is this worth giving up?", "\"${b.title}\" is protected.", "Remove it") { doDelete() } else doDelete()
    }
}

// ============================================================ Ventures
class VenturesScreen(a: MainActivity) : Screen(a) {
    override val title = "Ventures"
    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "Add venture") { edit(null) })
    private val palette = listOf(0xFF7FB8A4, 0xFFB39DDB, 0xFFE6C07B, 0xFF8AB4F8, 0xFFF2A285, 0xFFA8B0B8, 0xFFE88A8A, 0xFF9FD3E6, 0xFFC5D88A).map { it.toInt() }

    override fun content(): View = page {
        add(a.dimText("Tag every block and log with a venture to see time vs ₹ earned."), bottom = 12)
        val c = a.card(6)
        repo.ventures(true).forEach { v ->
            c.add(a.listRow(v.name, if (v.archived) "Archived" else null, "dot", v.color) { edit(v) })
        }
        add(c)
    }

    private fun edit(v: com.essential.app.data.Venture?) {
        var color = v?.color ?: palette.first()
        var archived = v?.archived ?: false
        val sh = Sheet(a, if (v == null) "New venture" else "Edit venture")
        val f = a.field("Name", v?.name)
        sh.add(f)
        val row = Flow(a)
        fun render() {
            row.removeAllViews()
            palette.forEach { col ->
                val d = View(a).apply {
                    background = rounded(col, a.dp(18).toFloat(), if (col == color) a.dp(3) else 0, Th.text)
                    minimumWidth = a.dp(36); minimumHeight = a.dp(36)
                    click(true) { color = col; render() }
                }
                row.addView(d)
            }
        }
        render()
        sh.add(row)
        if (v != null) sh.add(a.switchRow("Archived", "Hidden from pickers; history stays.", archived) { archived = it })
        sh.actions("Save") {
            if (f.value.isBlank()) return@actions
            if (v == null) repo.addVenture(f.value, color) else repo.updateVenture(v.id, f.value, color, archived)
            sh.dismiss(); a.refresh()
        }
        sh.show()
    }
}
