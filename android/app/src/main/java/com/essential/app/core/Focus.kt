package com.essential.app.core

import android.app.NotificationManager
import android.content.Context
import com.essential.app.data.Cat
import com.essential.app.data.HourLog
import com.essential.app.data.Plan
import com.essential.app.data.Repo
import com.essential.app.data.Source
import com.essential.app.data.Type
import com.essential.app.notify.Alarms
import com.essential.app.notify.Notifier

/**
 * Focus session state machine. State lives in settings so it survives process death.
 * While a session runs, hourly check-ins are skipped; on completion the time is logged as ESSENTIAL.
 */
object Focus {
    data class State(val id: Long, val task: String, val planned: Int, val endAt: Long, val pausedLeft: Long, val interruptions: Int, val startedAt: Long) {
        val paused get() = pausedLeft > 0
        fun leftMillis(now: Long = TimeUtil.nowMillis()) = if (paused) pausedLeft else maxOf(0, endAt - now)
    }

    fun state(ctx: Context): State? {
        val s = Repo.get(ctx).settings
        val id = s.long("focus_id")
        if (id <= 0) return null
        return State(id, s.str("focus_task"), s.int("focus_planned"), s.long("focus_end"), s.long("focus_paused_left"),
            s.int("focus_interruptions"), s.long("focus_started"))
    }

    fun isActive(ctx: Context) = state(ctx) != null

    fun start(ctx: Context, minutes: Int, task: String) {
        val repo = Repo.get(ctx)
        stopSilently(ctx)
        val now = TimeUtil.nowMillis()
        val id = repo.addFocus(Days.today(repo), now, minutes, task)
        val s = repo.settings
        s.set("focus_id", id); s.set("focus_task", task); s.set("focus_planned", minutes)
        s.set("focus_end", now + minutes * 60_000L); s.set("focus_paused_left", 0); s.set("focus_interruptions", 0); s.set("focus_started", now)
        if (s.bool("focus_dnd")) setDnd(ctx, true)
        Alarms.scheduleFocusEnd(ctx, now + minutes * 60_000L)
        Notifier.focusOngoing(ctx)
        Hooks.afterChange(ctx)
    }

    fun pause(ctx: Context) {
        val st = state(ctx) ?: return
        if (st.paused) return
        val s = Repo.get(ctx).settings
        s.set("focus_paused_left", maxOf(1000L, st.endAt - TimeUtil.nowMillis()))
        Alarms.cancelFocusEnd(ctx)
        Notifier.focusOngoing(ctx)
    }

    fun resume(ctx: Context) {
        val st = state(ctx) ?: return
        if (!st.paused) return
        val s = Repo.get(ctx).settings
        val end = TimeUtil.nowMillis() + st.pausedLeft
        s.set("focus_end", end); s.set("focus_paused_left", 0)
        Alarms.scheduleFocusEnd(ctx, end)
        Notifier.focusOngoing(ctx)
    }

    fun interrupted(ctx: Context) {
        val st = state(ctx) ?: return
        Repo.get(ctx).settings.set("focus_interruptions", st.interruptions + 1)
    }

    /** End the session. [completed] = ran the full time. Partial sessions still log the focused minutes. */
    fun finish(ctx: Context, completed: Boolean) {
        val st = state(ctx) ?: return
        val repo = Repo.get(ctx)
        val now = TimeUtil.nowMillis()
        val focusedMs = (st.planned * 60_000L - st.leftMillis(now)).coerceAtLeast(0)
        repo.updateFocus(st.id, now, st.interruptions, completed)
        if (completed || focusedMs >= 10 * 60_000L) logFocusTime(ctx, now - focusedMs, now, st.task, st.interruptions)
        clear(ctx)
        Notifier.cancelFocus(ctx)
        if (completed) Notifier.focusDone(ctx, st.planned, st.task)
        Hooks.afterChange(ctx)
    }

    private fun stopSilently(ctx: Context) { if (state(ctx) != null) finish(ctx, false) }

    private fun clear(ctx: Context) {
        val s = Repo.get(ctx).settings
        if (s.bool("focus_dnd")) setDnd(ctx, false)
        listOf("focus_id", "focus_task", "focus_planned", "focus_end", "focus_paused_left", "focus_interruptions", "focus_started").forEach { s.remove(it) }
        Alarms.cancelFocusEnd(ctx)
    }

    /** Split the focused span into clock-hour slots and log each as Essential. */
    fun logFocusTime(ctx: Context, startMs: Long, endMs: Long, task: String, interruptions: Int) {
        val repo = Repo.get(ctx)
        val ds = repo.dayStart()
        var t = TimeUtil.at(startMs)
        val end = TimeUtil.at(endMs)
        while (t.isBefore(end)) {
            val hourEnd = t.withMinute(0).withSecond(0).withNano(0).plusHours(1)
            val segEnd = if (hourEnd.isBefore(end)) hourEnd else end
            val mins = java.time.Duration.between(t, segEnd).toMinutes().toInt()
            if (mins > 0) {
                val date = TimeUtil.logicalDate(t, ds)
                val existing = repo.logFor(date, t.hour)
                val block = Days.resolve(repo, date).plannedFor(t.hour)
                val total = minOf(60, mins + (existing?.takeIf { it.source == Source.FOCUS }?.minutes ?: 0))
                repo.saveLog(HourLog(existing?.id ?: 0, date, t.hour, total, task.ifBlank { "Focus session" }, block?.category ?: Cat.ESSENTIAL,
                    block?.ventureId, Type.ESSENTIAL, if (interruptions == 0) 5 else 4, null,
                    if (block?.category == Cat.ESSENTIAL) Plan.YES else Plan.PARTLY, if (block?.category == Cat.ESSENTIAL) null else "Focus session",
                    null, null, Source.FOCUS, TimeUtil.nowMillis()))
            }
            t = segEnd
        }
    }

    fun dndAccess(ctx: Context): Boolean = (ctx.getSystemService(NotificationManager::class.java)).isNotificationPolicyAccessGranted

    private fun setDnd(ctx: Context, on: Boolean) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (!nm.isNotificationPolicyAccessGranted) return
        val s = Repo.get(ctx).settings
        try {
            if (on) {
                s.set("focus_prev_filter", nm.currentInterruptionFilter)
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
            } else {
                val prev = s.int("focus_prev_filter").takeIf { it > 0 } ?: NotificationManager.INTERRUPTION_FILTER_ALL
                nm.setInterruptionFilter(prev)
            }
        } catch (_: SecurityException) { }
    }
}
