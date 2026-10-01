package com.essential.app.core

import com.essential.app.data.Mode
import com.essential.app.data.Repo
import java.time.LocalDate
import kotlin.math.roundToInt

/**
 * Weekly report built on the phone from fixed rules and sentence templates (no AI, no network).
 * A future optional "AI coach" can implement [Coach] and replace [RuleCoach].
 */
interface Coach { fun weekly(repo: Repo, weekStart: LocalDate): WeeklyReport.Report }

object RuleCoach : Coach {
    override fun weekly(repo: Repo, weekStart: LocalDate) = WeeklyReport.build(repo, weekStart)
}

object WeeklyReport {
    data class Section(val title: String, val lines: List<String>)
    data class Report(val weekStart: LocalDate, val weekEnd: LocalDate, val headline: String, val sections: List<Section>, val suggestions: List<String>) {
        fun asText(): String = buildString {
            append("Essential · Week of ${TimeUtil.fmtShort(weekStart)}–${TimeUtil.fmtShort(weekEnd)}\n")
            append(headline).append("\n\n")
            sections.forEach { s -> append(s.title).append('\n'); s.lines.forEach { append("• ").append(it).append('\n') }; append('\n') }
            append("Next week\n"); suggestions.forEachIndexed { i, s -> append("${i + 1}. ").append(s).append('\n') }
        }
        fun wordCount(): Int = asText().split(Regex("\\s+")).count { it.isNotBlank() }
    }

    private fun pct(now: Double, prev: Double): String {
        if (prev <= 0.0) return if (now > 0) "new" else "–"
        val p = ((now - prev) / prev * 100).roundToInt()
        return (if (p >= 0) "+" else "") + "$p%"
    }

    fun build(repo: Repo, weekStart: LocalDate): Report {
        val today = Days.today(repo)
        val weekEnd = minOf(weekStart.plusDays(6), today)
        val cur = Insights(repo, weekStart, weekEnd)
        val prev = Insights(repo, weekStart.minusDays(7), weekStart.minusDays(1))
        val eh = cur.days.sumOf { it.essential }; val ehPrev = prev.days.sumOf { it.essential }
        val work = cur.days.sumOf { it.work }; val workPrev = prev.days.sumOf { it.work }
        val logged = cur.days.sumOf { it.logged }
        val sections = ArrayList<Section>()

        sections.add(Section("Hours", listOf(
            "Essential: ${TimeUtil.fmtHours(eh)}h (${pct(eh, ehPrev)} vs last week)",
            "Working: ${TimeUtil.fmtHours(work)}h (${pct(work, workPrev)})"
        )))

        val time = ArrayList<String>()
        val leak = cur.trivialLeaks().firstOrNull()
        if (leak != null) time.add("Biggest trivial leak: ${leak.first} (${TimeUtil.fmtHours(leak.second)}h)")
        val golden = cur.goldenHours().filter { it.value.first != null }
        val counts = cur.logs.groupingBy { it.hour }.eachCount()
        val rated = golden.filter { (counts[it.key] ?: 0) >= 2 }.ifEmpty { golden }
        val best = rated.maxByOrNull { it.value.first!! }
        val worst = rated.minByOrNull { it.value.first!! }
        if (best != null && worst != null && best.key != worst.key)
            time.add("Best hour ${TimeUtil.fmtTime(best.key * 60)} (focus ${"%.1f".format(best.value.first)}), weakest ${TimeUtil.fmtTime(worst.key * 60)} (${"%.1f".format(worst.value.first)})")
        val reason = cur.offPlanReasons().firstOrNull()
        if (reason != null) time.add("Top off-plan reason: ${reason.first} (${reason.second}×)")
        if (time.isNotEmpty()) sections.add(Section("Time", time))

        val ts = cur.tradeStats()
        if (ts.count > 0) {
            val l = arrayListOf("${ts.count} trades · win rate ${(ts.winRate * 100).roundToInt()}% · P&L ${TimeUtil.rupees(ts.pnl, true)}",
                "Rules followed: ${(ts.rulesFollowedPct * 100).roundToInt()}%")
            if (ts.revengeFomoLoss < 0) l.add("Losses on Revenge/FOMO trades: ${TimeUtil.rupees(ts.revengeFomoLoss)}")
            sections.add(Section("Trading", l))
        }

        val intent = repo.intent()
        if (intent != null) {
            val p = Insights.goalPace(intent, today)
            sections.add(Section("Essential Intent", listOf(
                "${intent.progress}% done, ${p.daysLeft} days left — " + if (p.onTrack) "on track" else "behind (expected ${p.expectedPct}%)")))
        }

        val sprint = repo.activeSprint(today)
        if (sprint != null) {
            val mx = cur.modeStats(Mode.MAX); val nm = Insights(repo, weekStart.minusDays(28), weekEnd).modeStats(Mode.NORMAL)
            val l = arrayListOf("Max days: ${mx.days}, ${TimeUtil.fmtHours(mx.essential)} Essential h/day vs Normal ${TimeUtil.fmtHours(nm.essential)}")
            val b = Insights.burnout(repo, today)
            l.add(if (b == null) "Burnout check: clear" else "Burnout check: watch — " + b.reasons.first())
            sections.add(Section("Sprint: ${sprint.goal}", l))
        }

        // Rule-based suggestions
        val sug = ArrayList<String>()
        if (logged > 0 && cur.days.sumOf { it.trivial } / logged > 0.15)
            sug.add("Cut ${leak?.first ?: "your top trivial activity"} — trivial time was ${((cur.days.sumOf { it.trivial } / logged) * 100).roundToInt()}% of logged hours.")
        val late = cur.logs.filter { it.hour >= 21 || it.hour < 4 }.mapNotNull { it.focus }
        val all = cur.logs.mapNotNull { it.focus }
        if (late.size >= 2 && late.average() < 3.0 && all.isNotEmpty() && late.average() < all.average())
            sug.add("Move evening work earlier — focus after 9 PM averages ${"%.1f".format(late.average())}.")
        if (ts.brokenCount >= 2) sug.add("Review your trading checklist — rules were broken in ${ts.brokenCount} trades.")
        val sleeps = repo.sleepLogs(weekStart, weekEnd)
        val short = sleeps.count { s -> s.hours < (if (Days.resolve(repo, s.date).mode == Mode.MAX) 5.5 else 7.0) - 0.25 }
        if (short >= 3) sug.add("Protect sleep this week — $short nights were below target.")
        val follow = cur.avg { it.follow }
        if (sug.size < 3 && follow != null && follow < 0.6) sug.add("Guard Essential Block 1: phone in another room until it ends.")
        if (sug.size < 3 && Insights.thinkTimeSkippedWeeks(repo, today) >= 1) sug.add("Book two hours of Think Time on Sunday.")
        val peak = cur.distractionsByHour().maxByOrNull { it.value }
        if (sug.size < 3 && peak != null && peak.value >= 3) sug.add("Plan a short break before ${TimeUtil.fmtTime(peak.key * 60)} — your peak distraction hour.")
        if (sug.size < 3) {
            val bestDay = cur.activeDays.maxByOrNull { it.essential }
            if (bestDay != null) sug.add("Repeat ${TimeUtil.fmtDow(bestDay.date)}: ${TimeUtil.fmtHours(bestDay.essential)} Essential Hours. What made it work?")
        }
        if (sug.size < 3) sug.add("Keep the ONE thing small and specific each morning.")

        val headline = when {
            ehPrev > 0 && eh >= ehPrev * 1.1 -> "A stronger week: more of your best hours went to what matters."
            ehPrev > 0 && eh < ehPrev * 0.9 -> "A lighter week. Less, but better — pick one thing to protect next week."
            else -> "A steady week. Keep spending the best hours on the few things that matter."
        }
        return Report(weekStart, weekEnd, headline, sections, sug.take(3))
    }
}
