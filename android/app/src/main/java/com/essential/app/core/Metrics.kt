package com.essential.app.core

import com.essential.app.data.Cat
import com.essential.app.data.HourLog
import com.essential.app.data.Plan
import com.essential.app.data.Repo
import com.essential.app.data.Type
import java.time.LocalDate
import kotlin.math.roundToInt

/** Pure calculations over logs. */
object Metrics {
    fun essentialHours(logs: List<HourLog>): Double = logs.filter { it.type == Type.ESSENTIAL }.sumOf { it.minutes } / 60.0
    fun trivialHours(logs: List<HourLog>): Double = logs.filter { it.type == Type.TRIVIAL }.sumOf { it.minutes } / 60.0
    fun necessaryHours(logs: List<HourLog>): Double = logs.filter { it.type == Type.NECESSARY }.sumOf { it.minutes } / 60.0
    fun isWork(l: HourLog) = l.type == Type.ESSENTIAL || (l.category in Cat.WORK && l.type != Type.TRIVIAL)
    fun workHours(logs: List<HourLog>): Double = logs.filter { isWork(it) }.sumOf { it.minutes } / 60.0
    fun loggedHours(logs: List<HourLog>): Double = logs.sumOf { it.minutes } / 60.0

    /** Share of logged hours that followed the plan (Partly counts half). Null when nothing rated. */
    fun followRate(logs: List<HourLog>): Double? {
        val rated = logs.filter { it.followedPlan != null }
        if (rated.isEmpty()) return null
        return rated.sumOf { when (it.followedPlan) { Plan.YES -> 1.0; Plan.PARTLY -> 0.5; else -> 0.0 } } / rated.size
    }

    fun avgFocus(logs: List<HourLog>): Double? = logs.mapNotNull { it.focus }.takeIf { it.isNotEmpty() }?.average()
    fun avgEnergy(logs: List<HourLog>): Double? = logs.mapNotNull { it.energy }.takeIf { it.isNotEmpty() }?.average()
    fun money(logs: List<HourLog>): Double = logs.sumOf { it.money ?: 0.0 }

    data class Part(val name: String, val weight: Int, val fraction: Double, val detail: String) {
        val points get() = weight * fraction.coerceIn(0.0, 1.0)
    }
    data class Score(val total: Int, val parts: List<Part>)

    data class ScoreInput(
        val essentialHours: Double, val targetEssential: Double, val workHours: Double, val targetWork: Double,
        val oneThingSet: Boolean, val oneThingDone: Boolean, val followRate: Double?, val habitsDone: Int, val habitsTotal: Int,
        val sleptOnTime: Boolean?, val weights: IntArray
    )

    fun score(i: ScoreInput): Score {
        val w = i.weights
        val parts = listOf(
            Part("Essential Hours", w[0], if (i.targetEssential > 0) i.essentialHours / i.targetEssential else 0.0,
                "${TimeUtil.fmtHours(i.essentialHours)} of ${TimeUtil.fmtHours(i.targetEssential)}h"),
            Part("Working hours", w[1], if (i.targetWork > 0) i.workHours / i.targetWork else 0.0,
                "${TimeUtil.fmtHours(i.workHours)} of ${TimeUtil.fmtHours(i.targetWork)}h"),
            Part("ONE thing", w[2], if (i.oneThingDone) 1.0 else 0.0,
                if (!i.oneThingSet) "Not set yet" else if (i.oneThingDone) "Done" else "Not yet"),
            Part("Plan followed", w[3], i.followRate ?: 0.0,
                i.followRate?.let { "${(it * 100).roundToInt()}% of logged hours" } ?: "No hours logged"),
            Part("Routines", w[4], if (i.habitsTotal > 0) i.habitsDone.toDouble() / i.habitsTotal else 0.0, "${i.habitsDone} of ${i.habitsTotal}"),
            Part("Sleep on time", w[5], if (i.sleptOnTime == true) 1.0 else 0.0,
                when (i.sleptOnTime) { null -> "Sleep not logged"; true -> "On time"; false -> "Late" })
        )
        val sumW = parts.sumOf { it.weight }.coerceAtLeast(1)
        val total = (parts.sumOf { it.points } * 100.0 / sumW).roundToInt().coerceIn(0, 100)
        return Score(total, parts)
    }

    /** Daily score from the database. */
    fun dayScore(repo: Repo, date: LocalDate, day: DayInfo = Days.resolve(repo, date)): Score {
        val s = repo.settings
        val logs = repo.logs(date)
        val plan = day.plan
        val habits = repo.habits()
        val done = repo.habitDone(date)
        val sleep = repo.sleepLog(date)
        val prevMode = Days.resolve(repo, date.minusDays(1)).mode
        val sleptOnTime = sleep?.let { TimeUtil.offset(it.bedtime, 720) <= TimeUtil.offset(s.sleep(prevMode) + 15, 720) }
        val weights = intArrayOf(s.int("w_eh"), s.int("w_work"), s.int("w_one"), s.int("w_plan"), s.int("w_routine"), s.int("w_sleep"))
        return score(ScoreInput(essentialHours(logs), s.targetEssential(day.mode), workHours(logs), s.targetWork(day.mode),
            !plan?.oneThing.isNullOrBlank(), plan?.oneDone == true, followRate(logs), habits.count { it.id in done }, habits.size,
            sleptOnTime, weights))
    }
}
