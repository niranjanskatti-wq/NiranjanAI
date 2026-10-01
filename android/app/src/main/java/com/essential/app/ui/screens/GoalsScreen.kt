package com.essential.app.ui.screens

import android.view.View
import com.essential.app.core.Hooks
import com.essential.app.core.Insights
import com.essential.app.core.TimeUtil
import com.essential.app.data.Goal
import com.essential.app.ui.*

/** Essential Intent (1) + supporting goals (max 3 total) with milestones. */
class GoalsScreen(a: MainActivity) : Screen(a) {
    override val title = "Goals"

    override fun actions() = listOf(a.iconBtn("plus", Th.text, desc = "Add goal") { addGoal() })

    override fun content(): View = page {
        val goals = repo.activeGoals()
        add(a.dimText("One Essential Intent, at most two supporting goals. Fewer goals, more progress."), bottom = 14)
        goals.forEach { g -> add(goalCard(g), bottom = 12) }
        if (goals.isEmpty()) add(a.btn("Set your Essential Intent") { addGoal() })
        val done = repo.allGoals().filter { it.status != "active" }
        if (done.isNotEmpty()) {
            add(a.label("Completed & dropped"), top = 12, bottom = 6)
            val c = a.card(6)
            done.forEach { g -> c.add(a.listRow(g.title, "${g.status.replaceFirstChar { it.uppercase() }} · ${g.progress}%", null)) }
            add(c)
        }
    }

    private fun goalCard(g: Goal): View {
        val c = a.card(18)
        val top = a.hbox()
        top.add(a.badge(if (g.isIntent) "Essential Intent" else "Supporting", if (g.isIntent) Th.primary else Th.necessary), WRAP, WRAP)
        top.grow()
        top.add(a.iconBtn("edit", Th.dim, 40, "Edit goal") { editGoal(g) }, WRAP, WRAP)
        c.add(top)
        c.add(a.txt(g.title, 18f, Th.text, Fonts.semibold), top = 8)
        c.addProgress(g.progress / 100.0, if (g.isIntent) Th.primary else Th.necessary, 8, top = 12)
        val pace = Insights.goalPace(g, today)
        c.add(a.dimText("${g.progress}% · ${pace.daysLeft} days left · expected ${pace.expectedPct}% by now"), top = 8)
        pace.projected?.let { c.add(a.dimText("At this pace: done by ${TimeUtil.fmtDayLong(it)}" + if (it.isAfter(g.endDate)) " (after target)" else " ✓"), top = 2) }
        val ms = repo.milestones(g.id)
        if (ms.isEmpty()) {
            c.add(a.dimText("Progress"), top = 12)
            c.add(a.slider(g.progress) { repo.setGoalProgress(g.id, it) }.apply {
                setOnSeekBarChangeListener(object : android.widget.SeekBar.OnSeekBarChangeListener {
                    override fun onProgressChanged(s: android.widget.SeekBar?, p: Int, u: Boolean) { if (u) repo.setGoalProgress(g.id, p) }
                    override fun onStartTrackingTouch(s: android.widget.SeekBar?) {}
                    override fun onStopTrackingTouch(s: android.widget.SeekBar?) { Hooks.afterChange(a); a.refresh() }
                })
            })
        }
        c.add(a.label("Milestones"), top = 14, bottom = 4)
        ms.forEach { m ->
            val r = a.hbox().apply { setPadding(0, a.dp(8), 0, a.dp(8)) }
            r.add(HomeScreen.checkBox(a, m.done) { repo.setMilestone(m.id, it, today); Hooks.afterChange(a); a.refresh() }, a.dp(24), a.dp(24), end = 12)
            r.add(a.txt(m.title, 15f, if (m.done) Th.dim else Th.text), 0, WRAP, 1f)
            r.add(a.iconBtn("close", Th.faint, 36, "Delete milestone") { repo.deleteMilestone(m.id); a.refresh() }, WRAP, WRAP)
            c.add(r)
        }
        c.add(a.btn("Add milestone", Btn.TEXT, "plus") {
            val sh = Sheet(a, "New milestone")
            val f = a.field("e.g. Term sheet signed with Rao Builders")
            sh.add(f).actions("Add") { if (f.value.isNotBlank()) { repo.addMilestone(g.id, f.value); Hooks.afterChange(a) }; sh.dismiss(); a.refresh() }.show()
        }, top = 4)
        return c
    }

    private fun addGoal() {
        val active = repo.activeGoals()
        val hasIntent = active.any { it.isIntent }
        if (active.size >= 3) {
            val sh = Sheet(a, "Three goals is the limit", "To add a goal, choose one to drop. Nothing is lost — it moves to Completed & dropped.")
            active.forEach { g -> sh.add(a.listRow(g.title, if (g.isIntent) "Essential Intent" else "Supporting", "close", Th.red) {
                repo.setGoalStatus(g.id, "dropped"); sh.dismiss(); a.refresh(); addGoal()
            }, bottom = 0) }
            sh.show(); return
        }
        editGoal(null, if (hasIntent) "supporting" else "intent")
    }

    private fun editGoal(g: Goal?, type: String = g?.type ?: "supporting") {
        var end = g?.endDate ?: today.plusDays(90)
        var t = type
        val sh = Sheet(a, if (g == null) "New goal" else "Edit goal")
        val f = a.field("Concrete and measurable", g?.title, multiline = true)
        sh.add(f)
        sh.add(a.choice(listOf("Essential Intent", "Supporting"), if (t == "intent") "Essential Intent" else "Supporting") { t = if (it == "Essential Intent") "intent" else "supporting" })
        lateinit var dateRow: android.widget.LinearLayout
        dateRow = a.listRow("Target date", TimeUtil.fmtDayLong(end), "log") { a.pickDate(end) { end = it; ((dateRow.getChildAt(1) as android.widget.LinearLayout).getChildAt(1) as android.widget.TextView).text = TimeUtil.fmtDayLong(it) } }
        sh.add(dateRow)
        if (g != null) {
            val r = a.hbox()
            r.add(a.btn("Mark complete", Btn.TONAL) { repo.setGoalProgress(g.id, 100); repo.setGoalStatus(g.id, "done"); sh.dismiss(); Hooks.afterChange(a); a.refresh() }, 0, WRAP, 1f, end = 8)
            r.add(a.btn("Drop", Btn.TONAL, color = Th.red) { repo.setGoalStatus(g.id, "dropped"); sh.dismiss(); Hooks.afterChange(a); a.refresh() }, 0, WRAP, 1f)
            sh.add(r)
        }
        sh.actions("Save") {
            if (f.value.isBlank()) return@actions
            if (t == "intent") repo.activeGoals().filter { it.isIntent && it.id != g?.id }.forEach { o -> repo.updateGoal(o.copy(type = "supporting")) }
            if (g == null) repo.addGoal(f.value, t, today, end) else repo.updateGoal(g.copy(title = f.value, type = t, endDate = end))
            sh.dismiss(); Hooks.afterChange(a); a.refresh()
        }
        sh.show()
    }
}
