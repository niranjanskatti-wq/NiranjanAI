package com.essential.app.core

import android.content.Context
import com.essential.app.data.Cat
import com.essential.app.data.HourLog
import com.essential.app.data.Plan
import com.essential.app.data.Repo
import com.essential.app.data.Type
import java.time.LocalDate

/** Shared one-tap logging used by notifications, widgets, tiles and the app. */
object Logging {
    const val AS_PLANNED = "as_planned"
    const val ESSENTIAL = "essential"
    const val TRIVIAL = "trivial"

    data class Slot(val date: LocalDate, val hour: Int)

    /** Hours of [day] that have ended and have no log. */
    fun missing(repo: Repo, day: DayInfo): List<Int> {
        val now = TimeUtil.now()
        val logged = repo.logs(day.date).map { it.hour }.toSet()
        return day.hours.filter { h -> !day.slotEnd(h).isAfter(now) && h !in logged }
    }

    /** The hour a quick action should log: the latest finished unlogged hour, else the current hour. */
    fun targetSlot(repo: Repo): Slot {
        val now = TimeUtil.now()
        val day = Days.resolve(repo, TimeUtil.logicalDate(now, repo.dayStart()))
        val logged = repo.logs(day.date).map { it.hour }.toSet()
        val prevHour = now.minusHours(1).hour
        val prevDate = TimeUtil.logicalDate(now.minusHours(1), repo.dayStart())
        if (prevDate == day.date && prevHour in day.hours && prevHour !in logged) return Slot(day.date, prevHour)
        if (prevDate != day.date) {
            val pd = Days.resolve(repo, prevDate)
            if (prevHour in pd.hours && repo.logFor(prevDate, prevHour) == null) return Slot(prevDate, prevHour)
        }
        return Slot(day.date, now.hour)
    }

    fun quick(ctx: Context, slot: Slot, kind: String, source: String, text: String? = null): HourLog {
        val repo = Repo.get(ctx)
        val day = Days.resolve(repo, slot.date)
        val block = day.plannedFor(slot.hour)
        val rules = repo.rules()
        val m = text?.let { Classifier.parse(it, rules) }
        val type = when (kind) {
            ESSENTIAL -> Type.ESSENTIAL
            TRIVIAL -> Type.TRIVIAL
            AS_PLANNED -> Cat.defaultType(block?.category)
            else -> m?.type ?: Cat.defaultType(m?.category ?: block?.category)
        }
        val activity = text?.trim()?.takeIf { it.isNotEmpty() } ?: block?.title ?: "Logged hour"
        val followed = when (kind) {
            AS_PLANNED -> Plan.YES
            ESSENTIAL -> if (block?.category == Cat.ESSENTIAL) Plan.YES else null
            else -> null
        }
        val log = HourLog(0, slot.date, slot.hour, 60, activity, m?.category ?: block?.category, m?.ventureId ?: block?.ventureId,
            type, null, null, followed, null, null, null, source, System.currentTimeMillis())
        val id = repo.saveLog(log)
        Hooks.afterChange(ctx)
        return log.copy(id = id)
    }

    fun sameAsLast(ctx: Context, slot: Slot, source: String): HourLog? {
        val repo = Repo.get(ctx)
        val prev = repo.lastLogBefore(slot.date, slot.hour) ?: return null
        val log = prev.copy(id = 0, date = slot.date, hour = slot.hour, minutes = 60, source = source, loggedAt = System.currentTimeMillis(),
            money = null, moneyNote = null)
        val id = repo.saveLog(log)
        Hooks.afterChange(ctx)
        return log.copy(id = id)
    }
}

/** Things to refresh after data changes: widgets and alarms. Set by the app at start-up. */
object Hooks {
    var onChange: ((Context) -> Unit)? = null
    var onScheduleChange: ((Context) -> Unit)? = null
    fun afterChange(ctx: Context) { onChange?.invoke(ctx) }
    fun scheduleChanged(ctx: Context) { onScheduleChange?.invoke(ctx); onChange?.invoke(ctx) }
}
