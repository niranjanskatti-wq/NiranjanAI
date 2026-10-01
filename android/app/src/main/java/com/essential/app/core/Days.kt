package com.essential.app.core

import com.essential.app.data.Block
import com.essential.app.data.DayPlan
import com.essential.app.data.Mode
import com.essential.app.data.Repo
import com.essential.app.data.Sprint
import com.essential.app.data.Template
import java.time.LocalDate
import java.time.ZonedDateTime

/** A resolved day: which template and mode apply, and its blocks. */
data class DayInfo(
    val date: LocalDate,
    val template: Template?,
    val mode: String,
    val blocks: List<Block>,
    val plan: DayPlan?,
    val sprint: Sprint?,
    val recovery: Sprint?,
    val wake: Int,
    val sleep: Int,
    val dayStart: Int
) {
    val isMax get() = mode == Mode.MAX
    val hours: List<Int> get() = TimeUtil.trackedHours(wake, sleep, dayStart)
    fun slotStart(hour: Int): ZonedDateTime = TimeUtil.slotStart(date, hour, dayStart)
    fun slotEnd(hour: Int): ZonedDateTime = slotStart(hour).plusHours(1)
    fun at(min: Int): ZonedDateTime = TimeUtil.timeOn(date, min, dayStart)
    fun plannedFor(hour: Int): Block? = Timeline.blockForHour(blocks, hour)
}

object Days {
    fun today(repo: Repo): LocalDate = TimeUtil.logicalDate(TimeUtil.now(), repo.dayStart())

    fun resolve(repo: Repo, date: LocalDate): DayInfo {
        val plan = repo.dayPlan(date)
        val sprint = repo.activeSprint(date)
        val recovery = if (sprint == null) repo.recoverySprint(date) else null
        val templates = repo.templates()
        val dow = date.dayOfWeek.value
        fun forMode(mode: String): Template? =
            templates.firstOrNull { it.mode == mode && dow in it.weekdays } ?: templates.firstOrNull { it.mode == mode }

        var template = plan?.templateId?.let { id -> templates.firstOrNull { it.id == id } }
        if (template == null) {
            // Sundays keep their own template even during a sprint.
            val sundayLike = templates.firstOrNull { it.mode == Mode.NORMAL && dow in it.weekdays && it.name.contains("Sunday", true) }
            template = if (sprint != null && sundayLike == null) forMode(Mode.MAX) ?: forMode(Mode.NORMAL) else forMode(Mode.NORMAL)
        }
        var mode = plan?.mode ?: template?.mode ?: Mode.NORMAL
        // Max Mode only runs inside a sprint.
        if (mode == Mode.MAX && sprint == null) {
            mode = Mode.NORMAL
            if (template?.mode == Mode.MAX) template = forMode(Mode.NORMAL)
        }
        val s = repo.settings
        return DayInfo(date, template, mode, repo.blocks(template?.id), plan, sprint, recovery, s.wake(mode), s.sleep(mode), repo.dayStart())
    }

    /** Switch a day's mode. Returns an explanation when it isn't allowed. */
    fun setMode(repo: Repo, date: LocalDate, mode: String): String? {
        if (mode == Mode.MAX) {
            if (repo.activeSprint(date) == null) {
                val rec = repo.recoverySprint(date)
                return if (rec != null) "Recovery week until ${TimeUtil.fmtShort(rec.recoveryEnd!!)}. Normal Mode helps you come back stronger."
                else "Max Mode runs inside a sprint. Start a sprint with a goal and an end date first."
            }
        }
        val dow = date.dayOfWeek.value
        val templates = repo.templates()
        val t = templates.firstOrNull { it.mode == mode && dow in it.weekdays } ?: templates.firstOrNull { it.mode == mode }
        repo.setDayTemplate(date, t?.id, mode)
        return null
    }

    fun setTemplate(repo: Repo, date: LocalDate, t: Template): String? {
        if (t.mode == Mode.MAX && repo.activeSprint(date) == null)
            return "\"${t.name}\" is a Max Mode template. Max Mode runs inside a sprint."
        repo.setDayTemplate(date, t.id, t.mode)
        return null
    }

    data class Now(val day: DayInfo, val current: Block?, val next: Block?, val currentEnd: ZonedDateTime?, val nextStart: ZonedDateTime?)

    fun now(repo: Repo): Now {
        val t = TimeUtil.now()
        val day = resolve(repo, TimeUtil.logicalDate(t, repo.dayStart()))
        val m = TimeUtil.minuteOfDay(t)
        val cur = Timeline.blockAt(day.blocks, m)
        val next = Timeline.nextBlock(day.blocks, cur, day.dayStart)
        var end: ZonedDateTime? = null
        if (cur != null) {
            val into = ((m - cur.start) % 1440 + 1440) % 1440
            end = t.withSecond(0).withNano(0).plusMinutes((cur.duration - into).toLong())
        }
        return Now(day, cur, next, end, end)
    }
}
