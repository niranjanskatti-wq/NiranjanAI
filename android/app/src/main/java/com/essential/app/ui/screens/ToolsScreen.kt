package com.essential.app.ui.screens

import android.view.View
import com.essential.app.core.Days
import com.essential.app.core.TimeUtil
import com.essential.app.ui.*

/** Tools grouped by the three stages: Explore, Eliminate, Execute. */
class ToolsScreen(a: MainActivity) : Screen(a) {
    override fun content(): View = page {
        add(a.h1("Tools"), top = 8, bottom = 4)
        add(a.dimText("Explore what matters. Eliminate the rest. Execute with ease."), bottom = 16)
        val notNow = repo.opportunities().count { it.decision == "Not Now" }
        val noMonth = repo.hoursSaved(today.withDayOfMonth(1), today)
        val sprint = repo.activeSprint(today)

        section("Explore", listOf(
            Triple("Essential Intent & goals", "Your one 90-day intent, supporting goals, milestones", "now") to { a.push(GoalsScreen(a)) },
            Triple("Opportunity filter", "Score a new idea. Below 90 is a no. $notNow parked in Not Now", "idea") to { a.push(OpportunityScreen(a)) },
            Triple("Play & Think Time", "Hours for life, play and quiet thinking", "moon") to { a.push(PlayThinkScreen(a)) },
            Triple("Monthly uncommit review", "Keep, reduce, stop, or test-stop each commitment", "repeat") to { a.push(UncommitScreen(a)) }
        ))
        section("Eliminate", listOf(
            Triple("\"No\" log & scripts", "${TimeUtil.fmtHours(noMonth)}h protected this month · polite decline templates", "close") to { a.push(NoLogScreen(a)) },
            Triple("Weekly obstacle", "One obstacle, one action, checked next Sunday", "warn") to { a.push(ObstacleScreen(a)) },
            Triple("Distractions", "Daily count and peak distraction hours", "bell") to { a.push(DistractionScreen(a)) }
        ))
        section("Execute", listOf(
            Triple("Focus mode", "25 / 50 / 90 minute calm countdown", "timer") to { FocusSheet.open(a) },
            Triple("Schedule templates", "Weekday, Sprint Day, Sunday, Travel Day", "log") to { a.push(TemplatesScreen(a)) },
            Triple("Sprint & Max Mode", sprint?.let { "Active: ${it.goal} · ends ${TimeUtil.fmtShort(it.end)}" } ?: "Up to 6 weeks, then a recovery week", "bolt") to { a.push(SprintScreen(a)) },
            Triple("Routines & habits", "Triggers, streaks, no guilt", "check") to { a.push(HabitsScreen(a)) },
            Triple("Sleep", "Bedtime, wake, quality vs next-day focus", "moon") to { a.push(SleepScreen(a)) },
            Triple("Trading journal (MCX)", "Checklist, revenge-trade guard, stats", "insights") to { a.push(TradingScreen(a)) },
            Triple("Time estimates & buffer", "Your planning error and suggested buffer", "timer") to { a.push(BufferScreen(a)) },
            Triple("Daily review", "Under 2 minutes", "edit") to { ReviewSheet.open(a, Days.today(repo)) },
            Triple("Ventures", "Add, rename, recolor, archive", "tools") to { a.push(VenturesScreen(a)) }
        ))
    }

    private fun android.widget.LinearLayout.section(name: String, items: List<Pair<Triple<String, String, String>, () -> Unit>>) {
        add(a.label(name), top = 8, bottom = 8)
        val c = a.card(6)
        items.forEach { (t, f) -> c.add(a.listRow(t.first, t.second, t.third, Th.primary) { f() }) }
        add(c, bottom = 12)
    }
}
