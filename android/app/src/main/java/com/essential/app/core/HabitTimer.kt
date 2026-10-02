package com.essential.app.core

import android.content.Context
import com.essential.app.data.Repo
import com.essential.app.notify.Alarms
import com.essential.app.notify.Notifier

/**
 * Timer for minute-based habits (meditation, pranayam, walking…). Either a countdown
 * (e.g. 20 min) or open-ended (counts up until you stop). State lives in settings so it
 * survives the app being closed; the end bell is an exact alarm.
 * When finished, the minutes are logged to the habit automatically.
 */
object HabitTimer {
    data class State(
        val habitId: Long, val name: String, val plannedMin: Int, val startedAt: Long,
        /** Wall-clock end for a running countdown; 0 for open-ended. */
        val endAt: Long,
        /** Milliseconds already counted before the current run (pauses). */
        val banked: Long,
        /** When the current run started; 0 while paused. */
        val runSince: Long,
        val intervalMin: Int
    ) {
        val open get() = plannedMin <= 0
        val paused get() = runSince == 0L
        fun elapsedMs(now: Long = TimeUtil.nowMillis()) = banked + if (paused) 0 else (now - runSince)
        fun leftMs(now: Long = TimeUtil.nowMillis()) = if (open) 0 else maxOf(0, plannedMin * 60_000L - elapsedMs(now))
    }

    private val KEYS = listOf("ht_habit", "ht_name", "ht_planned", "ht_started", "ht_end", "ht_banked", "ht_since", "ht_interval")

    fun state(ctx: Context): State? {
        val s = Repo.get(ctx).settings
        val id = s.long("ht_habit"); if (id <= 0) return null
        return State(id, s.str("ht_name"), s.int("ht_planned"), s.long("ht_started"), s.long("ht_end"), s.long("ht_banked"), s.long("ht_since"), s.int("ht_interval"))
    }

    fun isActive(ctx: Context) = state(ctx) != null

    fun start(ctx: Context, habitId: Long, minutes: Int, intervalMin: Int) {
        val repo = Repo.get(ctx)
        val h = repo.habit(habitId) ?: return
        if (isActive(ctx)) finish(ctx, save = true)
        val now = TimeUtil.nowMillis()
        val s = repo.settings
        s.set("ht_habit", h.id); s.set("ht_name", h.name); s.set("ht_planned", minutes); s.set("ht_started", now)
        s.set("ht_banked", 0); s.set("ht_since", now); s.set("ht_interval", intervalMin)
        s.set("ht_last_${h.id}", minutes); s.set("ht_interval_${h.id}", intervalMin)
        if (minutes > 0) { s.set("ht_end", now + minutes * 60_000L); Alarms.scheduleHabitTimerEnd(ctx, now + minutes * 60_000L) } else s.set("ht_end", 0)
        Notifier.habitTimerOngoing(ctx)
    }

    fun pause(ctx: Context) {
        val st = state(ctx) ?: return
        if (st.paused) return
        val s = Repo.get(ctx).settings
        s.set("ht_banked", st.elapsedMs()); s.set("ht_since", 0)
        Alarms.cancelHabitTimerEnd(ctx)
        Notifier.habitTimerOngoing(ctx)
    }

    fun resume(ctx: Context) {
        val st = state(ctx) ?: return
        if (!st.paused) return
        val s = Repo.get(ctx).settings
        val now = TimeUtil.nowMillis()
        s.set("ht_since", now)
        if (!st.open) { val end = now + st.leftMs(now); s.set("ht_end", end); Alarms.scheduleHabitTimerEnd(ctx, end) }
        Notifier.habitTimerOngoing(ctx)
    }

    /** Stop the timer. With [save], the minutes done (at least 1) are logged to the habit. Returns minutes logged. */
    fun finish(ctx: Context, save: Boolean, completed: Boolean = false): Int {
        val st = state(ctx) ?: return 0
        val repo = Repo.get(ctx)
        val mins = if (completed && !st.open) st.plannedMin else Math.round(st.elapsedMs() / 60_000.0).toInt()
        clear(ctx)
        var logged = 0
        if (save && mins >= 1) {
            repo.habit(st.habitId)?.let { h -> repo.logAmount(h, Days.today(repo), mins.toDouble(), note = "Timer"); logged = mins }
        }
        Notifier.cancelHabitTimer(ctx)
        if (completed) Notifier.habitTimerDone(ctx, st.name, logged)
        Hooks.afterChange(ctx)
        return logged
    }

    private fun clear(ctx: Context) {
        val s = Repo.get(ctx).settings
        KEYS.forEach { s.remove(it) }
        Alarms.cancelHabitTimerEnd(ctx)
    }

    fun lastMinutes(ctx: Context, habitId: Long, fallback: Int): Int = Repo.get(ctx).settings.strN("ht_last_$habitId")?.toIntOrNull() ?: fallback
    fun lastInterval(ctx: Context, habitId: Long): Int = Repo.get(ctx).settings.strN("ht_interval_$habitId")?.toIntOrNull() ?: 0
}
