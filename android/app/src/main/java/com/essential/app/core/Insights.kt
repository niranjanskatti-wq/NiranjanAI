package com.essential.app.core

import com.essential.app.data.Cat
import com.essential.app.data.Emotions
import com.essential.app.data.Goal
import com.essential.app.data.HourLog
import com.essential.app.data.Mode
import com.essential.app.data.Plan
import com.essential.app.data.Repo
import com.essential.app.data.Sprint
import com.essential.app.data.Trade
import com.essential.app.data.Type
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import kotlin.math.abs
import kotlin.math.roundToInt

data class DayStat(
    val date: LocalDate, val mode: String, val essential: Double, val work: Double, val necessary: Double, val trivial: Double,
    val logged: Double, val follow: Double?, val focus: Double?, val energy: Double?, val money: Double, val pnl: Double,
    val score: Int, val targetEssential: Double
)

/** Everything the dashboard and reports need for a date range, loaded once. */
class Insights(val repo: Repo, val from: LocalDate, val to: LocalDate) {
    val logs: List<HourLog> = repo.logsRange(from, to)
    val trades: List<Trade> = repo.trades(from, to)
    val days: List<DayStat>
    private val byDate = logs.groupBy { it.date }

    init {
        val tradesByDate = trades.groupBy { it.date }
        val list = ArrayList<DayStat>()
        var d = from
        while (!d.isAfter(to)) {
            val info = Days.resolve(repo, d)
            val l = byDate[d].orEmpty()
            val score = Metrics.dayScore(repo, d, info).total
            list.add(DayStat(d, info.mode, Metrics.essentialHours(l), Metrics.workHours(l), Metrics.necessaryHours(l), Metrics.trivialHours(l),
                Metrics.loggedHours(l), Metrics.followRate(l), Metrics.avgFocus(l), Metrics.avgEnergy(l), Metrics.money(l),
                tradesByDate[d].orEmpty().sumOf { it.pnl }, score, repo.settings.targetEssential(info.mode)))
            d = d.plusDays(1)
        }
        days = list
    }

    val activeDays get() = days.filter { it.logged > 0 }

    fun avg(sel: (DayStat) -> Double?): Double? = activeDays.mapNotNull(sel).takeIf { it.isNotEmpty() }?.average()

    /** Average focus and energy per clock hour. */
    fun goldenHours(): Map<Int, Pair<Double?, Double?>> = logs.groupBy { it.hour }.mapValues { (_, l) ->
        Metrics.avgFocus(l) to Metrics.avgEnergy(l)
    }

    data class VentureStat(val ventureId: Long?, val name: String, val color: Int, val hours: Double, val money: Double) {
        val perHour get() = if (hours > 0) money / hours else 0.0
    }

    fun byVenture(): List<VentureStat> {
        val vs = repo.ventures(true).associateBy { it.id }
        return logs.filter { Metrics.isWork(it) }.groupBy { it.ventureId }.map { (id, l) ->
            val v = id?.let { vs[it] }
            VentureStat(id, v?.name ?: "Untagged", v?.color ?: 0xFF6B7178.toInt(), l.sumOf { it.minutes } / 60.0, Metrics.money(l))
        }.sortedByDescending { it.hours }
    }

    /** Ventures taking ≥20% of work time while earning under half the average ₹/hour. */
    fun lowReturnVentures(): List<VentureStat> {
        val all = byVenture().filter { it.ventureId != null }
        val totalH = all.sumOf { it.hours }; val totalM = all.sumOf { it.money }
        if (totalH <= 0 || totalM <= 0) return emptyList()
        val avgRate = totalM / totalH
        return all.filter { it.hours / totalH >= 0.2 && it.perHour < avgRate * 0.5 }
    }

    fun offPlanReasons(): List<Pair<String, Int>> = logs.filter { it.followedPlan == Plan.NO || it.followedPlan == Plan.PARTLY }
        .mapNotNull { it.offPlanReason?.takeIf { r -> r.isNotBlank() } }.groupingBy { it }.eachCount().toList().sortedByDescending { it.second }

    fun distractionReasons(): List<Pair<String, Int>> = repo.distractions(from, to).groupingBy { it.reason?.takeIf { r -> r.isNotBlank() } ?: "No reason" }
        .eachCount().toList().sortedByDescending { it.second }

    fun distractionsByHour(): Map<Int, Int> = repo.distractions(from, to).groupingBy { TimeUtil.at(it.ts).hour }.eachCount()

    fun trivialLeaks(): List<Pair<String, Double>> = logs.filter { it.type == Type.TRIVIAL }
        .groupBy { it.activity.trim().lowercase() }.map { (k, l) -> (l.first().activity.ifBlank { k }) to l.sumOf { it.minutes } / 60.0 }
        .sortedByDescending { it.second }

    fun hoursProtected(): Double = repo.hoursSaved(from, to)

    fun categoryHours(cat: String): Double = logs.filter { it.category == cat }.sumOf { it.minutes } / 60.0

    data class ModeStat(val days: Int, val essential: Double, val focus: Double?, val energy: Double?, val perHour: Double, val pnl: Double, val work: Double)

    fun modeStats(mode: String, from: LocalDate = this.from, to: LocalDate = this.to): ModeStat {
        val ds = activeDays.filter { it.mode == mode && !it.date.isBefore(from) && !it.date.isAfter(to) }
        val l = logs.filter { lg -> ds.any { it.date == lg.date } }
        val work = ds.sumOf { it.work }
        return ModeStat(ds.size, ds.map { it.essential }.average0(), Metrics.avgFocus(l), Metrics.avgEnergy(l),
            if (work > 0) ds.sumOf { it.money } / work else 0.0, ds.sumOf { it.pnl } / ds.size.coerceAtLeast(1), ds.map { it.work }.average0())
    }

    data class TradeStats(val count: Int, val winRate: Double, val pnl: Double, val rulesFollowedPct: Double,
                          val byInstrument: List<Pair<String, Double>>, val byEmotion: List<Pair<String, Double>>,
                          val byHour: List<Pair<Int, Double>>, val followedPnl: Double, val brokenPnl: Double,
                          val brokenCount: Int, val revengeFomoLoss: Double)

    fun tradeStats(t: List<Trade> = trades): TradeStats {
        val n = t.size
        val wins = t.count { it.pnl > 0 }
        return TradeStats(n, if (n > 0) wins.toDouble() / n else 0.0, t.sumOf { it.pnl },
            if (n > 0) t.count { it.rulesFollowed }.toDouble() / n else 0.0,
            t.groupBy { it.instrument }.map { it.key to it.value.sumOf { x -> x.pnl } }.sortedByDescending { it.second },
            Emotions.ALL.map { e -> e to t.filter { it.emotion == e }.sumOf { it.pnl } }.filter { e -> t.any { it.emotion == e.first } },
            t.groupBy { TimeUtil.at(it.ts).hour }.map { it.key to it.value.sumOf { x -> x.pnl } }.sortedBy { it.first },
            t.filter { it.rulesFollowed }.sumOf { it.pnl }, t.filter { !it.rulesFollowed }.sumOf { it.pnl },
            t.count { !it.rulesFollowed },
            t.filter { (it.emotion == "Revenge" || it.emotion == "FOMO") && it.pnl < 0 }.sumOf { it.pnl })
    }

    /** Ratio of actual to estimated minutes for finished tasks (1.0 = perfect). */
    fun bufferRatio(): Double? = Companion.bufferRatio(repo)

    companion object {
        fun bufferRatio(repo: Repo): Double? {
            val done = repo.tasks().filter { it.actual != null && it.est > 0 }
            if (done.size < 2) return null
            return done.sumOf { it.actual!! }.toDouble() / done.sumOf { it.est }
        }

        /** Weekly buffer ratio trend: (week start, ratio). */
        fun bufferTrend(repo: Repo): List<Pair<LocalDate, Double>> =
            repo.tasks().filter { it.actual != null && it.est > 0 }.groupBy { TimeUtil.weekStart(it.date) }
                .map { (w, l) -> w to l.sumOf { it.actual!! }.toDouble() / l.sumOf { it.est } }.sortedBy { it.first }

        data class Pace(val goal: Goal, val daysLeft: Long, val expectedPct: Int, val projected: LocalDate?, val onTrack: Boolean)

        fun goalPace(goal: Goal, today: LocalDate): Pace {
            val total = ChronoUnit.DAYS.between(goal.startDate, goal.endDate).coerceAtLeast(1)
            val elapsed = ChronoUnit.DAYS.between(goal.startDate, today).coerceIn(0, total)
            val expected = ((elapsed * 100.0) / total).roundToInt()
            val daysLeft = ChronoUnit.DAYS.between(today, goal.endDate).coerceAtLeast(0)
            val projected = if (goal.progress >= 100) today else if (goal.progress > 0 && elapsed > 0) {
                val rate = goal.progress.toDouble() / elapsed
                today.plusDays(((100 - goal.progress) / rate).roundToInt().toLong())
            } else null
            val onTrack = goal.progress >= expected - 5 || (projected != null && !projected.isAfter(goal.endDate))
            return Pace(goal, daysLeft, expected, projected, onTrack)
        }

        data class Burnout(val reasons: List<String>)

        /** Sleep under 5.5h for 3 nights in a row, or average focus under 3 for 3 days running. */
        fun burnout(repo: Repo, today: LocalDate): Burnout? {
            val reasons = ArrayList<String>()
            val sleeps = repo.sleepLogs(today.minusDays(2), today).associateBy { it.date }
            val nights = (0..2).map { sleeps[today.minusDays(it.toLong())] }
            if (nights.all { it != null && it.hours < 5.5 })
                reasons.add("Sleep: " + nights.reversed().joinToString(", ") { TimeUtil.fmtHours(it!!.hours) + "h" } + " the last 3 nights")
            val focusDays = (1..3).map { repo.logs(today.minusDays(it.toLong())) }.map { Metrics.avgFocus(it) }
            if (focusDays.all { it != null && it < 3.0 })
                reasons.add("Focus: " + focusDays.reversed().joinToString(", ") { "%.1f".format(it) } + " average the last 3 days")
            return if (reasons.isEmpty()) null else Burnout(reasons)
        }

        /** Weeks (ending this week) with no Think Time at all. */
        fun thinkTimeSkippedWeeks(repo: Repo, today: LocalDate): Int {
            var count = 0
            var wk = TimeUtil.weekStart(today).minusWeeks(1)
            for (i in 0 until 4) {
                val logs = repo.logsRange(wk, wk.plusDays(6))
                if (logs.isEmpty()) break
                if (logs.none { it.category == Cat.THINK }) count++ else break
                wk = wk.minusWeeks(1)
            }
            return count
        }

        data class SprintReport(val sprint: Sprint, val max: ModeStat, val normal: ModeStat, val lines: List<String>)

        fun sprintReport(repo: Repo, sprint: Sprint): SprintReport {
            val compareFrom = sprint.start.minusDays(28)
            val to = minOf(sprint.recoveryEnd ?: sprint.end, Days.today(repo))
            val ins = Insights(repo, compareFrom, to)
            val max = ins.modeStats(Mode.MAX, sprint.start, sprint.end)
            val normal = ins.modeStats(Mode.NORMAL)
            val lines = ArrayList<String>()
            fun cmp(label: String, a: Double?, b: Double?, fmt: (Double) -> String) {
                if (a == null || b == null) return
                val diff = if (b != 0.0) ((a - b) / abs(b) * 100).roundToInt() else 0
                lines.add("$label: Max ${fmt(a)} vs Normal ${fmt(b)}" + if (b != 0.0) " (${if (diff >= 0) "+" else ""}$diff%)" else "")
            }
            cmp("Essential Hours/day", max.essential, normal.essential) { TimeUtil.fmtHours(it) + "h" }
            cmp("Focus", max.focus, normal.focus) { "%.1f".format(it) }
            cmp("Energy", max.energy, normal.energy) { "%.1f".format(it) }
            cmp("₹ per working hour", max.perHour, normal.perHour) { TimeUtil.rupees(it) }
            cmp("Trading P&L/day", max.pnl, normal.pnl) { TimeUtil.rupees(it) }
            return SprintReport(sprint, max, normal, lines)
        }
    }
}

private fun List<Double>.average0() = if (isEmpty()) 0.0 else average()
